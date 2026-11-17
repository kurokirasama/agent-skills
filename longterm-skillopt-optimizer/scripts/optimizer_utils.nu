# skills/longterm-skillopt-optimizer/scripts/optimizer_utils.nu

use /home/username/workspace/llms_configs/skills/longterm-memory-reader/mod.nu [get-vault find-project-root parse-frontmatter get-body]

# Parse trajectory logs for events (failures, errors, and successful executions) in custom skills
export def parse-trajectory-failures [project_path: path, --vault: path, --limit: int = 7]: nothing -> list<record> {
    let vault_path = $vault | default (get-vault)
    let root_info = find-project-root $project_path
    let basename = $root_info.path | path basename
    let slug = $basename | str lowercase | str replace --all " " "_" | str replace --all "-" "_" | str replace --regex --all "[^a-z0-9_]" ""
    
    # Resolve the existing AGENTS_MEMORY directory case-insensitively
    let agents_memory = [$vault_path "AGENTS_MEMORY"] | path join
    let log_dir = if ($agents_memory | path exists) {
        let match = ls $agents_memory
            | where type == dir
            | get name
            | where { |dir| ($dir | path basename | str lowercase) == $slug }
            | first 1
        if ($match | is-not-empty) {
            $match | first
        } else {
            [$agents_memory $slug] | path join
        }
    } else {
        [$agents_memory $slug] | path join
    }
    if not ($log_dir | path exists) { return [] }
    
    let log_files = glob ([$log_dir "*-log.md"] | path join) | sort -r | first $limit
    
    mut events = []
    for f in $log_files {
        let content = open --raw $f
        let lines = $content | lines
        
        let start_idx = try { $lines | enumerate | where { |l| $l.item =~ '^# Activated Skills' } | get 0.index } catch { null }
        if $start_idx == null { continue }
        
        let skills = $lines 
            | skip ($start_idx + 1)
            | take until { |l| $l =~ '^#' } 
            | where { |l| $l =~ '^- ' }
            | each { |l| $l | str replace --regex '^- ' '' | str trim }
            
        let commands = $content | split row "- **Command:**" | skip 1
        for cmd in $commands {
            let cmd_lines = $cmd | lines
            if ($cmd_lines | is-empty) { continue }
            let cmd_text = $cmd_lines | get 0 | str trim | str replace --regex "^`" "" | str replace --regex "`$" ""
            
            # Extract status line
            let status_line = $cmd_lines | where { |l| $l =~ '^\s*-\s*\*\*Status:\*\*' } | get 0?
            let status_val = if $status_line != null {
                $status_line | str replace --regex '^\s*-\s*\*\*Status:\*\*\s*' '' | str trim
            } else { "Success" }
            
            # Extract output description/summary if available
            let output_line = $cmd_lines | where { |l| $l =~ '^\s*-\s*\*\*Output Description:\*\*' or $l =~ '^\s*-\s*\*\*Output:\*\*' } | get 0?
            let output_val = if $output_line != null {
                $output_line | str replace --regex '^\s*-\s*\*\*(Output Description|Output):\*\*\s*' '' | str trim
            } else { "" }
            
            for s in $skills {
                $events = ($events | append {
                    skill: $s,
                    type: "command",
                    event: $cmd_text,
                    status: $status_val,
                    output: $output_val,
                    file: $f
                })
            }
        }
        
        let tools = $content | split row "- **Tool:**" | skip 1
        for tool in $tools {
            let tool_lines = $tool | lines
            if ($tool_lines | is-empty) { continue }
            let tool_text = $tool_lines | get 0 | str trim | str replace --regex "^`" "" | str replace --regex "`$" ""
            
            # Extract status line
            let status_line = $tool_lines | where { |l| $l =~ '^\s*-\s*\*\*Status:\*\*' } | get 0?
            let status_val = if $status_line != null {
                $status_line | str replace --regex '^\s*-\s*\*\*Status:\*\*\s*' '' | str trim
            } else { "Success" }
            
            # Extract output description/summary if available
            let output_line = $tool_lines | where { |l| $l =~ '^\s*-\s*\*\*Output Description:\*\*' or $l =~ '^\s*-\s*\*\*Output:\*\*' } | get 0?
            let output_val = if $output_line != null {
                $output_line | str replace --regex '^\s*-\s*\*\*(Output Description|Output):\*\*\s*' '' | str trim
            } else { "" }
            
            for s in $skills {
                $events = ($events | append {
                    skill: $s,
                    type: "tool",
                    event: $tool_text,
                    status: $status_val,
                    output: $output_val,
                    file: $f
                })
            }
        }
    }
    
    return ($events | uniq)
}


# Load all rejected improvements for reference
export def load-rejected-buffer [--vault: path]: nothing -> string {
    let vault_path = $vault | default (get-vault)
    let processed_dir = [$vault_path "AGENTS_MEMORY" "_draft_improvements" "processed_improvements"] | path join
    if not ($processed_dir | path exists) { return "" }
    
    let files = glob ([$processed_dir "*"] | path join)
    let contents = $files | each { |f|
        if ($f | path type) == "file" {
            let name = $f | path basename
            $"=== FILE: ($name) ===\n(open --raw $f)\n"
        } else { "" }
    } | str join "\n"
    
    return $contents
}

def parse-chunk-skill-name [header: string]: nothing -> string {
    let parsed_skill = $header | parse --regex '`(?P<name>[^`]+)`'
    if ($parsed_skill | is-not-empty) {
        $parsed_skill.0.name
    } else {
        $header | str replace --regex '^\d+\.\s*' '' | str trim
    }
}

def extract-chunk-rationale [chunk: string]: nothing -> string {
    let rationale_match = $chunk | parse --regex '(?m)-\s*\*\*Rationale:\*\*\s*(?P<rationale>.*)$'
    if ($rationale_match | is-not-empty) {
        $rationale_match.0.rationale | str trim
    } else {
        ""
    }
}

def extract-chunk-rejected-content [chunk: string]: nothing -> string {
    let content_match = $chunk | parse --regex '(?s)-\s*\*\*Content:\*\*\s*(?P<content>.*?)(?:\n\s*-\s*\*\*|$)'
    if ($content_match | is-not-empty) and ($content_match.0.content | str trim | is-not-empty) {
        $content_match.0.content | str trim
    } else {
        let patches_match = $chunk | parse --regex '(?s)-\s*\*\*Patches:\*\*\s*(?P<patches>.*)$'
        if ($patches_match | is-not-empty) and ($patches_match.0.patches | str trim | is-not-empty) {
            $patches_match.0.patches | str trim
        } else {
            $chunk | str trim
        }
    }
}

def append-rejected-to-registry [registry_file: path, skill_name: string, content_val: string]: nothing -> nothing {
    mut md_content = if ($registry_file | path exists) { open --raw $registry_file } else { "# Processed Improvements\n\n" }
    if not ($md_content | str contains "## Rejected Improvements (Negative Buffer)") {
        $md_content = ($md_content | str trim) + "\n\n## Rejected Improvements (Negative Buffer)\n\n"
    }
    
    let target_header = $"### `($skill_name)`"
    if not ($md_content | str contains $target_header) {
        $md_content = ($md_content | str trim) + $"\n\n### `($skill_name)`\n($content_val)\n"
        $md_content | save -f $registry_file
        print $"Archived rejected skill ($skill_name) to processed_improvements.md"
    }
}

# Process draft improvements to:
# 1. Scan for rejected plans and archive them immediately to processed_improvements.md.
# 2. Return list of approved plans that the agent needs to manually implement.
# 3. Archive drafts where implemented is true and log approved & rejected chunks to processed_improvements.md.
export def process-drafts [project_path: path, --vault: path]: nothing -> list<record> {
    let vault_path = $vault | default (get-vault)
    let agents_memory = [$vault_path "AGENTS_MEMORY"] | path join
    let draft_dir = [$agents_memory "_draft_improvements"] | path join
    let processed_dir = [$draft_dir "processed_improvements"] | path join
    
    if not ($draft_dir | path exists) { return [] }
    if not ($processed_dir | path exists) { mkdir $processed_dir }
    
    let drafts = glob ([$draft_dir "*.md"] | path join) | each { |f| $f | into string }
    
    mut approved_plans = []
    let registry_file = [$processed_dir "processed_improvements.md"] | path join
    
    for draft in $drafts {
        let content = open --raw $draft
        let fm = parse-frontmatter $content
        if $fm == null { continue }
        
        let draft_name = $draft | path basename
        let date_str = try { $fm.date | into string } catch { "Unknown" }
        let implemented = try { $fm.implemented } catch { false }
        
        let chunks = $content | split row "### " | skip 1
        
        if $implemented {
            # Update registry for implemented draft: only approved chunks go to Implemented, rejected chunks go to Negative Buffer
            mut approved_entries = []
            
            for chunk in $chunks {
                let lines = $chunk | lines
                if ($lines | is-empty) { continue }
                let header = $lines | get 0 | str trim
                if ($header | is-empty) { continue }
                let skill_name = parse-chunk-skill-name $header
                
                let is_approved = $chunk =~ '-\s*\[x\]\s*Approved'
                let is_rejected = $chunk =~ '-\s*\[x\]\s*Not Approved'
                
                if $is_approved or (not $is_rejected) {
                    let rationale = extract-chunk-rationale $chunk
                    $approved_entries = ($approved_entries | append $"- **($header)**: ($rationale)")
                }
                
                if $is_rejected {
                    let content_val = extract-chunk-rejected-content $chunk
                    append-rejected-to-registry $registry_file $skill_name $content_val
                }
            }
            
            if not ($approved_entries | is-empty) {
                mut md_content = if ($registry_file | path exists) { open --raw $registry_file } else { "# Processed Improvements\n\n" }
                if not ($md_content | str contains "## Implemented Improvements") {
                    $md_content = "# Processed Improvements\n\n## Implemented Improvements\n\n" + ($md_content | str replace "# Processed Improvements\n\n" "" | str replace "# Processed Improvements\n" "")
                }
                
                let draft_header = $"### Draft: `($draft_name)`"
                if not ($md_content | str contains $draft_header) {
                    mut entry_text = $"### Draft: `($draft_name)` \(Date: ($date_str)\)\n"
                    for entry in $approved_entries {
                        $entry_text = ($entry_text + $"($entry)\n")
                    }
                    
                    if ($md_content | str contains "## Rejected Improvements (Negative Buffer)") {
                        let parts = $md_content | split row "## Rejected Improvements (Negative Buffer)"
                        $md_content = ($parts.0 | str trim) + $"\n\n($entry_text)\n\n## Rejected Improvements \(Negative Buffer\)" + $parts.1
                    } else {
                        $md_content = ($md_content | str trim) + $"\n\n($entry_text)\n"
                    }
                    $md_content | save -f $registry_file
                }
            }
            
            mv $draft $processed_dir
            print $"Archived implemented draft: ($draft_name)"
            continue
        }
        
        # Handling drafts with implemented: false
        mut all_chunks_decided = true
        mut has_undecided_approvals = false
        
        for chunk in $chunks {
            let lines = $chunk | lines
            if ($lines | is-empty) { continue }
            let header = $lines | get 0 | str trim
            if ($header | is-empty) { continue }
            let skill_name = parse-chunk-skill-name $header
            
            let is_approved = $chunk =~ '-\s*\[x\]\s*Approved'
            let is_rejected = $chunk =~ '-\s*\[x\]\s*Not Approved'
            
            if $is_approved {
                let file_match = $chunk | parse --regex '(?m)-\s*\*\*File:\*\*\s*(?P<file>.*)$'
                let rel_file = if ($file_match | is-empty) { "" } else { $file_match.0.file | str trim }
                
                let patch_start = try { $lines | enumerate | where { |l| $l.item =~ '-\s*\*\*Patches:\*\*' } | get 0.index } catch { null }
                mut patches_text = ""
                if $patch_start != null {
                    let raw_patches = $lines | skip ($patch_start + 1)
                    $patches_text = $raw_patches | str join "\n"
                }
                
                $approved_plans = ($approved_plans | append {
                    draft_file: $draft_name,
                    skill: $skill_name,
                    file: $rel_file,
                    patches: $patches_text
                })
                $has_undecided_approvals = true
            } else if $is_rejected {
                let content_val = extract-chunk-rejected-content $chunk
                append-rejected-to-registry $registry_file $skill_name $content_val
            } else {
                $all_chunks_decided = false
            }
        }
        
        # If all chunks are decided, and there are NO approved plans that still need implementing
        # (e.g. they were all rejected), archive the file immediately.
        if $all_chunks_decided and (not $has_undecided_approvals) {
            mv $draft $processed_dir
            print $"Archived decided draft ($draft_name) to processed_improvements/"
        }
    }
    
    return $approved_plans
}



