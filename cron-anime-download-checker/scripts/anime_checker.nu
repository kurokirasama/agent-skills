# anime_checker.nu
# Engine for checking anime episodes across offline storage, local downloads, and transmission queue

# Filter torrents whose names or (series, episode) already exist in the external drives catalog
export def filter-redundant-torrents [torrents: list<any>, ext_catalog: list<any>]: nothing -> table<id: string, name: string, location: string> {
    if ($torrents | is-empty) or ($ext_catalog | is-empty) {
        return []
    }

    let ext_files = ($ext_catalog | select file location | compact)
    let t_parsed = ($torrents | each {|t|
        let fname = ($t.Name | ansi strip | str trim)
        let p = (parse-erai-filename $fname)
        {
            id: ($t.ID | into string | str replace '*' '' | str trim),
            name: $fname,
            series: $p.series,
            series_norm: ($p.series | str lowercase),
            episode: $p.episode
        }
    })

    let exact_names = ($t_parsed | get name)
    let exact_matches = ($ext_files | where file in $exact_names)
    let escaped_series = ($t_parsed
        | where episode > 0
        | get series
        | uniq
        | each {|s| $s | str replace --all --regex '([.\^\$\*\+\?\(\)\[\]\{\}\|\\])' '\$1' })
    let series_pattern = if ($escaped_series | is-empty) { "" } else { '(?i)(' + ($escaped_series | str join '|') + ')' }

    let ext_parsed = if $series_pattern == "" {
        []
    } else {
        $ext_files
        | where ($it.file | str starts-with "[") and ($it.file =~ $series_pattern)
        | each {|row|
            let p = (parse-erai-filename $row.file)
            if $p.episode > 0 {
                { series_norm: ($p.series | str lowercase), episode: $p.episode, location: $row.location, file: $row.file }
            } else { null }
        }
        | compact
    }

    $t_parsed
    | each {|t|
        let exact = ($exact_matches | where file == $t.name)
        if not ($exact | is-empty) {
            { id: $t.id, name: $t.name, location: ($exact | first | get location) }
        } else if $t.episode > 0 {
            let match_ep = ($ext_parsed | where episode == $t.episode and series_norm == $t.series_norm)
            if not ($match_ep | is-empty) {
                { id: $t.id, name: $t.name, location: ($match_ep | first | get location) }
            } else { null }
        } else { null }
    }
    | compact
}

# Extract all indexed files on external storage drives (excluding local downloads, keeping newest snapshot per drive location)
export def get-external-drive-catalog [db_dir_override?: path]: nothing -> list<any> {
    let db_dir = if ($db_dir_override | is-empty) {
        try { $env.MY_ENV_VARS.media_database | path expand } catch { "~/cloud/Directorios" | path expand }
    } else {
        $db_dir_override | path expand
    }
    if not ($db_dir | path exists) {
        return []
    }
    try { ls $"($db_dir)/*.json" } catch { [] }
    | where not ($it.name | path basename | str starts-with "Downloads_")
    | sort-by modified --reverse
    | each {|f|
        let rows = try { open $f.name | select file location path } catch { [] }
        let loc = if ($rows | is-empty) {
            ""
        } else {
            let locs = ($rows | get location | compact)
            if ($locs | is-empty) { ($f.name | path basename) } else { ($locs | first) }
        }
        { location: $loc, rows: $rows }
    }
    | where location != ""
    | uniq-by location
    | get rows
    | flatten
}

# Parse raw transmission-remote -l output table into structured records without external subshells
export def parse-transmission-output [raw: string]: nothing -> table<ID: string, Name: string, Status: string> {
    if ($raw | is-empty) { return [] }
    let all_lines = ($raw | lines | str trim)
    if ($all_lines | is-empty) { return [] }

    # Drop header line and footer Sum line
    let content_lines = ($all_lines
        | skip 1
        | where not ($it | str starts-with "Sum:")
        | where not ($it | is-empty))

    $content_lines
    | each {|l|
        let parts = ($l | split row -r '\s+')
        if ($parts | length) >= 5 {
            let raw_id = ($parts | get 0)
            let id = ($raw_id | str replace '*' '' | str trim)
            let matched_status = ($parts | where $it in ["Idle", "Queued", "Downloading", "Seeding", "Stopped", "Up & Down"])
            let status = if not ($matched_status | is-empty) { ($matched_status | first) } else { "Unknown" }

            let erai_idx = ($l | str index-of "[Erai-raws]")
            let name = if $erai_idx >= 0 {
                ($l | str substring $erai_idx.. | str trim)
            } else {
                ($parts | skip 8 | str join ' ' | str trim)
            }
            { ID: $id, Name: $name, Status: $status }
        } else { null }
    }
    | compact
}

# Fetch all active torrents from Transmission directly using transmission-remote
export def get-transmission-torrents []: nothing -> table<ID: string, Name: string, Status: string> {
    let res = (do { transmission-remote -n 'transmission:transmission' -l } | complete)
    if $res.exit_code != 0 {
        return []
    }
    parse-transmission-output $res.stdout
}

# Find all active torrents in Transmission that exist on external drives
export def find-redundant-torrents [catalog?: list<any>]: nothing -> table<id: string, name: string, location: string> {
    let ext_catalog = if $catalog == null { (get-external-drive-catalog) } else { $catalog }
    let current_torrents = (get-transmission-torrents)
    filter-redundant-torrents $current_torrents $ext_catalog
}

# Purge redundant torrents from Transmission queue using direct transmission-remote
export def purge-redundant-torrents [--dry-run, --catalog: list<any>]: nothing -> table<id: string, name: string, location: string> {
    let to_purge = (find-redundant-torrents $catalog)
    if ($to_purge | is-empty) {
        return []
    }
    if not $dry_run {
        let ids = ($to_purge | get id)
        let id_csv = ($ids | str join ',')
        do { transmission-remote -n 'transmission:transmission' -t $id_csv -rad } | complete
    }
    $to_purge
}

# Parse release filename or title from any subgroup ([Erai-raws], [PuyaSubs!], etc.) into series name and integer episode number
export def parse-erai-filename [name: string]: nothing -> record<series: string, episode: int> {
    let base = ($name | ansi strip | str trim | path basename)
    let parsed = ($base | parse --regex '^\[[^\]]+\]\s*(?<series>.+?)\s*-\s*(?<ep>\d+)(?:v\d+)?(?:\s+END)?(?:\s*\[|\s*\(|\s*\.|\s*$)')
    if ($parsed | is-empty) {
        { series: "", episode: 0 }
    } else {
        let row = ($parsed | first)
        {
            series: ($row.series | str trim),
            episode: ($row.ep | into int)
        }
    }
}

# Parse candidate anime series name from a towatch path
export def parse-candidate-from-path [p: string, year: int]: nothing -> any {
    let normalized = ($p | str replace -a '\' '/')
    if not ($normalized | str contains $"towatch/anime/($year)/") {
        return null
    }
    let parts = ($normalized | split row '/')
    let yr_str = ($year | into string)
    let idx = ($parts | enumerate | where item == $yr_str | get index)
    if ($idx | is-empty) {
        return null
    }
    let yr_idx = ($idx | first)
    let series_idx = $yr_idx + 1
    if $series_idx < ($parts | length) {
        let candidate = ($parts | get $series_idx | str trim)
        if ($candidate not-in ['Completed', 'MoviesOvas', 'scripts']) and not ($candidate | str starts-with '.') and ($candidate | str length) > 0 {
            return $candidate
        }
    }
    null
}

# Check if a parsed release series title matches a target candidate series (including sub-arc matching without base-season pollution)
def series-title-matches [parsed_series: string, target_series: string]: nothing -> bool {
    let norm_p = ($parsed_series | str trim | str lowercase)
    let norm_t = ($target_series | str trim | str lowercase)
    if ($norm_p == "") or ($norm_t == "") {
        return false
    }
    if $norm_p == $norm_t {
        return true
    }
    if ($target_series | str contains ' - ') {
        let norm_sub = ($target_series | split row ' - ' | last | str trim | str lowercase)
        if ($norm_sub != "") and (($norm_p == $norm_sub) or ($norm_p | str ends-with $" - ($norm_sub)")) {
            return true
        }
    }
    false
}

# Extract acquired episode numbers from media database records matching a series or its sub-arc
export def extract-episodes-from-records [series: string, records: list<any>]: nothing -> list<int> {
    if ($records | is-empty) { return [] }
    let clean_series = ($series | str trim)

    $records
    | get file
    | compact
    | uniq
    | each {|f|
        let parsed = (parse-erai-filename $f)
        if $parsed.episode > 0 and (series-title-matches $parsed.series $clean_series) {
            $parsed.episode
        } else { null }
    }
    | compact
    | sort
    | uniq
}

# Extract acquired episodes for a series from in-memory external catalog
export def query-catalog-episodes [series: string, catalog: list<any>]: nothing -> list<int> {
    if ($catalog | is-empty) { return [] }
    let clean_series = ($series | str trim)
    let sub_parts = ($clean_series | split row ' - ')
    let sub_title = if ($sub_parts | length) > 1 { ($sub_parts | last | str trim) } else { "" }

    let matching_records = ($catalog
        | where {|row|
            let f = ($row.file | default "")
            let p = ($row.path | default "")
            ($f | str contains -i $clean_series) or ($p | str contains -i $clean_series) or (
                if $sub_title != "" { ($f | str contains -i $sub_title) or ($p | str contains -i $sub_title) } else { false }
            )
        })

    extract-episodes-from-records $clean_series $matching_records
}

# Query the offline media database for all acquired episodes of a series across all storage locations (legacy fallback)
export def query-media-episodes [series: string]: nothing -> list<int> {
    let cat = (get-external-drive-catalog)
    query-catalog-episodes $series $cat
}

# Compute episode gaps by comparing acquired episodes against released episodes
export def compute-episode-gaps [acquired: list<int>, released: list<int>, min_episode?: int]: nothing -> list<int> {
    let acq_set = ($acquired | sort | uniq)
    let candidate_released = if ($min_episode | is-empty) {
        $released
    } else {
        $released | where $it >= $min_episode
    }
    $candidate_released
    | where {|e| $e not-in $acq_set }
    | sort
    | uniq
}

# Filter active candidate airing series from in-memory catalog for a given year
export def filter-active-candidate-series [catalog: list<any>, year: int]: nothing -> list<string> {
    if ($catalog | is-empty) { return [] }
    let yr_str = ($year | into string)
    let towatch_prefix = $"towatch/anime/($yr_str)/"
    let completed_prefix = $"towatch/anime/($yr_str)/Completed/"
    let movies_prefix = $"towatch/anime/($yr_str)/MoviesOvas/"

    # Identify series present in Completed/ or MoviesOvas/ (by folder name and parsed release title)
    let completed_rows = ($catalog
        | where {|row|
            let p = ($row.path? | default "" | str replace -a '\' '/')
            ($p | str contains $completed_prefix) or ($p | str contains $movies_prefix)
        })

    let completed_folders = ($completed_rows
        | each {|row|
            let p = ($row.path? | default "" | str replace -a '\' '/')
            let parts = ($p | split row '/')
            let idx = ($parts | enumerate | where item == $yr_str | get index)
            if not ($idx | is-empty) {
                let yr_idx = ($idx | first)
                let series_idx = $yr_idx + 2
                if $series_idx < ($parts | length) {
                    $parts | get $series_idx | str trim
                } else { null }
            } else { null }
        }
        | compact
        | uniq)

    let completed_titles = ($completed_rows
        | get file?
        | compact
        | each {|f| (parse-erai-filename $f).series }
        | where $it != ""
        | uniq)

    let completed_all = ($completed_folders | append $completed_titles | uniq)

    # Discover candidate series strictly in towatch/anime/<year>/<series> (excluding Completed/MoviesOvas)
    let active_rows = ($catalog
        | where {|row|
            let p = ($row.path? | default "" | str replace -a '\' '/')
            ($p | str contains $towatch_prefix) and not ($p | str contains $completed_prefix) and not ($p | str contains $movies_prefix)
        })

    let candidate_folders = ($active_rows
        | each {|row| parse-candidate-from-path ($row.path? | default "") $year }
        | compact
        | uniq
        | where $it not-in $completed_all)

    $candidate_folders
    | each {|folder|
        let folder_suffix = $"towatch/anime/($yr_str)/($folder)"
        let folder_files = ($active_rows
            | where {|r|
                let p = ($r.path? | default "" | str replace -a '\' '/')
                ($p | str ends-with $folder_suffix) or ($p | str contains $"($folder_suffix)/")
            }
            | get file?
            | compact)
        let parsed_titles = ($folder_files
            | each {|f|
                let p = (parse-erai-filename $f)
                if $p.episode > 0 and $p.series != "" { $p.series } else { null }
            }
            | compact)
        if ($parsed_titles | is-empty) {
            $folder
        } else {
            $parsed_titles
            | group-by --to-table
            | upsert cnt {|g| $g.items | length }
            | sort-by cnt --reverse
            | first
            | get group
        }
    }
    | where $it not-in $completed_all
    | uniq
    | sort
}

# Extract candidate anime series strictly from towatch/anime/<year>
export def get-candidate-series [year?: int, catalog?: list<any>]: nothing -> table<series: string, source: string> {
    let target_year = if ($year | is-empty) { (date now | format date "%Y" | into int) } else { $year }
    let cat = if $catalog == null { (get-external-drive-catalog) } else { $catalog }
    let candidates = (filter-active-candidate-series $cat $target_year)
    $candidates | each {|s| { series: $s, source: "towatch_airing" } }
}

# Audit acquired episodes across Tier 1, Tier 2, and Tier 3
export def audit-acquired-episodes [
    series: string,
    year?: int,
    catalog?: list<any>,
    local_files?: list<string>,
    torrents?: list<any>
]: nothing -> record<series: string, tier1_offline: list<int>, tier2_local: list<int>, tier3_transmission: list<int>, all_acquired: list<int>> {
    let target_year = if ($year | is-empty) { (date now | format date "%Y" | into int) } else { $year }
    let cat = if $catalog == null { (get-external-drive-catalog) } else { $catalog }

    # Tier 1: External storage across all drives via in-memory catalog
    let tier1 = (query-catalog-episodes $series $cat)

    # Tier 2: Local downloads directory
    let local_list = if $local_files == null {
        let torrent_dir = ("~/Downloads/Torrent" | path expand)
        if ($torrent_dir | path exists) { ls $torrent_dir | get name } else { [] }
    } else {
        $local_files
    }
    let tier2 = (extract-episodes-from-records $series ($local_list | each {|f| { file: $f } }))

    # Tier 3: Transmission queue directly via get-transmission-torrents
    let torrent_list = if $torrents == null {
        try { get-transmission-torrents } catch { [] }
    } else {
        $torrents
    }
    let torrent_names = ($torrent_list | each {|t|
        if ($t | describe | str starts-with "record") { ($t.Name? | default ($t.name? | default "")) } else { ($t | into string) }
    })
    let tier3 = (extract-episodes-from-records $series ($torrent_names | each {|n| { file: $n } }))

    let all_acq = ($tier1 | append $tier2 | append $tier3 | sort | uniq)

    {
        series: $series,
        tier1_offline: $tier1,
        tier2_local: $tier2,
        tier3_transmission: $tier3,
        all_acquired: $all_acq
    }
}

# Detect predominant video profile (resolution, codec, repack) using majority vote across files
export def detect-video-profile [files: list<string>]: nothing -> record<resolution: string, codec: string, is_repack: bool> {
    if ($files | is-empty) {
        return { resolution: "720p", codec: "AVC", is_repack: false }
    }
    let cnt_1080p = ($files | where {|f| $f | str contains "1080p" } | length)
    let cnt_720p = ($files | where {|f| $f | str contains "720p" } | length)
    let resolution = if $cnt_1080p > $cnt_720p { "1080p" } else { "720p" }

    let cnt_hevc = ($files | where {|f| ($f | str contains "HEVC") or ($f | str contains "x265") or ($f | str contains "H.265") } | length)
    let cnt_avc = ($files | length) - $cnt_hevc
    let codec = if $cnt_hevc > $cnt_avc { "HEVC" } else { "AVC" }

    let is_repack = ($files | any {|f| $f | str contains "REPACK" })

    { resolution: $resolution, codec: $codec, is_repack: $is_repack }
}

# Determine video profile for a series based on its acquired files in external catalog and local downloads
export def get-series-video-profile [series: string, catalog?: list<any>, local_files?: list<string>]: nothing -> record<resolution: string, codec: string, is_repack: bool> {
    let cat = if $catalog == null { (get-external-drive-catalog) } else { $catalog }
    let clean_series = ($series | str trim)
    let sub_parts = ($clean_series | split row ' - ')
    let sub_title = if ($sub_parts | length) > 1 { ($sub_parts | last | str trim) } else { "" }

    let cat_files = ($cat
        | where {|row|
            let f = ($row.file? | default "")
            let p = ($row.path? | default "")
            ($f | str contains -i $clean_series) or ($p | str contains -i $clean_series) or (
                if $sub_title != "" { ($f | str contains -i $sub_title) or ($p | str contains -i $sub_title) } else { false }
            )
        }
        | get file?
        | compact
        | where {|f|
            let parsed = (parse-erai-filename $f)
            $parsed.episode > 0 and (series-title-matches $parsed.series $clean_series)
        })

    let raw_local = if $local_files == null {
        let torrent_dir = ("~/Downloads/Torrent" | path expand)
        if ($torrent_dir | path exists) { ls $torrent_dir | get name } else { [] }
    } else {
        $local_files
    }
    let matching_local = ($raw_local
        | where {|f|
            let parsed = (parse-erai-filename $f)
            $parsed.episode > 0 and (series-title-matches $parsed.series $clean_series)
        })

    let all_files = ($cat_files | append $matching_local | uniq)
    detect-video-profile $all_files
}

# Extract latest aired episode number from AniList response record
export def parse-anilist-media [payload: any]: nothing -> int {
    if ($payload | is-empty) { return 0 }
    let media = ($payload.data?.Media?)
    if ($media | is-empty) { return 0 }

    let next_airing = ($media.nextAiringEpisode?.episode?)
    if ($next_airing != null) and ($next_airing > 1) {
        return ($next_airing - 1)
    }

    let status = ($media.status?)
    let total_eps = ($media.episodes?)
    if $status == "FINISHED" and $total_eps != null {
        return ($total_eps | into int)
    }

    if $total_eps != null {
        return ($total_eps | into int)
    }
    0
}

# Fetch latest aired episode number via AniList GraphQL with Jikan fallback
export def fetch-latest-aired-episode [series: string]: nothing -> int {
    let clean_title = ($series | str trim | split row ' - ' | first)
    let query = 'query ($search: String) { Media(search: $search, type: ANIME) { status episodes nextAiringEpisode { episode } } }'
    let body = { query: $query, variables: { search: $clean_title } } | to json

    let anilist_res = try {
        http post --max-time 5sec "https://graphql.anilist.co" $body --headers ["Content-Type" "application/json"]
    } catch { null }

    if $anilist_res != null {
        let ep = (parse-anilist-media $anilist_res)
        if $ep > 0 { return $ep }
    }

    # Jikan fallback
    let jikan_url = $"https://api.jikan.moe/v4/anime?q=($clean_title | url encode)&limit=1"
    let jikan_res = try { http get --max-time 5sec $jikan_url } catch { null }
    if $jikan_res != null {
        let anime_data = ($jikan_res.data? | default [])
        if not ($anime_data | is-empty) {
            let first_match = ($anime_data | first)
            let ep_cnt = ($first_match.episodes?)
            if $ep_cnt != null and $ep_cnt > 0 {
                return ($ep_cnt | into int)
            }
        }
    }
    0
}

# Parse Nyaa Erai-raws RSS items, optionally filtering by target video profile and series title
export def parse-nyaa-rss-items [
    raw: string,
    profile?: record<resolution: string, codec: string, is_repack: bool>,
    target_series?: string
]: nothing -> table<episode: int, title: string, torrent_url: string> {
    if ($raw | is-empty) { return [] }
    let target_res = if ($profile | is-empty) { "720p" } else { ($profile.resolution | default "720p") }
    let target_codec = if ($profile | is-empty) { "AVC" } else { ($profile.codec | default "AVC") }
    let filter_series = ($target_series | default "" | str trim)

    let items = ($raw | split row '<item>' | skip 1)
    let parsed_items = ($items | each {|item|
        let title_match = ($item | parse -r '<title>(?<title>.*?)</title>')
        let link_match = ($item | parse -r '<link>(?<link>.*?)</link>')
        if not ($title_match | is-empty) and not ($link_match | is-empty) {
            let title = ($title_match | get 0.title)
            let link = ($link_match | get 0.link)

            let parsed = (parse-erai-filename $title)
            let matches_series = if $filter_series == "" {
                true
            } else {
                series-title-matches $parsed.series $filter_series
            }
            if $parsed.episode > 0 and $matches_series {
                {
                    episode: $parsed.episode,
                    title: $title,
                    torrent_url: $link
                }
            } else { null }
        } else { null }
    } | compact)

    if ($parsed_items | is-empty) { return [] }

    # 1. Filter by target resolution (e.g. 1080p vs 720p)
    let res_filtered = ($parsed_items | where {|row| $row.title | str contains $target_res })
    let candidate_pool = if not ($res_filtered | is-empty) { $res_filtered } else { $parsed_items }

    # 2. Prefer target codec (e.g. HEVC) if requested
    let codec_filtered = if $target_codec == "HEVC" {
        let h = ($candidate_pool | where {|row| ($row.title | str contains "HEVC") or ($row.title | str contains "x265") })
        if not ($h | is-empty) { $h } else { $candidate_pool }
    } else if $target_codec == "AVC" {
        let a = ($candidate_pool | where {|row| not (($row.title | str contains "HEVC") or ($row.title | str contains "x265")) })
        if not ($a | is-empty) { $a } else { $candidate_pool }
    } else {
        $candidate_pool
    }

    $codec_filtered
    | sort-by episode
    | uniq-by episode
}

# Fetch released episodes from Nyaa Erai-raws RSS matching target profile
export def fetch-nyaa-episodes [series: string, profile?: record<resolution: string, codec: string, is_repack: bool>]: nothing -> table<episode: int, title: string, torrent_url: string> {
    let query = ($series | url encode)
    let rss_url = $"https://nyaa.si/?page=rss&c=0_0&f=0&u=Erai-raws&q=($query)"
    let raw = try { http get --max-time 5sec --raw $rss_url } catch { "" }
    parse-nyaa-rss-items $raw $profile $series
}

# Download a torrent file into the designated watch directory
export def download-torrent [torrent_url: string, dest_dir?: path]: nothing -> record<filename: string, success: bool> {
    let target_dir = if ($dest_dir | is-empty) { ("~/cloud/Aplicaciones/Gmail" | path expand) } else { ($dest_dir | path expand) }
    if not ($target_dir | path exists) {
        mkdir $target_dir
    }

    let fname = ($torrent_url | path basename)
    let dest_file = ($target_dir | path join $fname)

    try {
        http get --max-time 5sec $torrent_url | save -f $dest_file
        { filename: $fname, success: true }
    } catch {|e|
        { filename: $fname, success: false }
    }
}

# Verify Transmission pickup for newly downloaded torrent episodes
export def verify-transmission-pickup [expected_patterns: list<string>]: nothing -> table<pattern: string, status: string> {
    let watch_dir = ("~/cloud/Aplicaciones/Gmail" | path expand)
    let watch_files = (glob $"($watch_dir)/*.torrent" | path basename | str join "\n")
    let transmission_names = try {
        (get-transmission-torrents) | get Name | str join "\n"
    } catch { "" }

    $expected_patterns | each {|pat|
        let in_transmission = ($transmission_names | str contains -i $pat)
        let in_watch = ($watch_files | str contains -i $pat)
        let status = if $in_transmission {
            "queued"
        } else if $in_watch {
            "pending_pickup"
        } else {
            "failed_or_unknown"
        }
        { pattern: $pat, status: $status }
    }
}

# Run complete anime download check across candidates, identify gaps, download torrents, and print markdown report
export def run-anime-check [year?: int, --dry-run]: nothing -> nothing {
    let target_year = if ($year | is-empty) { (date now | format date "%Y" | into int) } else { $year }
    print $"# Anime Download Audit: (date now | format date '%Y-%m-%d %H:%M')"

    # Load deduplicated in-memory media catalog once for the entire run
    let catalog = (get-external-drive-catalog)

    # Check and purge any torrents currently in Transmission that already exist on external drives
    let purged = if $dry_run {
        (purge-redundant-torrents --dry-run --catalog $catalog)
    } else {
        (purge-redundant-torrents --catalog $catalog)
    }
    if not ($purged | is-empty) {
        print $"- Purged ($purged | length) redundant torrents already on external drives."
    }

    let candidates = (get-candidate-series $target_year $catalog)
    if ($candidates | is-empty) {
        print "- No active anime series found in towatch/anime/."
        return
    }

    print $"- Discovered ($candidates | length) candidate airing series."

    let yr_str = ($target_year | into string)
    let year_catalog = ($catalog | where {|row|
        let p = ($row.path? | default "")
        ($p | str contains $yr_str) or ($p | str contains "One Piece")
    })
    let torrent_dir = ("~/Downloads/Torrent" | path expand)
    let local_files = if ($torrent_dir | path exists) { ls $torrent_dir | get name } else { [] }
    let current_torrents = try { get-transmission-torrents } catch { [] }

    mut downloaded_torrents = []

    for item in $candidates {
        let series = $item.series
        let audit = (audit-acquired-episodes $series $target_year $year_catalog $local_files $current_torrents)
        let profile = (get-series-video-profile $series $year_catalog $local_files)
        let max_acquired = if not ($audit.all_acquired | is-empty) { ($audit.all_acquired | math max) } else { 0 }

        # Query official airing episode count via AniList / Jikan
        let latest_aired = (fetch-latest-aired-episode $series)

        # If official airing info shows we are up to date, skip querying Nyaa
        if $latest_aired > 0 and $max_acquired >= $latest_aired {
            print $"- ($series): ($max_acquired) acquired, ($latest_aired) aired [($profile.resolution)] — UP TO DATE"
            continue
        }

        # Otherwise query Nyaa Erai-raws releases matching series profile
        let nyaa_releases = (fetch-nyaa-episodes $series $profile)
        let released_eps = if ($nyaa_releases | is-empty) { [] } else { ($nyaa_releases | get episode) }

        # If AniList reported higher aired or if unverified, compute gaps against Nyaa releases
        let min_ep = if $series == "One Piece" and not ($audit.tier1_offline | is-empty) {
            ($audit.tier1_offline | math min)
        } else { null }
        let gaps = (compute-episode-gaps $audit.all_acquired $released_eps $min_ep)

        if ($gaps | is-empty) {
            print $"- ($series): ($audit.all_acquired | length) acquired, ($released_eps | length) released [($profile.resolution)] — UP TO DATE"
        } else {
            print $"- ($series): MISSING EPISODES: ($gaps | str join ', ') [($profile.resolution)]"
            for ep in $gaps {
                let matched = ($nyaa_releases | where episode == $ep)
                if not ($matched | is-empty) {
                    let match = ($matched | first)
                    if not $dry_run {
                        let dl = (download-torrent $match.torrent_url)
                        if $dl.success {
                            $downloaded_torrents = ($downloaded_torrents | append { series: $series, episode: $ep, file: $dl.filename })
                            print $"  • Downloaded torrent for episode ($ep): ($dl.filename)"
                        } else {
                            print $"  • FAILED downloading torrent for episode ($ep): ($match.torrent_url)"
                        }
                    } else {
                        print $"  • [DRY RUN] Would download torrent for episode ($ep): ($match.title)"
                    }
                }
            }
        }
    }

    if not ($downloaded_torrents | is-empty) {
        print "\n## Transmission Pickup Verification"
        let patterns = ($downloaded_torrents | each {|t| $"[Erai-raws] ($t.series) - ($t.episode)" })
        let verif = (verify-transmission-pickup $patterns)
        for v in $verif {
            print $"- ($v.pattern): ($v.status)"
        }
    } else {
        print "\n- No new torrents required download."
    }
}

