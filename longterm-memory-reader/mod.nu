# longterm-memory-reader/mod.nu

# Helper to get the vault path from environment or fallback.
export def get-vault [] {
    let env_vault = try { $env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT } catch { null }
    let vault = $env_vault | default $env.OBSIDIAN_VAULT_ROOT? | default "~/workspace/obsidian/vaults"
    $vault | path expand
}

# Helper to find the project root by walking up directories.
# Looks for 'conductor/' first, then '.git/'.
export def find-project-root [start_path: path]: nothing -> record {
    let start_expanded = $start_path | path expand
    let is_file = ($start_expanded | path exists) and (($start_expanded | path type) == "file")
    mut curr = if $is_file { $start_expanded | path dirname } else { $start_expanded }
    loop {
        if ([$curr "conductor"] | path join | path exists) {
            return { path: $curr, type: "conductor" }
        }
        if ([$curr ".git"] | path join | path exists) {
            return { path: $curr, type: "git" }
        }
        let parent = $curr | path dirname
        if $parent == $curr {
            break
        }
        $curr = $parent
    }
    return { path: (if $is_file { $start_expanded | path dirname } else { $start_expanded }), type: "none" }
}

# Helper to get the absolute path of a long-term memory note.
export def get-note-path [
    slug: string,
    --vault: path
]: nothing -> path {
    let vault_path = $vault | default (get-vault)
    [$vault_path "AGENTS_MEMORY" $slug $"($slug).md"] | path join
}

# Helper to parse YAML frontmatter from a markdown string.
# Returns a record or null on failure.
export def parse-frontmatter [content: string]: nothing -> any {
    # Strip UTF-8 BOM if present
    let content = $content | str replace --regex '^\u{FEFF}' ''
    # Extract only the first frontmatter block bounded by leading ---
    let parsed = $content | parse --regex '(?s)\A---\r?\n(?P<fm>.*?)\r?\n---'
    if ($parsed | is-empty) {
        return null
    }
    let result = $parsed | get 0.fm
    try { $result | from yaml } catch { null }
}

# Helper to get body text after frontmatter block.
export def get-body [content: string]: nothing -> string {
    # Strip UTF-8 BOM if present
    let content = $content | str replace --regex '^\u{FEFF}' ''
    let lines = $content | lines
    let delimiters = $lines | enumerate | where item == "---" | get index
    
    # The first --- must be at the very start of the file (index 0) for frontmatter to exist
    if ($delimiters | is-empty) or ($delimiters | get 0) != 0 or ($delimiters | length) < 2 {
        return $content
    }
    
    let body_start = ($delimiters | get 1) + 1
    $lines | skip $body_start | str join "\n"
}

# Helper to load YYYY-MM-DD.md files in a project folder.
# Caps retrieval to the last 30 days of activity by default.
def load-daily-entries [dir: path, days: int = 30]: nothing -> string {
    if not ($dir | path exists) {
        return ""
    }
    
    let threshold = (date now) - ($days * 1day)
    let files = ls $dir
        | where type == file
        | where name =~ '\d{4}-\d{2}-\d{2}\.md$'
        | sort-by name
        | where { |f| (try { $f.name | path basename | str replace ".md" "" | into datetime } catch { (date now) - 36500day }) >= $threshold }
    
    let entries = $files | each { |file|
        let date = $file.name | path basename | str replace ".md" ""
        let content = open --raw $file.name
        # Strip frontmatter if present
        let body = get-body $content | str trim
        $"## ($date)\n\n($body)"
    }
    
    $entries | str join "\n\n"
}

# Helper to load YYYY-MM-DD-log.md files in a project folder.
# Caps retrieval to the last 30 days of activity by default.
export def load-trajectory-logs [dir: path, days: int = 30]: nothing -> string {
    if not ($dir | path exists) {
        return ""
    }
    
    let threshold = (date now) - ($days * 1day)
    let files = ls $dir
        | where type == file
        | where name =~ '\d{4}-\d{2}-\d{2}-log\.md$'
        | sort-by name
        | where { |f| (try { $f.name | path basename | str replace "-log.md" "" | into datetime } catch { (date now) - 36500day }) >= $threshold }
    
    let entries = $files | each { |file|
        let date = $file.name | path basename | str replace "-log.md" ""
        let content = open --raw $file.name
        # Strip frontmatter if present
        let body = get-body $content | str trim
        $"## ($date) Log\n\n($body)"
    }
    
    $entries | str join "\n\n"
}

# Get long-term memory context for a given path.
export def get-context [
    path: path,            # The absolute path of the current project.
    --vault: path          # Optional: Override the vault path.
]: nothing -> any {
    let vault_path = $vault | default (get-vault)
    let agents_memory = [$vault_path "AGENTS_MEMORY"] | path join

    # Gracefully return null if AGENTS_MEMORY directory doesn't exist yet
    if not ($agents_memory | path exists) {
        return null
    }

    let root_info = find-project-root $path
    if $root_info.type == "none" {
        print -e $"Warning: The path \(($path)\) is not within a Conductor or Git project. Proceeding with it directly as project root."
    }
    let project_dir = $root_info.path
    let basename = $project_dir | path basename
    let guessed_slugs = [
        ($basename | str lowercase | str replace --all " " "_" | str replace --all "-" "_" | str replace --regex --all "[^a-z0-9_]" "")
    ]
    
    # Try to extract project name from product.md if it exists
    let product_md = $"($project_dir)/conductor/product.md"
    let guessed_slugs = if ($product_md | path exists) {
        let content = open --raw $product_md | str replace --regex '^\u{FEFF}' ''
        let parsed = $content | parse --regex '(?m)^# Product Definition: (?P<name>.*)$'
        if not ($parsed | is-empty) {
            let name_match = $parsed | get 0.name | str trim
            let slug = $name_match | str lowercase | str replace --all " " "_" | str replace --all "-" "_" | str replace --regex --all "[^a-z0-9_]" ""
            $guessed_slugs | append $slug
        } else {
            $guessed_slugs
        }
    } else {
        $guessed_slugs
    }

    mut match_data: any = null
    for slug in ($guessed_slugs | uniq) {
        let dir = [$agents_memory $slug] | path join
        let f = [$dir $"($slug).md"] | path join
        if ($f | path exists) {
            let content = open --raw $f
            let data = parse-frontmatter $content
            let note_path = if $data != null and not ($data.absolute_path? | is-empty) { try { $data.absolute_path | path expand | into string } catch { "" } } else { "" }
            if $data != null and $note_path == ($project_dir | into string) {
                let body = load-daily-entries $dir
                $match_data = {
                    file: $f,
                    data: $data,
                    body: $body
                }
                break
            }
        }
    }

    if $match_data == null {
        # Fallback to linear scan of directories under AGENTS_MEMORY
        let dirs = ls $agents_memory
            | where type == dir
            | get name
        
        let matches = $dirs | each { |dir|
            let slug = $dir | path basename
            let f = [$dir $"($slug).md"] | path join
            if ($f | path exists) {
                let content = open --raw $f
                let data = parse-frontmatter $content
                let note_path = if $data != null and not ($data.absolute_path? | is-empty) { try { $data.absolute_path | path expand | into string } catch { "" } } else { "" }
                if $data != null and $note_path == ($project_dir | into string) {
                    let body = load-daily-entries $dir
                    {
                        file: $f,
                        data: $data,
                        body: $body
                    }
                } else {
                    null
                }
            } else {
                null
            }
        } | compact
        
        $match_data = if ($matches | is-empty) { null } else { $matches | first }
    }

    if $match_data == null {
        return null
    }

    # Load Global Context (Truncated for context efficiency)
    let brain_file = [$agents_memory "BRAIN.md"] | path join
    let brain_raw = if ($brain_file | path exists) {
        open --raw $brain_file
    } else { "" }
    let brain_len = $brain_raw | str length
    let brain = if $brain_len > 5000 {
        ($brain_raw | str substring 0..5000) + "\n\n... [BRAIN.md Truncated] ..."
    } else { $brain_raw }
    
    let soul_file = [$agents_memory "SOUL.md"] | path join
    let soul_raw = if ($soul_file | path exists) {
        open --raw $soul_file
    } else { "" }
    let soul_len = $soul_raw | str length
    let soul = if $soul_len > 5000 {
        ($soul_raw | str substring 0..5000) + "\n\n... [SOUL.md Truncated] ..."
    } else { $soul_raw }

    let body_len = $match_data.body | str length
    let recent_entries = if $body_len > 8000 {
        let first_part = $match_data.body | str substring 0..2000
        let last_start = $body_len - 6000
        let last_end = $body_len - 1
        let last_part = $match_data.body | str substring $last_start..$last_end
        $"($first_part)\n\n... [Truncated History] ...\n\n($last_part)"
    } else {
        $match_data.body
    }

    let file_path = $match_data.file | path expand | into string
    let resolved_slug = $match_data.file | path dirname | path basename

    let recent_logs = load-trajectory-logs ($match_data.file | path dirname)
    return {
        project_name: (try { $match_data.data.project_name } catch { null }),
        path: (try { $match_data.data.absolute_path } catch { null }),
        description: (try { $match_data.data.description } catch { null }),
        uses_conductor: (try { $match_data.data.uses_conductor } catch { null }),
        uses_git: (try { $match_data.data.uses_git } catch { null }),
        last_updated: (try { $match_data.data.last_updated } catch { null }),
        slug: $resolved_slug,
        file_path: $file_path,
        recent_entries: $recent_entries,
        recent_logs: $recent_logs,
        brain: $brain,
        soul: $soul
    }
}

# Alias for get-context to match naming conventions in other skills.
# Returns a clean Markdown string suitable for context-loading without token bloat.
export def init-session [
    path: path,
    --vault: path
]: nothing -> string {
    let ctx = get-context $path --vault $vault
    if $ctx == null {
        return "null"
    }

    let out = [
        $"# LTM Context: ($ctx.project_name | default 'Unknown Project')",
        $"- **Path**: ($ctx.path)",
        $"- **Slug**: ($ctx.slug)",
        $"- **File**: ($ctx.file_path)",
        $"- **Conductor**: ($ctx.uses_conductor)",
        $"- **Git**: ($ctx.uses_git)",
        $"- **Last Updated**: ($ctx.last_updated | default 'Never')",
        "",
        $"## Description\n($ctx.description | default 'No description.')",
        "",
        $"## SOUL.md \(Agent Identity\)\n($ctx.soul)",
        "",
        $"## BRAIN.md \(Semantic Memory\)\n($ctx.brain)",
        "",
        $"## Recent Episodic Memory\n($ctx.recent_entries)"
    ]

    $out | str join "\n"
}

# Consolidation State & Data Gathering

# Get the path to the consolidation state file.
def get-state-path [vault: path]: nothing -> path {
    [$vault "AGENTS_MEMORY" ".consolidation_state.json"] | path join
}

# Read the last consolidation date from the state file.
export def get-consolidation-state [--vault: path]: nothing -> any {
    let vault_path = $vault | default (get-vault)
    let state_file = get-state-path $vault_path
    
    if ($state_file | path exists) {
        return (open $state_file)
    }
    
    return {
        last_consolidation_date: null
    }
}

# Update the last consolidation date in the state file.
export def update-consolidation-state [date: datetime, --vault: path]: nothing -> nothing {
    let vault_path = $vault | default (get-vault)
    let state_file = get-state-path $vault_path
    
    let state = {
        last_consolidation_date: ($date | format date "%Y-%m-%d")
    }
    
    $state | save -f $state_file
}

# Gathers entries from episodic memory notes since the last consolidation.
export def gather-unconsolidated-memories [--limit: int = 10, --vault: path]: nothing -> any {
    let vault_path = $vault | default (get-vault)
    let agents_memory = [$vault_path "AGENTS_MEMORY"] | path join
    
    if not ($agents_memory | path exists) {
        return []
    }
    
    let state = get-consolidation-state --vault $vault_path
    let last_date = if ($state.last_consolidation_date | is-not-empty) {
        $state.last_consolidation_date | into datetime
    } else {
        (date now) - 365day # Default to 1 year ago if no state
    }
    
    let project_dirs = ls $agents_memory | where type == dir | get name
    
    let entries = $project_dirs | each { |dir|
        let slug = $dir | path basename
        let daily_files = ls $dir 
            | where type == file 
            | where name =~ '\d{4}-\d{2}-\d{2}\.md$'
            | where { |f| 
                let f_date = $f.name | path basename | str replace ".md" "" | into datetime
                $f_date > $last_date
              }
        
        if ($daily_files | is-not-empty) {
            let recent_body = $daily_files | each { |f|
                let date_str = $f.name | path basename | str replace ".md" ""
                let content = open --raw $f.name
                let body = get-body $content | str trim
                $"## ($date_str)\n\n($body)"
            } | str join "\n\n"
            
            # Read index note for project name
            let index_note = [$dir $"($slug).md"] | path join
            let project_name = if ($index_note | path exists) {
                let fm = parse-frontmatter (open --raw $index_note)
                $fm.project_name? | default $slug
            } else {
                $slug
            }
            
            {
                project_name: $project_name,
                last_updated: ($daily_files | last | get name | path basename | str replace ".md" ""),
                recent_body: $recent_body,
                slug: $slug
            }
        } else {
            null
        }
    } | compact | sort-by last_updated --reverse | first $limit
    
    return $entries
}
