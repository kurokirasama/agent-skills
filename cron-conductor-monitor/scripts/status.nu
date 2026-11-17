export def get-status [conductor_path: string, root: string = ""] {
    let tracks_file = $conductor_path | path join "tracks.md"
    let parent_dir = $conductor_path | path dirname
    let todos_file = $parent_dir | path join "todos.md"

    let full_path = $parent_dir | path expand
    let expanded_root = if ($root | is-empty) {
        $conductor_path | path dirname | path dirname
    } else {
        $root
    } | path expand

    # Calculate folder relative to root
    let is_under_root = ($full_path | str starts-with $expanded_root)
    let relative_path = if $is_under_root {
        $full_path | str replace $expanded_root "" | str trim --left --char (char path_sep)
    } else {
        $full_path | path basename
    }
    let path_parts = $relative_path | path split
    let parent_folder = if $is_under_root and ($path_parts | length) > 1 {
        $path_parts | first
    } else {
        $relative_path
    }

    let pending_tracks = if ($tracks_file | path exists) {
        # Parsing Project Tracks Registry
        let content = open --raw $tracks_file | str replace --regex '^\u{FEFF}' ''
        let lines = $content | lines | str trim
        let track_indices = $lines | enumerate | where { |it| $it.item =~ '^-\s*\[[\s~]\]' } | get index

        $track_indices | each { |idx|
            let line = $lines | get $idx
            let status_char = $line | parse --regex '.*?-\s*\[(?<status>[\s~])\].*' | get 0?.status | default " "
            let status = if $status_char == "~" { "In Progress" } else { "Pending" }
            
            # Try Format A (inline link)
            let match_a = $line | parse --regex '.*?-\s*\[[\s~]\]\s*\[(?<title>[^\]]+)\]\(\s*(?:\./)?tracks/(?<id>[^/\s\)]+)(?:/.*)?\)'
            if ($match_a | is-not-empty) {
                let r = $match_a | get 0
                { id: $r.id, title: $r.title, status: $status }
            } else {
                # Try Format B (Track: title)
                let match_b = $line | parse --regex '.*?-\s*\[[\s~]\]\s*\*\*Track:\s*(?<title>.*?)\*\*.*'
                mut title = if ($match_b | is-not-empty) {
                    $match_b | get 0.title
                } else {
                    $line | str replace -r '^-\s*\[[\s~]\]\s*' ''
                }
                
                # Scan same line for ID first (Format B with inline link)
                mut id = "unknown"
                let same_line_id = $line | parse --regex '.*?tracks/(?<id>[^/\s\)]+)(?:/.*)?'
                if ($same_line_id | is-not-empty) {
                    $id = $same_line_id | get 0.id
                }
                
                # If title contains a markdown link, strip link brackets for display
                let clean_title_match = $title | parse --regex '.*?\[(?<clean_title>[^\]]+)\]\(\s*(?:\./)?tracks/.*?\)'
                if ($clean_title_match | is-not-empty) {
                    $title = $clean_title_match | get 0.clean_title
                }
                
                # If ID is still unknown, scan subsequent lines for ID
                if $id == "unknown" {
                    let next_lines = $lines | skip ($idx + 1)
                    for next_line in $next_lines {
                        if ($next_line =~ '^-\s*\[') {
                            break # Reached next track, stop search
                        }
                        if ($next_line =~ 'Link:' or $next_line =~ 'tracks/') {
                            let parsed_id = $next_line | parse --regex '.*?tracks/(?<id>[^/\s\)]+)(?:/.*)?'
                            if ($parsed_id | is-not-empty) {
                                $id = $parsed_id | get 0.id
                                break
                            }
                        }
                    }
                }
                { id: $id, title: $title, status: $status }
            }
        }
    } else {
        []
    }
    let pending_todos = if ($todos_file | path exists) {
        let content = open --raw $todos_file | str replace --regex '^\u{FEFF}' ''
        $content
        | lines 
        | where { |line| $line =~ '^\s*[-*]?\s*\[[\s~]\]' }
        | each { |line| 
            $line | str replace -r '^\s*[-*]?\s*\[[\s~]\]\s*' ''
        } | str trim | where { |todo| $todo != "" }
    } else {
        []
    }

    if ($pending_tracks | is-empty) and ($pending_todos | is-empty) {
        return null
    }

    let project_name = $parent_dir | path basename

    {
        folder: $parent_folder,
        project: $project_name,
        path: $parent_dir,
        tracks: $pending_tracks,
        todos: $pending_todos
    }
}

def main [conductor_path: string, root: string = ""] {
    let res = get-status $conductor_path $root
    if $res != null {
        $res | to json
    }
}