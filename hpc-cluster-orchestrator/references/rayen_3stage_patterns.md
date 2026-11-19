# 3-Stage server HPC Pipeline Patterns & Blueprints

Distilled from production multi-seed and Monte Carlo research campaigns (`shell/` orchestration scripts). Adapt node names, remote repo paths, and expected artifact counts per project — never hardcode one project's constants into another.

---

## 1. Stage 1 — `shell/check_cluster.nu` Contract

Design `check_cluster.nu` so both humans and `orchestrate_simulations.nu` consume the same structured status source of truth:

- **Standard CLI Flags:**
  - `--structured (-s)`: Return NUON/JSON-compatible record without ANSI table printing.
  - `--dry-run (-d)`: Skip live SSH calls and return deterministic schema preview.
  - `--proxy (-p)` / `--no-proxy (-n)` / `--identity (-i)` / `--user (-u)`: Transparent jump-host proxy via `desktop` when running from laptop (`laptop`), bypassed on VPN/direct LAN (`$current_hostname == $desktop_name`).
  - `--cpu-threshold: float = 50.0`: Marks a compute node busy if `%CPU` exceeds threshold even without SLURM allocation (catches direct `nohup` jobs).
- **Returned 3-Stage Status Record:**
  ```nu
  {
    stage1_remote_compute: {
      host: $cluster_host
      node_reachable: bool
      slurm_queue: list
      node_processes: list
      completed_units: int
      expected_units: int
      active_checkpoints: int
      eta_seconds: int
    }
    stage2_local_rsync_parity: {
      local_units_synced: int
      expected_units: int
      in_parity: bool
    }
    stage3_local_postprocess: {
      plots_rendered: int
      summary_report_ready: bool
      insights_report_ready: bool
    }
  }
  ```
- **Progress Log Parsing Pitfall:** MATLAB `\b`-based progress bars do not flush cleanly to Slurm `.out` logs and can look frozen with `grep -v`. Parse logs with raw streaming (`cat`) and extract both milestone lines and elapsed timestamps.

---

## 2. Stage 1 & 2 — `shell/orchestrate_simulations.nu` Contract

1. **Pre-Flight Code Deployment Sync:**
   Before dispatching any job, sync code/scripts from local repo to remote cluster repo (`rsync -avz --exclude='.git' --exclude='results/' --exclude='data/' ...`) or verify git commit parity. Never launch stale remote code.
2. **Resource-Aware Concurrency & State File:**
   Track job states in `shell/orchestrator_state.json` (`pending` → `running` → `completed` → `synced`) with explicit concurrency caps (e.g., max 1 memory-heavy Python/GPU job or up to 2 CPU MATLAB batches concurrently).
3. **Dual-Mode Dispatch (SLURM `sbatch` + SSH `nohup` Fallback):**
   ```nu
   # 1. Attempt SLURM submission
   # sbatch --partition=<part> --nodelist=<node> <script.sbatch>
   # 2. Check squeue shortly after submission:
   # If Reason contains "PartitionConfig", "Invalid", or "ReqNodeNotAvail":
   #   scancel <job_id>
   #   Fallback via direct SSH background launch using `;` before nohup so FDs detach cleanly:
   #   ssh <node> "cd <remote_repo> && mkdir -p logs; nohup env ... <cmd> > logs/<id>.log 2>&1 < /dev/null & echo $!"
   ```
   Prefix direct PIDs as `<node>:<pid>` (e.g., `n002:12345`) so `check_remote_job_alive` queries SLURM for numeric IDs and `ps -p <pid>` on `<node>` for direct fallback jobs.
4. **Early Exit & Auto-Resume Reconciliation:**
   If a `running` job disappears from `squeue` / `ps`, verify whether all expected output artifacts exist on server. If partial, reset state to `pending` so the next tick resumes via checkpoint/skip-completed logic.
5. **Stage 2 Incremental & Final Rsync Pull:**
   ```nu
   # Exit code 24 (partial transfer due to vanished transient files) is non-fatal when checkpoints/active dirs exist
   ^rsync -avz --exclude='candidates/' --exclude='*_checkpoint*' --exclude='*.tmp' $"($remote_results)/" $"($local_results)/"
   ```
   Wait for `stage2_local_rsync_parity.in_parity == true` before starting Stage 3.

---

## 3. Remote Compute-Only Entrypoint Guardrails

Every script invoked by `.sbatch` or remote `nohup` MUST enforce:
- **Compute-Only Flag:** `skip_plots = true;` (MATLAB) or `SKIP_PLOTS = True` / `--skip-plots` (Python).
- **Decoupled NFS I/O:** Accumulate results inside `parfor` / `ProcessPoolExecutor` workers in memory or via `DataQueue` and write finished `.mat`/`.json` summaries outside the tight inner worker loop.
- **Zero Plot Exports:** No `figure`, `exportgraphics`, `saveas`, `print -dpdf`, or `plt.savefig` anywhere in remote execution paths.

---

## 4. Stage 3 — Strict Local Postprocessing Rules

Once `stage2_local_rsync_parity.in_parity == true`:
- **Headless Local Plotting:**
  - MATLAB: `h = figure('Visible', 'off'); ... exportgraphics(h, pdf_path, 'ContentType', 'vector'); close(h);` (avoid bare `gcf` races).
  - Python: `import matplotlib; matplotlib.use('Agg')` before `pyplot`, save vector PDF + high-DPI PNG, always `plt.close(fig)`.
- **Report & Statistical Handoff:** Generate raw comparison tables (`summary_report.md`) locally, then activate `results-insights-enhancer` to add qualitative analysis, non-parametric tests, SOTA comparisons, and `insights_report.md`.
