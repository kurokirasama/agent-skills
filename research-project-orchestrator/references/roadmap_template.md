# Research Project `project-plan.md` Master Template (8-Stage Skill-Mapped Roadmap)

Use this full blueprint when writing `./project-plan.md` in a research project workspace. Customize every placeholder (`<...>`) using ingested user ideas, grant documents, and workspace discoveries.

---

```markdown
# Research Project Plan: <Project Title>

## 1. Project Objectives
- **General Objective:** <Clear statement of the overarching research goal>
- **Specific Objectives:**
  1. <Objective 1 — e.g., design/formulation>
  2. <Objective 2 — e.g., empirical/benchmark validation against SOTA>
  3. <Objective 3 — e.g., statistical & qualitative analysis + Q1/Q2 publication>
- **Scope Boundaries & Non-Claims:**
  - **In Scope (This Manuscript):** <Explicit scope>
  - **Out of Scope (Reserved for Future Papers):** <Explicit exclusions>
- **Success Criteria:** <Reproducible empirical evidence, statistical validation, 0 ground-truth discrepancies, submission-ready Q1/Q2 paper>

---

## 2. High-Level Execution Roadmap

### Stage 1: Workspace & Conductor Initialization
- **Goal:** Establish Spec-Driven Development (`conductor/`), Git privacy rules, Obsidian long-term memory, and modular LaTeX/research folder layout.
- **Skills (Strict Sequence):** `conductor-setup` **FIRST**, then `initialize-research` (plus `git-remote-connect` if needed).
- **How to Invoke:**
  ```text
  # Step 1A: Initialize Conductor workspace first (creates conductor/, asks Public vs Private repo)
  /conductor-setup

  # Step 1B: After conductor/index.md exists, scaffold research directories & LaTeX article template
  /conductor-newtrack activate initialize-research and follow instructions
  /conductor-implement
  ```
- **Deliverables:** `conductor/{index.md,product.md,tech-stack.md,workflow.md,tracks.md}`, Obsidian memory note, `articles/<paper_slug>/`, `bibliography/`, `docs/`, `scripts/`, `shell/`.
- **Exit Gate:** `conductor/index.md` and `articles/<paper_slug>/main.tex` exist and compile cleanly.

### Stage 2: Initial Bibliographical Research & Dual-Journal Selection
- **Goal:** Survey the current state of the art, collect experimental/algorithmic design ideas, download verified source PDFs, and select **Attempt 1 (Primary)** + **Minimal-Reformat Cascade Backup** target journals.
- **Skills:** `deep-research` (orchestrates paid `gemini-deep-research` ONLY after user cost approval, parallelized with `deep-retrieval-task` and `source-retrieval-task`; optionally `paper-analysis-expert` for key papers).
- **How to Invoke:**
  ```text
  Activate deep-research for "<topic & hypotheses>" in Full Bibliographical & Dual-Journal Candidacy mode.
  Save outputs under bibliography/search/initial_review/ and produce journal_candidates_report.md with at least 2 paired options (Primary Attempt 1 + Minimal-Reformat Cascade Backup) for user selection.
  ```
- **Deliverables:** `bibliography/*.bib`, `bibliography/papers/*.pdf`, per-paper Markdown summaries, `journal_candidates_report.md`.
- **Exit Gate:** User explicitly confirms Primary + Backup journal selection and approves BibTeX baseline corpus.

### Stage 3: Research Implementation, Experiments & Qualitative Analysis
- **Goal:** Ingest `bibliography/`, `docs/`, objectives, and `project-plan.md`; design and implement the proposed method and baselines; size compute (Local vs server HPC); run experiments; generate comparisons, automated reports, and deep qualitative/statistical insights.
- **Skills:** `/conductor-newtrack` + `/conductor-implement` + domain skills (`matlab-expert` / `programmer-expert` / `data-scientist` / `pandas-pro` / `python-testing-patterns` / `nushell-expert` / `test-engineer`), `hpc-cluster-orchestrator` (if server HPC or API batch), and `results-insights-enhancer`.
- **How to Invoke:**
  ```text
  # 3A: Size workload (Local vs server) and design implementation tracks
  Activate hpc-cluster-orchestrator to evaluate workload sizing and validate 3-stage server compliance (if offloading to server: check_cluster.nu, orchestrate_simulations.nu, bidirectional rsync, skip_plots = true on server, zero remote figure rendering, strictly local plotting).

  # 3B: Plan & execute modular implementation/experiment tracks (enforce pytest via python-testing-patterns and vectorized local postprocessing via pandas-pro for Python codebases)
  /conductor-newtrack <feature/experiment track description>
  /conductor-implement

  # 3C: After Stage 2 rsync parity & local summary_report.md generation, expand qualitative & statistical analysis
  /conductor-newtrack activate results-insights-enhancer and follow instructions
  /conductor-implement
  ```
- **Deliverables:** Tested production codebase, `shell/check_cluster.nu` & `shell/orchestrate_simulations.nu` (when using server), locally rendered vector PDF figures, `summary_report.md`, and co-located `insights_report.md` (Wilcoxon/Friedman stats + SOTA table).
- **Exit Gate:** 100% Stage 2 data parity (if server), all plots rendered locally, and `summary_report.md` + `insights_report.md` verified.

### Stage 4: Capped Bibliographical Refresh & Venue Re-evaluation
- **Goal:** Capture papers published during the implementation window and re-evaluate Primary/Backup journal fit in case empirical results expanded or shifted scope.
- **Skills:** `deep-research` (Capped Refresh Mode — asks user cost approval before paid deep research).
- **How to Invoke:**
  ```text
  Activate deep-research in Capped Refresh Mode covering [<Stage2_date> .. <today>].
  Deduplicate against existing bibliography/*.bib, update SOTA comparisons if needed, and re-evaluate Primary/Backup journals in journal_candidates_report.md.
  ```
- **Deliverables:** Updated `.bib`, new delta paper summaries, updated `journal_candidates_report.md`.
- **Exit Gate:** User confirms final Primary Attempt 1 + Backup journal pair before manuscript drafting.

### Stage 5: Manuscript Authoring
- **Goal:** Author the publication-ready LaTeX manuscript strictly matching official journal guidelines, verified numbers/figures, clear SOTA contrast, contributions, discussion, future work, and funding acknowledgments.
- **Skills:** `write-journal-paper` (coordinates `latex-expert` and `writing-expert`; integrates `outline.json`, `citation_map.json`, PaperBanana local visual critic, and `FormatAgent` PDF visual-grid & page-limit inspection).
- **How to Invoke:**
  ```text
  /conductor-newtrack activate write-journal-paper for <articles/<paper_slug>/> targeting <Primary Journal>
  /conductor-implement
  ```
- **Deliverables:** Compiled manuscript PDF, modular `.tex` sections, `outline.json`, `citation_map.json`, vector PDF figures, `booktabs` tables.
- **Exit Gate:** Clean LaTeX build, zero visual layout/margin overflows, and strict adherence to target journal guidelines.

### Stage 6: Empirical Ground-Truth Audit & Multi-Session Peer Review Loop
- **Goal:** Verify every numerical claim, table, caption, code parameter, equation, and citation against raw ground truth; then run rigorous multi-referee simulated peer review across fresh sessions with user approval before edits until approved.
- **Skills:** `paper-ground-truth-auditor` + `peer-reviewer` (`peer-reviewer-editor`, `peer-reviewer-methodology`, `peer-reviewer-novelty`) + `python-testing-patterns` (if Python simulation/pandas verification suites are re-run).
- **How to Invoke:**
  ```text
  # Round N (run EACH new round in a FRESH session!):
  Activate paper-ground-truth-auditor on <articles/<paper_slug>/> against <summary_report.md> and <.bib>.
  /conductor-newtrack activate peer-reviewer for <articles/<paper_slug>/> targeting <Primary Journal>
  /conductor-implement
  # Present audit_discrepancy_matrix.md + REVIEW_REPORT.md suggestions to user for approval BEFORE applying edits!
  ```
- **Deliverables:** `audit_discrepancy_matrix.md` (0 open critical discrepancies), `REVIEW_REPORT.md` (with `AgentReview`, `LitReviewQuality`, and Round 2+ `SxS` dual-order deltas).
- **Exit Gate:** Zero critical numerical/citation/methodological blockers and explicit user sign-off.

### Stage 7: First-Attempt Submission Packaging
- **Goal:** Archive modular sources (`original/`) and build the publisher-compliant submission bundle (Cover Letter, Highlights, Graphical Abstract, CRediT, flat Aries EM / Elsevier / IEEE package).
- **Skills:** `paper-submission-packager`.
- **How to Invoke:**
  ```text
  Activate paper-submission-packager in First-Attempt Submission Packaging mode for <Primary Journal>.
  ```
- **Deliverables:** `articles/<paper_slug>/original/` snapshot, clean compiled `<publisher>_submission/` bundle, Cover Letter & checklist.
- **Exit Gate:** Clean compile inside submission bundle + user final submission sign-off.

### Stage 8: Post-Submission Revision or Backup Journal Cascade
- **Goal:** Execute point-by-point revision & rebuttal if accepted with revisions, OR execute minimal-reformat cascade transfer to the Backup Journal if rejected.
- **Skills:** `paper-submission-packager` + `paper-ground-truth-auditor` (if revised numbers) + `peer-reviewer` (rebuttal check).
- **How to Invoke:**
  ```text
  # If Revise & Resubmit:
  Activate paper-submission-packager in Revision & Rebuttal mode with referee comments at <path>.
  # If Rejected (Cascade to Backup):
  Activate paper-submission-packager in Minimal-Reformat Backup Cascade mode targeting <Backup Journal>.
  ```
- **Deliverables:** `Response_to_Reviewers` + `latexdiff` PDF (revision) OR `<backup_publisher>_submission/` bundle (cascade).
- **Exit Gate:** Resubmission / cascade bundle verified and submitted cleanly.

---

## 3. Algorithmic, Methodological & Workflow Ideas
- **Proposed Method & Core Architecture:** <Algorithms, mathematical formulations, hyperparameters>
- **Baseline & Benchmark Design:** <Competitors, datasets/simulations, seeds/folds, non-parametric tests>
- **Compute & server HPC Plan:** <Sizing estimate, Local vs server, `skip_plots = true` compute-only script layout, local postprocessing plan>
- **Visualization & Diagram Plan:** <Key conceptual architecture diagrams & empirical plots>
- **Key Risks & Mitigations:** <Data leakage, cluster stalls, scope creep, journal desk-reject risks>
```
