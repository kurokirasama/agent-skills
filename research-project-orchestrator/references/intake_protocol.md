# Research Intake & Discovery Protocol

Follow this structured protocol during Steps 1–2 of `research-project-orchestrator`:

---

## 1. Silent Workspace Reconnaissance (`context-mode`)
Before asking the user redundant questions, inspect the current directory (`$env.PWD`) via `ctx_batch_execute` / `ctx_execute_file`:
- Check for existing files: `README.md`, `*.pdf` (grant proposals, previous articles), `*.md`, `*.bib`, `src/` / `matlab/` / `python/`, `conductor/`, `project-plan.md`.
- If PDF proposals exist, extract their objectives, methodology, timeline, grant number/funding source, and dataset plans via `pdf-to-markdown` (`markdonify`) or Python inside `ctx_execute`.
- Check if `project-plan.md` already exists: if so, treat this run as an update/refinement unless the user requests a clean overwrite.

---

## 2. Clarifying Questionnaire (Discord-First Gate)
Send `to-discord $msg -p` FIRST, then ask ONLY the items not already answered by workspace files or the user's prompt (always provide `(Recommended)` + `Other` options):

1. **Compute Placement & Scale:**
   - Local Workstation (`<4h`, `<=16 GB` RAM, `<=8` parallel jobs)
   - server HPC Cluster (`>=4h`, multi-seed/Monte Carlo sweeps — uses 3-stage `hpc-cluster-orchestrator`)
   - Cloud / LLM Batch API (uses pilot cost gate before full sweep)
2. **Target Venue Policy & Budget:**
   - Q1/Q2 Subscription (`$0 USD` APC) + Minimal-Reformat Cascade Backup `(Recommended)`
   - Open Access Q1/Q2 (APC budget available)
   - Top-Tier Conference (`ICLR` / `CVPR` / `NeurIPS` / `IEEE`) + Journal Extension Backup
3. **Implementation Language & Environment:**
   - Python / PyTorch / JAX / Scikit-Learn
   - MATLAB (routes through `matlab-expert`)
   - Hybrid (e.g., MATLAB/Python compute + Nushell orchestration & reporting)
4. **Funding / Grant Acknowledgments & Repo Visibility:**
   - Grant code(s) for `Acknowledgments` + Public vs Private Git repo policy (needed later for `conductor-setup`).
