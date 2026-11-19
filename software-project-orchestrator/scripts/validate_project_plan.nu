# Schema and archetype validator for code-only project-plan.md blueprints

# Validate a software project-plan.md file against required sections, 8 stages, and archetype-specific skills.
export def validate-software-plan [
  plan_path: path = "project-plan.md"
  --archetype (-a): string = "web"
  --llm (-l)  # Enforce LLM/RAG security protocol checks (llm-security.md, prompt injection, or .gemini_security)
]: nothing -> record {
  let arch = ($archetype | str lowercase | str trim)
  if not ($plan_path | path exists) {
    return {
      pass: false
      archetype: $arch
      missing_sections: ["ALL (file not found)"]
      missing_stages: []
      missing_skills: []
      warnings: [$"Plan file does not exist: ($plan_path)"]
    }
  }

  let raw = (open --raw $plan_path)
  let low = ($raw | str lowercase)

  mut missing_sections = []
  mut missing_stages = []
  mut missing_skills = []
  mut warnings = []

  # 1. Required 3 top-level sections
  if not ($low =~ '##\s*1\.\s*project objectives|##\s*project objectives') {
    $missing_sections = ($missing_sections | append "## 1. Project Objectives & Product Vision")
  }
  if not ($low =~ '##\s*2\.\s*high-level execution roadmap|##\s*high-level execution roadmap|##\s*execution roadmap') {
    $missing_sections = ($missing_sections | append "## 2. High-Level Execution Roadmap")
  }
  if not ($low =~ '##\s*3\.\s*architecture|##\s*architecture.*ideas|##\s*implementation.*ideas') {
    $missing_sections = ($missing_sections | append "## 3. Architecture, Implementation & Workflow Ideas")
  }

  # 2. Required 8 stages
  for n in 1..8 {
    let stage_pat = $"###\\s*stage\\s+($n)\\b"
    if not ($low =~ $stage_pat) {
      $missing_stages = ($missing_stages | append $"Stage ($n)")
    }
  }

  # 3. Core skills required across all software archetypes
  mut required_skills = [
    "conductor-setup"
    "context-expert"
    "test-engineer"
    "conductor-review"
    "security-analyst-specialist"
    "create-software-project-docs"
  ]

  # 4. Archetype-specific mandatory skills (UI/Web projects require design, a11y, SEO)
  if $arch in ["web" "static" "ui"] {
    $required_skills = ($required_skills | append ["design-md-skill" "frontend-design" "accessibility" "seo"])
  }

  for sk in $required_skills {
    if not ($low | str contains $sk) {
      $missing_skills = ($missing_skills | append $sk)
    }
  }

  # 4b. LLM / RAG security protocol requirement when --llm is set
  if $llm {
    let has_llm_sec = (
      ($low | str contains "llm-security")
      or ($low | str contains "prompt injection")
      or ($low | str contains ".gemini_security")
    )
    if not $has_llm_sec {
      $missing_skills = ($missing_skills | append "llm-security protocol")
    }
  }

  # 5. Check fenced invocation code blocks, multi-session audit loop, and deploy payload/domain hygiene
  if not ($raw | str contains "```") {
    $warnings = ($warnings | append "Missing fenced invocation code blocks (```...```) showing how to invoke stage skills.")
  }
  if not (($low | str contains "fresh session") or ($low | str contains "different session")) {
    $warnings = ($warnings | append "Stage 6 should explicitly instruct repeating pre-release audits across fresh sessions.")
  }
  if $arch in ["web" "api" "static" "ui"] {
    let has_exclusions = (
      ($low | str contains "exclusion")
      or ($low | str contains "stripping")
      or ($low | str contains ".dockerignore")
      or ($low | str contains "deploy_prod.nu")
    )
    let has_domain_sweep = (
      ($low | str contains "https://")
      or ($low | str contains "domain sweep")
      or ($low | str contains "localhost")
    )
    if (not $has_exclusions) or (not $has_domain_sweep) {
      $warnings = ($warnings | append "Stage 6/8 should specify deploy payload exclusions (stripping conductor/GEMINI.md/.env) and localhost->https:// domain sweep.")
    }
  }

  let has_blocking_warnings = ($warnings | any {|w| $w | str contains "code block" })
  let pass = (
    ($missing_sections | is-empty)
    and ($missing_stages | is-empty)
    and ($missing_skills | is-empty)
    and (not $has_blocking_warnings)
  )

  {
    pass: $pass
    archetype: $arch
    missing_sections: $missing_sections
    missing_stages: $missing_stages
    missing_skills: $missing_skills
    warnings: $warnings
  }
}

# CLI entrypoint to validate a software project-plan.md file and emit JSON.
export def main [
  plan_path: path = "project-plan.md"
  --archetype (-a): string = "web"
  --llm (-l)  # Enforce LLM/RAG security protocol checks
] {
  validate-software-plan $plan_path --archetype $archetype --llm=$llm | to json
}
