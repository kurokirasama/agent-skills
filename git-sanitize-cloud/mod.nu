# skills/git-sanitize-cloud/mod.nu
# Diagnostic gathering module for Git repositories in cloud-synced folders (cloud & workspace)

# Detect if the target path is hosted in a cloud-synchronized environment and identify git state
export def detect-cloud-environment [
    --path: string = "."
]: nothing -> record {
    let target = ($path | path expand)
    
    let is_dropbox = ($target =~ '(?i)cloud')
    let is_yandex = ($target =~ '(?i)yandex(\.|\s*)disk' or $target =~ '(?i)yandex')
    
    let provider = if $is_dropbox {
        "cloud"
    } else if $is_yandex {
        "yandex"
    } else {
        "none"
    }
    
    let is_cloud = ($provider != "none")
    
    let git_check = (do { ^git -C $target rev-parse --show-toplevel } | complete)
    let has_git = ($git_check.exit_code == 0)
    let repo_root = if $has_git {
        ($git_check.stdout | str trim)
    } else {
        ""
    }
    
    let daemons = (try {
        ps | where { |p| $p.name =~ "(?i)(cloud|yandex-disk)" }
    } catch { [] })
    let daemon_running = (not ($daemons | is-empty))
    
    {
        is_cloud: $is_cloud,
        provider: $provider,
        has_git: $has_git,
        repo_root: $repo_root,
        daemon_running: $daemon_running
    }
}

# Inspect cloud synchronization artifacts such as stale locks and conflict copies
export def inspect-cloud-artifacts [
    --path: string = "."
]: nothing -> record {
    let env_info = (detect-cloud-environment --path $path)
    let repo_root = if $env_info.has_git {
        $env_info.repo_root
    } else {
        ($path | path expand)
    }
    
    let git_dir = [($repo_root), ".git"] | path join
    let git_exists = ($git_dir | path exists)
    
    # 1. Stale .git lock files
    let stale_locks = if $git_exists {
        try {
            glob $"($git_dir)/**/*.lock"
        } catch { [] }
    } else { [] }
    
    # Check if active git process is running
    let git_procs = (try {
        ps | where { |p| $p.name =~ "(?i)^git(\\.exe)?$" }
    } catch { [] })
    let git_running = (not ($git_procs | is-empty))
    
    # 2. Conflict copies inside .git/
    let git_conflicts = if $git_exists {
        let pattern1 = try { glob $"($git_dir)/**/*conflicted*" } catch { [] }
        let pattern2 = try { glob $"($git_dir)/**/*sync-conflict*" } catch { [] }
        let pattern3 = try { glob $"($git_dir)/**/*Case conflict*" } catch { [] }
        $pattern1 ++ $pattern2 ++ $pattern3 | uniq
    } else { [] }
    
    # 3. Conflict copies in worktree (excluding .git/)
    let wt_conflicts = (try {
        let p1 = try { glob $"($repo_root)/**/*conflicted*" } catch { [] }
        let p2 = try { glob $"($repo_root)/**/*sync-conflict*" } catch { [] }
        let p3 = try { glob $"($repo_root)/**/*Case conflict*" } catch { [] }
        $p1 ++ $p2 ++ $p3
        | where { |f| ($f !~ '/\.git(/|$)') }
        | uniq
    } catch { [] })
    
    {
        stale_locks: $stale_locks,
        git_running: $git_running,
        git_dir_conflicts: $git_conflicts,
        worktree_conflicts: $wt_conflicts
    }
}

# Inspect Git repository integrity using git fsck
export def inspect-git-integrity [
    --path: string = "."
]: nothing -> record {
    let env_info = (detect-cloud-environment --path $path)
    if not $env_info.has_git {
        return {
            is_intact: false,
            errors: ["Not a git repository"],
            warnings: [],
            raw_output: ""
        }
    }
    
    let repo_root = $env_info.repo_root
    let fsck_res = (do { ^git -C $repo_root fsck --full } | complete)
    let combined_out = $"($fsck_res.stdout)\n($fsck_res.stderr)" | str trim
    let lines = ($combined_out | lines | where { |l| not ($l | is-empty) })
    
    let errors = ($lines | where { |l|
        ($l =~ "(?i)error:") or ($l =~ "(?i)fatal:") or ($l =~ "(?i)corrupt")
    })
    let warnings = ($lines | where { |l|
        ($l =~ "(?i)warning:") or ($l =~ "(?i)dangling")
    })
    
    let is_intact = ($fsck_res.exit_code == 0 and ($errors | is-empty))
    
    {
        is_intact: $is_intact,
        errors: $errors,
        warnings: $warnings,
        raw_output: $combined_out
    }
}

# Refresh remote-tracking refs from origin. Non-destructive: only updates
# .git/refs/remotes (plus FETCH_HEAD); never touches the worktree, index, or
# local branches. MUST run before trusting any ahead/behind comparison,
# because origin/<branch> is only as fresh as the last fetch.
export def refresh-remote-refs [
    --path: string = "."
    --remote: string = "origin"
]: nothing -> record {
    let env_info = (detect-cloud-environment --path $path)
    if not $env_info.has_git {
        return {
            fetched: false,
            remote: $remote,
            exit_code: 1,
            output: "Not a git repository"
        }
    }

    let repo_root = $env_info.repo_root
    let res = (do { ^git -C $repo_root fetch $remote --prune } | complete)

    {
        fetched: ($res.exit_code == 0),
        remote: $remote,
        exit_code: $res.exit_code,
        output: (($res.stdout + $res.stderr) | str trim)
    }
}

# Inspect divergence between local index, worktree, and remote origin
export def inspect-cloud-divergence [
    --path: string = "."
]: nothing -> record {
    let env_info = (detect-cloud-environment --path $path)
    if not $env_info.has_git {
        return {
            branch: "",
            upstream: "",
            local_head: "",
            remote_head: "",
            ahead: 0,
            behind: 0,
            phantom_deletes: [],
            stale_local_files: [],
            uncommitted_changes: []
        }
    }
    
    let repo_root = $env_info.repo_root
    
    # Current branch
    let br_res = (do { ^git -C $repo_root branch --show-current } | complete)
    let branch = ($br_res.stdout | str trim)
    
    # Upstream branch
    let up_res = (do { ^git -C $repo_root rev-parse --abbrev-ref --symbolic-full-name "@{u}" } | complete)
    let upstream = if $up_res.exit_code == 0 {
        ($up_res.stdout | str trim)
    } else {
        ""
    }
    
    # Local and remote HEAD SHAs (remote is the fetched remote-tracking ref)
    let lh_res = (do { ^git -C $repo_root rev-parse HEAD } | complete)
    let local_head = if $lh_res.exit_code == 0 {
        ($lh_res.stdout | str trim)
    } else {
        ""
    }
    let rh_res = if $upstream != "" {
        (do { ^git -C $repo_root rev-parse $upstream } | complete)
    } else {
        { exit_code: 1, stdout: "", stderr: "" }
    }
    let remote_head = if $rh_res.exit_code == 0 {
        ($rh_res.stdout | str trim)
    } else {
        ""
    }

    # Ahead / Behind counts
    mut ahead = 0
    mut behind = 0
    if ($upstream != "") {
        let count_res = (do { ^git -C $repo_root rev-list --left-right --count $"HEAD...($upstream)" } | complete)
        if $count_res.exit_code == 0 {
            let counts = ($count_res.stdout | str trim | split row (char tab))
            if ($counts | length) >= 2 {
                $ahead = (try { $counts | get 0 | into int } catch { 0 })
                $behind = (try { $counts | get 1 | into int } catch { 0 })
            }
        }
    }
    
    # Git porcelain status
    let status_res = (do { ^git -C $repo_root status --porcelain } | complete)
    let status_lines = ($status_res.stdout | lines | where { |l| not ($l | is-empty) })
    
    mut phantom_deletes = []
    mut stale_local_files = []
    mut uncommitted_changes = []
    
    for line in $status_lines {
        let code = ($line | str substring 0..2)
        let file_rel = ($line | str substring 3..) | str trim
        let file_path = [($repo_root), $file_rel] | path join
        
        # Check for Phantom Staged Delete:
        # Code starts with 'D' (staged deletion), but file still exists on disk!
        let is_staged_delete = ($code | str starts-with "D")
        if $is_staged_delete {
            if ($file_path | path exists) {
                $phantom_deletes = ($phantom_deletes | append $file_rel)
            } else {
                $uncommitted_changes = ($uncommitted_changes | append $file_rel)
            }
            continue
        }
        
        # Check for Stale Local Files:
        # File is modified in worktree (unstaged ' M' or staged 'M ')
        if ($file_path | path exists) and ($code =~ "M") {
            # Check commit date of the file
            let commit_date_res = (do {
                ^git -C $repo_root log -1 --format="%cI" -- $file_rel
            } | complete)
            
            if $commit_date_res.exit_code == 0 and ($commit_date_res.stdout | str trim | is-not-empty) {
                let commit_dt_str = ($commit_date_res.stdout | str trim)
                let commit_dt = (try { $commit_dt_str | into datetime } catch { null })
                let file_stat = (try { ls $file_path | get 0 } catch { null })
                
                if ($commit_dt != null) and ($file_stat != null) {
                    let file_mtime = $file_stat.modified
                    # If file modified time is older than the last commit date,
                    # this strongly indicates an outdated cloud overwrite!
                    if $file_mtime < $commit_dt {
                        $stale_local_files = ($stale_local_files | append $file_rel)
                        continue
                    }
                }
            }
        }
        
        $uncommitted_changes = ($uncommitted_changes | append $file_rel)
    }
    
    {
        branch: $branch,
        upstream: $upstream,
        local_head: $local_head,
        remote_head: $remote_head,
        ahead: $ahead,
        behind: $behind,
        phantom_deletes: $phantom_deletes,
        stale_local_files: $stale_local_files,
        uncommitted_changes: $uncommitted_changes
    }
}

# Unified orchestrator returning a comprehensive structured diagnostic record.
# Fetches origin first by default; a stale remote-tracking ref would otherwise
# produce false "0 ahead / 0 behind" results. Use --no-fetch only when the refs
# were already refreshed in this session.
export def gather-cloud-repo-status [
    --path: string = "."
    --no-fetch
]: nothing -> record {
    let env_diag = (detect-cloud-environment --path $path)
    let remote_sync = if $no_fetch {
        {
            fetched: false,
            remote: "origin",
            exit_code: 0,
            output: "skipped (--no-fetch)"
        }
    } else {
        refresh-remote-refs --path $path
    }
    let art_diag = (inspect-cloud-artifacts --path $path)
    let int_diag = (inspect-git-integrity --path $path)
    let div_diag = (inspect-cloud-divergence --path $path)

    {
        environment: $env_diag,
        remote_sync: $remote_sync,
        artifacts: $art_diag,
        integrity: $int_diag,
        divergence: $div_diag
    }
}
