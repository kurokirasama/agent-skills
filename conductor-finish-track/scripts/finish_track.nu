# skills/conductor-finish-track/scripts/finish_track.nu
# Helper functions for verifying and archiving Conductor tracks

# Check whether all tasks and subtasks in a plan.md file are completed ([x])
export def verify-plan-completed [plan_path: string]: nothing -> record<completed: bool, pending: list<string>> {
    if not ($plan_path | path exists) {
        return { completed: false, pending: ["plan.md not found"] }
    }
    let content = open --raw $plan_path
    let lines = ($content | lines)
    let pending = ($lines | where { |line| ($line =~ '^\s*-\s*\[[\s~]\]') } | each { |line| $line | str trim })
    {
        completed: ($pending | is-empty),
        pending: $pending
    }
}

# Check whether a track has completed its review checkpoints or verification tasks
export def verify-plan-reviewed [plan_path: string]: nothing -> bool {
    if not ($plan_path | path exists) {
        return false
    }
    let content = open --raw $plan_path
    let lines = ($content | lines)
    
    # Check if there is any verification/review task marked [x]
    let has_verification = ($lines | any { |line| 
        ($line =~ '^\s*-\s*\[x\].*(?:Verification|Review|review)')
    })
    
    # Also check if all tasks in general are [x]
    let all_completed = (verify-plan-completed $plan_path).completed

    $has_verification or $all_completed
}

# Move track directory from conductor/tracks/<track_id> to conductor/archive/<track_id>
export def archive-track-folder [
    track_id: string,
    --conductor-dir: string = "conductor"
]: nothing -> nothing {
    let base = ($conductor_dir | path expand)
    let src = ([$base "tracks" $track_id] | path join)
    let archive_dir = ([$base "archive"] | path join)
    let dest = ([$archive_dir $track_id] | path join)

    if not ($src | path exists) {
        error make { msg: $"Source track directory does not exist: ($src)" }
    }

    if not ($archive_dir | path exists) {
        mkdir $archive_dir
    }

    mv $src $dest
}

# Update metadata.json in conductor/archive/<track_id> with status "archived" and completed_at timestamp
export def update-track-metadata [
    track_id: string,
    --conductor-dir: string = "conductor"
]: nothing -> nothing {
    let base = ($conductor_dir | path expand)
    let meta_file = ([$base "archive" $track_id "metadata.json"] | path join)

    if not ($meta_file | path exists) {
        # Check if still in tracks/
        let fallback_meta = ([$base "tracks" $track_id "metadata.json"] | path join)
        if ($fallback_meta | path exists) {
            let meta = (open $fallback_meta)
            let updated = ($meta | upsert status "archived" | upsert completed_at (date now | format date "%Y-%m-%dT%H:%M:%S%z"))
            $updated | to json | save -f $fallback_meta
            return
        }
        return
    }

    let meta = (open $meta_file)
    let updated = ($meta | upsert status "archived" | upsert completed_at (date now | format date "%Y-%m-%dT%H:%M:%S%z"))
    $updated | to json | save -f $meta_file
}

# Remove the track entry from conductor/tracks.md
export def cleanup-tracks-registry [
    track_id: string,
    --tracks-md: string = "conductor/tracks.md"
]: nothing -> nothing {
    let file_path = ($tracks_md | path expand)
    if not ($file_path | path exists) {
        return
    }

    let raw = open --raw $file_path
    let lines = ($raw | lines)
    
    # Filter out lines corresponding to this track section
    mut filtered_lines = []
    mut skipping = false

    for line in $lines {
        if ($line | str contains $track_id) {
            # If the link line contains track_id, drop previous separator/heading if matched
            if ($filtered_lines | length) > 0 and (($filtered_lines | last) | str contains "**Track:") {
                $filtered_lines = ($filtered_lines | drop 1)
            }
            if ($filtered_lines | length) > 0 and (($filtered_lines | last) == "---") {
                $filtered_lines = ($filtered_lines | drop 1)
            }
            continue
        } else if ($line =~ $"- \\[.\\] \\*\\*Track:.*($track_id)") {
            continue
        } else {
            $filtered_lines = ($filtered_lines | append $line)
        }
    }

    # Clean up any trailing empty lines or redundant separators
    let cleaned_text = ($filtered_lines | str join "\n" | str trim)
    $"($cleaned_text)\n" | save -f $file_path
}

# Main entry point for standalone CLI execution
export def main [
    track_id: string,
    --force (-f),
    --skip-review (-s),
    --conductor-dir: string = "conductor"
] {
    let base = ($conductor_dir | path expand)
    let track_path = ([$base "tracks" $track_id] | path join)

    if not ($track_path | path exists) {
        print $"[ERROR] Track not found at: ($track_path)"
        return 1
    }

    let plan_path = ([$track_path "plan.md"] | path join)
    let completion = (verify-plan-completed $plan_path)

    if not $completion.completed and not $force {
        print $"[ERROR] Track ($track_id) has ($completion.pending | length) pending tasks in plan.md:"
        for p in $completion.pending {
            print $"  ($p)"
        }
        print "Use --force to bypass task completion check."
        return 1
    }

    let reviewed = (verify-plan-reviewed $plan_path)
    if not $reviewed and not $skip_review and not $force {
        print $"[ERROR] Track ($track_id) has not been reviewed."
        print "Please run `/conductor-review` or use --skip-review to proceed."
        return 1
    }

    print $"Archiving track ($track_id)..."
    archive-track-folder $track_id --conductor-dir $conductor_dir
    update-track-metadata $track_id --conductor-dir $conductor_dir
    cleanup-tracks-registry $track_id --tracks-md ([$base "tracks.md"] | path join)

    print $"Track ($track_id) successfully archived."
    return 0
}
