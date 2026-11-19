# Journal Paper Writing Instructions

Source of truth for the `write-journal-paper` Conductor workflow. The track's `howto.md` is generated from this guide plus [paper_orchestra_protocols.md](./paper_orchestra_protocols.md) and the user's gathered inputs.

## Procedure
1. **Activate Core Skills & Target Guidelines:**
   - Activate `latex-expert` and `writing-expert`.
   - Identify the selected **Primary (Attempt 1)** journal from `journal_candidates_report.md` (or `bibliography/`). Download the official **Author Guidelines** and **LaTeX Template** (`.cls`, `.bst`, page/word limits, highlights/graphical abstract rules); if gated behind a portal, ask the user via Discord + interactive prompt.
2. **Synthesize Master `outline.json` & `citation_map.json`:**
   - Read `bibliography/`, `docs/`, and the local results reports (`summary_report.md`, `insights_report.md`) completely via `context-mode`.
   - Build `outline.json` (`plotting_plan`, separated `intro_related_work_plan`, balanced `section_plan` with zero orphaned `X.1` subsections, page-budget targets) and verified `citation_map.json` (only verified `.bib` keys).
3. **Scaffold Modular LaTeX Architecture:**
   - Use `\include`/`\input` modular files under `articles/<paper_slug>/` (`main.tex`, `sections/*.tex`, `figures/`, `tables/`, `.bib`) so `main.tex` remains clean.
   - Create empty section headers/files first and confirm clean error-free compilation at baseline.
4. **Generate & Audit Publication Figures/Tables (Locally Only):**
   - Prefer vector PDFs for plots and `booktabs` (`\toprule`, `\midrule`, `\bottomrule`) for tables.
   - Apply the PaperBanana 5-stage visual critic loop (up to 3 rounds) to confirm crisp legends, readable typography, and zero clipped labels.
5. **Author Grounded Manuscript Sections:**
   - **Introduction & Related Work:** Strictly enforce the SOTA contrast, novelty positioning, and timeline-cutoff/anti-hallucination rules (never claim superiority over an uncompared paper; never invent citations).
   - **Methodology & Experiments:** Match exact hyperparameters, splits, statistical tests, and budget numbers from code and `insights_report.md`.
   - **Results & Discussion:** Give complete empirical explanations, qualitative mechanisms, limitations, and well-scoped **Future Work** oriented to the target journal — strictly omitting any capabilities reserved for future papers (`mention`/`avoid` constraints).
   - **Acknowledgments:** Include exact funding/grant details provided by the user and CRediT / Ethics / Data Availability statements required by the journal.
6. **Parallel Prose Refinement & Humanization:**
   - Once the full manuscript compiles cleanly, spawn parallel `writing-expert` agents (one per non-empty section `.tex` file, after user approval if swarming, or sequentially) to polish prose, burstiness, perplexity, and academic flow without altering any numbers or `\cite{}` keys.
7. **`FormatAgent` PDF Layout & Page-Limit Inspection:**
   - Re-compile full PDF, render pages (`pdftoppm -png`), and inspect visually for table/margin overflows, figure placement before Conclusion, orphan headings, and exact adherence to page/highlight limits.
8. **Verification Handoff & User Presentation:**
   - Present the compiled draft PDF and summary to the user, and explicitly recommend running Stage 6 verification in a fresh session via `paper-ground-truth-auditor` and `peer-reviewer` before final packaging.

## Notes
- Plan phases typically map to: `(1–2) Guidelines, Outline & Citation Map` → `(3) Modular LaTeX Scaffold` → `(4) Visuals & Tables Audit` → `(5) Section Drafting` → `(6–7) Writing-Expert Humanization & FormatAgent PDF Audit` → `(8) Verification & Review Handoff`.
- Every generated `plan.md` MUST instruct reading `howto.md` first as a starting point, not a contract.
