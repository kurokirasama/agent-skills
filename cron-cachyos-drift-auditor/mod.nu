# skills/cron-cachyos-drift-auditor/mod.nu
# Entry point module for cron-cachyos-drift-auditor
# Audits local CachyOS packages against /home/username/workspace/Backups/linux/conductor/package_lists.json
# and syncs review drafts with Obsidian AGENTS_MEMORY/_drafts_drifts

use scripts/audit.nu *
use scripts/draft_generator.nu *
use scripts/apply_approved.nu *

# Main orchestrator command to audit CachyOS package and config drift
export def audit-cachyos-drift [
    --dry-run(-d)                          # Run audit and draft without persisting files or modifying external services
    --date: string                         # Override audit date (defaults to today YYYY-MM-DD)
    --package-lists-path: string           # Path to /home/username/workspace/Backups/linux/conductor/package_lists.json
    --rejected-drift-path: string          # Path to rejected_drift.json
    --base-packages-path: string           # Path to base_packages.json
    --drafts-dir: string                   # Path to _drafts_drifts directory
    --processed-dir: string                # Path to processed_drafts directory
    --force(-f)                            # Force regenerate draft even if one exists for the current date
    --git-commit                           # Commit updated package_lists.json in Backups/linux
    --skip-apply                           # Skip processing existing drafts before auditing
    --skip-notify                          # Skip Habitica notification dispatch
] {
    let d = if ($date != null) { $date } else { date now | format date "%Y-%m-%d" }
    let host_info = (detect-host)
    let host = $host_info.target_host
    print $"=== Starting CachyOS Drift Audit: ($d) on ($host) ==="

    # Phase 3: First, process any pending review drafts in _drafts_drifts/
    mut applied_drafts = []
    if not $skip_apply {
        print "--- Step 1: Checking for approved drafts in Obsidian AGENTS_MEMORY/_drafts_drifts ---"
        $applied_drafts = (process-all-drafts
            --drafts-dir $drafts_dir
            --package-lists-path $package_lists_path
            --rejected-drift-path $rejected_drift_path
            --processed-dir $processed_dir
            --dry-run=($dry_run)
            --git-commit=($git_commit)
        )
        let resolved_count = ($applied_drafts | where processed and (($it.approved_count > 0) or ($it.rejected_count > 0)) | length)
        print ("  Processed " + ($applied_drafts | length | into string) + " existing draft files [" + ($resolved_count | into string) + " resolved].")
    }

    # Phase 1: Audit system drift against package_lists.json and rejected_drift.json
    print $"--- Step 2: Probing ($host) local package drift ---"
    let audit_res = (audit-drift
        --package-lists-path $package_lists_path
        --rejected-drift-path $rejected_drift_path
        --base-packages-path $base_packages_path
    )

    let shared_candidates = (audit-shared-candidates
        --package-lists-path $package_lists_path
        --rejected-drift-path $rejected_drift_path
    )

    let counts = $audit_res.counts
    let missing_sum = (($counts.missing_official) + ($counts.missing_aur))
    print $"  Target Host: ($audit_res.target_host)"
    print $"  New Official: ($counts.new_official), New AUR: ($counts.new_aur)"
    print $"  Missing: ($missing_sum), Suppressed: ($counts.suppressed), Base Suppressed: ($counts.base_suppressed)"
    print $"  Proposed Shared: ($shared_candidates.counts.proposed_shared)"
    print $"  Total Actionable Drift: ($counts.total_drift)"

    let combined_audit_res = ($audit_res | upsert shared_candidates $shared_candidates)
    let total_actionable = ($counts.total_drift + $shared_candidates.counts.proposed_shared)

    # Phase 2: If drift detected, generate review draft and dispatch Habitica todo
    mut draft_res: any = { created: false, path: null, counts: $counts, message: "No draft created" }
    mut notif_res: any = { notified: false, success: true, message: "No notification needed" }

    if $total_actionable > 0 {
        print "--- Step 3: Generating review draft in Obsidian AGENTS_MEMORY/_drafts_drifts ---"
        $draft_res = (generate-draft $combined_audit_res
            --drafts-dir $drafts_dir
            --date $d
            --force=($force)
            --dry-run=($dry_run)
        )
        print $"  ($draft_res.message)"

        if not $skip_notify {
            print "--- Step 4: Dispatching Habitica notification ---"
            $notif_res = (notify-habitica $draft_res $combined_audit_res --dry-run=($dry_run))
            print $"  ($notif_res.message)"
        }
    } else {
        print "--- Step 3: No actionable drift found. System is in full sync with Backups/linux declarative packages! ---"
    }

    print $"=== CachyOS Drift Audit Completed: ($d) ==="

    {
        date: $d,
        target_host: $audit_res.target_host,
        mode: "local",
        counts: $counts,
        shared_candidates: $shared_candidates,
        draft: $draft_res,
        notification: $notif_res,
        applied_drafts: $applied_drafts
    }
}
