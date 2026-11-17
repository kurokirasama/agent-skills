# Helper functions for scaffolding a peer review Conductor track

# Turn an arbitrary string into a clean lowercase hyphenated slug
export def slugify [text: string] {
  $text 
    | str lowercase 
    | str replace -a -r '[^a-z0-9]+' '-' 
    | str trim -c '-'
}

# Generate a standardized track ID for the peer review track
export def generate-track-id [journal_name: string, date_str?: string] {
  let date_part = if ($date_str != null and ($date_str | str length) > 0) {
    $date_str
  } else {
    (date now | format date "%Y%m%d")
  }
  let slug = (slugify $journal_name)
  $"peer_review_($slug)_($date_part)"
}

# Scaffolds track artifacts given an input record
export def scaffold-review-track [params: record] {
  let manuscript_path = $params.manuscript_path
  let journal_name = $params.journal_name
  let aims_scope = ($params.aims_scope? | default "Standard journal scope.")
  let author_guidelines = ($params.author_guidelines? | default "Standard author submission guidelines.")
  let areas_of_concern = ($params.areas_of_concern? | default "None specified.")
  let date_str = ($params.date_str? | default (date now | format date "%Y%m%d"))
  let tracks_dir = ($params.tracks_dir? | default "conductor/tracks")

  let track_id = (generate-track-id $journal_name $date_str)
  let track_dir = ($tracks_dir | path join $track_id)

  if ($track_dir | path exists) {
    return {
      success: false,
      error: $"Track directory already exists at ($track_dir)",
      track_id: $track_id,
      track_dir: $track_dir
    }
  }

  mkdir $track_dir

  # 1. metadata.json
  let now_iso = (date now | format date "%Y-%m-%dT%H:%M:%S%z")
  let metadata_content = {
    track_id: $track_id,
    type: "feature",
    status: "new",
    created_at: $now_iso,
    updated_at: $now_iso,
    description: $"Peer review manuscript for ($journal_name)"
  }
  $metadata_content | to json -i 2 | save -f ($track_dir | path join "metadata.json")

  # 2. index.md
  let index_content = [
    $"# Track ($track_id) Context"
    ""
    "- [Specification](./spec.md)"
    "- [Implementation Plan](./plan.md)"
    "- [How-To Guide](./howto.md)"
    "- [Metadata](./metadata.json)"
  ] | str join "\n"

  $index_content | save -f ($track_dir | path join "index.md")

  # 3. spec.md
  let spec_content = [
    $"# Specification: Academic Peer Review of '($manuscript_path)' for '($journal_name)'"
    ""
    "## 1. Overview & Objectives"
    $"Simulate a rigorous, constructive, publication-grade academic peer review for the paper draft at `($manuscript_path)` targeting **($journal_name)**."
    "The review evaluates venue scope fit, desk-reject vulnerability, methodological and statistical rigor, and literature-grounded novelty."
    ""
    $"- **Target Journal:** ($journal_name)"
    $"- **Target Aims & Scope:** ($aims_scope)"
    $"- **Author Submission Guidelines:** ($author_guidelines)"
    $"- **Author Specific Concerns:** ($areas_of_concern)"
    ""
    "## 2. Reviewer Panel Architecture"
    "The review will be executed across three specialized agent roles (or sequential fallback):"
    "1. **Editor-in-Chief (`@peer-reviewer-editor`)**: Desk-reject risk triage, format and length compliance, scope calibration, and final synthesis."
    "2. **Reviewer 1 (`@peer-reviewer-methodology`)**: Technical correctness, baseline fairness, ablation isolation, statistical significance, and ARRIVE/CONSORT/ML checklist audit."
    "3. **Reviewer 2 (`@peer-reviewer-novelty`)**: Literature-grounded novelty verification, live scientific paper/preprint search (2023-2026), and citation gap discovery."
    ""
    "## 3. Deliverables"
    "1. `REVIEW_REPORT.md`: Comprehensive referee report with quantitative scorecards, major flaws, section-by-section line notes, and prioritized revision checklist."
    "2. Executive Chat Summary: High-level verdict (Accept / Minor Revision / Major Revision / Reject), desk-reject risk score, and top action items."
    ""
    "## 4. Acceptance Criteria"
    "- [ ] Manuscript draft fully read and deconstructed into core claims."
    "- [ ] Target journal scope and author guidelines ingested and verified."
    "- [ ] Methodology audited for baseline fairness, statistical validity, and reproducibility."
    "- [ ] External literature searched via web search or Research MCP tools for prior art and missing citations."
    "- [ ] Final synthesized report saved to `REVIEW_REPORT.md` in the manuscript directory."
  ] | str join "\n"

  $spec_content | save -f ($track_dir | path join "spec.md")

  # 4. plan.md
  let plan_content = [
    $"# Implementation Plan: Academic Peer Review for ($journal_name)"
    ""
    "## Phase 1: Manuscript Ingestion & Editorial Triage"
    "- [ ] Task: Read howto.md in the track directory and use it as the starting point for implementation (may be improved during execution)."
    $"- [ ] Task: Parse manuscript at '($manuscript_path)' and extract structure, core claims, and experimental tables"
    $"- [ ] Task: Evaluate target journal fit and desk-reject risks against ($journal_name) guidelines via @peer-reviewer-editor"
    "- [ ] Task: Conductor - User Manual Verification 'Phase 1: Manuscript Ingestion & Editorial Triage' (Protocol in workflow.md)"
    ""
    "## Phase 2: Technical Methodology & Reproducibility Audit"
    "- [ ] Task: Audit experimental baselines, ablation studies, and dataset splits via @peer-reviewer-methodology"
    "- [ ] Task: Evaluate statistical validity, sample sizes, error bars, and reproducibility checklists"
    "- [ ] Task: Conductor - User Manual Verification 'Phase 2: Technical Methodology & Reproducibility Audit' (Protocol in workflow.md)"
    ""
    "## Phase 3: Literature-Grounded Novelty & Prior Art Search"
    "- [ ] Task: Extract explicit novelty claims and formulate literature search queries"
    "- [ ] Task: Execute live literature search via Research MCP tools / Brave search to identify prior art and missing citations via @peer-reviewer-novelty"
    "- [ ] Task: Calibrate scientific contribution level (Substantive vs. Incremental vs. Marginal)"
    "- [ ] Task: Conductor - User Manual Verification 'Phase 3: Literature-Grounded Novelty & Prior Art Search' (Protocol in workflow.md)"
    ""
    "## Phase 4: Report Synthesis & Actionable Delivery"
    "- [ ] Task: Synthesize all referee reports into unified 'REVIEW_REPORT.md' in the manuscript directory"
    "- [ ] Task: Formulate final editorial recommendation (Accept, Minor Rev, Major Rev, Reject) and prioritized action checklist"
    "- [ ] Task: Present executive chat summary to author"
    "- [ ] Task: Conductor - User Manual Verification 'Phase 4: Report Synthesis & Actionable Delivery' (Protocol in workflow.md)"
  ] | str join "\n"

  $plan_content | save -f ($track_dir | path join "plan.md")

  # 5. howto.md
  let howto_content = [
    $"# How-To Guide: Peer Review for ($journal_name)"
    ""
    $"This guide directs the execution of the peer review for manuscript `($manuscript_path)`."
    ""
    "## Target Venue Context"
    $"- **Journal:** ($journal_name)"
    $"- **Scope & Focus:** ($aims_scope)"
    $"- **Author Guidelines:** ($author_guidelines)"
    $"- **Author Doubts/Notes:** ($areas_of_concern)"
    ""
    "## Execution Protocols"
    ""
    "### 1. Editorial Triage"
    $"In-depth triage to check scope alignment with ($journal_name), length limits, and desk-reject risks."
    ""
    "### 2. Methodological Rigor"
    "Audit baseline fairness (2023-2026 recency), ablation isolation, and statistical validity."
    ""
    "### 3. Novelty & Prior Art Search"
    "Search external scientific literature for unacknowledged prior art and missing citations."
    ""
    "### 4. Final Report Generation"
    $"Combine evaluations into `REVIEW_REPORT.md` located next to `($manuscript_path)`."
  ] | str join "\n"

  $howto_content | save -f ($track_dir | path join "howto.md")

  {
    success: true,
    track_id: $track_id,
    track_dir: $track_dir
  }
}
