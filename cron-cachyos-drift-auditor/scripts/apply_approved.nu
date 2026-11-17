# skills/cron-cachyos-drift-auditor/scripts/apply_approved.nu
# Reads marked review drafts from Obsidian AGENTS_MEMORY/_drafts_drifts,
# applies approved package updates to /home/username/workspace/Backups/linux/conductor/package_lists.json,
# records rejected items to rejected_drift.json, and archives processed drafts.

def get-vault-path [] {
    try { $env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT } catch { "/home/username/workspace/obsidian/vaults" } | path expand
}

def get-default-package-lists-path [] {
    "/home/username/workspace/Backups/linux/conductor/package_lists.json"
}

def get-default-backups-dir [] {
    "/home/username/workspace/Backups/linux"
}

def get-default-rejected-path [] {
    let base = try { $env.MY_ENV_VARS.llms_configs } catch { "/home/username/workspace/llms_configs" } | path expand
    let skill_rej = $"($base)/skills/cron-cachyos-drift-auditor/rejected_drift.json"
    let backup_rej = "/home/username/workspace/Backups/linux/conductor/rejected_drift.json"
    if ($backup_rej | path exists) { $backup_rej } else { $skill_rej }
}

def get-default-drafts-dir [] {
    let vault = (get-vault-path)
    $"($vault)/AGENTS_MEMORY/_drafts_drifts"
}

def get-default-processed-dir [] {
    let vault = (get-vault-path)
    $"($vault)/AGENTS_MEMORY/_drafts_drifts/processed_drafts"
}

# Parses a review draft Markdown file into structured items
export def parse-draft [draft_path: string] {
    if not ($draft_path | path exists) {
        error make { msg: $"Draft file not found: ($draft_path)" }
    }

    let raw_text = (open --raw $draft_path)
    let sections = ($raw_text | split row "### Package: `")

    let date_lines = ($raw_text | lines | where {|l| $l =~ '^date:\s*'})
    let date_match = if ($date_lines | is-not-empty) { $date_lines | first } else { "" }
    let draft_date = if ($date_match | is-not-empty) {
        $date_match | str replace -r '^date:\s*"?([^"]*)"?.*$' '$1' | str trim
    } else {
        $draft_path | path parse | get stem
    }

    let host_lines = ($raw_text | lines | where {|l| $l =~ '^target_host:\s*'})
    let host_match = if ($host_lines | is-not-empty) { $host_lines | first } else { "" }
    let draft_host = if ($host_match | is-not-empty) {
        $host_match | str replace -r '^target_host:\s*"?([^"]*)"?.*$' '$1' | str trim
    } else {
        ""
    }

    let items = ($sections | skip 1 | each {|sec|
        let name = ($sec | split row "`" | first | str trim)
        let is_approved = ($sec =~ '-\s+\[[xX]\]\s+Approved')
        let is_rejected = ($sec =~ '-\s+\[[xX]\]\s+Not Approved')
        let is_official = (($sec =~ 'package_lists\.json\.official') or ($sec =~ 'package_lists\.json\.shared\.official') or ($sec =~ 'Official Repository Package'))
        let is_aur = (($sec =~ 'package_lists\.json\.aur') or ($sec =~ 'package_lists\.json\.shared\.aur') or ($sec =~ 'AUR Foreign Package'))
        let is_move = ($sec =~ 'Move to shared')
        let is_remove = ($sec =~ 'Remove from')

        let decision = if ($is_approved and not $is_rejected) {
            "approved"
        } else if ($is_rejected and not $is_approved) {
            "rejected"
        } else {
            "unresolved"
        }

        let target = if $is_official { "official" } else if $is_aur { "aur" } else { "unknown" }
        let op = if $is_move { "move" } else if $is_remove { "remove" } else { "add" }

        {
            name: $name,
            target: $target,
            op: $op,
            decision: $decision
        }
    })

    {
        path: $draft_path,
        date: $draft_date,
        target_host: $draft_host,
        items: $items
    }
}

# Finds and marks completed the pending Habitica review todo corresponding to a processed draft
export def complete-habitica [
    draft_date: string
    draft_host?: string
    --mock-todos: list
    --dry-run
] {
    let host = if ($draft_host != null and $draft_host != "") { $draft_host } else {
        try { detect-host | get target_host } catch { "cachyos-host" }
    }

    let pending_todos = if ($mock_todos != null) {
        $mock_todos
    } else {
        let h_script = "/home/username/workspace/my_scripts/nushell/habitica.nu"
        let nu_config = "/home/username/.config/nushell/config.nu"
        let nu_env = "/home/username/.config/nushell/env.nu"
        try {
            let res = (^nu --config $nu_config --env-config $nu_env -c $"use ($h_script) *; h ls todos | where completed == false | to json" | complete)
            if $res.exit_code == 0 and ($res.stdout | is-not-empty) {
                $res.stdout | from json
            } else {
                []
            }
        } catch {
            []
        }
    }

    if ($pending_todos | is-empty) {
        return {
            success: true,
            completed: false,
            count: 0,
            todo_ids: [],
            message: ("No pending Habitica todos found to match draft " + $draft_date + " (" + $host + ").")
        }
    }

    let matching = ($pending_todos | where {|it|
        let text = ($it.text? | default "")
        let has_prefix = ($text | str contains $"Review CachyOS Drift Draft ($draft_date)")
        if not $has_prefix {
            false
        } else if ($host != null and $host != "") {
            (($text | str contains $host) or not (($text | str contains "(") or ($text | str contains "[")))
        } else {
            true
        }
    })

    if ($matching | is-empty) {
        return {
            success: true,
            completed: false,
            count: 0,
            todo_ids: [],
            message: ("No matching Habitica todo found for draft " + $draft_date + " (" + $host + ").")
        }
    }

    let matching_ids = ($matching | get _id)

    if $dry_run {
        return {
            success: true,
            completed: true,
            dry_run: true,
            count: ($matching | length),
            todo_ids: $matching_ids,
            message: ("[DRY-RUN] Would mark " + ($matching | length | into string) + " Habitica todo(s) completed for draft " + $draft_date + " (" + $host + ").")
        }
    }

    let h_script = "/home/username/workspace/my_scripts/nushell/habitica.nu"
    let nu_config = "/home/username/.config/nushell/config.nu"
    let nu_env = "/home/username/.config/nushell/env.nu"
    let call_res = (try {
        let ids_json = ($matching_ids | to json -r)
        let nu_cmd = $"use ($h_script) *; let ids = '($ids_json)' | from json; h complete-todos --ids $ids"
        let res = (^nu --config $nu_config --env-config $nu_env -c $nu_cmd | complete)
        $res
    } catch { |err|
        { exit_code: 1, stdout: "", stderr: ($err | into string) }
    })

    let is_ok = ($call_res.exit_code == 0)
    let msg = if $is_ok {
        ("Successfully marked " + ($matching | length | into string) + " Habitica todo(s) as completed for draft " + $draft_date + " (" + $host + ").")
    } else {
        ("Failed to complete Habitica todo for draft " + $draft_date + ": " + ($call_res.stderr | str trim))
    }

    {
        success: $is_ok,
        completed: $is_ok,
        count: ($matching | length),
        todo_ids: $matching_ids,
        output: ($call_res.stdout | str trim),
        error: ($call_res.stderr | str trim),
        message: $msg
    }
}

# Applies decisions from a single draft file
export def apply-draft [
    draft_path: string
    --package-lists-path: string
    --rejected-drift-path: string
    --processed-dir: string
    --target-host: string
    --dry-run
    --git-commit
    --skip-habitica
    --mock-habitica-todos: list
] {
    let pkg_file = if ($package_lists_path != null) { $package_lists_path } else { get-default-package-lists-path }
    let rej_file = if ($rejected_drift_path != null) { $rejected_drift_path } else { get-default-rejected-path }
    let proc_dir = if ($processed_dir != null) { $processed_dir } else { get-default-processed-dir }

    if not ($pkg_file | path exists) {
        error make { msg: $"package_lists.json not found: ($pkg_file)" }
    }

    let parsed = (parse-draft $draft_path)
    let draft_host = $parsed.target_host
    let current_host = if ($target_host != null) { $target_host } else { (try { detect-host | get target_host } catch { "cachyos-host" }) }
    let is_local_host = ($draft_host == null or $draft_host == "" or $draft_host == $current_host)
    let items = $parsed.items

    let approved_items = ($items | where decision == "approved")
    let rejected_items = ($items | where decision == "rejected")
    let unresolved_items = ($items | where decision == "unresolved")

    if (($approved_items | length) == 0) and (($rejected_items | length) == 0) {
        return {
            processed: false,
            draft_path: $draft_path,
            approved_count: 0,
            rejected_count: 0,
            unresolved_count: ($unresolved_items | length),
            archived: false,
            message: "No approved or rejected items found. Draft remains in _drafts_drifts/."
        }
    }

    let off_adds = ($approved_items | where target == "official" and op == "add" | get name)
    let off_removes = ($approved_items | where target == "official" and op == "remove" | get name)
    let off_moves = ($approved_items | where target == "official" and op == "move" | get name)
    let aur_adds = ($approved_items | where target == "aur" and op == "add" | get name)
    let aur_removes = ($approved_items | where target == "aur" and op == "remove" | get name)
    let aur_moves = ($approved_items | where target == "aur" and op == "move" | get name)

    let rej_off = ($rejected_items | where target == "official" | get name)
    let rej_aur = ($rejected_items | where target == "aur" | get name)

    # 1. Update package_lists.json
    let repo_data = (open $pkg_file)
    let is_shared_schema = (($repo_data | columns) | any {|c| $c == "shared" or $c == "hosts"})

    let updated_pkg_data = if not $is_shared_schema {
        mut curr_off = ($repo_data.official? | default [])
        mut curr_aur = ($repo_data.aur? | default [])

        if ($off_adds | is-not-empty) {
            $curr_off = ($curr_off | append $off_adds)
        }
        if ($off_moves | is-not-empty) {
            $curr_off = ($curr_off | append $off_moves)
        }
        if ($off_removes | is-not-empty) {
            $curr_off = ($curr_off | where not ($it in $off_removes))
        }
        if ($aur_adds | is-not-empty) {
            $curr_aur = ($curr_aur | append $aur_adds)
        }
        if ($aur_moves | is-not-empty) {
            $curr_aur = ($curr_aur | append $aur_moves)
        }
        if ($aur_removes | is-not-empty) {
            $curr_aur = ($curr_aur | where not ($it in $aur_removes))
        }

        {
            official: ($curr_off | sort | uniq),
            aur: ($curr_aur | sort | uniq)
        }
    } else {
        mut shared_off = ($repo_data.shared.official? | default [])
        mut shared_aur = ($repo_data.shared.aur? | default [])
        mut hosts_data = ($repo_data.hosts? | default {})

        let target_h = if ($draft_host != null and $draft_host != "") { $draft_host } else { $current_host }
        let host_record = ($hosts_data | get -o $target_h | default { type: "desktop", official: [], aur: [] })
        mut host_off = ($host_record.official? | default [])
        mut host_aur = ($host_record.aur? | default [])

        # Adds go to target host only
        if ($off_adds | is-not-empty) {
            $host_off = ($host_off | append $off_adds)
        }
        if ($aur_adds | is-not-empty) {
            $host_aur = ($host_aur | append $aur_adds)
        }

        # Removes strip from shared AND target host
        if ($off_removes | is-not-empty) {
            $shared_off = ($shared_off | where not ($it in $off_removes))
            $host_off = ($host_off | where not ($it in $off_removes))
        }
        if ($aur_removes | is-not-empty) {
            $shared_aur = ($shared_aur | where not ($it in $aur_removes))
            $host_aur = ($host_aur | where not ($it in $aur_removes))
        }

        # Moves append to shared and strip from ALL hosts
        if ($off_moves | is-not-empty) {
            $shared_off = ($shared_off | append $off_moves)
            $host_off = ($host_off | where not ($it in $off_moves))
        }
        if ($aur_moves | is-not-empty) {
            $shared_aur = ($shared_aur | append $aur_moves)
            $host_aur = ($host_aur | where not ($it in $aur_moves))
        }

        let updated_target_host = ($host_record
            | upsert official ($host_off | sort | uniq)
            | upsert aur ($host_aur | sort | uniq))
        $hosts_data = ($hosts_data | upsert $target_h $updated_target_host)

        if ($off_moves | is-not-empty) or ($aur_moves | is-not-empty) {
            let other_hosts = ($hosts_data | columns | where {|h| $h != $target_h })
            for oh in $other_hosts {
                let rec = ($hosts_data | get $oh)
                mut o_off = ($rec.official? | default [])
                mut o_aur = ($rec.aur? | default [])
                if ($off_moves | is-not-empty) {
                    $o_off = ($o_off | where not ($it in $off_moves))
                }
                if ($aur_moves | is-not-empty) {
                    $o_aur = ($o_aur | where not ($it in $aur_moves))
                }
                let o_updated = ($rec
                    | upsert official ($o_off | sort | uniq)
                    | upsert aur ($o_aur | sort | uniq))
                $hosts_data = ($hosts_data | upsert $oh $o_updated)
            }
        }

        let shared_record = ($repo_data.shared? | default {})
        let updated_shared = ($shared_record
            | upsert official ($shared_off | sort | uniq)
            | upsert aur ($shared_aur | sort | uniq))

        $repo_data
            | upsert shared $updated_shared
            | upsert hosts $hosts_data
    }

    # 2. Update rejected_drift.json
    let rej_data = if ($rej_file | path exists) {
        open $rej_file
    } else {
        { official: [], aur: [], files: [] }
    }
    mut r_off = ($rej_data.official? | default [])
    mut r_aur = ($rej_data.aur? | default [])
    let r_files = ($rej_data.files? | default [])

    if ($rej_off | is-not-empty) {
        $r_off = ($r_off | append $rej_off)
    }
    if ($rej_aur | is-not-empty) {
        $r_aur = ($r_aur | append $rej_aur)
    }

    let updated_rej_data = {
        official: ($r_off | sort | uniq),
        aur: ($r_aur | sort | uniq),
        files: $r_files
    }

    if $dry_run {
        return {
            processed: true,
            dry_run: true,
            draft_path: $draft_path,
            approved_count: ($approved_items | length),
            rejected_count: ($rejected_items | length),
            unresolved_count: ($unresolved_items | length),
            added_official: $off_adds,
            removed_official: $off_removes,
            moved_official: $off_moves,
            added_aur: $aur_adds,
            removed_aur: $aur_removes,
            moved_aur: $aur_moves,
            rejected_official: $rej_off,
            rejected_aur: $rej_aur,
            archived: (($unresolved_items | length) == 0),
            habitica_completed: (if ((($unresolved_items | length) == 0) and (not $skip_habitica)) {
                (complete-habitica $parsed.date $draft_host --mock-todos $mock_habitica_todos --dry-run)
            } else { null })
        }
    }

    # Write files
    $updated_pkg_data | to json | save -f $pkg_file
    $updated_rej_data | to json | save -f $rej_file

    # If all items resolved, archive draft (only if local host)
    mut archived = false
    if (($unresolved_items | length) == 0) and $is_local_host {
        if not ($proc_dir | path exists) {
            mkdir $proc_dir
        }
        let raw_content = (open --raw $draft_path)
        let updated_content = ($raw_content | str replace "implemented: false" "implemented: true")
        let filename = ($draft_path | path basename)
        let target_proc_path = $"($proc_dir)/($filename)"

        $updated_content | save -f $target_proc_path
        rm -f $draft_path
        $archived = true
    }

    # Complete corresponding Habitica task upon successful archival
    mut habitica_res: any = null
    if $archived and (not $skip_habitica) {
        $habitica_res = (complete-habitica $parsed.date $draft_host --mock-todos $mock_habitica_todos)
    }

    # Commit package_lists.json to git repo if requested
    mut commit_hash: any = null
    if $git_commit {
        let repo_dir = get-default-backups-dir
        if ($"($repo_dir)/.git" | path exists) {
            let commit_msg = $"chore(cachyos): synchronize approved package drift from ($parsed.date) draft"
            ^git -C $repo_dir add conductor/package_lists.json
            if ($rej_file | str starts-with $repo_dir) {
                ^git -C $repo_dir add ($rej_file | path relative-to $repo_dir)
            }
            let commit_res = (try { ^git -C $repo_dir commit -m $commit_msg | complete } catch { { exit_code: 1, stdout: "" } })
            if $commit_res.exit_code == 0 {
                $commit_hash = (^git -C $repo_dir log -1 --format="%h" | str trim)
            }
        }
    }

    {
        processed: true,
        dry_run: false,
        draft_path: $draft_path,
        approved_count: ($approved_items | length),
        rejected_count: ($rejected_items | length),
        unresolved_count: ($unresolved_items | length),
        added_official: $off_adds,
        removed_official: $off_removes,
        moved_official: $off_moves,
        added_aur: $aur_adds,
        removed_aur: $aur_removes,
        moved_aur: $aur_moves,
        rejected_official: $rej_off,
        rejected_aur: $rej_aur,
        archived: $archived,
        habitica_completed: $habitica_res,
        commit_hash: $commit_hash
    }
}

# Processes all draft files present in _drafts_drifts/
export def process-all-drafts [
    --drafts-dir: string
    --package-lists-path: string
    --rejected-drift-path: string
    --processed-dir: string
    --target-host: string
    --all-hosts
    --dry-run
    --git-commit
    --skip-habitica
    --mock-habitica-todos: list
] {
    let d_dir = if ($drafts_dir != null) { $drafts_dir } else { get-default-drafts-dir }
    if not ($d_dir | path exists) {
        return []
    }

    let draft_files = (glob $"($d_dir)/*.md")
    if ($draft_files | is-empty) {
        return []
    }

    let current_host = if ($target_host != null) { $target_host } else { (try { detect-host | get target_host } catch { "cachyos-host" }) }

    mut results = []
    for f in $draft_files {
        let parsed = (try { parse-draft $f } catch { null })
        if ($parsed == null) { continue }

        # Skip draft belonging to another machine unless --all-hosts is explicitly passed
        if (not $all_hosts) and ($parsed.target_host != null) and ($parsed.target_host != "") and ($parsed.target_host != $current_host) {
            continue
        }

        let r = (apply-draft $f
            --package-lists-path $package_lists_path
            --rejected-drift-path $rejected_drift_path
            --processed-dir $processed_dir
            --target-host $current_host
            --dry-run=($dry_run)
            --git-commit=($git_commit)
            --skip-habitica=($skip_habitica)
            --mock-habitica-todos $mock_habitica_todos
        )
        $results = ($results | append $r)
    }

    $results
}
