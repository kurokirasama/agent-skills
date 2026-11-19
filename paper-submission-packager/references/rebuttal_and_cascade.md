# Revision Rebuttal & Backup Journal Cascade Protocols

---

## 1. Point-by-Point Rebuttal Template (`Response_to_Reviewers.tex` / `.md`)

Structure responses so the Action Editor and every Referee can verify compliance in seconds:

1. **Opening Summary:** Thank the Editor and Referees; summarize the major experimental/analytical additions or structural clarifications made across the revision.
2. **Atomic Item-by-Item Blocks (Never Combine Unrelated Comments):**
   ```markdown
   ### Reviewer #1 — Comment 1.2
   > **Reviewer Comment:** [Exact quoted comment verbatim]

   **Author Response:** [Direct, polite answer stating exactly whether and how we addressed it.]

   **Changes Made in Manuscript:** [Exact Section, Page, Table/Figure number, and quoted revised excerpt or diff summary.]
   ```
3. **Ground-Truth & Diff Verification:**
   - Generate tracked changes against the exact submitted snapshot:
     ```bash
     latexdiff --flatten original_v1/main.tex revised_v2/main.tex > diff_v1_v2.tex
     ```
   - Re-run `paper-ground-truth-auditor` whenever revised experiments, p-values, tables, or citations were added during rebuttal.

---

## 2. Minimal-Reformat Cascade Matrix

Choose Primary + Backup pairs in Stage 2/4 so rejection requires switching templates/styles rather than rewriting the manuscript:

| Primary Venue Family | Low-Friction Backup Family | Typical Reformat Effort |
| :--- | :--- | :--- |
| **Elsevier `elsarticle` Q1** (e.g., *SWEVO*, *ESWA*, *Information Sciences*) | **Elsevier `elsarticle` Q1/Q2** (e.g., *Applied Soft Computing*, *Engineering Applications of AI*) | **Minimal:** Keep `\documentclass{elsarticle}`, sections, highlights (`<=85` chars), CRediT, and bibliography `.bst` nearly intact; adjust framing/scope emphasis. |
| **Springer `sn-jnl` Q1/Q2** (e.g., *Neural Computing & Applications*, *Soft Computing*) | **Springer `sn-jnl` Q2** or **Elsevier `elsarticle`** | **Minimal-Low:** Same flat EM bundle within Springer; or single script/template swap to `elsarticle` + add 3–5 highlights bullets. |
| **IEEE Transactions (`IEEEtran`)** | **IEEE Access / IEEE Journal** or **Elsevier `elsarticle`** | **Low:** Reuse figures/tables and BibTeX; adjust column layout (`1-col` vs `2-col`) and bio blocks. |
| **ML Conference (`ICLR` / `NeurIPS` / `CVPR`)** | **Sister ML Conference** or **Journal Extension (`JMLR`/`TMLR`/Elsevier)** | **Low-Moderate:** Restore author metadata/acknowledgments if moving from double-blind conference to single-blind journal; expand related work & ablations if expanding page budget. |
