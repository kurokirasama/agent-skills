# Dual-Journal Candidacy & Capped Refresh Protocols

---

## 1. Dual-Journal Selection Protocol (`journal_candidates_report.md`)

When conducting initial (Stage 2) or refresh (Stage 4) bibliographic research for an academic manuscript, evaluate candidate venues systematically before drafting so the manuscript structure aligns with target standards from day one.

### Evaluation Criteria per Candidate Venue
1. **Indexing & Quartile:** Web of Science SCIE / Scopus quartile (`Q1` / `Q2`), Impact Factor / CiteScore, and editorial reputation.
2. **Publication Cost (`$0` Subscription vs APC):** Explicitly flag whether a `$0 USD` hybrid/subscription track exists vs mandatory Gold Open Access APCs.
3. **Scope & Empirical Fit:** Alignment between the project's contribution, dataset scale, and recent papers published in the journal.
4. **Bibliography Cross-Reference:** Count how many verified papers from the project's `.bib` / `bibliography/` were published in each candidate journal (strong indicator of editorial appetite).
5. **Template & Cascade Compatibility:** Document class (`elsarticle`, `sn-jnl`, `IEEEtran`), word/page limits, highlights/graphical abstract rules, and **Reformat Effort** when transferring from Primary → Backup.

### Required Output Structure (`journal_candidates_report.md`)
Present **at least two paired recommendations** and prompt the user (after Discord alert) to select **Attempt 1** and **Backup**:
- **Primary Candidate (Attempt 1):** Highest-impact/scope fit target.
- **Minimal-Reformat Backup Candidate:** High-acceptance or sister Q1/Q2 journal in the same publisher/template family (requiring minimal structural/prose edits after rejection).
- **Optional Conservative Safety Net:** Solid Q2/Q3 or specialized domain venue if major scope constraints arise.

---

## 2. Capped Refresh Mode (Pre-Writing Delta — Stage 4)

Because empirical implementation and cluster campaigns take weeks or months, run a **bounded refresh pass** right before manuscript drafting:

### Scope & Time Cap Rules
- **Time Window Cap:** Query strictly from `<last_research_date - 1 month>` up to `<today>`, deduplicating against existing DOIs/`.bib` keys so prior summaries are preserved, not re-processed from scratch.
- **Query Focus:**
  1. New SOTA competitors, benchmark results, or preprints published during implementation (checking whether any must be cited as concurrent/recent work).
  2. Retractions, dataset corrections, or updated published versions of previously cited arXiv preprints.
  3. **Scope-Change Venue Re-Evaluation:** Compare actual achieved empirical outcomes (e.g., expanded benchmark count, stronger statistical wins, new theoretical proof, or narrowed scope) against the Stage 2 `journal_candidates_report.md` selection. Recommend upgrading/adjusting Attempt 1 or Backup **only** if justified by achieved evidence, and confirm with the user.
