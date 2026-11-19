# Helper module for scaffolding a domain-agnostic results-insights-enhancer Conductor track

# Convert an arbitrary string into a clean lowercase hyphenated slug.
export def slugify [text: string]: nothing -> string {
  $text
    | str lowercase
    | str replace -a -r '[^a-z0-9]+' '-'
    | str trim -c '-'
}

# Generate a unique track ID with incremental numeric suffix on collision.
export def generate-track-id [
  date_str?: string
  tracks_dir: string = "conductor/tracks"
  prefix: string = "enhance_results_report"
]: nothing -> string {
  let date_part = if ($date_str != null and ($date_str | str trim | str length) > 0) {
    $date_str | str trim
  } else {
    (date now | format date "%Y%m%d")
  }
  let base_id = $"($prefix)_($date_part)"
  let candidate_dir = ($tracks_dir | path join $base_id)
  if not ($candidate_dir | path exists) {
    return $base_id
  }

  mut suffix = 1
  mut resolved = ""
  loop {
    let candidate = $"($base_id)_($suffix)"
    if not (($tracks_dir | path join $candidate) | path exists) {
      $resolved = $candidate
      break
    }
    $suffix = $suffix + 1
  }
  $resolved
}

def format-list-or-default [items: any, fallback: string]: nothing -> string {
  if $items == null {
    return $fallback
  }
  let desc = ($items | describe)
  if ($desc | str starts-with "list") {
    if ($items | is-empty) {
      return $fallback
    }
    return ($items | each {|x| $x | into string } | str join ", ")
  }
  let as_str = ($items | into string | str trim)
  if ($as_str | is-empty) { $fallback } else { $as_str }
}

# Scaffold a 4-phase results-insights-enhancer Conductor track from parameterized inputs.
export def scaffold-enhancer-track [params: record]: nothing -> record {
  let report_path = ($params.report_path? | default "" | into string | str trim)
  if ($report_path | is-empty) {
    error make { msg: "scaffold-enhancer-track requires a non-empty 'report_path' in params." }
  }

  let metric_report_path = ($params.metric_report_path? | default "N/A (discover from bibliography/)" | into string | str trim)
  let domain = ($params.domain? | default "Empirical Benchmark Evaluation" | into string | str trim)
  let methods_str = (format-list-or-default ($params.methods?) "All evaluated baselines and proposed method(s) in summary_report.md")
  let datasets_str = (format-list-or-default ($params.datasets?) "All benchmarks/datasets present in summary_report.md")
  let date_str = ($params.date_str? | default (date now | format date "%Y%m%d"))
  let tracks_dir = ($params.tracks_dir? | default "conductor/tracks")
  let tracks_file = ($params.tracks_file? | default "conductor/tracks.md")
  let update_tracks = ($params.update_tracks_file? | default true)
  let prefix = ($params.prefix? | default "enhance_results_report")

  let track_id = (generate-track-id $date_str $tracks_dir $prefix)
  let track_dir = ($tracks_dir | path join $track_id)
  mkdir $track_dir

  let now_iso = (date now | format date "%Y-%m-%dT%H:%M:%S%z")
  let metadata_content = {
    track_id: $track_id
    type: "feature"
    status: "new"
    created_at: $now_iso
    updated_at: $now_iso
    description: $"Enhance ($report_path) with qualitative analysis and generate companion insights_report.md \(($domain)\)"
  }
  $metadata_content | to json -i 2 | save -f ($track_dir | path join "metadata.json")

  let index_content = [
    $"# Track ($track_id) Context"
    ""
    "- [Specification](./spec.md)"
    "- [Implementation Plan](./plan.md)"
    "- [How-To Guide](./howto.md)"
    "- [Metadata](./metadata.json)"
  ] | str join "\n"
  $index_content | save -f ($track_dir | path join "index.md")

  let spec_content = [
    $"# Track Specification: Qualitative Results Analysis & Research Insights \(($track_id)\)"
    ""
    "## 1. Overview"
    $"This track enhances `($report_path)` with structured qualitative analysis and generates a co-located `insights_report.md` featuring non-parametric statistical testing and SOTA literature grounding for **($domain)**."
    ""
    "## 2. Scope Parameters"
    $"- **Target Summary Report:** `($report_path)`"
    $"- **Literature Baselines Source:** `($metric_report_path)`"
    $"- **Research Domain:** ($domain)"
    $"- **Evaluated Methods:** ($methods_str)"
    $"- **Benchmarks / Tasks:** ($datasets_str)"
    ""
    "## 3. Functional Requirements"
    "- **FR-1 (Ingestion & Numerical Integrity):** Parse `summary_report.md` without modifying existing quantitative comparison table values."
    "- **FR-2 (In-Place Qualitative Expansion):** Expand the qualitative results analysis section covering methodological mechanics, computational efficiency/scaling, complexity trade-offs, failure-mode robustness, and visual link integrity."
    "- **FR-3 (Companion `insights_report.md`):** Synthesize executive rankings, paired/multi-method non-parametric statistical tests (Wilcoxon, Friedman + post-hoc), SOTA literature comparison table, Pareto efficiency, and manuscript implications."
    ""
    "## 4. BDD / Gherkin Acceptance Criteria"
    "```gherkin"
    $"Scenario: Enhance summary_report.md and synthesize insights_report.md for ($domain)"
    $"  Given the experimental comparison report at ($report_path)"
    "  When the qualitative expansion and statistical synthesis phases are executed"
    "  Then summary_report.md contains an expanded qualitative analysis section with zero altered original table numbers and zero broken figure links"
    "  And a co-located insights_report.md exists with non-parametric significance tests, effect sizes, and grounded SOTA comparisons"
    "```"
  ] | str join "\n"
  $spec_content | save -f ($track_dir | path join "spec.md")

  let plan_content = [
    $"# Implementation Plan: ($track_id)"
    ""
    "## Phase 1: Target Path Resolution & Report Ingestion"
    "- [ ] Task: Read howto.md in the track directory and use it as the starting point for implementation (adapt and update if diverging)"
    $"- [ ] Task: Locate, parse, and validate summary_report.md at '($report_path)' using context-mode"
    "- [ ] Task: Conductor - User Manual Verification 'Target Path Resolution & Report Ingestion' (Protocol in workflow.md)"
    ""
    "## Phase 2: In-Place Enhancement of summary_report.md"
    $"- [ ] Task: Expand the Qualitative Results Analysis section for ($methods_str) across ($datasets_str) using skills/results-insights-enhancer/references/qualitative_template.md"
    "- [ ] Task: Audit and verify all relative figure/plot links on disk without altering existing numeric table rows"
    "- [ ] Task: Conductor - User Manual Verification 'In-Place Enhancement of summary_report.md' (Protocol in workflow.md)"
    ""
    "## Phase 3: Generation of Companion insights_report.md"
    $"- [ ] Task: Synthesize co-located insights_report.md with non-parametric tests \(Wilcoxon / Friedman\) and grounded SOTA baselines from '($metric_report_path)' using references/statistical_tests.md and references/literature_baselines.md"
    "- [ ] Task: Author Pareto efficiency trade-offs and manuscript contribution/limitation takeaways"
    "- [ ] Task: Conductor - User Manual Verification 'Generation of Companion insights_report.md' (Protocol in workflow.md)"
    ""
    "## Phase 4: Final Verification & Consistency Audit"
    "- [ ] Task: Verify Markdown rendering, LaTeX math formatting, table alignment, relative links, and co-location of both reports"
    "- [ ] Task: Conductor - User Manual Verification 'Final Verification & Consistency Audit' (Protocol in workflow.md)"
  ] | str join "\n"
  $plan_content | save -f ($track_dir | path join "plan.md")

  let howto_content = [
    "> **Starting point, not a contract.** Adapt, improve, or replace this guide as you learn during implementation; update it whenever you diverge."
    ""
    $"# Implementation Guide: ($track_id)"
    ""
    "## Target Artifacts"
    $"- **Input / In-Place Target:** `($report_path)`"
    $"- **Literature Source:** `($metric_report_path)`"
    $"- **Methods:** ($methods_str)"
    $"- **Datasets / Tasks:** ($datasets_str)"
    ""
    "## Phase 1: Ingestion & Extraction"
    "1. Analyze `summary_report.md` with `ctx_execute_file` (do not dump raw Markdown tables manually)."
    "2. Snapshot all quantitative table rows before editing so Phase 4 can confirm zero numerical drift."
    ""
    "## Phase 2: Qualitative Results Analysis"
    "1. Follow `references/qualitative_template.md` from `skills/results-insights-enhancer/`."
    "2. Verify every Markdown image/PDF path resolves relative to the report directory."
    ""
    "## Phase 3: Companion `insights_report.md`"
    "1. Use `references/statistical_tests.md` for Wilcoxon / Friedman + Holm / Nemenyi test formulation and effect sizes."
    "2. Use `references/literature_baselines.md` to build the SOTA table strictly from verified bibliography/metrics (never invent external numbers)."
    ""
    "## Phase 4: Verification"
    "1. Confirm both `summary_report.md` and `insights_report.md` reside in the same parent directory."
    "2. Verify Markdown lint/alignment, math delimiters, and link targets."
  ] | str join "\n"
  $howto_content | save -f ($track_dir | path join "howto.md")

  if $update_tracks and ($tracks_file | path exists) {
    let track_entry = [
      ""
      "---"
      $"- [ ] **Track: Qualitative Results Analysis & Insights Synthesis \(($domain)\)**"
      $"  *Link: [./tracks/($track_id)/]\(./tracks/($track_id)/\)*"
      ""
    ] | str join "\n"
    $track_entry | save -a -f $tracks_file
  }

  {
    success: true
    track_id: $track_id
    track_dir: $track_dir
  }
}
