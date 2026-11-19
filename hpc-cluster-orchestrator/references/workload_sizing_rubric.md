# Computational Workload & API Cost Sizing Rubric

Use this rubric during **Stage 3 (Research Implementation Planning)** before choosing between Local workstation execution, server HPC offloading, or Cloud API Batch campaigns.

---

## 1. Local vs. server HPC Decision Matrix

| Criterion | Run Locally (`workstation` / `desktop`) | Offload to server HPC (`hpc-cluster-orchestrator`) |
| :--- | :--- | :--- |
| **Estimated Single-Machine Wall-Clock** | `< 4 hours` | `>= 4 hours` (multi-hour or multi-day sweeps) |
| **Peak RAM Footprint** | `<= 16 GB` (or fits comfortably within local RAM) | `> 16 GB` or memory pressure risks OOM |
| **Independent Jobs / Seeds / Grid Points** | `<= 8` jobs | `> 8` parallel jobs (multi-seed benchmarks, bootstrap Monte Carlo, grid sweeps) |
| **Hardware Acceleration** | Fits local 16GB GPU / fast iterative dev & debugging | Cluster CPU nodes (`n001`/`n002`) or heavy multi-node sweeps |
| **Figure / Plot Rendering** | **ALWAYS LOCAL** | **NEVER ON RAYEN** (`skip_plots = true` mandatory) |

### Hybrid Split Rule
Even when running experiments locally, still keep plotting decoupled (`--skip-plots` during long simulation runs → separate fast postprocessing script) so crashes or early stops never lose raw `.mat`/`.json`/`.csv` artifacts.

---

## 2. LLM / Cloud API Workload Sizing & Pilot Protocol (from `ProjectA`)

When experiments invoke paid external APIs (Gemini Batch API, OpenAI, embeddings, etc.):
1. **Minimal Pilot First (`N = 5..20` units):** Measure real per-call input/output/image tokens, latency, failure rate, and JSON parse rate before scaling.
2. **Pre-Flight Cost Table:** Estimate full-campaign spend (`total_calls * avg_input_tokens * input_rate + avg_output_tokens * output_rate`), comparing interactive vs Batch API pricing (50% discount where applicable) and free-tier quotas.
3. **Mandatory User Cost Gate:** Send Discord summary + ask user approval before launching any paid run exceeding a nominal pilot budget.
4. **Resumable JSONL / Timestamped Checkpoints:** Log every API request/response keyed by `(item_id, rep, condition)` so partial failures repair/resume without re-paying for completed calls.
