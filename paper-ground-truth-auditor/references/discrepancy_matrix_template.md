# Discrepancy Matrix Template & Severity Rubric

Use this schema for `audit_discrepancy_matrix.md`:

---

## Severity Rubric
- **CRITICAL:** Factual/numeric contradiction between manuscript and ground truth (`>5%` numerical drift, wrong order of magnitude, false table winner, unverified/hallucinated `\cite{}` key, missing mandatory P0 citation, code-vs-paper hyperparameter mismatch, invalid math equation).
- **MAJOR:** Significant precision/rounding drift (`1%–5%`), misleading figure caption, or ambiguous split/protocol statement that could trigger a referee rejection.
- **MINOR:** Formatting or cosmetic drift (`<=1%` rounding variance, uncited `.bib` entries, minor notation polish).

---

## Standard Output Layout

```markdown
# Empirical Audit Discrepancy Matrix
Generated on: <YYYY-MM-DD HH:MM:SS>
Ground Truth Source: `<path_to_summary_report_or_data>`
Target Manuscript: `<path_to_tex_dir>`

## Summary of Identified Discrepancies & Inconsistencies
- **Total Discrepancies/Inconsistencies Detected:** <N>
- **Table & Numerical Discrepancies:** <N_tbl>
- **Narrative Prose / Caption / Code-Parity Discrepancies:** <N_prose>
- **Hallucinated / Unverified Citations:** <N_hallucinated>
- **Missing P0 Citations:** <N_missing_p0>

## Detailed Discrepancy Inventory
| File | Line | Scope | Metric | Paper Value | Ground Truth Value | Severity |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `<file.tex>` | `<line>` | `<Dataset/Section>` | `<Metric/Claim>` | `<paper_val>` | `<gt_val>` | `<CRITICAL|MAJOR|MINOR>` |

## Citation Grounding (Citation F1)
- **Unique Cited Keys:** <n_cited> | **BibTeX Keys:** <n_bib>
- **Precision:** <prec> | **Recall:** <rec> | **F1:** <f1>
- **Hallucinated Keys:** `<list>`
- **Missing P0 Keys:** `<list>`
- **Uncited BibTeX Keys:** `<list>`
```
