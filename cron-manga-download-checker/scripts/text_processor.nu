# Text Processing Library for cron-manga-download-checker
# Focused strictly on HTML-to-text conversion and Regex extraction.

# Strip HTML from email content.
# Returns plain text version of the HTML.
export def strip-html [html?: string] {
    let input = if ($html | is-empty) { $in } else { $html }
    return ($input | ^html2text)
}

# Extract the manga name, chapter number, and URL from text.
# Returns a record { name: string, chapter: string, url: string/null } or null.
export def parse-manga-info [text: string] {
    # Split by lines and process each line
    let lines = $text | lines | each { |it| $it | str trim } | where { |it| $it | is-not-empty }
    
    # Extract URL if present
    let url_regex = '(?i)(?P<url>https?://(?:https?://)?(?:[a-zA-Z0-9-]+\.)?fanfox\.net/manga/[^\s"''\>]+)'
    let url_match = $text | parse -r $url_regex
    let url = if ($url_match | is-empty) == false {
        $url_match | get url | first
    } else {
        null
    }

    for line in $lines {
        # Pattern 1: Vol + Ch
        let vol_ch_regex = '(?i)(?P<name>.+?)\s+Vol\.\d+\s+Ch\.(?P<chapter>\d+(?:\.\d+)?)'
        let vol_ch_match = $line | parse -r $vol_ch_regex
        if ($vol_ch_match | is-empty) == false {
            let res = $vol_ch_match | last | update name { |it| $it.name | split row ":" | last | str trim }
            return ($res | insert url $url)
        }

        # Pattern 2: Simple Ch
        let ch_regex = '(?i)(?P<name>.+?)\s+Ch\.(?P<chapter>\d+(?:\.\d+)?)'
        let ch_match = $line | parse -r $ch_regex
        if ($ch_match | is-empty) == false {
            let res = $ch_match | last | update name { |it| $it.name | split row ":" | last | str trim }
            return ($res | insert url $url)
        }
    }

    return null
}

# Find and parse all existing URLs in folderwatched crawljob files
def get-existing-crawljob-urls [folderwatched: path] {
    let files = glob ($folderwatched | path join "*.crawljob")
    if ($files | is-empty) {
        return []
    }
    
    let regex = '(?i)(?P<url>https?://(?:https?://)?(?:[a-zA-Z0-9-]+\.)?fanfox\.net/manga/[^\s,\]\n\r]+)'
    let urls = $files | each { |f|
        let content = open $f -r
        let matches = $content | parse -r $regex
        if ($matches | is-empty) {
            []
        } else {
            $matches | get url
        }
    } | flatten | uniq | str trim
    
    return $urls
}

# Generate a JDownloader crawljob file containing non-duplicate missing chapter URLs.
# Returns the path of the created file, or null if no new URLs were added.
export def generate-crawljob [
    urls: list<string>
    --folderwatched: path = "/home/username/cloud/Aplicaciones/Gmail/folderwatched"
] {
    # Clean and filter incoming URLs (only non-empty, valid links)
    let clean_urls = $urls | where { |u| ($u | is-empty) == false } | uniq | str trim
    if ($clean_urls | is-empty) {
        return null
    }

    # Ensure folderwatched directory exists
    if ($folderwatched | path exists) == false {
        mkdir $folderwatched
    }

    # Read existing URLs from all .crawljob files in folderwatched
    let existing = get-existing-crawljob-urls $folderwatched

    # Filter out duplicate URLs
    let new_urls = $clean_urls | where { |u| ($u in $existing) == false }
    if ($new_urls | is-empty) {
        return null
    }

    # Format crawljob content
    let date_str = date now | format date "%Y%m%d_%H%M%S"
    let filename = $"manga_crawljob_($date_str).crawljob"
    let filepath = $folderwatched | path join $filename

    # Build properties-like format:
    mut lines = [
        "enabled=true"
        "overwritePackagizerEnabled = false"
        "text = ["
    ]
    for u in $new_urls {
        $lines = ($lines | append $"  ($u),")
    }
    $lines = ($lines | append "]" "")
    let content = $lines | str join "\n"
    
    # Save the file
    $content | save $filepath

    return $filepath
}