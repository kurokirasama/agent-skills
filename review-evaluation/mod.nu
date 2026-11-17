# skills/review-evaluation/mod.nu
# Shared utilities for the review-evaluation skill.

# Auto-detect programming language from file extensions in a directory.
export def detect-language [dir: path] {
    let files = glob $"($dir)/**/*"
    let extensions = $files
        | each { |f| $f | path parse | get extension }
        | uniq

    let lang = if ($extensions | any { |e| $e in ["py", "ipynb"] }) {
        "python"
    } else if ($extensions | any { |e| $e in ["R", "r", "Rmd"] }) {
        "r"
    } else if ($extensions | any { |e| $e in ["m"] }) {
        "octave"
    } else {
        "unknown"
    }

    { language: $lang, extensions: $extensions }
}

# Decompress archives (.zip, .rar, .7z, .tar.gz) in-place in a directory.
export def decompress-archives [dir: path] {
    let archives = glob $"($dir)/*.{zip,rar,7z,tar.gz,tgz}"

    if ($archives | is-empty) {
        return
    }

    for archive in $archives {
        let ext = $archive | path parse | get extension | str lowercase

        match $ext {
            "zip" => {
                let result = try {
                    ^unzip -o $archive -d $dir | complete
                } catch {
                    { exit_code: 1, stderr: "unzip command not found or failed" }
                }
                if $result.exit_code != 0 {
                    print $"Decompress warning: unzip failed for ($archive)"
                }
            }
            "rar" => {
                let result = try {
                    ^unrar x -o+ $archive $dir | complete
                } catch {
                    { exit_code: 1, stderr: "unrar command not found or failed" }
                }
                if $result.exit_code != 0 {
                    print $"Decompress warning: unrar failed for ($archive)"
                }
            }
            "7z" => {
                let result = try {
                    ^7z x $archive $"-o($dir)" -y | complete
                } catch {
                    { exit_code: 1, stderr: "7z command not found or failed" }
                }
                if $result.exit_code != 0 {
                    print $"Decompress warning: 7z failed for ($archive)"
                }
            }
            "gz" | "tgz" => {
                let result = try {
                    ^tar -xzf $archive -C $dir | complete
                } catch {
                    { exit_code: 1, stderr: "tar command not found or failed" }
                }
                if $result.exit_code != 0 {
                    print $"Decompress warning: tar failed for ($archive)"
                }
            }
            _ => { print $"Unsupported archive format: ($ext)" }
        }
    }

    let nested = glob $"($dir)/**/*.{zip,rar,7z,tar.gz}"
    if not ($nested | is-empty) {
        for n in $nested {
            let parent = $n | path dirname
            decompress-archives $parent
        }
    }
}

# Update a field in grupos.json at the given group index.
export def update-grupos-json [
    path: string, grupo: int, key: string, value: any
] {
    let data = open --raw $path | from json
    let idx = $grupo - 1

    let updated = $data
        | enumerate
        | each { |row|
            if ($row.index == $idx) {
                $row.item | upsert $key $value
            } else {
                $row.item
            }
        }

    $updated | to json | save -f $path
}

# Get the shell command to run a file in the given language.
export def get-run-command [language: string, file: string] {
    match $language {
        "python" => $"python3 ($file)"
        "r" => $"Rscript ($file)"
        "octave" => $"octave --no-gui ($file)"
        _ => $"(language) ($file)"
    }
}
