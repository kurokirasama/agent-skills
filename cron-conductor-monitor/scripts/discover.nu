def main [root?: string, --json-file: string] {
    if ($json_file | is-not-empty) {
        let file = $json_file | path expand
        if not ($file | path exists) {
            print -e $"Error: JSON file not found: ($file)"
            return
        }
        open $file | each { |p| print $p }
        return
    }

    let base = ($root | default "~/workspace" | path expand)
    let paths = glob $"($base)/**/conductor" --exclude [ "**/node_modules/**" "**/.git/**" "**/target/**" "**/venv/**" "**/.venv/**" "**/.cache/**" "**/build/**" "**/dist/**" ] | each { |p| $p | into string }
    $paths | str join "\n"
}
