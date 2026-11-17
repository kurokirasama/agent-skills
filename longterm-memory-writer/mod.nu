# longterm-memory-writer/mod.nu
use ../longterm-memory-reader/mod.nu *

# Helper to check if a slug has a collision with another project in AGENTS_MEMORY.
# If a collision is found (same slug, but different absolute_path in the note's frontmatter),
# it returns a unique slug by appending a suffix.
# Case-insensitive: if a directory exists with different casing but same project path,
# the existing directory name is reused to avoid duplicates on case-sensitive filesystems.
export def resolve-unique-slug [
    slug: string,
    absolute_path: path,
    --vault: path
]: nothing -> any {
    let vault_path = $vault | default (get-vault)
    let path_str = $absolute_path | path expand | into string

    # Case-insensitive scan of existing AGENTS_MEMORY directories
    let agents_memory = [$vault_path "AGENTS_MEMORY"] | path join
    let slug_lower = $slug | str lowercase
    if ($agents_memory | path exists) {
        let existing = ls $agents_memory
            | where type == dir
            | get name
            | where { |dir| ($dir | path basename | str lowercase) == $slug_lower }
            | first 1
        if ($existing | is-not-empty) {
            let existing_dir = $existing | first | path basename
            let note_path = get-note-path $existing_dir --vault $vault_path
            if ($note_path | path exists) {
                let content = open --raw $note_path
                let data = parse-frontmatter $content
                if $data != null {
                    let note_abs_path = if not ($data.absolute_path? | is-empty) {
                        try { $data.absolute_path | path expand | into string } catch { "" }
                    } else { "" }
                    if $note_abs_path == $path_str {
                        # Same project with different casing: reuse existing directory name
                        return $existing_dir
                    }
                }
            }
        }
    }

    # Fallback: scan ALL existing notes for a matching absolute_path, regardless of
    # slug derivation (e.g. product.md name vs directory basename produce different
    # slugs). Reuse the existing directory to prevent duplicates.
    if ($agents_memory | path exists) {
        let matching = ls $agents_memory
            | where type == dir
            | get name
            | each { |dir_path|
                let dir_name = $dir_path | path basename
                let note_path = get-note-path $dir_name --vault $vault_path
                if ($note_path | path exists) {
                    let content = open --raw $note_path
                    let data = parse-frontmatter $content
                    if $data != null {
                        let note_abs_path = if not ($data.absolute_path? | is-empty) {
                            try { $data.absolute_path | path expand | into string } catch { "" }
                        } else { "" }
                        if $note_abs_path == $path_str { $dir_name } else { "" }
                    } else { "" }
                } else { "" }
            }
            | where { |r| not ($r | is-empty) }
            | first 1
        if ($matching | is-not-empty) {
            return ($matching | first)
        }
    }

    mut current_slug = $slug
    mut counter = 0
    let max_attempts = 99  # Guard against infinite loop (F9 fix)
    
    loop {
        if $counter > $max_attempts {
            # Fallback: use a timestamp-based unique suffix
            let ts = date now | format date "%Y%m%d%H%M%S"
            return $"($slug)_($ts)"
        }

        let note_path = get-note-path $current_slug --vault $vault_path
        if not ($note_path | path exists) {
            return $current_slug
        }
        
        # Read the frontmatter and check if absolute_path matches
        let content = open --raw $note_path
        let data = parse-frontmatter $content
        if $data != null {
            let note_abs_path = if not ($data.absolute_path? | is-empty) {
                try { $data.absolute_path | path expand | into string } catch { "" }
            } else { "" }
            if $note_abs_path == $path_str {
                # It's the same project! No collision, reuse this slug.
                return $current_slug
            }
        }
        
        # Collision detected: slug exists but belongs to a different path!
        # Append a suffix and try again
        $counter = $counter + 1
        $current_slug = $"($slug)_($counter)"
    }
}

# Retrieve project metadata required to manually initialize a long-term memory note.
# This script does NOT write to the file system. It only gathers the necessary data.
export def get-init-metadata [
    path: path,            # The absolute path of the project.
    --vault: path          # Optional: Override the vault path.
]: nothing -> any {
    let root_info = find-project-root $path
    let project_dir = $root_info.path
    let project_name_default = $project_dir | path basename
    
    let product_md = $"($project_dir)/conductor/product.md"
    mut project_name = $project_name_default
    mut description = ""
    
    if ($product_md | path exists) {
        let content = open --raw $product_md
        # Try to extract project name from heading
        let parsed_name = $content | parse --regex '(?m)^# Product Definition: (?P<name>.*)$'
        if not ($parsed_name | is-empty) {
            $project_name = $parsed_name | get 0.name | str trim
        }
        
        # Try to extract summary
        let parsed_summary = $content | parse --regex '(?ms)## Summary\s*\n(?P<summary>.*?)(?:\n##|$)'
        if not ($parsed_summary | is-empty) {
            $description = $parsed_summary | get 0.summary | str trim | str replace --all "\n" " "
        }
    }

    let has_git_cmd = (which git | is-not-empty)
    let uses_git = ($"($project_dir)/.git" | path exists) or ($has_git_cmd and ((try { ^git -C $project_dir rev-parse --is-inside-work-tree | complete | get exit_code } catch { 1 }) == 0))
    let uses_conductor = $"($project_dir)/conductor" | path exists
    
    mut raw_slug = $project_name | str lowercase | str replace --all " " "_" | str replace --all "-" "_" | str replace --regex --all "[^a-z0-9_]" ""
    if ($raw_slug | is-empty) { $raw_slug = "project" }
    let slug = resolve-unique-slug $raw_slug $project_dir --vault $vault
    
    return {
        project_name: $project_name,
        absolute_path: ($project_dir | into string),
        description: $description,
        uses_conductor: $uses_conductor,
        uses_git: $uses_git,
        slug: $slug
    }
}

# Retrieve deep context for initialization (Git, GitHub, Conductor).
# This script automates read-only data gathering to prevent wasting agent turns.
# Output is aggressively throttled to protect the context window.
export def get-deep-context [
    path: path,            # The absolute path of the project.
]: nothing -> record {
    let root_info = find-project-root $path
    let project_dir = $root_info.path | into string
    
    # 1. Git Status & Log (Minimal)
    let has_git_cmd = (which git | is-not-empty)
    let has_git = ($"($project_dir)/.git" | path exists) or ($has_git_cmd and ((try { ^git -C $project_dir rev-parse --is-inside-work-tree | complete | get exit_code } catch { 1 }) == 0))
    let git_info = if $has_git {
        let status = (try { ^git -C $project_dir status --short | complete | get stdout } catch { "" }) | str substring 0..500
        let log = try { ^git -C $project_dir log -n 3 --oneline | complete | get stdout } catch { "" }
        { status: $status, log: $log }
    } else {
        { status: "Not a Git repository.", log: "" }
    }

    # 2. GitHub Info (Minimal Description only)
    let gh_info = if (which gh | is-not-empty) and $has_git {
        let remotes = (try { ^git -C $project_dir remote | complete | get stdout } catch { "" }) | lines | each { |l| l | str trim }
        let has_remote = ($remotes | is-not-empty)
        if $has_remote {
            let remote_name = $remotes | first
            let repo_url = (try { ^git -C $project_dir remote get-url $remote_name | complete | get stdout } catch { "" }) | str trim
            let result = if ($repo_url | is-empty) { "" } else {
                try { ^gh repo view $repo_url --json description | complete | get stdout } catch { "" }
            }
            let desc = try { $result | from json | get description } catch { "" }
            if ($desc | is-empty) { "" } else { $desc }
        } else {
            "No git remote configured."
        }
    } else {
        "GitHub CLI not available or not a git repo."
    }


    # 3. Conductor Info (Throttled to 500 chars)
    let conductor_info = if ($"($project_dir)/conductor" | path exists) {
        let tech_stack = if ($"($project_dir)/conductor/tech-stack.md" | path exists) { open --raw $"($project_dir)/conductor/tech-stack.md" | str substring 0..500 } else { "" }
        let tracks = if ($"($project_dir)/conductor/tracks.md" | path exists) { open --raw $"($project_dir)/conductor/tracks.md" | str substring 0..500 } else { "" }
        { tech_stack: $tech_stack, tracks: $tracks }
    } else {
        { tech_stack: "No Conductor environment.", tracks: "" }
    }

    return {
        git: $git_info,
        github: $gh_info,
        conductor: $conductor_info
    }
}

# Write a trajectory log (YYYY-MM-DD-log.md) for the given project path.
export def write-trajectory-log [
    project_path: path,
    skills: list<string>,
    commands: list<any>,
    tools: list<any>,
    --vault: path
]: nothing -> any {
    let meta = get-init-metadata $project_path --vault $vault
    let slug = $meta.slug
    let vault_path = $vault | default (get-vault)
    let project_mem_dir = $"($vault_path)/AGENTS_MEMORY/($slug)" | path expand
    
    if not ($project_mem_dir | path exists) {
        mkdir $project_mem_dir
    }
    
    let today = date now | format date "%Y-%m-%d"
    let log_file = $"($project_mem_dir)/($today)-log.md"
    
    let session_id = try { $env.GEMINI_SESSION_ID | default "unknown" } catch { "unknown" }
    mut content = $"---
project: ($slug)
date: ($today)
session_id: ($session_id)
---

# Activated Skills
"
    for s in $skills {
        $content = $"($content)- ($s)\n"
    }
    
    $content = $"($content)\n# Executed Commands\n"
    for cmd in $commands {
        let cmd_str = try { $cmd.command? | default $cmd } catch { $cmd }
        let status = try { $cmd.status? | default "Success" } catch { "Success" }
        let output = try { $cmd.output? | default "" } catch { "" }
        let res = try { $cmd.resolution? | default "" } catch { "" }
        let err = try { $cmd.error? | default "" } catch { "" }
        let issue = try { $cmd.issue? | default "" } catch { "" }
        let inconsistency = try { $cmd.inconsistency? | default "" } catch { "" }
        
        $content = $"($content)- **Command:** `($cmd_str)`\n  - **Status:** ($status)\n"
        if not ($output | is-empty) {
            $content = $"($content)  - **Output Description:** ($output)\n"
        }
        if not ($err | is-empty) {
            $content = $"($content)  - **Error/Issue:** ($err)\n"
        }
        if not ($issue | is-empty) {
            $content = $"($content)  - **Issue:** ($issue)\n"
        }
        if not ($inconsistency | is-empty) {
            $content = $"($content)  - **Inconsistency:** ($inconsistency)\n"
        }
        if not ($res | is-empty) {
            $content = $"($content)  - **Resolution:** ($res)\n"
        }
    }
    
    $content = $"($content)\n# MCP Tool Calls\n"
    for tool in $tools {
        let name = try { $tool.name? | default "" } catch { "" }
        let args = try { $tool.arguments? | to json -r } catch { "{}" }
        let status = try { $tool.status? | default "Success" } catch { "Success" }
        let output = try { $tool.output? | default "" } catch { "" }
        let res = try { $tool.resolution? | default "" } catch { "" }
        let err = try { $tool.error? | default "" } catch { "" }
        let issue = try { $tool.issue? | default "" } catch { "" }
        let inconsistency = try { $tool.inconsistency? | default "" } catch { "" }
        
        $content = $"($content)- **Tool:** `($name)`\n  - **Arguments:** `($args)`\n  - **Status:** ($status)\n"
        if not ($output | is-empty) {
            $content = $"($content)  - **Output Description:** ($output)\n"
        }
        if not ($err | is-empty) {
            $content = $"($content)  - **Error/Issue:** ($err)\n"
        }
        if not ($issue | is-empty) {
            $content = $"($content)  - **Issue:** ($issue)\n"
        }
        if not ($inconsistency | is-empty) {
            $content = $"($content)  - **Inconsistency:** ($inconsistency)\n"
        }
        if not ($res | is-empty) {
            $content = $"($content)  - **Resolution:** ($res)\n"
        }
    }
    
    # Safe merge (draft 2026-08-29): preserve existing same-day records with an atomic
    # backup so concurrent agent sessions never clobber each other.
    let existing = if ($log_file | path exists) {
        cp $log_file $"($log_file).bak"
        try { open --raw $log_file } catch { "" }
    } else { "" }

    if not ($existing | is-empty) {
        let session_marker = $"## Session: ($session_id) at"
        if ($existing | str contains $session_marker) {
            # Idempotent: this session is already recorded; drop the stale backup.
            rm -f $"($log_file).bak"
            return
        }
        let session_header = $"\n($session_marker) (date now | format date '%H:%M:%S')\n"
        $content = $existing + $session_header + (strip-frontmatter $content)
    }

    try {
        $content | save --force $log_file
        if ($"($log_file).bak" | path exists) { rm -f $"($log_file).bak" }
    } catch { |err|
        return-error $"Failed to write trajectory log (backup preserved): ($err.msg)"
    }
}

# Appends a dated waypoint entry for an insight note to INSIGHTS/INSIGHTS.md atomically.
# Skips silently if the note is already referenced (idempotent).
# Usage: append-insight-waypoint <insight_path> [--vault <path>]
export def append-insight-waypoint [
    insight_path: path,     # The insight note; its basename is linked in the index.
    --vault: path           # Optional: override the vault path.
]: nothing -> nothing {
    let vault_path = $vault | default (get-vault)
    let index_file = ([$vault_path "INSIGHTS" "INSIGHTS.md"] | path join | path expand)
    if not ($index_file | path exists) { return-error $"INSIGHTS index not found: ($index_file)" }

    let rel = $insight_path | path basename
    let index_content = try { open --raw $index_file } catch { "" }
    let already_linked = $index_content | lines | where { |l| $l | str starts-with $"- [($rel)]\(" } | length
    if $already_linked > 0 { return }

    cp $index_file $"($index_file).bak"
    let entry = $"- [($rel)]\(($rel)\) — (date now | format date '%Y-%m-%d %H:%M')\n"
    try {
        $entry | save --append $index_file
        rm -f $"($index_file).bak"
    } catch { |err|
        return-error $"Failed to update INSIGHTS index (backup preserved): ($err.msg)"
    }
}

# Strips the YAML frontmatter block from a markdown string (private helper).
def strip-frontmatter [content: string]: nothing -> string {
    let lines = $content | lines
    let marks = $lines | enumerate | where { |e| $e.item == "---" } | get index
    if ($marks | length) < 2 { return $content }
    $lines | skip ($marks.1 + 1) | str join "\n" | str trim
}
