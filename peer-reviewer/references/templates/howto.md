# How-To Guide: Implementing the Academic Peer Review Track

This guide provides concrete, per-phase operational instructions for executing the peer review track generated for manuscript `{{MANUSCRIPT_PATH}}` and target journal `{{TARGET_JOURNAL}}`.

---

## Architecture & Subagent Coordination

The review execution coordinates three specialized subagents from `agents/` (with automatic fallback to sequential execution if subagent spawning is unavailable):
- `@peer-reviewer-editor`: Editorial triage, scope checking, and final verdict synthesis.
- `@peer-reviewer-methodology`: Technical soundness, experimental baselines, statistical validity, and reproducibility checklists.
- `@peer-reviewer-novelty`: Literature search, prior art detection, and claim novelty calibration.

---

## Phase 1: Ingestion & Editorial Triage
1. **Locate Manuscript**: Verify the manuscript file(s) at `{{MANUSCRIPT_PATH}}`.
   - If LaTeX: inspect `main.tex` and included section files.
   - If Markdown or PDF text: read the full manuscript text into context.
2. **Fetch Target Journal Details**:
   - Query or read the target journal's "Aims & Scope" and author guidelines for `{{TARGET_JOURNAL}}`.
   - Check page limits, mandatory sections (Data Availability, Ethics, Conflicts of Interest), and formatting specifications.
3. **Run Triage**:
   - Launch or invoke `@peer-reviewer-editor` with the manuscript and journal guidelines.
   - Compute Desk-Reject Risk (`Low`, `Medium`, `High`) and document scope compatibility.

---

## Phase 2: Methodological Rigor & Technical Audit
1. **Audit Claims & Hypotheses**:
   - Trace explicit empirical claims in the Abstract and Introduction to corresponding experiments in the Results section.
2. **Scrutinize Baselines & Ablations**:
   - Verify whether baselines are contemporary and properly tuned.
   - Confirm that each proposed module has an associated ablation experiment.
3. **Statistical Integrity Check**:
   - Check sample sizes, standard deviations/errors across multiple runs, and p-value/effect size interpretations.
   - Run or inspect reproducibility checklist items (e.g. ARRIVE, CONSORT, or ML Reproducibility Checklist).
4. **Invoke Reviewer 1**:
   - Dispatch `@peer-reviewer-methodology` to produce the technical critique and score.

---

## Phase 3: Literature Grounding & Novelty Audit
1. **Extract Novelty Claims**:
   - Deconstruct core algorithmic or theoretical claims.
2. **Execute Live Literature Search**:
   - Use web search or Research MCP tools (`literature-search-arxiv`, `literature-search-biorxiv`, `pubmed-database`, Semantic Scholar, Brave Search) to search for similar work from 2023–2026.
   - Search for potential unacknowledged duplicates or overlapping methods.
3. **Identify Missing Citations**:
   - Record landmark papers and recent SOTA preprints that the authors overlooked.
4. **Invoke Reviewer 2**:
   - Dispatch `@peer-reviewer-novelty` to produce the prior art assessment and novelty rating.

---

## Phase 4: Report Synthesis & Actionable Delivery
1. **Synthesize Feedback**:
   - Combine the reports from Editor, Reviewer 1, and Reviewer 2 into `{{REPORT_PATH}}`.
   - Fill all sections of the `REVIEW_REPORT.md` template.
2. **Formulate Editorial Verdict**:
   - Assign final recommendation: **Accept**, **Minor Revision**, **Major Revision**, or **Reject**.
   - Prioritize the Actionable Revision Checklist.
3. **Deliver Executive Chat Summary**:
   - Present a concise, structured summary in chat highlighting key takeaways, desk-reject probability, and top must-fix items.
