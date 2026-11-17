# skills/cron-cachyos-drift-auditor/scripts/draft_generator.nu
# Formats audit results into reviewable Markdown drafts with approval checkboxes
# Saves drafts directly to Obsidian AGENTS_MEMORY/_drafts_drifts

def get-vault-path [] {
    try { $env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT } catch { "/home/username/workspace/obsidian/vaults" } | path expand
}

def get-default-drafts-dir [] {
    let vault = (get-vault-path)
    $"($vault)/AGENTS_MEMORY/_drafts_drifts"
}

# Formats an audit result into Markdown text
export def format-draft-markdown [
    audit_res: record
    --date: string
] {
    let d = if ($date != null) { $date } else { date now | format date "%Y-%m-%d" }
    let host = if ("target_host" in $audit_res) { $audit_res.target_host } else { "cachyos-host" }
    let mode = if ("mode" in $audit_res) { $audit_res.mode } else { "local" }
    let counts = $audit_res.counts
    let drift = $audit_res.drift

    let actionable_total = (($counts.new_official) + ($counts.new_aur) + ($counts.missing_official) + ($counts.missing_aur))
    let missing_total = (($counts.missing_official) + ($counts.missing_aur))

    mut draft_lines = [
        "---",
        $"date: \"($d)\"",
        $"target_host: \"($host)\"",
        "implemented: false",
        "---",
        "",
        $"# CachyOS System Drift Audit: ($d)",
        "",
        "## Summary",
        $"- Target Host: `($host)`",
        $"- Execution Mode: `($mode)`",
        $"- New Official Packages: ($counts.new_official)",
        $"- New AUR Packages: ($counts.new_aur)",
        $"- Missing / Uninstalled Packages: ($missing_total)",
        ("- Suppressed [Rejected] Packages: " + ($counts.suppressed | into string)),
        ("- Base OS Packages Suppressed: " + (($counts.base_suppressed? | default 0) | into string)),
        $"- Total Actionable Items: ($actionable_total)",
        ""
    ]

    if ($counts.new_official > 0) {
        $draft_lines = ($draft_lines | append [
            "## 1. Proposed New Official Packages",
            "Mark `- [x] Approved` to add to `/home/username/workspace/Backups/linux/conductor/package_lists.json` (`official`).",
            "Mark `- [x] Not Approved` to suppress permanently in `rejected_drift.json`.",
            ""
        ])

        for pkg in $drift.new_official {
            $draft_lines = ($draft_lines | append [
                $"### Package: `($pkg)`",
                "- **Category**: Official Repository Package",
                "- **Status**: Installed on CachyOS, missing from declarative repository",
                "- **Proposed Action**: Append to `package_lists.json.official`",
                "- **Decision**:",
                "  - [ ] Approved",
                "  - [ ] Not Approved",
                ""
            ])
        }
    }

    if ($counts.new_aur > 0) {
        $draft_lines = ($draft_lines | append [
            "## 2. Proposed New AUR Packages",
            "Mark `- [x] Approved` to add to `/home/username/workspace/Backups/linux/conductor/package_lists.json` (`aur`).",
            "Mark `- [x] Not Approved` to suppress permanently in `rejected_drift.json`.",
            ""
        ])

        for pkg in $drift.new_aur {
            $draft_lines = ($draft_lines | append [
                $"### Package: `($pkg)`",
                "- **Category**: AUR Foreign Package",
                "- **Status**: Installed via paru/AUR on CachyOS, missing from declarative repository",
                "- **Proposed Action**: Append to `package_lists.json.aur`",
                "- **Decision**:",
                "  - [ ] Approved",
                "  - [ ] Not Approved",
                ""
            ])
        }
    }

    if ($missing_total > 0) {
        $draft_lines = ($draft_lines | append [
            "## 3. Missing Packages (Present in Repo, Missing on System)",
            "These packages are listed in `package_lists.json` but are not installed on CachyOS.",
            "Mark `- [x] Approved` to prune from `package_lists.json`.",
            "Mark `- [x] Not Approved` to retain in `package_lists.json` (e.g. planned or optional packages).",
            ""
        ])

        let missing_off = if ("missing_official" in $drift) { $drift.missing_official } else { [] }
        for pkg in $missing_off {
            $draft_lines = ($draft_lines | append [
                $"### Package: `($pkg)`",
                "- **Category**: Official Repo (Missing locally)",
                "- **Status**: Absent from CachyOS",
                "- **Proposed Action**: Remove from `package_lists.json.official`",
                "- **Decision**:",
                "  - [ ] Approved",
                "  - [ ] Not Approved",
                ""
            ])
        }

        let missing_a = if ("missing_aur" in $drift) { $drift.missing_aur } else { [] }
        for pkg in $missing_a {
            $draft_lines = ($draft_lines | append [
                $"### Package: `($pkg)`",
                "- **Category**: AUR (Missing locally)",
                "- **Status**: Absent from CachyOS",
                "- **Proposed Action**: Remove from `package_lists.json.aur`",
                "- **Decision**:",
                "  - [ ] Approved",
                "  - [ ] Not Approved",
                ""
            ])
        }
    }

    let shared_cand = if ("shared_candidates" in $audit_res) {
        $audit_res.shared_candidates
    } else {
        { proposed_shared_official: [], proposed_shared_aur: [], counts: { proposed_shared: 0 } }
    }
    let prop_off = ($shared_cand.proposed_shared_official? | default [])
    let prop_aur = ($shared_cand.proposed_shared_aur? | default [])
    let prop_total = (($prop_off | length) + ($prop_aur | length))

    if ($prop_total > 0) {
        $draft_lines = ($draft_lines | append [
            "## 4. Proposed Move to Shared Items",
            "These packages are recorded per-host but identical across ALL machines. Move them to `shared`.",
            ""
        ])

        for pkg in $prop_off {
            $draft_lines = ($draft_lines | append [
                $"### Package: `($pkg)`",
                "- **Category**: Official Repository Package",
                "- **Status**: Present in every host's list, currently per-host",
                "- **Proposed Action**: Move to shared — append to `package_lists.json.shared.official`, strip from every `hosts.*.official`",
                "- **Decision**:",
                "  - [ ] Approved",
                "  - [ ] Not Approved",
                ""
            ])
        }

        for pkg in $prop_aur {
            $draft_lines = ($draft_lines | append [
                $"### Package: `($pkg)`",
                "- **Category**: AUR Foreign Package",
                "- **Status**: Present in every host's list, currently per-host",
                "- **Proposed Action**: Move to shared — append to `package_lists.json.shared.aur`, strip from every `hosts.*.aur`",
                "- **Decision**:",
                "  - [ ] Approved",
                "  - [ ] Not Approved",
                ""
            ])
        }
    }

    $draft_lines | str join (char nl)
}

# Generates draft file in _drafts_drifts directory atomically
export def generate-draft [
    audit_res: record
    --drafts-dir: string
    --date: string
    --force
    --dry-run
] {
    let d = if ($date != null) { $date } else { date now | format date "%Y-%m-%d" }
    let target_dir = if ($drafts_dir != null) { $drafts_dir } else { get-default-drafts-dir }

    if not ($target_dir | path exists) {
        mkdir $target_dir
    }

    let prop_total = ($audit_res.shared_candidates?.counts?.proposed_shared? | default 0)
    let actionable_drift = (($audit_res.counts.new_official) + ($audit_res.counts.new_aur) + ($audit_res.counts.missing_official) + ($audit_res.counts.missing_aur) + $prop_total)
    if ($actionable_drift == 0) {
        return {
            created: false,
            path: null,
            reason: "zero_drift",
            message: "No package drift detected against repository. No review draft needed."
        }
    }

    let host = ($audit_res.target_host? | default "cachyos-host")
    let draft_filename = $"($d)_($host).md"
    let draft_path = $"($target_dir)/($draft_filename)"

    if $dry_run {
        return {
            created: true,
            dry_run: true,
            path: $draft_path,
            date: $d,
            target_host: $host,
            counts: $audit_res.counts,
            message: $"[DRY-RUN] Draft would be written to ($draft_path)"
        }
    }

    let legacy_path = $"($target_dir)/($d).md"
    let check_path = if ($draft_path | path exists) { $draft_path } else if ($legacy_path | path exists) { $legacy_path } else { null }

    if ($check_path != null) and (not $force) {
        let existing_content = (open --raw $check_path)
        if ($existing_content =~ "implemented: true") {
            let timestamp_suffix = (date now | format date "%H%M%S")
            let suffixed_path = $"($target_dir)/($d)_($host)_($timestamp_suffix).md"
            let content = (format-draft-markdown $audit_res --date $d)
            $content | save -f $suffixed_path
            return {
                created: true,
                path: $suffixed_path,
                date: $d,
                target_host: $host,
                counts: $audit_res.counts,
                message: $"Draft created at ($suffixed_path)"
            }
        }
    }

    let content = (format-draft-markdown $audit_res --date $d)
    let tmp_path = $"($target_dir)/.tmp_($draft_filename)"
    $content | save -f $tmp_path
    mv -f $tmp_path $draft_path

    {
        created: true,
        path: $draft_path,
        date: $d,
        target_host: $host,
        counts: $audit_res.counts,
        message: $"Draft successfully written to ($draft_path)"
    }
}

# Creates Habitica review todo with checklist of drifted packages
export def notify-habitica [
    draft_result: record
    audit_res: record
    --dry-run
] {
    if not ($draft_result.created? | default false) {
        return {
            success: true,
            notified: false,
            message: "No draft created, skipping Habitica notification."
        }
    }

    let d = $draft_result.date
    let counts = $draft_result.counts
    let host = if ("target_host" in $audit_res) { $audit_res.target_host } else { "cachyos-host" }
    let drift = (if ("drift" in $audit_res) { $audit_res.drift } else { {} })

    let new_off = (if ("new_official" in $drift) { $drift.new_official } else { [] })
    let new_a = (if ("new_aur" in $drift) { $drift.new_aur } else { [] })
    let missing_off = (if ("missing_official" in $drift) { $drift.missing_official } else { [] })
    let missing_a = (if ("missing_aur" in $drift) { $drift.missing_aur } else { [] })

    let prop_off = (if ("shared_candidates" in $audit_res) { $audit_res.shared_candidates.proposed_shared_official? | default [] } else { [] })
    let prop_aur = (if ("shared_candidates" in $audit_res) { $audit_res.shared_candidates.proposed_shared_aur? | default [] } else { [] })

    mut items = []
    for pkg in $new_off { $items = ($items | append $"official: ($pkg)") }
    for pkg in $new_a { $items = ($items | append $"aur: ($pkg)") }
    for pkg in $missing_off { $items = ($items | append $"missing [official]: ($pkg)") }
    for pkg in $missing_a { $items = ($items | append $"missing [aur]: ($pkg)") }
    for pkg in $prop_off { $items = ($items | append $"move to shared [official]: ($pkg)") }
    for pkg in $prop_aur { $items = ($items | append $"move to shared [aur]: ($pkg)") }

    let checklist = if ($items | length) > 25 {
        let first_24 = ($items | first 24)
        let remaining = (($items | length) - 24)
        $first_24 | append $"... and ($remaining) more items in draft"
    } else {
        $items
    }

    let todo_text = $"Review CachyOS Drift Draft ($d) [($host)]"
    let draft_path = if ("path" in $draft_result) { $draft_result.path } else { "" }
    let missing_sum = (($counts.missing_official) + ($counts.missing_aur))
    let notes = $"Review draft at ($draft_path)\nHost: ($host)\nOfficial: ($counts.new_official), AUR: ($counts.new_aur), Missing: ($missing_sum)"
    let tag_name = $"software-updates-($host)"

    if $dry_run {
        return {
            success: true,
            notified: true,
            dry_run: true,
            todo_text: $todo_text,
            checklist: $checklist,
            tag: $tag_name,
            message: $"[DRY-RUN] Habitica todo would be created for ($todo_text) with tag ($tag_name) and ($checklist | length) items."
        }
    }

    let h_script = "/home/username/workspace/my_scripts/nushell/habitica.nu"
    let call_res = (try {
        let nu_config = "/home/username/.config/nushell/config.nu"
        let nu_env = "/home/username/.config/nushell/env.nu"
        let payload = {
            todo_text: $todo_text,
            notes: $notes,
            checklist: $checklist,
            tag: $tag_name
        }
        let payload_file = $"/tmp/.habitica_drift_($d).json"
        $payload | to json | save -f $payload_file

        let nu_cmd = $"use ($h_script) *; let p = open ($payload_file); h add todos --text $p.todo_text --notes $p.notes --priority 1 --due '' --checklist $p.checklist --tag-name [$p.tag]"
        let res = (^nu --config $nu_config --env-config $nu_env -c $nu_cmd | complete)
        rm -f $payload_file
        $res
    } catch { |err|
        { exit_code: 1, stdout: "", stderr: ($err | into string) }
    })

    {
        success: ($call_res.exit_code == 0),
        notified: ($call_res.exit_code == 0),
        todo_text: $todo_text,
        tag: $tag_name,
        checklist_count: ($checklist | length),
        output: ($call_res.stdout | str trim),
        error: ($call_res.stderr | str trim)
    }
}
