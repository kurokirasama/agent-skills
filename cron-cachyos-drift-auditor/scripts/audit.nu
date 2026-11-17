# skills/cron-cachyos-drift-auditor/scripts/audit.nu
# Drift detection engine for CachyOS packages against conductor/package_lists.json
# Strictly local execution on CachyOS with dynamic hostname detection

def get-default-package-lists-path [] {
    "/home/username/workspace/Backups/linux/conductor/package_lists.json"
}

def get-default-rejected-path [] {
    let base = try { $env.MY_ENV_VARS.llms_configs } catch { "/home/username/workspace/llms_configs" } | path expand
    let skill_rej = $"($base)/skills/cron-cachyos-drift-auditor/rejected_drift.json"
    let backup_rej = "/home/username/workspace/Backups/linux/conductor/rejected_drift.json"
    if ($backup_rej | path exists) { $backup_rej } else { $skill_rej }
}

def get-default-base-packages-path [] {
    let base = try { $env.MY_ENV_VARS.llms_configs } catch { "/home/username/workspace/llms_configs" } | path expand
    let backup_base = "/home/username/workspace/Backups/linux/conductor/base_packages.json"
    let skill_base = $"($base)/skills/cron-cachyos-drift-auditor/base_packages.json"
    if ($backup_base | path exists) { $backup_base } else { $skill_base }
}

# Dynamically detects the current host without assumptions or SSH
export def detect-host [] {
    let current_host = try {
        sys host | get hostname
    } catch {
        try {
            ^hostname | str trim
        } catch {
            "cachyos-host"
        }
    }

    {
        target_host: $current_host,
        mode: "local",
        available: true,
        message: $"Running locally on ($current_host)"
    }
}

# Retrieves installed official and AUR packages from the local CachyOS machine
export def get-system-packages [host_info: record] {
    let all_explicit = (try {
        ^pacman -Qqe | lines | each { |l| $l | str trim } | where { |l| ($l | str length) > 0 }
    } catch {
        []
    })

    let aur_explicit = (try {
        ^pacman -Qqem | lines | each { |l| $l | str trim } | where { |l| ($l | str length) > 0 }
    } catch {
        []
    })

    let official_explicit = ($all_explicit | where not ($it in $aur_explicit))

    {
        official: $official_explicit,
        aur: $aur_explicit
    }
}

# Audits local system package drift against /home/username/workspace/Backups/linux/conductor/package_lists.json
export def audit-drift [
    --package-lists-path: string
    --rejected-drift-path: string
    --base-packages-path: string
    --mock-system: record
] {
    let pkg_file = if ($package_lists_path != null) { $package_lists_path } else { get-default-package-lists-path }
    let rej_file = if ($rejected_drift_path != null) { $rejected_drift_path } else { get-default-rejected-path }
    let base_file = if ($base_packages_path != null) { $base_packages_path } else { get-default-base-packages-path }

    let host_info = (detect-host)
    let current_host = $host_info.target_host

    let repo_data = if ($pkg_file | path exists) {
        open $pkg_file
    } else {
        { official: [], aur: [] }
    }

    let repo_official = if ("shared" in $repo_data) {
        let shared_off = ($repo_data.shared.official? | default [])
        let host_off = ($repo_data.hosts? | default {} | get -o $current_host | get -o official | default [])
        ($shared_off | append $host_off | sort | uniq)
    } else {
        ($repo_data.official? | default [])
    }

    let repo_aur = if ("shared" in $repo_data) {
        let shared_a = ($repo_data.shared.aur? | default [])
        let host_a = ($repo_data.hosts? | default {} | get -o $current_host | get -o aur | default [])
        ($shared_a | append $host_a | sort | uniq)
    } else {
        ($repo_data.aur? | default [])
    }

    let rejected_data = if ($rej_file | path exists) {
        open $rej_file
    } else {
        { official: [], aur: [], files: [] }
    }

    let rej_official = ($rejected_data.official? | default [])
    let rej_aur = ($rejected_data.aur? | default [])

    let base_data = if ($base_file | path exists) {
        try { open $base_file } catch { { official: [], aur: [] } }
    } else {
        { official: [], aur: [] }
    }
    let base_official = ($base_data.official? | default [])
    let base_aur = ($base_data.aur? | default [])

    let sys_packages = if ($mock_system != null) {
        $mock_system
    } else {
        get-system-packages $host_info
    }

    let sys_official = ($sys_packages.official? | default [])
    let sys_aur = ($sys_packages.aur? | default [])

    # All installed packages on system (including dependencies) to prevent false-positive "missing" alerts
    let all_installed_sys = if ($mock_system != null) {
        ($sys_official | append $sys_aur | uniq)
    } else {
        try {
            ^pacman -Qq | lines | each { |l| $l | str trim } | where { |l| ($l | str length) > 0 }
        } catch {
            ($sys_official | append $sys_aur | uniq)
        }
    }

    # Filter out items present in rejected_drift.json
    let unrejected_sys_off = ($sys_official | where not ($it in $rej_official))
    let unrejected_sys_aur = ($sys_aur | where not ($it in $rej_aur))

    # All expected packages across both categories to reconcile cross-category shifts
    let all_expected_packages = ($repo_official | append $repo_aur | uniq)

    # Calculate base-suppressed packages (installed, not expected in manifest, not rejected, but in base_packages.json)
    let base_suppressed_official = ($unrejected_sys_off | where ($it in $base_official) and not ($it in $all_expected_packages) | sort | uniq)
    let base_suppressed_aur = ($unrejected_sys_aur | where ($it in $base_aur) and not ($it in $all_expected_packages) | sort | uniq)
    let base_suppressed_count = (($base_suppressed_official | length) + ($base_suppressed_aur | length))

    # Calculate differences against expected (cross-category reconciled) and base OS
    let new_official = ($unrejected_sys_off | where not ($it in $all_expected_packages) and not ($it in $base_official) | sort | uniq)
    let new_aur = ($unrejected_sys_aur | where not ($it in $all_expected_packages) and not ($it in $base_aur) | sort | uniq)

    let missing_official = if ($mock_system != null) {
        ($repo_official | where not ($it in $all_installed_sys) | sort | uniq)
    } else {
        try {
            if ($repo_official | is-empty) { [] } else {
                let res = (^pacman -T ...$repo_official | complete)
                ($res.stdout | lines | each { |l| $l | str trim } | where { |l| ($l | str length) > 0 } | sort | uniq)
            }
        } catch {
            ($repo_official | where not ($it in $all_installed_sys) | sort | uniq)
        }
    }

    let missing_aur = if ($mock_system != null) {
        ($repo_aur | where not ($it in $all_installed_sys) | sort | uniq)
    } else {
        try {
            if ($repo_aur | is-empty) { [] } else {
                let res = (^pacman -T ...$repo_aur | complete)
                ($res.stdout | lines | each { |l| $l | str trim } | where { |l| ($l | str length) > 0 } | sort | uniq)
            }
        } catch {
            ($repo_aur | where not ($it in $all_installed_sys) | sort | uniq)
        }
    }

    let suppressed_official = ($sys_official | where ($it in $rej_official) and not ($it in $all_expected_packages) | sort | uniq)
    let suppressed_aur = ($sys_aur | where ($it in $rej_aur) and not ($it in $all_expected_packages) | sort | uniq)

    let suppressed_count = (($suppressed_official | length) + ($suppressed_aur | length))
    let total_drift = (($new_official | length) + ($new_aur | length) + ($missing_official | length) + ($missing_aur | length))

    {
        target_host: $current_host,
        mode: "local",
        package_lists_path: $pkg_file,
        rejected_drift_path: $rej_file,
        base_packages_path: $base_file,
        counts: {
            new_official: ($new_official | length),
            new_aur: ($new_aur | length),
            missing_official: ($missing_official | length),
            missing_aur: ($missing_aur | length),
            suppressed: $suppressed_count,
            base_suppressed: $base_suppressed_count,
            total_drift: $total_drift
        },
        drift: {
            new_official: $new_official,
            new_aur: $new_aur,
            missing_official: $missing_official,
            missing_aur: $missing_aur,
            suppressed_official: $suppressed_official,
            suppressed_aur: $suppressed_aur,
            base_suppressed_official: $base_suppressed_official,
            base_suppressed_aur: $base_suppressed_aur
        }
    }
}

# Cross-machine shared package candidate analysis
export def audit-shared-candidates [
    --package-lists-path: string
    --rejected-drift-path: string
] {
    let pkg_file = if ($package_lists_path != null) { $package_lists_path } else { get-default-package-lists-path }
    let repo_data = if ($pkg_file | path exists) { open $pkg_file } else { { shared: {}, hosts: {} } }
    let hosts = ($repo_data.hosts? | default {})
    let host_names = ($hosts | columns)
    if ($host_names | length) < 2 {
        return {
            proposed_shared_official: [],
            proposed_shared_aur: [],
            counts: { proposed_shared: 0 }
        }
    }

    let all_off = ($host_names | each { |h| $hosts | get $h | get -o official | default [] })
    let all_aur = ($host_names | each { |h| $hosts | get $h | get -o aur | default [] })

    # intersection across all hosts
    let inter_off = ($all_off | reduce { |lst, acc| $acc | where ($it in $lst) })
    let inter_aur = ($all_aur | reduce { |lst, acc| $acc | where ($it in $lst) })

    let shared_off = ($repo_data.shared.official? | default [])
    let shared_aur = ($repo_data.shared.aur? | default [])
    let rej_file = if ($rejected_drift_path != null) { $rejected_drift_path } else { get-default-rejected-path }
    let rej = if ($rej_file | path exists) { open $rej_file } else { { official: [], aur: [] } }
    let rej_official = ($rej.official? | default [])
    let rej_aur = ($rej.aur? | default [])

    let cand_off = ($inter_off | where not ($it in $shared_off) and not ($it in $rej_official) | sort | uniq)
    let cand_aur = ($inter_aur | where not ($it in $shared_aur) and not ($it in $rej_aur) | sort | uniq)

    {
        proposed_shared_official: $cand_off,
        proposed_shared_aur: $cand_aur,
        counts: {
            proposed_shared: (($cand_off | length) + ($cand_aur | length))
        }
    }
}
