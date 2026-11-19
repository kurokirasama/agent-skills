---
name: deep-research
description: High-level orchestrator for end-to-end research, parallelizing native Gemini Deep Research (with user cost approval) and multi-source retrieval/synthesis, supporting Dual-Journal Candidacy ranking and Capped Refresh updates.
---
# Deep Research Orchestrator

## Objective
Conduct an exhaustive, end-to-end research task on a specific topic by parallelizing native background research (`gemini-deep-research`) with a multi-source retrieval and synthesis pipeline (`deep-retrieval-task` + `source-retrieval-task`).

Supports two specialized academic modes in addition to general research (see [references/journal_candidacy_and_refresh.md](references/journal_candidacy_and_refresh.md)):
1. **Full Bibliographical & Dual-Journal Candidacy Mode (Stage 2):** Produces verified BibTeX, downloaded PDFs/summaries, and `journal_candidates_report.md` ranking **Primary (1st Attempt)** + **Minimal-Reformat Cascade Backup** journals for user selection.
2. **Capped Refresh Mode (`refresh`, Stage 4):** Time-bounded post-implementation delta pass covering recent months of literature and re-evaluating Primary/Backup venues if project scope expanded or shifted.

---

## 1. Preparation & Cost Approval (Mandatory Gate)
**CRITICAL**: This pipeline utilizes `gemini-deep-research`, which incurs an API cost. You MUST send a Discord notification (`to-discord $msg -p`) and explicitly ask the user for approval before proceeding.

- **Unified Topic Definition**: Clearly define the research topic, mode (`Full` vs `Capped Refresh` with date cutoff), and classification (Scientific vs Knowledge).
- **Approval Prompt**: *"The `deep-research` orchestrator will parallelize the native Gemini Deep Research command (`ai deep-research start --max`) with the retrieval and synthesis pipeline. This incurs an API cost. Do you approve its usage for this task?"*
- **Fallback**: If the user declines, proceed using ONLY non-paid retrieval logic (`deep-retrieval-task`, `source-retrieval-task`, and academic MCP tools: arXiv, OpenAlex, Europe PMC, PubMed, Exa).

---

## 2. Parallel Execution Phase
Once approved (or in non-paid fallback mode), execute the parallel tracks:

### Deep Research Swarm Option
For extensive multi-domain research, propose a **Deep Research Swarm** (never launch without Discord alert + user approval):
- **Roster (`workspace: "inherit"`):** `scholar-worker` (arXiv, Europe PMC, OpenAlex, Semantic Scholar), `web-worker` (web scraping, publisher guidelines, news), `synthesis-worker` (indexing, BibTeX & summary synthesis), `monitor` (`swarm_monitor`).
- **Manual Slash Command:** `/swarm Research topic <topic_query>`.

### Dual Track Execution (Default / Fallback)
- **Track A (Native Gemini Deep Research — only if cost approved):**
  - Activate `gemini-deep-research` and run `ai deep-research start "<refined_prompt>" --max`.
  - Record the Research ID and continue immediately to Track B.
- **Track B (Retrieval Pipeline):**
  - Execute `deep-retrieval-task` (respecting date bounds in Capped Refresh Mode) to collect candidate source URLs and scholarly DOIs.
  - Download accessible full-text PDFs into `bibliography/papers/` and pass URLs to `source-retrieval-task` for RAG-based synthesis and structured Markdown summaries in `bibliography/summaries/`.

---

## 3. Monitoring & Convergence
- Poll Track A status with `ai deep-research status --id "<id>"` while completing Track B synthesis.
- Cross-check all collected DOIs/BibTeX entries (no fabricated titles, authors, years, or venues).

---

## 4. Final Consolidation & Venue Ranking

Retrieve Track A (`ai deep-research retrieve`) and merge with Track B into `bibliography/search/<run_slug>/`:
1. **Consolidated Research Report:** Native deep research findings + grounded synthesis + chronological SOTA gaps.
2. **Verified References:** Updated `.bib` database + per-paper summaries + source URL manifest.
3. **Dual-Journal Candidacy Report (`journal_candidates_report.md` — when academic publication is in scope):**
   Following [references/journal_candidacy_and_refresh.md](references/journal_candidacy_and_refresh.md), evaluate JCR/Scopus Q1/Q2 candidates, APC (`$0` subscription vs Open Access), bibliography overlap, and template compatibility, then present **at least 2 paired journal options** for the user to choose from:
   - **Attempt 1 (Primary Target):** Best impact/scope match for initial submission.
   - **Cascade Backup Target:** Same publisher family or minimal-reformat alternative requiring minimal manuscript changes if rejected.

## Progressive Disclosure
- **Dual-Journal Candidacy & Capped Refresh Guide:** [references/journal_candidacy_and_refresh.md](references/journal_candidacy_and_refresh.md)
