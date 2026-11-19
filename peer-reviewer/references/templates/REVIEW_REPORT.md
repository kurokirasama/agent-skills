# Comprehensive Academic Peer Review Report

**Manuscript Title:** {{MANUSCRIPT_TITLE}}
**Target Journal:** {{TARGET_JOURNAL}}
**Review Date:** {{DATE}}
**Synthesized Editorial Recommendation:** {{EDITORIAL_RECOMMENDATION}} <!-- Accept / Minor Revision / Major Revision / Reject -->
**Desk-Reject Risk Assessment:** {{DESK_REJECT_RISK}} <!-- Low / Medium / High -->

---

## 1. Executive Summary & Editorial Triage

### 1.1 Overview of the Work
{{EXECUTIVE_SUMMARY}}

### 1.2 Target Journal Scope & Fit
- **Scope Alignment:** {{SCOPE_ALIGNMENT_NOTE}}
- **Author Guidelines & Reporting Compliance:** {{GUIDELINES_COMPLIANCE_NOTE}}
- **Desk-Reject Risk Rationale:** {{DESK_REJECT_RATIONALE}}

---

## 2. Evaluation Scorecard

| Evaluation Dimension | Score (1–10) | Evaluation Summary |
|---|:---:|---|
| **Technical & Methodological Rigor** | {{SCORE_RIGOR}} | {{SUMMARY_RIGOR}} |
| **Novelty & Scientific Originality** | {{SCORE_NOVELTY}} | {{SUMMARY_NOVELTY}} |
| **Experimental Depth & Baseline Fairness** | {{SCORE_EXPERIMENTS}} | {{SUMMARY_EXPERIMENTS}} |
| **Statistical Validity & Reproducibility** | {{SCORE_STATISTICS}} | {{SUMMARY_STATISTICS}} |
| **Clarity, Structure & Presentation** | {{SCORE_PRESENTATION}} | {{SUMMARY_PRESENTATION}} |

**Overall Recommendation Score:** {{OVERALL_SCORE}}/10
- **AgentReview Axes (1–4):** Soundness: {{SCORE_SOUNDNESS}}/4 | Presentation: {{SCORE_PRESENTATION_4}}/4 | Contribution: {{SCORE_CONTRIBUTION}}/4
- **LitReviewQuality (0–100):** Coverage: {{LIT_COVERAGE}} | Relevance: {{LIT_RELEVANCE}} | Critical Analysis (<=60 cap if descriptive): {{LIT_ANALYSIS}}
- **Ground-Truth Audit Status (`paper-ground-truth-auditor`):** {{GROUND_TRUTH_STATUS}} <!-- PASS / N discrepancies in audit_discrepancy_matrix.md -->

---

## 3. Major Strengths
1. {{STRENGTH_1}}
2. {{STRENGTH_2}}
3. {{STRENGTH_3}}

---

## 4. Fatal Flaws & Major Concerns (Essential for Re-Review)
*These items must be resolved satisfactorily before publication can be considered.*

1. **[Methodology / Baselines]:** {{MAJOR_CONCERN_1}}
2. **[Literature / Prior Art]:** {{MAJOR_CONCERN_2}}
3. **[Validation / Claims]:** {{MAJOR_CONCERN_3}}

---

## 5. Detailed Reviewer Reports

### 5.1 Reviewer 1: Methodological Rigor & Reproducibility
- **Experimental Formulation & Correctness:**
  {{REVIEWER_1_FORMULATION}}
- **Baseline Selection & Ablation Depth:**
  {{REVIEWER_1_BASELINES}}
- **Statistical Analysis & Data Integrity:**
  {{REVIEWER_1_STATISTICS}}
- **Reproducibility Checklist Compliance (ARRIVE/CONSORT/ML):**
  {{REVIEWER_1_REPRODUCIBILITY}}

### 5.2 Reviewer 2: Literature-Grounded Novelty & Prior Art
- **Contribution Deconstruction:**
  {{REVIEWER_2_CONTRIBUTIONS}}
- **Discovered Prior Art & Overlapping Work:**
  {{REVIEWER_2_PRIOR_ART}}
- **Missing Citations & Context Gaps:**
  {{REVIEWER_2_CITATIONS}}
- **Novelty Classification:** {{NOVELTY_CLASSIFICATION}} <!-- Transformative / Incremental / Marginal / Re-invention -->

---

## 6. Section-by-Section Line Notes & Minor Points
- **Abstract & Introduction:**
  - {{LINE_NOTE_1}}
- **Methodology & Mathematical Formulation:**
  - {{LINE_NOTE_2}}
- **Experiments & Results:**
  - {{LINE_NOTE_3}}
- **Discussion & Conclusion:**
  - {{LINE_NOTE_4}}

---

## 7. Actionable Revision Checklist for Authors (Requires User Approval Before Editing)
- [ ] **Priority 1 (Critical):** {{ACTION_ITEM_1}}
- [ ] **Priority 2 (Major):** {{ACTION_ITEM_2}}
- [ ] **Priority 3 (Clarification/Polish):** {{ACTION_ITEM_3}}

---

## 8. Multi-Session `SxS` Dual-Order Delta (Round 2+ Only)
- **Evaluated Versions:** `{{V_PREV}}` vs `{{V_CURR}}` (verified in both A/B and B/A presentation orders)
- **Resolved Prior Blockers:** {{RESOLVED_BLOCKERS}}
- **Remaining / Newly Introduced Issues:** {{REMAINING_ISSUES}}
- **Net Quality Delta Verdict:** {{SXS_VERDICT}} <!-- Strong Improvement / Moderate Improvement / Neutral / Regression -->
