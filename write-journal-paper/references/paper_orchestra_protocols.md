# PaperOrchestra Authoring, Visual & Layout Protocols

Adapted natively for Agent Skills from `google-research/paper-orchestra`. Apply these 4 invariants inside every `write-journal-paper` Conductor track.

---

## 1. Master Structural Plan (`outline.json`)

Before writing any prose, synthesize `bibliography/`, `docs/`, results reports, and target journal guidelines into `articles/<paper_slug>/outline.json`:

1. **`plotting_plan`:** Enumerate every figure needed to substantiate hypotheses:
   - `figure_id` (semantic name, e.g. `fig_framework_overview`, `fig_convergence_comparison`)
   - `plot_type`: strictly `"plot"` (data-driven statistical chart rendered via local Matplotlib/MATLAB/R code) OR `"diagram"` (conceptual architecture/pipeline diagram rendered via vector/diagram generator)
   - `data_source`: exact local report/script path or conceptual spec
   - `aspect_ratio`: explicit (`"16:9"`, `"3:2"`, `"1:1"`, `"2:3"`)
2. **`intro_related_work_plan` (No Citation Overlap):**
   - Partition macro-framing references (`Introduction`: domain motivation, foundational models, gap statement) from comparative prior-art references (`Related Work`: grouped method taxonomies and explicit contrast vs the proposed approach).
3. **`section_plan` (Strict Structural Hierarchy & Budgets):**
   - **No Orphaned Subsections:** If Subsection `X.1` exists, `X.2` MUST exist; otherwise fold prose directly under Section `X`.
   - **Page & Word Budgets:** Derive per-section target word/page counts from the target journal/conference guidelines.
   - **Exhaustive `citation_hints`:** Record targeted citation keys/queries for EVERY dataset, baseline, evaluation metric, and foundational theorem referenced in any section.

---

## 2. Verified `citation_map.json` & Anti-Hallucination Rules

Construct `articles/<paper_slug>/citation_map.json` directly from verified `.bib` entries and summaries before drafting:
- **Closed-World Citation Rule:** Agents MUST ONLY emit `\cite{key}` / `\citep{key}` / `\citet{key}` keys present verbatim in `citation_map.json` and `.bib`. Never invent or recall citation keys from memory.
- **Timeline Cutoff & SOTA Fairness Rule:**
  - Do NOT treat concurrent or post-cutoff publications as defeated baselines unless actually implemented and evaluated on equal splits.
  - NEVER claim the proposed method achieves SOTA or beats a cited method unless quantitative experimental comparison data exists in the results reports.
- **Content Enrichment:** Read the verified abstract/summary of every entry in `citation_map.json` before citing it so comparative claims stay factually grounded.

---

## 3. PaperBanana 5-Stage Visual Critic Loop (Strictly Local Execution)

Render all figures locally (NEVER on server HPC) via a structured 5-stage quality loop (up to `max_critic_rounds = 3`):

1. **Retriever:** Gather domain visual style conventions and target journal figure rules (single- vs two-column width, font legibility at print scale).
2. **Planner:** Specify exact axes, legends, error bars, annotations, colorblind-safe palette, and subpanel layout from `plotting_plan`.
3. **Stylist:** Enforce typography (`>= 8pt` readable when scaled), line weights, uncluttered legends, and vector PDF output (`ContentType='vector'` / Matplotlib PDF).
4. **Visualizer:** Execute local plotting script (`"plot"`) or diagram synthesis (`"diagram"`).
5. **Multimodal Visual Critic (Up to 3 Rounds):** Render output figure image/PDF and inspect visually for overlapping text, clipped labels, missing legends, low contrast, or mismatch against raw ground-truth data; regenerate until clean.

---

## 4. `FormatAgent` PDF Visual-Grid & Page-Limit Audit

After full LaTeX compilation (`pdflatex`/`xelatex` + `bibtex`):
1. Convert compiled PDF pages to PNG grids (`pdftoppm -png -r 150 main.pdf page_check`) and visually inspect every page.
2. **Placement Rule:** Figures and tables MUST appear near or after their first `\ref{}` and strictly BEFORE `Conclusion` (move supplementary material to `Appendix` after `References`).
3. **Layout & Overflow Checks:** Fix wide tables overflowing margins (`resizebox` / `booktabs` column wrapping), clipped labels, and orphan/widow section headers at column bottoms (`\clearpage` / `\FloatBarrier` if needed).
4. **Page Limit Enforcement:** Measure main-body pages (up to start of `References`) against the target journal/conference hard cap; condense verbose prose or shift auxiliary derivations/ablations to Appendix rather than shrinking margins or violating template `.cls`/`.sty`.
