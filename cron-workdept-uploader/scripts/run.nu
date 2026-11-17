#!/usr/bin/env nu
# run.nu
# Autonomous execution pulse for cron-workdept-uploader

use ./pipeline.nu [
    parse-thesis-filename
    parse-video-metadata
    select-next-video
    select-next-thesis
    build-thesis-metadata
    build-general-metadata
    build-video-metadata
    extract-candidate-frames
    select-best-frame
    upload-video-resumable
    upload-video-thumbnail
    format-markdown-report
    check-token-health
    send-token-alert
    select-published-video
    transcribe-video-srt
    select-shorts-highlight
    process-shorts-media
    build-shorts-metadata
    record-short-state
    format-shorts-report
    clean-video-intermediates
]

# Main pulse entry point
def main [
    --dry-run # Simulate execution without uploading to YouTube or moving files
] {
    let script_dir = ($env.CURRENT_FILE | path dirname)
    let skill_dir = ($script_dir | path dirname)
    let state_file = ($skill_dir | path join "state.json")
    let log_file = ($skill_dir | path join "log.txt")
    let staging_dir = "/home/username/workspace/Downloads/videos_titulos/to_upload"
    let uploaded_dir = "/home/username/workspace/Downloads/videos_titulos/uploaded"

    let now_iso = (date now | format date "%Y-%m-%dT%H:%M:%S%z")

    # Logging helper
    let log = { |msg: string|
        let entry = $"[($now_iso)] ($msg)\n"
        $entry | save --append $log_file
        print $msg
    }

    do $log "=== Starting cron-workdept-uploader pulse ==="

    # -------------------------------------------------------------
    # 0. Pre-Flight: Verify YouTube OAuth token health for workdept channel
    # -------------------------------------------------------------
    do $log "Pre-flight: Checking YouTube OAuth token health for 'workdept'..."
    let token_health = if $dry_run {
        { valid: true, account: "workdept", message: "Dry-run mode, simulated token valid." }
    } else {
        check-token-health "workdept"
    }

    if not ($token_health.valid? | default false) {
        let alert_err = $"CRITICAL: OAuth token for channel 'workdept' is expired or invalid, and unattended renewal failed: ($token_health.message)"
        do $log $alert_err
        if $dry_run {
            send-token-alert --recipient "user@example.com" --dry-run
        } else {
            send-token-alert --recipient "user@example.com"
        }
        print $"(ansi red_bold)($alert_err)(ansi reset)"
        return
    }
    do $log "OAuth token verified successfully."

    # -------------------------------------------------------------
    # 1. Load state
    # -------------------------------------------------------------
    let state = if ($state_file | path exists) {
        try { open $state_file } catch { { last_uploaded: null, queue: [], videos: {}, shorts: {} } }
    } else {
        { last_uploaded: null, queue: [], videos: {}, shorts: {} }
    }

    # -------------------------------------------------------------
    # 2. Part 1: Full Video Upload Pipeline (Strict Precedence)
    # -------------------------------------------------------------
    do $log "--- Checking pending full videos in staging directory ---"
    let pending_files = if ($staging_dir | path exists) {
        (ls $staging_dir | where name =~ '(?i)\.mp4$' | get name)
    } else {
        []
    }

    let target = if not ($pending_files | is-empty) {
        select-next-video $pending_files $state
    } else {
        null
    }

    if ($target == null) {
        do $log "No eligible pending full videos to upload (staging empty or all candidates completed)."
        print "Full Videos: No pending uploads."
    } else {
        let candidate_desc = if $target.type == "thesis" {
            $"($target.filename) [Type: thesis, Year: ($target.year), Student: ($target.student), Final Rank: ($target.final_rank)]"
        } else {
            $"($target.filename) [Type: general]"
        }
        do $log $"Selected candidate: ($candidate_desc)"
        let video_full_path = ($staging_dir | path join $target.filename)

        # Extract candidate frames and select best thumbnail
        do $log "Extracting thumbnail candidate frames via ffmpeg..."
        let cand_frames = (extract-candidate-frames $video_full_path "/tmp")
        let best_frame = if ($cand_frames | is-empty) {
            do $log "Warning: ffmpeg frame extraction returned no frames."
            null
        } else {
            let chosen = (select-best-frame $cand_frames)
            do $log $"Selected thumbnail frame: ($chosen)"
            $chosen
        }

        # Generate content summary via aimsy
        do $log $"Invoking aimsy summary for ($target.filename)..."
        let summary_text = if $dry_run {
            if $target.type == "thesis" {
                "Resumen simulado para modo dry-run: Análisis estadístico de series de tiempo y modelos predictivos aplicados a datos reales."
            } else {
                "Resumen simulado para modo dry-run: Conferencia sobre ciencia de datos, inteligencia artificial y modelamiento estadístico."
            }
        } else {
            let work_dir = ($video_full_path | path dirname)
            let stem = ($video_full_path | path parse | get stem)
            cd $work_dir
            clean-video-intermediates $video_full_path

            try { aimsy $video_full_path | ignore } catch {|err| do $log $"Warning: aimsy failed with error: ($err.msg)." }
            let summary_file = ($work_dir | path join $"($stem)_summary.md")
            mut text = if ($summary_file | path exists) { try { open --raw $summary_file } catch { "" } } else { "" }
            if ($text | is-empty) {
                do $log "Warning: aimsy produced no summary text. Using fallback summary."
                $text = if $target.type == "thesis" {
                    $"Presentación y defensa de Proyecto de Título en SUBJECT por ($target.student), Work University."
                } else {
                    $"Contenido académico y de divulgación en ciencia de datos y estadística, Work University."
                }
            }
            clean-video-intermediates $video_full_path
            $text
        }

        # Construct virality-optimized metadata
        do $log "Constructing virality-optimized metadata..."
        let metadata = (build-video-metadata $target $summary_text)

        # Upload or Dry-Run Simulation
        if $dry_run {
            do $log "[DRY-RUN] Simulating upload. Skipping actual YouTube API calls and file moving."
            let simulated_run = {
                filename: $target.filename
                type: $target.type
                title: $metadata.title
                student: $target.student
                year: $target.year
                url: "https://youtu.be/DRY_RUN_SIMULATION"
                video_id: "DRY_RUN_SIMULATION"
                thumbnail_uploaded: ($best_frame != null)
                description: $metadata.description
                tags: $metadata.tags
            }
            print (format-markdown-report $simulated_run)
            for f in $cand_frames {
                try { rm -f $f } catch { }
            }
        } else {
            # Resumable Upload
            do $log "Starting resumable upload to YouTube channel @workdept..."
            let upload_result = try {
                upload-video-resumable $video_full_path $metadata "workdept"
            } catch { |err|
                do $log $"ERROR: Upload failed: ($err.msg)"
                let updated_videos = ($state.videos | upsert $target.stem {
                    status: "failed"
                    type: $target.type
                    error: $err.msg
                    year: $target.year
                    student: $target.student
                    failed_at: $now_iso
                })
                $state | upsert videos $updated_videos | to json | save -f $state_file
                return-error $"Upload failed: ($err.msg)"
            }

            let video_id = $upload_result.video_id
            let video_url = $upload_result.url
            do $log $"Video uploaded successfully! Video ID: ($video_id), URL: ($video_url)"

            # Set custom thumbnail
            mut thumb_uploaded = false
            if ($best_frame != null) and ($best_frame | path exists) {
                do $log $"Uploading custom thumbnail from ($best_frame)..."
                let thumb_res = (upload-video-thumbnail $video_id $best_frame "workdept")
                $thumb_uploaded = ($thumb_res == true)
                for f in $cand_frames {
                    try { rm -f $f } catch { }
                }
            }

            # Atomic move to uploaded/
            mkdir $uploaded_dir
            let dest_path = ($uploaded_dir | path join $target.filename)
            do $log $"Moving video from ($video_full_path) to ($dest_path)..."
            try {
                mv $video_full_path $dest_path
                do $log "File moved successfully."
            } catch { |err|
                do $log $"Warning: Failed to move file to uploaded/: ($err.msg)"
            }

            # Update state (success-gated)
            let updated_videos = ($state.videos | upsert $target.stem {
                status: "completed"
                type: $target.type
                video_id: $video_id
                url: $video_url
                year: $target.year
                student: $target.student
                uploaded_at: $now_iso
                thumbnail_uploaded: $thumb_uploaded
            })

            let updated_state = ($state | upsert last_uploaded {
                id: $video_id
                filename: $target.filename
                uploaded_at: $now_iso
            } | upsert videos $updated_videos)

            $updated_state | to json | save -f $state_file
            do $log "Updated state.json successfully."

            # Format and print Markdown report
            let run_summary = {
                filename: $target.filename
                type: $target.type
                title: $metadata.title
                student: $target.student
                year: $target.year
                url: $video_url
                video_id: $video_id
                thumbnail_uploaded: $thumb_uploaded
                description: $metadata.description
                tags: $metadata.tags
            }
            print (format-markdown-report $run_summary)
            print "\nEMAIL STEP: send the upload notification per references/email_notification_guide.md"
        }
    }

    # -------------------------------------------------------------
    # 3. Part 2: YouTube Shorts Generation & Upload Pipeline
    # -------------------------------------------------------------
    do $log "--- Starting YouTube Shorts pipeline ---"
    let current_state = if ($state_file | path exists) {
        try { open $state_file } catch { $state }
    } else {
        $state
    }

    let published_target = (select-published-video $uploaded_dir $current_state)

    if ($published_target.source == "none") or ($published_target.path | is-empty) {
        do $log "No published videos found in uploaded/ or on YouTube to generate Shorts."
        print "Shorts: No published videos available."
    } else {
        do $log $"Selected published video for Short: ($published_target.filename) [Source: ($published_target.source), Previous shorts: ($published_target.shorts_count)]"

        # 3.1: Generate or read timestamped SRT transcription
        do $log "Generating/reading timestamped SRT transcription..."
        let srt_blocks = if $dry_run {
            transcribe-video-srt $published_target.path --dry-run
        } else {
            transcribe-video-srt $published_target.path
        }

        if ($srt_blocks | is-empty) {
            do $log "Warning: Transcription produced no subtitles. Skipping Short generation."
        } else {
            # 3.2: Select 30-50s highlight excluding previously extracted intervals
            let existing_shorts = ($current_state.shorts? | default {} | get -o $published_target.stem | default [])
            do $log $"Selecting 30-50s highlight excluding ($existing_shorts | length) previous shorts..."
            let highlight = if $dry_run {
                select-shorts-highlight $srt_blocks $existing_shorts --dry-run
            } else {
                select-shorts-highlight $srt_blocks $existing_shorts
            }
            do $log $"Selected highlight: ($highlight.start_time) -> ($highlight.end_time) [Duration: ($highlight.duration)s] | Hook: '($highlight.hook)'"

            # 3.3: Cut and 1:1 Crop
            do $log "Cutting highlight and scaling to 9:16 fit+blur..."
            let media_res = if $dry_run {
                process-shorts-media $published_target.path $highlight.start_time $highlight.end_time --dry-run
            } else {
                process-shorts-media $published_target.path $highlight.start_time $highlight.end_time
            }

            # 3.4: Construct Shorts YouTube metadata
            let short_meta = (build-shorts-metadata $highlight $published_target.stem)

            # 3.5: Upload or Dry-Run Simulation
            if $dry_run {
                do $log "[DRY-RUN] Simulating Short upload to YouTube."
                let simulated_short_run = {
                    source_filename: $published_target.filename
                    start_time: $highlight.start_time
                    end_time: $highlight.end_time
                    duration: $highlight.duration
                    title: $short_meta.title
                    url: "https://youtu.be/DRY_RUN_SHORT_SIMULATION"
                    video_id: "DRY_RUN_SHORT_SIMULATION"
                    description: $short_meta.description
                    tags: $short_meta.tags
                }
                print ""
                print (format-shorts-report $simulated_short_run)
            } else {
                do $log "Uploading Short to YouTube channel @workdept..."
                let short_upload_res = try {
                    upload-video-resumable $media_res.cropped_file $short_meta "workdept"
                } catch { |err|
                    do $log $"ERROR: Short upload failed: ($err.msg)"
                    try { rm -f $media_res.cut_file } catch { }
                    try { rm -f $media_res.cropped_file } catch { }
                    return-error $"Short upload failed: ($err.msg)"
                }

                let short_id = $short_upload_res.video_id
                let short_url = $short_upload_res.url
                do $log $"Short uploaded successfully! ID: ($short_id), URL: ($short_url)"

                # 3.6: Record Short state
                let short_entry = {
                    video_id: $short_id
                    url: $short_url
                    start_time: $highlight.start_time
                    end_time: $highlight.end_time
                    start_sec: $highlight.start_sec
                    end_sec: $highlight.end_sec
                    duration: $highlight.duration
                    title: $short_meta.title
                    uploaded_at: $now_iso
                }
                record-short-state $state_file $published_target.stem $short_entry | ignore
                do $log "Recorded short interval in state.json."

                # 3.7: Cleanup temporary cut/cropped media files
                do $log "Cleaning up temporary media files..."
                try { rm -f $media_res.cut_file } catch { }
                try { rm -f $media_res.cropped_file } catch { }

                # 3.8: Format and print Shorts report
                let short_report_data = {
                    source_filename: $published_target.filename
                    start_time: $highlight.start_time
                    end_time: $highlight.end_time
                    duration: $highlight.duration
                    title: $short_meta.title
                    url: $short_url
                    video_id: $short_id
                    description: $short_meta.description
                    tags: $short_meta.tags
                }
                print ""
                print (format-shorts-report $short_report_data)
            }
        }
    }

    do $log "=== Pulse completed successfully ==="
}
