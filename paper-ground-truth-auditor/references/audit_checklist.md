# 4-Dimension Empirical Ground-Truth Audit Checklist

---

## Dimension 1: Numerical, Table, Caption & Narrative Prose Parity
- [ ] **Tables vs. Ground Truth:** Every numeric cell (`mean`, `std`, `median`, `IQR`, `runtime`, `speedup`, `p-value`, `parameter count`) in LaTeX tables matches `summary_report.md` / `insights_report.md` / raw summaries within rounding tolerance.
- [ ] **Order-of-Magnitude & Multiplier Prose:** Check verbal claims (`"5x faster"`, `"two orders of magnitude"`, `"up to 40% reduction"`) against exact ratios computed from ground truth.
- [ ] **Aggregate Budgets & Sample Sizes:** Verify total evaluated models, seed ranges, fold counts, and dataset dimensions ($N$, $D$) stated in text match actual experimental logs.
- [ ] **Figure Caption & Image Consistency:** Verify captions do not cite wrong topologies, wrong parameter counts, or outdated preliminary runs, and every `\includegraphics` target matches its caption.

---

## Dimension 2: Code-vs-Paper Algorithm & Protocol Fidelity
- [ ] **Data Splits & Preprocessing:** Train/validation/test ratios, normalization/scaling, and leakage guards match executed code.
- [ ] **Hyperparameters & Grid Ranges:** Population sizes, generation caps, mutation/crossover rates, learning rates, bootstrap reps, and tolerances in `.tex` match production code constants.
- [ ] **Selection & Evaluation Rules:** Confirm whether optimization used unpenalized vs penalized loss, early stopping, or multi-objective selection exactly as coded.
- [ ] **No Phantom Capabilities:** Confirm no feature or ablation described in the paper was disabled or skipped in the actual cluster/local production script.

---

## Dimension 3: Citation Grounding & Citation F1 Audit (PaperOrchestra Pattern)
- [ ] **Zero Hallucinated Keys (`Precision = 1.0`):** Every `\cite{...}`, `\citep{...}`, `\citet{...}` key exists in `.bib` and `citation_map.json`.
- [ ] **BibTeX Metadata Accuracy:** Author surnames, publication year, venue name, and DOI/arXiv ID match retrieved records (no stale preprint metadata when published venue exists).
- [ ] **P0 / P1 Prior-Art Coverage (`Recall`):** Every essential baseline, dataset source, and foundational theorem mentioned in text has its corresponding verified P0/P1 citation.
- [ ] **Timeline & SOTA Fairness Rule:** No paper published after the experimental cutoff is falsely claimed as a beaten baseline unless actually executed in comparison scripts.

---

## Dimension 4: Symbolic & Mathematical Consistency (Optional / When Math-Heavy)
- [ ] **Notation Consistency:** Symbols defined once and used identically across equations, algorithms, tables, and figures.
- [ ] **Dimension & Boundary Checks:** Matrix dimensions, summations, index bounds, and units align across derivations.
- [ ] **Symbolic Verification:** Check non-trivial gradients, Jacobians, complexity bounds, or closed-form formulas via Python `sympy` or Wolfram MCP where available.
