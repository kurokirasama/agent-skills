# pipeline.nu
# Core processing, filename parsing, and video selection for cron-workdept-uploader

# Parses a thesis presentation video filename into structured metadata.
#
# Examples:
#   parse-thesis-filename "2022_Detective_de_Datos__COVID-19_-_Sample_Student_final_final.mp4"
export def parse-thesis-filename [
    filename: string # Path or basename of the thesis video file
]: nothing -> record {
    let base = ($filename | path basename)
    let stem = ($base | path parse | get stem)

    # Determine final rank based on suffix occurrences
    let final_rank = if ($stem =~ '(_final_final)$') {
        2
    } else if ($stem =~ '(_final)$') {
        1
    } else {
        0
    }

    # Split into left (year + title) and right (student + suffix)
    let halves = ($stem | split row "_-_")
    if ($halves | length) < 2 {
        return {
            filename: $base
            stem: $stem
            year: 0
            title: $stem
            student: "Desconocido"
            final_rank: $final_rank
        }
    }

    let left = ($halves | get 0)
    let right = ($halves | get 1)

    # Parse year and title from left
    let year_str = ($left | split row "_" | first)
    let year = try { $year_str | into int } catch { 0 }
    let title_raw = ($left | str replace --regex $"^($year_str)_+" "")
    let title = ($title_raw
        | str replace -a "__" " "
        | str replace -a "_" " "
        | split row " "
        | where { |it| ($it | str length) > 0 }
        | str join " "
        | str trim)

    # Parse student from right by stripping final suffixes
    let student_raw = ($right | str replace --regex '(_final)+$' '')
    let student = ($student_raw
        | str replace -a "_" " "
        | split row " "
        | where { |it| ($it | str length) > 0 }
        | str join " "
        | str trim)

    {
        filename: $base
        stem: $stem
        year: $year
        title: $title
        student: $student
        final_rank: $final_rank
    }
}

# Classifies a video file as either "thesis" or "general".
#
# Examples:
#   classify-video-type "2023_Descifrando_el_Futuro_con_Datos_-_Bastián_Astudillo_final.mp4" # -> "thesis"
#   classify-video-type "charla_series_tiempo.mp4" # -> "general"
export def classify-video-type [
    filename: string # Path or basename of the video file
]: nothing -> string {
    let base = ($filename | path basename)
    let stem = ($base | path parse | get stem)
    let halves = ($stem | split row "_-_")

    if ($halves | length) < 2 {
        return "general"
    }

    let left = ($halves | get 0)
    let year_str = ($left | split row "_" | first)
    let year = try { $year_str | into int } catch { 0 }

    if ($year < 2000) or ($year > 2099) {
        return "general"
    }

    let right = ($halves | get 1)
    if ($right | str trim | is-empty) {
        return "general"
    }

    "thesis"
}

# Parses any video file into structured metadata, unified across thesis and general videos.
#
# Examples:
#   parse-video-metadata "2023_a_-_b_final.mp4"
#   parse-video-metadata "charla_ml.mp4"
export def parse-video-metadata [
    filename: string # Path or basename of the video file
]: nothing -> record {
    let vtype = (classify-video-type $filename)
    let base = ($filename | path basename)
    let stem = ($base | path parse | get stem)

    if $vtype == "thesis" {
        let tp = (parse-thesis-filename $filename)
        $tp | insert type "thesis"
    } else {
        {
            filename: $base
            stem: $stem
            type: "general"
            year: null
            title: null
            student: null
            final_rank: 0
        }
    }
}

# Selects the next video to upload, strictly prioritizing eligible thesis videos over general videos.
#
# Examples:
#   select-next-video ["2023_a_-_b_final.mp4", "charla.mp4"] $state
export def select-next-video [
    files: list<string> # List of file paths or basenames to evaluate
    state: record       # Current skill state record containing `videos` dictionary
]: nothing -> any {
    if ($files | is-empty) {
        return null
    }

    # Parse all files with unified metadata
    let parsed = ($files | each { |f| parse-video-metadata $f })

    # Filter out videos already marked completed in state
    let pending = ($parsed | where { |it|
        let entry = ($state.videos? | get -o $it.stem)
        (($entry | get -o status) != "completed")
    })

    if ($pending | is-empty) {
        return null
    }

    # 1. Check for eligible thesis videos first
    let thesis_candidates = ($pending | where type == "thesis")
    if not ($thesis_candidates | is-empty) {
        # Deduplicate thesis videos by (year, title, student), picking candidate with highest final_rank
        let deduped = ($thesis_candidates
            | group-by { |it| $"($it.year)_($it.title)_($it.student)" }
            | values
            | each { |group| $group | sort-by final_rank --reverse | first })

        if not ($deduped | is-empty) {
            # Find candidates with oldest academic year
            let min_year = ($deduped | get year | math min)
            let oldest_candidates = ($deduped | where year == $min_year)
            return ($oldest_candidates | shuffle | first)
        }
    }

    # 2. Fallback to general videos (if no thesis videos pending)
    let general_candidates = ($pending | where type == "general")
    if ($general_candidates | is-empty) {
        return null
    }

    # Pick the first general candidate
    $general_candidates | first
}

# Selects the next thesis video to upload based on age (oldest year), deduplication, and completion state.
#
# Examples:
#   select-next-thesis ["2022_a_-_b_final.mp4"] $state
export def select-next-thesis [
    files: list<string> # List of file paths or basenames to evaluate
    state: record       # Current skill state record containing `videos` dictionary
]: nothing -> any {
    select-next-video $files $state
}

# Builds YouTube metadata (title, description, tags, category) adhering to virality research.
export def build-thesis-metadata [
    parsed: record       # Parsed filename record (year, title, student)
    summary_text: string # Summary of the presentation content
]: nothing -> record {
    let title = $"($parsed.title) | Proyecto de Título SUBJECT WORK"

    # Derive two high-impact content hashtags
    let candidate_words = ($"($parsed.title) ($summary_text)"
        | str replace -a "," ""
        | str replace -a "." ""
        | str replace -a ":" ""
        | split row " "
        | where { |w| ($w | str length) >= 5 }
        | where { |w|
            let lower = ($w | str lowercase)
            not ($lower in ["sobre", "usando", "estudio", "proyecto", "titulo", "carrera", "analisis", "universidad"])
        })

    let kw1 = ($candidate_words | get 0? | default "CienciaDeDatos" | str replace --regex '[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ]' '')
    let kw2 = ($candidate_words | get 1? | default "Estadistica" | str replace --regex '[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ]' '')
    let tag1 = if ($kw1 | is-empty) { "#CienciaDeDatos" } else { $"#($kw1)" }
    let tag2 = if ($kw2 | is-empty) { "#Estadistica" } else { $"#($kw2)" }

    let institutional_tags = ["#SUBJECT", "#WORK", "#ProyectoDeTitulo"]
    let hashtags = ([$tag1, $tag2] | append $institutional_tags | uniq | str join " ")

    # NOTE: the AI summary ($summary_text) is used ONLY for hashtag/tag derivation
    # above. It MUST NOT appear in the YouTube description.
    let description = ("Proyecto de Título de " + $parsed.student + " para la carrera de SUBJECT de la Work University (WORK), " + ($parsed.year | into string) + ".\n\n" + $hashtags)

    # Construct broad + specific + institutional tags
    let broad_tags = ["estadística", "ciencia de datos", "data science", "análisis de datos"]
    let specific_tags = ($candidate_words | first 5 | each { |w| $w | str lowercase })
    let inst_tags = [
        "Work University",
        "SUBJECT",
        "proyecto de título",
        ($parsed.year | into string),
        ($parsed.student | str lowercase)
    ]

    mut tags = ($broad_tags | append $specific_tags | append $inst_tags | uniq)
    # Ensure tags total characters under 450
    while (($tags | str join ",") | str length) > 450 and (($tags | length) > 5) {
        $tags = ($tags | drop 1)
    }

    {
        title: $title
        description: $description
        tags: $tags
        categoryId: "27"
    }
}

# Generates a high-CTR, reachability-optimized title from video content summary with institutional branding.
#
# Examples:
#   generate-reachability-title "En este seminario sobre modelos predictivos, exploramos cómo predecir la inflación con redes neuronales..." "charla_series"
export def generate-reachability-title [
    summary_text: string # Summary of the video content
    fallback_stem: string = "" # Video stem to use as fallback if summary is empty
]: nothing -> string {
    let branding = " | WORK DEPT"
    let max_hook_len = (100 - ($branding | str length))

    # If summary text is too short, format fallback stem
    if ($summary_text | str trim | str length) < 15 {
        let clean_fallback = ($fallback_stem
            | str replace -a "_" " "
            | str replace -a "-" " "
            | split row " "
            | where { |w| ($w | str length) > 0 }
            | each { |w|
                let first_char = ($w | str substring 0..0 | str uppercase)
                let rest = ($w | str substring 1..)
                $"($first_char)($rest)"
            }
            | str join " ")
        return $"($clean_fallback)($branding)"
    }

    # Extract hook clause from summary
    # Strategy 1: Look for "cómo ..." or "como ..."
    let como_match = ($summary_text | parse --regex '(?i)(?:cómo|como)\s+([^,.:;\n]+)')
    mut hook = if not ($como_match | is-empty) {
        let raw_hook = ($como_match | get 0.capture0 | str trim)
        $"Cómo ($raw_hook)"
    } else {
        ""
    }

    # Strategy 2: If no "cómo", look for lead topic in summary
    if ($hook | is-empty) or (($hook | str length) < 15) {
        let topic_match = ($summary_text | parse --regex '(?i)(?:sobre|de|en torno a)\s+([^,.:;\n]+)')
        if not ($topic_match | is-empty) {
            $hook = ($topic_match | get 0.capture0 | str trim)
        }
    }

    # Strategy 3: Fallback to the first sentence or clause
    if ($hook | is-empty) or (($hook | str length) < 15) {
        let first_sentence = ($summary_text | split row "." | first | str trim)
        let first_clause = ($first_sentence | split row "," | first | str trim)
        $hook = if ($first_clause | str length) >= 15 { $first_clause } else { $first_sentence }
    }

    # Capitalize the first letter of hook
    let hook_first = ($hook | str substring 0..0 | str uppercase)
    let hook_rest = ($hook | str substring 1..)
    mut final_hook = ($"($hook_first)($hook_rest)" | str trim)

    # Truncate if exceeds 55 chars while preserving whole words
    if ($final_hook | str length) > 55 {
        let words = ($final_hook | split row " ")
        mut truncated = []
        for w in $words {
            if (($truncated | append $w | str join " " | str length) <= 55) {
                $truncated = ($truncated | append $w)
            }
        }
        $final_hook = ($truncated | str join " ")
    }

    # Clean punctuation
    $final_hook = ($final_hook | str replace --regex '[,.:;]+$' '')

    $"($final_hook)($branding)"
}

# Derives a brief 1-2 sentence insight from the full AI video summary for use in
# YouTube descriptions. Returns a shortened derivation, NEVER the full summary text.
#
# Examples:
#   extract-brief-insight "Taller sobre redes neuronales. Segunda oración con detalles extensos." # -> "Taller sobre redes neuronales."
export def extract-brief-insight [
    summary_text: string # Full AI-generated summary from aimsy
]: nothing -> string {
    let clean = $summary_text | str trim | str replace --regex '\s+' ' '
    if ($clean | is-empty) {
        return "Contenido académico y de divulgación de la carrera de SUBJECT, Work University."
    }
    let first_sentence = $clean | split row "." | first | str trim
    let base = if ($first_sentence | is-empty) { $clean } else { $"($first_sentence)." }
    if ($base | str length) <= 200 {
        return $base
    }
    let words = $base | split row " "
    mut kept = []
    for w in $words {
        if (($kept | append $w | str join " " | str length) <= 197) {
            $kept = ($kept | append $w)
        }
    }
    let joined = $kept | str join " " | str trim
    if ($joined | is-empty) {
        $"($base | str substring 0..197 | str trim)…"
    } else {
        $"($joined)…"
    }
}

# Builds YouTube metadata (title, description, tags, category) for general academic/department videos.
export def build-general-metadata [
    parsed: record       # Parsed video record (filename, stem, etc.)
    summary_text: string # Summary of the presentation content
]: nothing -> record {
    let title = (generate-reachability-title $summary_text $parsed.stem)

    # Derive high-impact content hashtags
    let candidate_words = ($"($title) ($summary_text)"
        | str replace -a "," ""
        | str replace -a "." ""
        | str replace -a ":" ""
        | split row " "
        | where { |w| ($w | str length) >= 5 }
        | where { |w|
            let lower = ($w | str lowercase)
            not ($lower in ["sobre", "usando", "estudio", "charla", "taller", "seminario", "carrera", "analisis", "universidad", "presentacion"])
        })

    let kw1 = ($candidate_words | get 0? | default "CienciaDeDatos" | str replace --regex '[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ]' '')
    let kw2 = ($candidate_words | get 1? | default "Estadistica" | str replace --regex '[^a-zA-Z0-9áéíóúÁÉÍÓÚñÑ]' '')
    let tag1 = if ($kw1 | is-empty) { "#CienciaDeDatos" } else { $"#($kw1)" }
    let tag2 = if ($kw2 | is-empty) { "#Estadistica" } else { $"#($kw2)" }

    let institutional_tags = ["#WORKDEPT", "#WORK", "#SUBJECT"]
    let hashtags = ([$tag1, $tag2] | append $institutional_tags | uniq | str join " ")

    # NOTE: use a brief derived insight here, NEVER the raw AI summary text.
    # The full $summary_text remains in use ONLY for title/hook, hashtag, and tag derivation above.
    let brief_insight = extract-brief-insight $summary_text
    let description = ("Video académico y de divulgación de la carrera de SUBJECT de la Work University (WORK).\n\n" + $brief_insight + "\n\n" + $hashtags)

    # Construct broad + specific + institutional tags
    let broad_tags = ["estadística", "ciencia de datos", "data science", "análisis de datos", "educación", "Work University", "ies work", "SUBJECT"]
    let specific_tags = ($candidate_words | first 5 | each { |w| $w | str lowercase })
    mut tags = ($broad_tags | append $specific_tags | uniq)

    while (($tags | str join ",") | str length) > 450 and (($tags | length) > 5) {
        $tags = ($tags | drop 1)
    }

    {
        title: $title
        description: $description
        tags: $tags
        categoryId: "27"
    }
}

# Unified dispatcher to construct YouTube metadata based on video candidate type.
#
# Examples:
#   build-video-metadata $cand $summary
export def build-video-metadata [
    candidate: record    # Candidate record from parse-video-metadata
    summary_text: string # Summary of the video content
]: nothing -> record {
    let vtype = ($candidate.type? | default "thesis")
    if $vtype == "general" {
        build-general-metadata $candidate $summary_text
    } else {
        build-thesis-metadata $candidate $summary_text
    }
}

# Extracts 3-5 candidate thumbnail frames at strategic timestamps using ffmpeg.
export def extract-candidate-frames [
    video_path: string            # Path to the source MP4 video
    output_dir: string = "/tmp"   # Destination directory for candidate frames
]: nothing -> list<string> {
    # Probe duration
    let dur_raw = try {
        ^ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 $video_path
        | str trim
        | into float
    } catch { 100.0 }

    let timestamps = [
        ($dur_raw * 0.15 | into int),
        ($dur_raw * 0.35 | into int),
        ($dur_raw * 0.55 | into int),
        ($dur_raw * 0.75 | into int)
    ]

    let base_stem = ($video_path | path parse | get stem)
    mut extracted = []

    for ts in $timestamps {
        let out_file = ($output_dir | path join $"thumb_($base_stem)_($ts)s.jpg")
        try {
            ^ffmpeg -ss ($ts | into string) -i $video_path -frames:v 1 -q:v 2 $out_file -y o+e>| ignore
            if ($out_file | path exists) {
                $extracted = ($extracted | append $out_file)
            }
        } catch { }
    }

    $extracted
}

# Evaluates candidate frames and selects the highest-scoring thumbnail frame based on visual entropy.
export def select-best-frame [
    candidates: list<string> # Paths to candidate JPEG frames
]: nothing -> any {
    if ($candidates | is-empty) {
        return null
    }

    # Use file size at fixed quality as entropy/detail proxy (higher detail, graphs, clear slides)
    let evaluated = ($candidates | each { |p|
        let s = try { (ls $p | get 0.size | into int) } catch { 0 }
        { path: $p, size: $s }
    })

    $evaluated | sort-by size --reverse | first | get path
}

# Uploads a video to YouTube using the Data API v3 resumable protocol.
export def upload-video-resumable [
    video_path: string # Absolute path to the MP4 file
    metadata: record   # Record containing title, description, tags, categoryId
    account: string = "workdept" # Target account name
]: nothing -> record {
    let token = (yt-get-access-token $account)
    if ($token | is-empty) {
        return-error $"No valid access token available for account '($account)'"
    }

    let file_size = (ls $video_path | get 0.size | into int)
    let init_url = "https://www.googleapis.com/upload/youtube/v3/videos?uploadType=resumable&part=snippet,status"
    let body_record = {
        snippet: {
            title: $metadata.title
            description: $metadata.description
            tags: $metadata.tags
            categoryId: ($metadata.categoryId? | default "27")
        }
        status: {
            privacyStatus: "public"
            selfDeclaredMadeForKids: false
        }
    }

    print "Initiating resumable upload session with YouTube Data API v3..."
    let init_res = try {
        http post --full --allow-errors $init_url ($body_record | to json) --headers {
            Authorization: $"Bearer ($token)"
            Content-Type: "application/json; charset=UTF-8"
            X-Upload-Content-Type: "video/mp4"
            X-Upload-Content-Length: ($file_size | into string)
        }
    } catch { |err|
        return-error $"Failed to initiate resumable upload session: ($err.msg)"
    }

    if ($init_res.status < 200 or $init_res.status >= 300) and ($init_res.status != 308) {
        return-error $"YouTube API initiation failed with HTTP ($init_res.status): ($init_res.body)"
    }

    let upload_url = ($init_res.headers.response | where name =~ '(?i)location' | get value | first)
    if ($upload_url | is-empty) {
        return-error "YouTube API did not return a resumable upload Location header."
    }

    print $"Uploading video bytes [($file_size) bytes] to YouTube..."
    # NOTE: `open` without --raw returns binary so uploaded bytes match Content-Length exactly.
    let upload_res = try {
        http put --full --allow-errors $upload_url (open $video_path) --headers {
            Content-Type: "video/mp4"
            Content-Length: ($file_size | into string)
        }
    } catch { |err|
        return-error $"Failed during video byte streaming: ($err.msg)"
    }

    if ($upload_res.status != 200 and $upload_res.status != 201) {
        return-error $"Upload failed with HTTP ($upload_res.status): ($upload_res.body)"
    }

    # NOTE: `http --full` auto-parses JSON bodies into records, so only `from json` when needed.
    let result_json = (if ($upload_res.body | describe | str starts-with "record") { $upload_res.body } else { $upload_res.body | from json })
    let video_id = $result_json.id
    print $"Successfully uploaded video! YouTube ID: ($video_id)"

    {
        video_id: $video_id
        url: $"https://youtu.be/($video_id)"
        raw_response: $result_json
    }
}

# Uploads a custom thumbnail for an existing YouTube video.
export def upload-video-thumbnail [
    video_id: string
    thumbnail_path: string
    account: string = "workdept"
] {
    let token = (yt-get-access-token $account)
    let thumb_url = $"https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId=($video_id)"

    print $"Uploading custom thumbnail for video ($video_id)..."
    let res = try {
        http post --full --allow-errors $thumb_url (open $thumbnail_path) --headers {
            Authorization: $"Bearer ($token)"
            Content-Type: "image/jpeg"
        }
    } catch { |err|
        print $"Warning: thumbnail upload failed: ($err.msg)"
        return null
    }

    if ($res.status == 200 or $res.status == 201) {
        print "Successfully uploaded custom thumbnail."
        true
    } else {
        print $"Warning: thumbnail upload returned HTTP ($res.status): ($res.body)"
        false
    }
}

# Formats the execution pulse results as a clean Markdown report for stdout.
export def format-markdown-report [
    run: record # Execution run record with video, student, title, id, url, etc.
]: nothing -> string {
    let thumb_status = (if ($run.thumbnail_uploaded? | default false) { "Uploaded" } else { "Default/Skipped" })
    # NOTE: raw URL on its own paragraph so Discord unfurls a rich video embed
    # and the to-discord paragraph splitter keeps it in the first message.
    let vtype = ($run.type? | default (if ($run.student? | is-empty) { "general" } else { "thesis" }))
    let header_title = if $vtype == "general" {
        "# Cron Pulse Report: WORK DEPT Video Uploader (General)"
    } else {
        "# Cron Pulse Report: WORK DEPT Thesis Uploader"
    }

    mut lines = [
        $header_title
        $""
        $"**Watch:** ($run.url)"
        $""
        $"**Video:** `($run.filename)`"
        $"**Type:** ($vtype)"
        $"**Title:** ($run.title)"
    ]

    if $vtype == "thesis" and not ($run.student? | is-empty) {
        $lines = ($lines | append $"**Student:** ($run.student)")
        $lines = ($lines | append $"**Academic Year:** ($run.year)")
    }

    $lines = ($lines | append [
        $"**YouTube Video ID:** `($run.video_id)`"
        $"**Custom Thumbnail:** ($thumb_status)"
        $""
        $"## Description"
        $"```"
        $"($run.description)"
        $"```"
        $""
        $"## Tags"
        $"($run.tags | str join ', ')"
    ])

    $lines | str join "\n"
}

# Checks YouTube OAuth token health for a channel account, attempting unattended refresh if needed.
export def check-token-health [
    account: string = "workdept"
]: nothing -> record {
    let stat = try {
        if $account == "workdept" {
            yt-api status --ies
        } else {
            yt-api status
        }
    } catch { |err|
        { valid: false, error: ($err | to nuon) }
    }

    let is_valid = ($stat.valid? | default false)
    if not $is_valid {
        # Attempt unattended refresh via yt-get-access-token
        let refreshed_token = try {
            yt-get-access-token $account
        } catch { |err|
            null
        }

        if ($refreshed_token == null or ($refreshed_token | is-empty)) {
            return {
                valid: false
                account: $account
                message: $"OAuth token for '($account)' is expired or missing, and unattended renewal failed."
            }
        }
    }

    {
        valid: true
        account: $account
        message: $"OAuth token for '($account)' is valid."
    }
}

# Dispatches alert notifications to Discord and Email when token renewal fails.
export def send-token-alert [
    --recipient: string = "user@example.com"
    --dry-run
] {
    let alert_msg = "⚠ [WORK DEPT Alert] YouTube OAuth token for channel 'workdept' has expired or is invalid, and cannot be renewed unattended. Please run `yt-oauth-login workdept` on the host to authenticate."
    let email_subject = "[URGENT] WORK DEPT YouTube OAuth Token Expired"
    let email_body = $"Estimado,\n\nEl token de autenticación de YouTube para el canal @workdept ha expirado o no pudo ser renovado de manera desatendida.\n\nAcción requerida inmediata:\nEjecute el siguiente comando en la terminal:\n  yt-oauth-login workdept\n\nSaludos,\nSistema Automatizado WORK DEPT"

    if $dry_run {
        print $"[DRY-RUN] Discord alert would be sent: ($alert_msg)"
        print $"[DRY-RUN] Email alert would be sent to ($recipient) with subject: ($email_subject)"
        return {
            discord_sent: true
            email_sent: true
            recipient: $recipient
            dry_run: true
        }
    }

    mut discord_ok = false
    try {
        $alert_msg | to-discord -p
        $discord_ok = true
    } catch { |err|
        print $"Warning: Failed to send Discord alert: ($err.msg)"
    }

    mut email_ok = false
    try {
        send-gmail $recipient $email_subject --body $email_body
        $email_ok = true
    } catch { |err|
        print $"Warning: Failed to send email alert: ($err.msg)"
    }

    {
        discord_sent: $discord_ok
        email_sent: $email_ok
        recipient: $recipient
        dry_run: false
    }
}

# Parses raw SRT subtitle text into a structured table of subtitle entries.
export def parse-srt-subtitles [
    content: string # Raw SRT text content
]: nothing -> list<record> {
    if ($content | str trim | is-empty) {
        return []
    }

    # Normalize line endings and split into subtitle blocks
    let normalized = ($content | str replace -a "\r\n" "\n" | str replace -a "\r" "\n")
    let raw_blocks = ($normalized | split row "\n\n")

    mut results = []
    for block in $raw_blocks {
        let block_lines = ($block | lines | each { |l| $l | str trim } | where not ($it | is-empty))
        if ($block_lines | is-empty) {
            continue
        }

        # Check if first line is an index or timestamp
        let time_idx = if ($block_lines | length) > 1 and (($block_lines | get 1) =~ '-->') {
            1
        } else if (($block_lines | get 0) =~ '-->') {
            0
        } else {
            -1
        }

        if $time_idx == -1 {
            continue
        }

        let time_line = ($block_lines | get $time_idx)
        let time_parts = ($time_line | split row "-->" | each { |t| $t | str trim })
        if ($time_parts | length) < 2 {
            continue
        }

        let start_time = ($time_parts | get 0 | split row "," | first | str trim)
        let end_time = ($time_parts | get 1 | split row "," | first | str trim)
        let text_lines = ($block_lines | skip ($time_idx + 1))
        let text_content = ($text_lines | str join " " | str trim)

        let entry = {
            index: (($results | length) + 1)
            start: $start_time
            end: $end_time
            text: $text_content
        }
        $results = ($results | append $entry)
    }

    $results
}

# Selects a published video candidate for creating a Short (local uploaded/ preferred, YouTube fallback).
export def select-published-video [
    uploaded_dir: string
    state: record
    --channel-account: string = "workdept"
    --cache-dir: string = "/tmp/workdept_shorts_cache"
]: nothing -> record {
    let local_files = if ($uploaded_dir | path exists) {
        (ls $uploaded_dir | where name =~ '(?i)\.mp4$' | get name)
    } else {
        []
    }

    if not ($local_files | is-empty) {
        # Build weighted list: count how many shorts each candidate already has
        let candidates = ($local_files | each { |f|
            let base = ($f | path basename)
            let stem = ($base | path parse | get stem)
            let existing_shorts = ($state.shorts? | default {} | get -o $stem | default [] | length)
            {
                path: $f
                filename: $base
                stem: $stem
                shorts_count: $existing_shorts
            }
        })

        # Group by shorts_count ascending to prioritize videos with fewest/no shorts
        let min_count = ($candidates | get shorts_count | math min)
        let best_tier = ($candidates | where shorts_count == $min_count)
        let picked = ($best_tier | shuffle | first)

        let known_video_id = ($state.videos? | default {} | get -o $picked.stem | get -o video_id)

        return {
            source: "local"
            path: $picked.path
            filename: $picked.filename
            stem: $picked.stem
            video_id: $known_video_id
            shorts_count: $picked.shorts_count
        }
    }

    # Fallback: Query published videos via YouTube channel
    print "Local uploaded/ directory empty, checking YouTube channel uploads..."
    mkdir $cache_dir

    let yt_list = try {
        # Query YouTube Data API for channel uploads
        let token = (yt-get-access-token $channel_account)
        let res = (http get $"https://www.googleapis.com/youtube/v3/search?part=snippet&forMine=true&type=video&maxResults=15" --headers {
            Authorization: $"Bearer ($token)"
        })
        $res.items? | default []
    } catch { |err|
        []
    }

    if ($yt_list | is-empty) {
        return {
            source: "none"
            path: ""
            filename: ""
            stem: ""
            video_id: null
            shorts_count: 0
        }
    }

    let picked_yt = ($yt_list | shuffle | first)
    let vid_id = $picked_yt.id.videoId
    let vid_title = $picked_yt.snippet.title
    let dest_path = ($cache_dir | path join $"($vid_id).mp4")

    if not ($dest_path | path exists) {
        print $"Downloading YouTube video ($vid_id) via yt-dlp..."
        try {
            ^yt-dlp -f "bestvideo[ext=mp4]+bestaudio[ext=m4a]/best[ext=mp4]/best" -o $dest_path $"https://youtu.be/($vid_id)"
        } catch { |err|
            print $"Warning: yt-dlp download failed: ($err.msg)"
        }
    }

    {
        source: "youtube"
        path: $dest_path
        filename: $"($vid_id).mp4"
        stem: $vid_id
        video_id: $vid_id
        title: $vid_title
        shorts_count: 0
    }
}

# Cleans intermediate files (.mp3, -clean.mp3, .txt, -clean.txt, .srt, _summary.md) generated during transcription/summarization.
export def clean-video-intermediates [video_path: string]: nothing -> nothing {
    let work_dir = ($video_path | path dirname)
    let stem = ($video_path | path parse | get stem)
    for suffix in [".mp3" "-clean.mp3" ".txt" "-clean.txt" ".srt" "_summary.md"] {
        let f = ($work_dir | path join $"($stem)($suffix)")
        if ($f | path exists) {
            try { rm -f $f } catch { }
        }
    }
}

# Transcribes video audio with timestamps using `ai video2text --srt`.
export def transcribe-video-srt [
    video_path: string
    --dry-run
]: nothing -> list<record> {
    if $dry_run {
        return [
            { index: 1, start: "00:00:02", end: "00:00:15", text: "En esta investigación abordamos los modelos de regresión y series temporales." }
            { index: 2, start: "00:00:15", end: "00:00:48", text: "El resultado principal demostró una mejora del 35% en precisión predictiva." }
            { index: 3, start: "00:00:48", end: "00:01:20", text: "Concluimos que las redes neuronales optimizadas superan ampliamente a los baselines." }
        ]
    }

    let work_dir = ($video_path | path dirname)
    let stem = ($video_path | path parse | get stem)
    let srt_path = ($work_dir | path join $"($stem).srt")

    # Deterministic CWD + Pre-flight cleanup of stale intermediates to prevent interactive ffmpeg prompts
    cd $work_dir
    clean-video-intermediates $video_path

    print $"Invoking ai video2text --srt for ($video_path)..."
    try {
        ai video2text --srt $video_path
    } catch { |err|
        print $"Warning: ai video2text execution threw error: ($err.msg)"
    }

    # Locate generated SRT file
    let candidate_srt = if ($srt_path | path exists) {
        $srt_path
    } else if (($stem | path join ".srt" | path exists)) {
        $"($stem).srt"
    } else {
        null
    }

    if ($candidate_srt == null) {
        print "Warning: No .srt file found after transcription."
        clean-video-intermediates $video_path
        return []
    }

    let content = (open --raw $candidate_srt)
    let subtitles = (parse-srt-subtitles $content)

    # Post-consumption cleanup of intermediate working files
    clean-video-intermediates $video_path

    $subtitles
}

# Converts a time string (hh:mm:ss or mm:ss) into total seconds.
export def time-str-to-seconds [t: string]: nothing -> int {
    let parts = ($t | split row ":" | each { |p| try { $p | into int } catch { 0 } })
    if ($parts | length) == 3 {
        (($parts | get 0) * 3600) + (($parts | get 1) * 60) + ($parts | get 2)
    } else if ($parts | length) == 2 {
        (($parts | get 0) * 60) + ($parts | get 1)
    } else if ($parts | length) == 1 {
        $parts | get 0
    } else {
        0
    }
}

# Formats total seconds into a standard time string (hh:mm:ss).
export def seconds-to-time-str [s: int]: nothing -> string {
    let h = ($s // 3600)
    let rem = ($s mod 3600)
    let m = ($rem // 60)
    let sec = ($rem mod 60)
    let hh = (if $h < 10 { $"0($h)" } else { $"($h)" })
    let mm = (if $m < 10 { $"0($m)" } else { $"($m)" })
    let ss = (if $sec < 10 { $"0($sec)" } else { $"($sec)" })
    $"($hh):($mm):($ss)"
}

# Checks if a candidate interval overlaps with any existing intervals.
export def is-interval-overlapping [
    candidate: record # { start_sec: int, end_sec: int } or { start_time: string, end_time: string }
    existing: list<record> # list of records with start_sec/end_sec
]: nothing -> bool {
    let c_start = ($candidate.start_sec? | default (time-str-to-seconds ($candidate.start_time? | default "00:00:00")))
    let c_end = ($candidate.end_sec? | default (time-str-to-seconds ($candidate.end_time? | default "00:00:00")))

    for ex in $existing {
        let e_start = ($ex.start_sec? | default (time-str-to-seconds ($ex.start_time? | default "00:00:00")))
        let e_end = ($ex.end_sec? | default (time-str-to-seconds ($ex.end_time? | default "00:00:00")))
        let max_start = if $c_start > $e_start { $c_start } else { $e_start }
        let min_end = if $c_end < $e_end { $c_end } else { $e_end }
        if $max_start < $min_end {
            return true
        }
    }
    false
}

# Calculates centered 1:1 square crop filter parameters preserving height and trimming width excess.
export def calculate-1x1-crop-params [
    width: int
    height: int
]: nothing -> record {
    if $width >= $height {
        let left_offset = (($width - $height) // 2)
        {
            size: $"($height):($height)"
            left: ($left_offset | into string)
            top: "0"
            width: $height
            height: $height
        }
    } else {
        let top_offset = (($height - $width) // 2)
        {
            size: $"($width):($width)"
            left: "0"
            top: ($top_offset | into string)
            width: $width
            height: $width
        }
    }
}

# Selects a 30-50 second highlight clip from SRT blocks using AI, avoiding overlapping intervals.
export def select-shorts-highlight [
    srt_blocks: list<record>
    existing_shorts: list<record> = []
    --dry-run
]: nothing -> record {
    if $dry_run {
        return {
            start_time: "00:00:15"
            end_time: "00:00:50"
            start_sec: 15
            end_sec: 50
            duration: 35
            hook: "Predicción y Redes Neuronales"
            rationale: "High statistical impact and clear conclusion"
            hashtags: ["#RedesNeuronales", "#Prediccion", "#DataScience"]
        }
    }

    if ($srt_blocks | is-empty) {
        return {
            start_time: "00:00:00"
            end_time: "00:00:40"
            start_sec: 0
            end_sec: 40
            duration: 40
            hook: "Momento Destacado WORK DEPT"
            rationale: "Default fallback clip"
            hashtags: ["#Estadistica", "#DataScience", "#WORK"]
        }
    }

    let transcript_text = ($srt_blocks | each { |b| $"[($b.start) -> ($b.end)] ($b.text)" } | str join "\n")
    let prompt = $"You are an expert video editor creating a viral YouTube Short from an academic presentation.
Analyze the following transcript with timestamps. Select the SINGLE most interesting, impactful, self-contained highlight clip lasting between 30 and 50 seconds - strictly at most 60 seconds.
Focus on a strong hook, key statistical insight, conclusion, or provocative research result.
Excluded previously extracted intervals: ($existing_shorts | to json -r)

Transcript:
($transcript_text)

Respond ONLY with valid JSON in this exact structure without markdown:
{
  \"start_time\": \"hh:mm:ss\",
  \"end_time\": \"hh:mm:ss\",
  \"hook\": \"Short catchy hook title - maximum 50 characters\",
  \"rationale\": \"Why this clip was chosen\",
  \"hashtags\": [\"#Hashtag1\", \"#Hashtag2\"]
}"

    let ai_response = try {
        google_ai $prompt | str replace --regex '^```[a-z]*\n' '' | str replace --regex '\n```$' '' | str trim | from json
    } catch {
        null
    }

    if ($ai_response != null) and ("start_time" in $ai_response) and ("end_time" in $ai_response) {
        let s_sec = (time-str-to-seconds $ai_response.start_time)
        let e_sec = (time-str-to-seconds $ai_response.end_time)
        let dur = ($e_sec - $s_sec)
        let valid_dur = if $dur >= 20 and $dur <= 60 { $dur } else { 40 }
        let final_end_time = if $dur >= 20 and $dur <= 60 { $ai_response.end_time } else { (seconds-to-time-str ($s_sec + 40)) }

        return {
            start_time: $ai_response.start_time
            end_time: $final_end_time
            start_sec: $s_sec
            end_sec: ($s_sec + $valid_dur)
            duration: $valid_dur
            hook: ($ai_response.hook? | default "Momento Destacado WORK DEPT")
            rationale: ($ai_response.rationale? | default "AI selected highlight")
            hashtags: ($ai_response.hashtags? | default ["#Estadistica", "#DataScience", "#WORK"])
        }
    }

    # Fallback to middle segment if AI parsing fails
    let total_blocks = ($srt_blocks | length)
    let mid_idx = ($total_blocks // 2)
    let mid_block = ($srt_blocks | get $mid_idx)
    let s_sec = (time-str-to-seconds $mid_block.start)
    let e_sec = ($s_sec + 40)

    {
        start_time: $mid_block.start
        end_time: (seconds-to-time-str $e_sec)
        start_sec: $s_sec
        end_sec: $e_sec
        duration: 40
        hook: "Resultados de Investigación | WORK DEPT"
        rationale: "Algorithmic center-point highlight selection"
        hashtags: ["#Estadistica", "#DataScience", "#WORK"]
    }
}

# Processes video by cutting the selected highlight and cropping to 1:1 centered square format.
export def process-shorts-media [
    video_path: string
    start_time: string
    end_time: string
    --output-dir: string = "/tmp"
    --dry-run
]: nothing -> record {
    let stem = ($video_path | path parse | get stem)
    let cut_output = ($output_dir | path join $"($stem)_cut.mp4")
    let scaled_output = ($output_dir | path join $"($stem)_cut_scaled_9x16.mp4")
    let final_output = ($output_dir | path join $"($stem)_cut_short_9x16.mp4")
    let music_dir = (["~" "workspace" "Downloads" "videos_titulos"] | path join | path expand)

    if $dry_run {
        print $"[DRY-RUN] media cut-video ($video_path) ($start_time) ($end_time) -o ($cut_output) -r"
        print $"[DRY-RUN] media scale-video ($cut_output) --aspect-ratio 9:16 --scale-mode fit --pad-mode blur --size 1080:1920 -o ($scaled_output)"
        print $"[DRY-RUN] media add-audio ($scaled_output) <random-mp3> --volume-factor 0.05 -o ($final_output)"
        return {
            cut_file: $cut_output
            scaled_file: $scaled_output
            cropped_file: $final_output
            final_file: $final_output
            duration: ((time-str-to-seconds $end_time) - (time-str-to-seconds $start_time))
            dry_run: true
        }
    }

    # Pre-flight: remove stale intermediates so ffmpeg never prompts (cron-safe).
    for stale in [$cut_output $scaled_output $final_output] {
        try { rm -f $stale } catch { }
    }

    # Step 1: Cut segment
    print $"Cutting segment ($start_time) -> ($end_time) from ($video_path) for 9:16 scaling..."
    media cut-video $video_path $start_time $end_time -o $cut_output -r

    # Step 2: Scale to vertical with blurred-background padding (default look).
    print $"Scaling ($cut_output) to 9:16 fit+blur..."
    media scale-video $cut_output --aspect-ratio 9:16 --scale-mode fit --pad-mode blur --size 1080:1920 --output $scaled_output

    # Step 3: Mix random background music at low volume.
    let mp3s = try { glob ($music_dir | path join "*.mp3") } catch { [] }
    if ($mp3s | is-empty) {
        return-error $"No background music found in ($music_dir)"
    }
    let bgm = ($mp3s | shuffle | first)
    print $"Mixing background audio ($bgm | path basename) at volume 0.05..."
    media add-audio $scaled_output $bgm --volume-factor 0.05 --output $final_output

    # Step 4: Drop the scaled-only intermediate; keep cut + final for the caller.
    try { rm -f $scaled_output } catch { }

    {
        cut_file: $cut_output
        scaled_file: $scaled_output
        # NOTE: legacy key name kept for run.nu compatibility; holds the final
        # 9:16 scaled + audio-mixed file (not a 1:1 crop). Prefer `final_file`.
        cropped_file: $final_output
        final_file: $final_output
        audio_mp3: $bgm
        duration: ((time-str-to-seconds $end_time) - (time-str-to-seconds $start_time))
        dry_run: false
    }
}

# Persists extracted short range and metadata into state.json under `shorts`.
export def record-short-state [
    state_file: string
    video_stem: string
    short_record: record
]: nothing -> record {
    let current_state = if ($state_file | path exists) {
        try { open $state_file } catch { { videos: {}, shorts: {} } }
    } else {
        { videos: {}, shorts: {} }
    }

    let existing_shorts = ($current_state.shorts? | default {})
    let video_shorts = ($existing_shorts | get -o $video_stem | default [])
    let updated_video_shorts = ($video_shorts | append $short_record)
    let new_shorts = ($existing_shorts | upsert $video_stem $updated_video_shorts)
    let new_state = ($current_state | upsert shorts $new_shorts)

    $new_state | save -f $state_file
    $new_state
}

# Constructs YouTube metadata tailored for YouTube Shorts (#Shorts tag, hook title, virality hashtags).
export def build-shorts-metadata [
    highlight: record
    video_stem: string
]: nothing -> record {
    let hook_title = ($highlight.hook | str trim)
    let title = if ($hook_title =~ '(?i)#shorts') {
        $hook_title
    } else {
        $"($hook_title) #Shorts"
    }

    let default_hashtags = ["#Shorts", "#SUBJECT", "#WORK", "#DataScience", "#Estadistica"]
    let extra_hashtags = ($highlight.hashtags? | default [])
    let combined_hashtags = ($default_hashtags | append $extra_hashtags | uniq)

    let description = $"Momento destacado de SUBJECT WORK.\n\n($combined_hashtags | str join ' ')"
    let tags = ["Shorts", "SUBJECT", "WORK", "Work University", "Data Science", "Estadística"]
        | append ($highlight.hashtags? | default [] | each { |h| $h | str replace '#' '' })
        | uniq

    {
        title: $title
        description: $description
        tags: $tags
        categoryId: "27"
        privacyStatus: "public"
    }
}

# Formats the YouTube Short execution results as a clean Markdown report for stdout.
export def format-shorts-report [
    run: record # Execution run record with short url, source video, duration, title, etc.
]: nothing -> string {
    mut lines = [
        "# Cron Pulse Report: WORK DEPT YouTube Short"
        ""
        $"**Watch Short:** ($run.url)"
        ""
        $"**Source Video:** `($run.source_filename)`"
        $"**Interval:** `($run.start_time)` -> `($run.end_time)` [Duration: ($run.duration)s]"
        $"**Title:** ($run.title)"
        $"**YouTube Video ID:** `($run.video_id)`"
        ""
        "## Description"
        "```"
        $"($run.description)"
        "```"
        ""
        "## Tags"
        $"($run.tags | str join ', ')"
    ]

    $lines | str join "\n"
}




