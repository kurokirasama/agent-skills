# Pipeline sizing and 3-stage server compliance validator for hpc-cluster-orchestrator

# Assess compute placement (local vs rayen vs api_batch) and whether a pilot run is required.
export def assess-workload [spec: record]: nothing -> record {
  let hours = ($spec.estimated_local_hours? | default 0.0 | into float)
  let mem_gb = ($spec.memory_gb? | default 0.0 | into float)
  let jobs = ($spec.parallel_jobs? | default 1 | into int)
  let needs_gpu = ($spec.requires_gpu? | default false | into bool)
  let api_calls = ($spec.api_calls? | default 0 | into int)

  mut reasons = []
  mut needs_pilot = false

  if $api_calls >= 200 {
    $reasons = ($reasons | append $"High API volume \(($api_calls) calls\): run a minimal pilot and estimate total API cost before full launch.")
    $needs_pilot = true
  }

  let rayen_triggers = (
    ($hours >= 4.0) or ($mem_gb > 16.0) or ($jobs > 8) or ($needs_gpu and $hours >= 4.0)
  )

  if $hours >= 4.0 {
    $reasons = ($reasons | append $"Estimated local runtime ($hours)h >= 4h threshold.")
  }
  if $mem_gb > 16.0 {
    $reasons = ($reasons | append $"Peak RAM ($mem_gb)GB > 16GB local budget.")
  }
  if $jobs > 8 {
    $reasons = ($reasons | append $"Parallel sweep size ($jobs) jobs > 8 local threshold.")
  }
  if $needs_gpu and $hours >= 4.0 {
    $reasons = ($reasons | append "Sustained GPU sweep >= 4h benefits from cluster scheduling.")
  }

  let target = if $rayen_triggers {
    $needs_pilot = true
    "rayen"
  } else if $api_calls >= 200 {
    "api_batch"
  } else {
    if ($reasons | is-empty) {
      $reasons = ["Fits within local workstation thresholds (<4h, <=16GB RAM, <=8 jobs, <200 API calls)."]
    }
    "local"
  }

  {
    target: $target
    needs_pilot: $needs_pilot
    reasons: $reasons
  }
}

# Inspect a remote compute script (.m, .py, .sh, .sbatch) for compute-only, no-plotting, and NFS I/O compliance.
export def validate-remote-script [script_path: path]: nothing -> record {
  if not ($script_path | path exists) {
    return {
      path: ($script_path | into string)
      pass: false
      violations: ["Remote script file does not exist."]
    }
  }

  let raw = (open --raw $script_path)
  let ext = ($script_path | path parse | get extension | str lowercase)
  mut violations = []

  # 1. Forbidden remote figure export / plotting calls
  let forbidden_calls = [
    "exportgraphics("
    "saveas("
    "savefig("
    "plt.savefig("
    "print('-dpdf'"
    'print("-dpdf"'
    "print('-dpng'"
    'print("-dpng"'
  ]
  for pat in $forbidden_calls {
    if ($raw | str contains $pat) {
      $violations = ($violations | append $"Forbidden remote plotting/export call detected: ($pat)")
    }
  }

  # 2. Enforce compute-only skip_plots guard for MATLAB/Python remote entrypoints
  if $ext in ["m", "py"] {
    let has_skip_true = (
      ($raw =~ '(?i)skip_plots\s*=\s*(true|1)\b')
      or ($raw =~ '(?i)--skip-plots')
    )
    let sets_skip_false = ($raw =~ '(?i)skip_plots\s*=\s*(false|0)\b')
    if $sets_skip_false {
      $violations = ($violations | append "Remote script explicitly disables skip_plots (false/0); server jobs MUST be compute-only.")
    } else if not $has_skip_true {
      $violations = ($violations | append "Missing explicit compute-only guard (skip_plots = true / SKIP_PLOTS = True / --skip-plots).")
    }
  }

  # 3. Detect save(...) inside MATLAB parfor blocks (NFS lock contention hazard)
  if $ext == "m" {
    let lines = ($raw | lines)
    mut in_parfor = false
    mut parfor_save_hit = false
    for ln in $lines {
      let trimmed = ($ln | str trim)
      if ($trimmed | str starts-with "%") {
        continue
      }
      if ($trimmed =~ '^parfor\b') {
        $in_parfor = true
      } else if $in_parfor and ($trimmed =~ '^end\b') {
        $in_parfor = false
      } else if $in_parfor and ($trimmed =~ '\bsave\s*\(') {
        $parfor_save_hit = true
      }
    }
    if $parfor_save_hit {
      $violations = ($violations | append "NFS contention hazard: save(...) invoked directly inside MATLAB parfor loop; defer persistence outside parfor.")
    }
  }

  {
    path: ($script_path | into string)
    pass: ($violations | is-empty)
    violations: $violations
  }
}

def find-matching-files [dir: path, pattern: string]: nothing -> list<path> {
  let root = ($dir | path expand)
  if not ($root | path exists) { return [] }
  glob ($root | path join "**" $pattern) --exclude ["**/.git/**" "**/node_modules/**" "**/__pycache__/**"]
}

# Validate a project directory for 3-stage server pipeline compliance.
export def validate-cluster-pipeline [project_dir: path = "."]: nothing -> record {
  let root = ($project_dir | path expand)
  if not ($root | path exists) {
    return {
      pass: false
      errors: [$"Project directory does not exist: ($root)"]
      checked_remote_scripts: []
    }
  }

  mut errors = []

  # 1. Check for shell/check_cluster*.nu
  let check_scripts = (find-matching-files $root "check_cluster*.nu")
  if ($check_scripts | is-empty) {
    $errors = ($errors | append "Missing cluster status script (expected check_cluster*.nu under shell/ or project tree).")
  } else {
    let has_structured = ($check_scripts | any {|p| (open --raw $p) | str contains "--structured" })
    if not $has_structured {
      $errors = ($errors | append "check_cluster*.nu must support --structured flag for orchestrator integration.")
    }
  }

  # 2. Check for orchestrate_*.nu with rsync parity support
  let orch_scripts = (find-matching-files $root "orchestrate_*.nu")
  if ($orch_scripts | is-empty) {
    $errors = ($errors | append "Missing cluster orchestrator script (expected orchestrate_*.nu).")
  } else {
    let has_rsync = ($orch_scripts | any {|p| (open --raw $p) | str contains "rsync" })
    if not $has_rsync {
      $errors = ($errors | append "orchestrate_*.nu must integrate rsync for pre-flight code sync and Stage 2 artifact parity.")
    }
  }

  # 3. Inspect remote entrypoints referenced by sbatch or named *rayen* / *cluster*
  let sbatch_files = (find-matching-files $root "*.sbatch")
  let remote_m = (find-matching-files $root "*rayen*.m")
  let remote_py = (find-matching-files $root "*rayen*.py")
  let candidate_remotes = ($remote_m | append $remote_py | uniq)

  mut checked = []
  for f in $candidate_remotes {
    let res = (validate-remote-script $f)
    $checked = ($checked | append $res)
    if not $res.pass {
      for v in $res.violations {
        $errors = ($errors | append $"($f | path basename): ($v)")
      }
    }
  }

  for sb in $sbatch_files {
    let sb_raw = (open --raw $sb)
    if ($sb_raw | str contains "savefig") or ($sb_raw | str contains "exportgraphics") {
      $errors = ($errors | append $"($sb | path basename): sbatch script must not invoke plotting commands.")
    }
  }

  {
    pass: ($errors | is-empty)
    errors: $errors
    checked_remote_scripts: $checked
  }
}

# CLI entrypoint to validate 3-stage cluster pipeline compliance and emit JSON.
export def main [project_dir: path = "."] {
  validate-cluster-pipeline $project_dir | to json
}
