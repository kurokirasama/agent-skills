#!/usr/bin/env nu
# check-wallpapers.nu
# cron-pixel-wallpapers: scan moewalls.com pixel-art newest list, download new mp4s.
# Frame extraction is done by the agent via `media get-frame` (parallel, user-context
# command) — see SKILL.md. This script has two modes:
#   --download : discover + download new mp4s to ~/workspace/Downloads (prints list)
#   --finalize : move extracted PNGs to the wallpaper folder + delete mp4s (summary)
# Self-contained: no relative imports. Absolute paths only.

const WALLPAPER_DIR = "/home/username/workspace/Wallpapers_pixels"
const DOWNLOAD_DIR = "/home/username/workspace/Downloads"
const LIST_URL = "https://moewalls.com/category/pixel-art/?order=newest"
const PAGE_URL = "https://moewalls.com/category/pixel-art/page/(page)/?order=newest"
const DOWNLOAD_ENDPOINT = "https://go.moewalls.com/download.php?video="
const MAX_PAGES = 10

def "get-html" [url: string]: nothing -> string {
    try { http get --raw $url } catch { "" }
}

def "derive-key" [title: string]: nothing -> string {
    $"($title)-moewalls-com"
}

def "already-exists" [key: string]: nothing -> bool {
    (glob $"($WALLPAPER_DIR)/($key).*" | length) > 0
}

def "extract-data-url" [detail_html: string]: nothing -> string {
    let rows = ($detail_html | parse -r 'id="moe-download"[^>]*data-url="(?P<url>[^"]+)"')
    if ($rows | is-empty) { "" } else { $rows | first | get url }
}

def "download-mp4" [url: string, path: string]: nothing -> bool {
    try {
        http get --full $url | get body | save -r -f $path
        true
    } catch {
        false
    }
}

def "move-file" [src: string, dst: string]: nothing -> bool {
    try {
        mv -f $src $dst
        true
    } catch {
        false
    }
}

def "find-new-titles" []: nothing -> list<string> {
    mut new_titles: list<string> = []
    mut stopped = false

    for page in 1..$MAX_PAGES {
        if $stopped { break }
        let url = if $page == 1 { $LIST_URL } else { $PAGE_URL | str replace "(page)" ($page | into string) }
        let html = get-html $url
        if ($html | is-empty) { break }

        let titles = ($html | parse -r 'moewalls\.com/pixel-art/(?P<title>[^" ]+)-live-wallpaper/' | get title | uniq)

        for title in $titles {
            if (already-exists (derive-key $title)) {
                $stopped = true
                break
            }
            $new_titles = ($new_titles | append $title)
        }
    }
    $new_titles
}

def "download-new" [] {
    let titles = find-new-titles
    print $"- New wallpapers found: ($titles | length)"

    mut errors: list<string> = []
    mut downloaded: list<string> = []

    for title in $titles {
        let key = derive-key $title
        let mp4_path = $"($DOWNLOAD_DIR)/($key).mp4"

        if (already-exists $key) {
            $downloaded = ($downloaded | append $"($title) - skipped, already present")
            continue
        }

        let detail_url = $"https://moewalls.com/pixel-art/($title)-live-wallpaper/"
        let data_url = extract-data-url (get-html $detail_url)

        if ($data_url | is-empty) {
            $errors = ($errors | append $"($title): no download data-url found")
            continue
        }

        if not (download-mp4 $"($DOWNLOAD_ENDPOINT)($data_url)" $mp4_path) {
            $errors = ($errors | append $"($title): download failed")
            continue
        }
        $downloaded = ($downloaded | append $title)
    }

    print $"- Mp4s downloaded: ($downloaded | length)"
    if ($errors | length) > 0 {
        print $"- Errors: ($errors | length)"
        for e in $errors { print $"  - ($e)" }
    }

    print "- Next: run 'media get-frame 00:00:00 <mp4 files>' via the evaluate tool, then run this script with --finalize"
}

def "finalize" [] {
    mut errors: list<string> = []
    mut moved: list<string> = []
    mut deleted: list<string> = []

    let mp4s = (glob $"($DOWNLOAD_DIR)/*-moewalls-com.mp4")
    for mp4 in $mp4s {
        let stem = ($mp4 | path parse | get stem)
        let png = $"($DOWNLOAD_DIR)/($stem).png"
        let target = $"($WALLPAPER_DIR)/($stem).png"

        if not ($png | path exists) {
            $errors = ($errors | append $"($stem): png not found - was media get-frame run?")
            continue
        }

        if (already-exists $stem) {
            rm -f $mp4
            $deleted = ($deleted | append $stem)
            continue
        }

        if not (move-file $png $target) {
            $errors = ($errors | append $"($stem): move failed")
            continue
        }
        $moved = ($moved | append $stem)

        rm -f $mp4
        $deleted = ($deleted | append $stem)
    }

    print $"- Frames extracted and moved: ($moved | length)"
    print $"- Mp4s deleted: ($deleted | length)"
    if ($errors | length) > 0 {
        print $"- Errors: ($errors | length)"
        for e in $errors { print $"  - ($e)" }
    }
}

def main [--download, --finalize] {
    if $finalize {
        finalize
    } else {
        download-new
    }
}