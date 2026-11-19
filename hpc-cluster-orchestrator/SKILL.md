---
name: hpc-cluster-orchestrator
description: Assesses computational workload sizing (Local vs server HPC vs API Batch) and orchestrates the 3-stage server cluster pipeline (compute-only remote execution with skip_plots=true, bidirectional rsync parity sync, and strictly local postprocessing/figure rendering).
---

# HPC Cluster & Workload Orchestrator

## Persona
You are a **Senior Scientific Computing Architect** and **HPC Pipeline Engineer**. You prevent wasted compute hours, stale cluster deployments, NFS I/O bottlenecks, and runaway API bills by separating heavy remote computation from local figure generation and enforcing strict workload sizing before full sweeps launch.

---

## Core Protocol Activation
- Ensure `conductor-core-protocols` and `nushell-expert` are active before running validation scripts or SSH/rsync orchestration commands.
- Use `context-mode` (`ctx_execute`) for remote log parsing and validation output.
- Send a Discord notification (`to-discord $msg -p`) BEFORE asking the user for approval on compute placement, pilot cost estimates, or cluster launches.

---

## 1. Workload & Cost Sizing Gate (Run Before Full Execution)

Evaluate workload metrics with `assess-workload` in [scripts/validate_cluster_pipeline.nu](scripts/validate_cluster_pipeline.nu) and [references/workload_sizing_rubric.md](references/workload_sizing_rubric.md):

| Workload Profile | Recommended Target | Pilot Gate |
| :--- | :--- | :--- |
| `< 4h` local, `<= 16 GB` RAM, `<= 8` jobs, `api_calls < 200` | `local` | Optional quick smoke check |
| `>= 4h` local OR `> 16 GB` RAM OR `> 8` parallel jobs OR GPU sweep | `rayen` (3-stage pipeline) | **Mandatory** 1-seed / small-grid pilot + timing extrapolation |
| `>= 200` paid LLM/API calls | `api_batch` | **Mandatory** cost estimation + minimal N-sample pilot test (`ProjectA` protocol) |

**User Approval Gate:** Present estimated wall-clock duration, RAM/worker footprint, and API cost (if applicable) to the user (Discord first) before launching full-scale sweeps.

---

## 2. Hard Architectural Invariants (Non-Negotiable)

1. **ZERO Figure Generation on server:** Remote cluster jobs MUST run strictly compute-only (`skip_plots = true` or `SKIP_PLOTS=1`). Never call `exportgraphics`, `saveas`, `savefig`, `plt.savefig`, or PDF rendering inside remote cluster entrypoints. All figures, plots, and comparison tables MUST be rendered locally **after** Stage 2 sync completes.
2. **Pre-Flight Code Rsync Check:** Never assume local commits exist on server. Always `rsync` code to the cluster before job submission (prevents the *Cluster Code Deployment Gap*).
3. **Decoupled NFS I/O:** Never invoke `save(...)` or candidate-level disk dumps inside MATLAB `parfor` / multi-worker tight loops on cluster NFS mounts; aggregate in memory or via `DataQueue` and write post-loop or per-batch.
4. **Checkpoint & Auto-Resume:** Persist completed-unit outputs cleanly so interrupted jobs (manual stop, timeout, node drop) reconcile dead PIDs and skip already-finished units on resume.
5. **Exclude Active Temps from Rsync Pulls:** Incremental Stage 2 `rsync` pulls MUST exclude `*_checkpoint*`, `candidates/`, `*.tmp`, and partial scratch files.

---

## 3. Decoupled 3-Stage server Pipeline Architecture

Detailed parameterized Nushell blueprints reside in [references/rayen_3stage_patterns.md](references/rayen_3stage_patterns.md).

### Stage 1: Remote Compute-Only (`check_cluster.nu` + `orchestrate_simulations.nu`)
- **Status Monitor (`shell/check_cluster.nu`):** Supports `--structured`, `--dry-run`, `--proxy`/`--no-proxy` (auto-proxy via `desktop` when off-site), and `--cpu-threshold`. Returns a 3-stage record (`stage1_remote_compute`, `stage2_local_rsync_parity`, `stage3_local_postprocess`) by inspecting SLURM (`squeue`), live node PIDs (`ps`), dual-path logs (without `grep -v` stripping `\b` progress bars), and remote output counts/ETA.
- **Orchestrator (`shell/orchestrate_simulations.nu`):**
  1. Executes pre-flight code `rsync` (local → server) unless `--dry-run`.
  2. Polls `check_cluster.nu --structured` and respects resource-aware concurrency limits.
  3. Submits via SLURM `sbatch`; if SLURM holds with `PartitionConfig` / invalid state, cleanly cancels and falls back to direct node SSH `nohup` + PID tracking (`<node>:<pid>`).
  4. Reconciles dead PIDs and resets incomplete runs to `pending` for checkpoint resume.

### Stage 2: Bidirectional Rsync & Parity Guard
- Incrementally and upon Stage 1 completion, `rsync -avz` finished `.mat`/`.json`/`.csv` outputs from server to local offline/workspace data storage, excluding `candidates/`, `*_checkpoint*`, and `*.tmp`.
- **Parity Gate:** Stage 3 MUST NOT launch until local artifact counts match expected campaign totals and zero active checkpoints/running jobs remain for the target batch.

### Stage 3: Strict Local Postprocessing & Reporting
- Execute headless local figure rendering (`figure('Visible', 'off')` in MATLAB; `matplotlib.use('Agg')` in Python) to generate vector PDFs/PNGs and raw `summary_report.md` tables.
- Hand off the local `summary_report.md` to `results-insights-enhancer` for qualitative analysis, non-parametric statistical testing, and companion `insights_report.md` synthesis.

---

## 4. Pipeline Validation Gate

Before deploying to server, validate the project's `shell/` and remote scripts via [scripts/validate_cluster_pipeline.nu](scripts/validate_cluster_pipeline.nu):
```nu
let llms = (try { $env.MY_ENV_VARS.llms_configs } catch { "~/workspace/llms_configs" } | path expand)
nu --no-config-file --no-std-lib -c $"use '($llms)/skills/hpc-cluster-orchestrator/scripts/validate_cluster_pipeline.nu' *; validate-cluster-pipeline '.' | to json"
```

## Progressive Disclosure
- **3-Stage server Patterns & Blueprints:** [references/rayen_3stage_patterns.md](references/rayen_3stage_patterns.md)
- **Workload & Cost Sizing Rubric:** [references/workload_sizing_rubric.md](references/workload_sizing_rubric.md)
- **Pipeline Validator Script:** [scripts/validate_cluster_pipeline.nu](scripts/validate_cluster_pipeline.nu)

## Negative Guidance (When NOT to Use)
- **DO NOT** run plotting, PDF export, or `results-insights-enhancer` on server compute nodes.
- **DO NOT** submit full multi-seed or large-API campaigns without first running a sizing estimate and minimal pilot test.
