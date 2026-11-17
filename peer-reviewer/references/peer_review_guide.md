# Comprehensive Academic Peer Review Guide & Heuristics

This reference guide establishes the principles, heuristics, and evaluation criteria used by the `peer-reviewer` ecosystem. Modeled after premier journal guidelines (Nature, IEEE TPAMI, ACM TOIS, JMLR, Lancet) and agentic peer-review frameworks (Google Research's ScholarPeer, K-Dense Scientific Agent Skills), it equips referees with standardized auditing rubrics.

---

## 1. The Two-Tier Review Paradigm

The peer-review workflow divides responsibilities between two specialized roles:
1. **Tier 1: Editorial Triage (Editor-in-Chief / Meta-Reviewer)**: Focuses on venue compatibility, desk-reject risks, formal submission hygiene, and final balance/decision synthesis.
2. **Tier 2: Specialized Technical Referees**:
   - **Referee 1 (Methodological Rigor & Transparency)**: Deep dive into mathematical formulation, experimental design, baseline tuning fairness, dataset hygiene, and statistical significance.
   - **Referee 2 (Literature-Grounded Novelty & Prior Art)**: Probing skeptic checking explicit novelty claims against live scientific literature (preprints, publications), identifying missing citations, and calibrating genuine incremental vs substantive advances.

---

## 2. Editorial Triage & Desk-Reject Matrix

Before committing full referee resources, an Editor-in-Chief audits manuscripts against 5 fatal rejection vectors:

| Triage Dimension | High Risk (Desk Reject) | Medium Risk (Needs Revision) | Low Risk (Proceed to Review) |
|---|---|---|---|
| **Aims & Scope Fit** | Topic completely outside journal charter (e.g., pure software tutorial submitted to theoretical biology journal). | Tangential topic; fails to highlight relevance to the journal's target community. | Direct match with regular themes and recent special issues. |
| **Completeness & Structure** | Incomplete drafts, missing methods, missing discussions, or truncated proofs. | Marginal structure, poor formatting, or sections out of standard order. | Fully structured (Abstract, Intro, Related Work, Method, Experiments, Conclusion). |
| **Mandatory Declarations** | Missing ethical approvals for human/animal data; absent Data/Code Availability statement when mandated. | Generic or placeholder statements ("Data available upon reasonable request"). | Explicit repository links, DOIs, accession numbers, and ethics protocol IDs. |
| **Length & Form Guidelines** | Grossly exceeds page/word limits (e.g., 25 pages submitted to a 10-page maximum letter journal). | Slightly over limit; easily trimmable in revision. | Strictly adheres to venue formatting and length constraints. |
| **Language & Readability** | Obscurity of language or disjointed logic prevents comprehension of technical claims. | Frequent grammatical slips, but technical narrative remains interpretable. | Clear, authoritative academic prose and well-typeset mathematical notation. |

---

## 3. Methodological Rigor & Transparency Audit

Technical referees must examine empirical and mathematical claims across 4 critical pillars:

### Pillar 1: Baseline Fairness & Selection
- **Recency**: Are the comparison methods contemporary (state of the art within the last 24–36 months)? Comparing only against 10-year-old classical algorithms is a major red flag.
- **Tuning Hygiene**: Were baselines properly tuned on validation sets, or were default parameters used that handicap competitor performance?
- **Equitable Resources**: Did the proposed method and baselines operate under comparable compute budgets, training epochs, or parameter counts?

### Pillar 2: Experimental Design & Data Integrity
- **Data Splitting**: Strict separation between training, validation, and testing sets. Flag temporal leakage (using future data to predict past events) and group leakage (e.g., images from the same patient across train and test).
- **Ablation Studies**: Does the paper isolate every newly proposed component? If components A, B, and C are added, is there an ablation removing each individually ($A+B$, $A+C$, $B+C$)?
- **Synthetic vs Real-World**: If synthetic datasets are used, are their generation assumptions realistic? Is there validation on accepted public benchmarks?

### Pillar 3: Statistical Rigor & Measurement
- **Multiple Trials & Variance**: Are results reported across multiple random seeds (at least 3–5 runs)? Are mean and standard deviation / standard error clearly tabulated?
- **Hypothesis Testing**: Are claims of "statistically significant superiority" supported by formal tests (paired t-test, Wilcoxon signed-rank test)?
- **Effect Sizes vs P-values**: Does the paper report effect sizes (e.g., Cohen's d) rather than relying solely on arbitrary p-value thresholds ($p < 0.05$)?
- **Imbalance & Metrics**: In imbalanced tasks, are appropriate metrics reported (e.g., Precision-Recall AUC, Balanced Accuracy, Matthews Correlation Coefficient) instead of misleading overall Accuracy?

### Pillar 4: Reproducibility Standards (ARRIVE / CONSORT / ML Checklist)
- **Code & Artifact Availability**: Are public GitHub/Zenodo links or anonymous code repositories provided?
- **Hyperparameter Disclosure**: Are all hyperparameters, learning rates, batch sizes, optimizer choices, and hardware environments explicitly specified?
- **Protocol Transparency**: For clinical or animal studies, verify compliance with CONSORT (randomized trials) or ARRIVE (in vivo animal experiments) reporting items.

---

## 4. Literature-Grounded Novelty & Prior-Art Verification

A realistic referee does not rely on subjective intuition alone; claims of novelty are actively verified against the published literature.

### 1. Claim Deconstruction
Extract the authors' exact claims:
- *"We are the first to introduce mechanism X to task Y."*
- *"We propose a fundamentally new loss formulation for Z."*
- *"Our approach achieves 5x faster convergence without loss of accuracy."*

### 2. Live Literature Search Strategy
Referees formulate search queries combining:
- `[Core Algorithmic Technique]` + `[Domain / Task]` + `[Key Mathematical Property]`
- Search queries must target recent preprints (arXiv, bioRxiv) and conference/journal publications (2023–2026).
- Search for synonym terminology (e.g., "contrastive predictive coding" vs "temporal self-supervised representation").

### 3. Novelty Taxonomy
- **Tier 1 (Substantive / Paradigm Shift)**: Introduces genuinely new concepts, disproves widely accepted beliefs, or solves long-standing theoretical bottlenecks.
- **Tier 2 (Solid Incremental Contribution)**: Well-motivated integration of known techniques yielding non-trivial empirical or theoretical benefits. High venue suitability.
- **Tier 3 (Marginal Delta)**: Routine plug-and-play substitution with minimal technical insight. Suitable for application-oriented workshops, borderline for top journals.
- **Tier 4 (Re-invention of Known Art)**: Core technique already published in prior literature; claims of originality are invalid due to insufficient literature awareness.

---

## 5. Reviewer Recommendation Standards

| Decision | Empirical Rigor | Novelty & Significance | Venue Fit | Action Required |
|---|---|---|---|---|
| **Accept** | Flawless; code/data fully available; strong statistical verification. | High; clear contribution to state of the art. | Direct alignment with journal readership. | Minor typographical or citation adjustments. |
| **Minor Revision** | High; minor baseline clarifications or figure improvements required. | Good; solid contribution clearly established. | Good fit. | Resolvable within 2 to 4 weeks without new major experiments. |
| **Major Revision** | Medium; missing essential baselines, unvalidated ablations, or ambiguous splits. | Promising concept, but empirical support is incomplete. | Potentially good fit. | Requires new experiments, baseline comparisons, or substantial rewriting (6–12 weeks). |
| **Reject** | Low; fatal methodological flaws, irremediable data leakage, or invalid statistics. | Low / Derivative; or core method is already known in prior art. | Or severe scope mismatch. | Cannot be cured by reasonable revision. |

---

## 6. Constructive Feedback Heuristics

- **Be Specific & Line-Referenced**: Never say "Section 3 is unclear." Instead write: *"In Section 3.2, Equation 4 omits the definition of parameter $\lambda$. Clarify whether $\lambda$ is dynamically scheduled or fixed."*
- **Acknowledge Genuine Strengths**: Start with what the authors did well to ground the critique constructively.
- **Distinguish Fatal Flaws from Nice-to-Haves**: Explicitly separate "Essential for Re-Review" from "Minor Suggestions for Polish".
