# skills/create-skill-workflow/mod.nu

export def create-skill-workflow [
    --subset: list<string> = [] # Optional list of files or glob patterns to process
] {
    let files = if ($subset | is-empty) {
        glob *.md
    } else {
        $subset | each { |it| glob $it } | flatten | uniq
    }

    if ($files | is-empty) {
        print "No markdown files found."
        return
    }

    $files | each { |file|
        process-file $file
    }
}

def process-file [file: path] {
    let file_path = $file | path expand
    print $"[create-skill-workflow] Processing ($file_path)..."
    
    # 1. execute nushell command `add-preamble file.md`
    if (which add-preamble | is-empty) {
        print $"[create-skill-workflow] Error: 'add-preamble' not found. Skipping ($file_path)."
        return
    }
    
    add-preamble $file_path
    
    # 2. remove from the preamble the author
    let content = open --raw $file_path
    
    # Remove author line from frontmatter
    let cleaned_content = $content | str replace -r '(?m)^author:.*?\n' ''
    
    $cleaned_content | save -f $file_path
}
