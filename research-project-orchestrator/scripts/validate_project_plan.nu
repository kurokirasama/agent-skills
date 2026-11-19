# Schema and ordering validator for research project-plan.md blueprints

# Validate a research project-plan.md file against required sections, 8 stages, skill mappings, and ordering rules.
export def validate-research-plan [plan_path: path = "project-plan.md"]: nothing -> record {
  if not ($plan_path | path exists) {
    return {
      pass: false
      missing_sections: ["ALL (file not found)"]
      missing_stages: []
      missing_skills: []
      ordering_errors: []
      warnings: [$"Plan file does not exist: ($plan_path)"]
    }
  }

  let raw = (open --raw $plan_path)
  let low = ($raw | str lowercase)

  mut missing_sections = []
  mut missing_stages = []
  mut missing_skills = []
  mut ordering_errors = []
  mut warnings = []

  # 1. Required 3 top-level sections
  if not ($low =~ '##\s*1\.\s*project objectives|##\s*project objectives') {
    $missing_sections = ($missing_sections | append "## 1. Project Objectives")
  }
  if not ($low =~ '##\s*2\.\s*high-level execution roadmap|##\s*high-level execution roadmap|##\s*execution roadmap') {
    $missing_sections = ($missing_sections | append "## 2. High-Level Execution Roadmap")
  }
  if not ($low =~ '##\s*3\.\s*algorithmic|##\s*algorithmic.*ideas|##\s*implementation.*ideas') {
    $missing_sections = ($missing_sections | append "## 3. Algorithmic, Methodological & Workflow Ideas")
  }

  # 2. Required 8 stages
  for n in 1..8 {
    let stage_pat = $"###\\s*stage\\s+($n)\\b"
    if not ($low =~ $stage_pat) {
      $missing_stages = ($missing_stages | append $"Stage ($n)")
    }
  }

  # 3. Required skill mentions across the research pipeline
  let required_skills = [
    "conductor-setup"
    "initialize-research"
    "deep-research"
    "hpc-cluster-orchestrator"
    "results-insights-enhancer"
    "write-journal-paper"
    "paper-ground-truth-auditor"
    "peer-reviewer"
    "paper-submission-packager"
  ]
  for sk in $required_skills {
    if not ($low | str contains $sk) {
      $missing_skills = ($missing_skills | append $sk)
    }
  }

  # 4. Critical Stage 1 ordering rule: conductor-setup MUST appear before initialize-research
  let stage1_start = ($low | str index-of "### stage 1")
  let stage1_slice = if $stage1_start >= 0 { $low | str substring $stage1_start.. } else { $low }
  if ($stage1_slice | str contains "conductor-setup") and ($stage1_slice | str contains "initialize-research") {
    let idx_setup = ($stage1_slice | str index-of "conductor-setup")
    let idx_init = ($stage1_slice | str index-of "initialize-research")
    if $idx_init < $idx_setup {
      $ordering_errors = ($ordering_errors | append "Stage 1 ordering error: 'conductor-setup' MUST appear before 'initialize-research'.")
    }
  }

  # 5. Check invocation code blocks exist
  if not ($raw | str contains "```") {
    $warnings = ($warnings | append "Missing fenced invocation code blocks (```...```) showing how to invoke stage skills.")
  }

  # 6. Check key safety invariants
  if not ($low | str contains "skip_plots") {
    $warnings = ($warnings | append "Stage 3 should explicitly enforce 'skip_plots = true' (no remote plotting on server).")
  }
  if not (($low | str contains "fresh session") or ($low | str contains "different session")) {
    $warnings = ($warnings | append "Stage 6 should explicitly instruct repeating reviews across fresh sessions.")
  }

  let has_blocking_warnings = ($warnings | any {|w| $w | str contains "code block" })
  let pass = (
    ($missing_sections | is-empty)
    and ($missing_stages | is-empty)
    and ($missing_skills | is-empty)
    and ($ordering_errors | is-empty)
    and (not $has_blocking_warnings)
  )

  {
    pass: $pass
    missing_sections: $missing_sections
    missing_stages: $missing_stages
    missing_skills: $missing_skills
    ordering_errors: $ordering_errors
    warnings: $warnings
  }
}

# CLI entrypoint to validate a research project-plan.md file and emit JSON.
export def main [plan_path: path = "project-plan.md"] {
  validate-research-plan $plan_path | to json
}
