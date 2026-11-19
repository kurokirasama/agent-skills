# Qualitative Results Analysis Reference Template

Use this domain-agnostic structure when expanding the qualitative analysis section (e.g., `## Qualitative Results Analysis`) of an experimental `summary_report.md`. Adapt subsection titles and metrics to the active study's domain (ML, optimization, simulation, statistics, systems, etc.) without changing original quantitative tables.

---

## Section Structure & Content Guidelines

### 1. Methodological Mechanics Breakdown
Contrast the internal mechanics and structural differences across all evaluated methods (`Baseline 1`, ..., `Proposed Method`):
- **Representation & Search/Model Space:** Fixed vs adaptive parameterization, inductive biases, constraints, and degrees of freedom.
- **Core Update / Inference / Optimization Loop:** Surrogate vs evolutionary vs gradient vs analytical mechanics, initialization strategy, and stopping criteria.
- **Why Mechanics Diverge Empirically:** Map structural properties directly to observed performance gaps (e.g., why fixed-capacity baselines saturate or over-parameterize while adaptive methods prune/scale).

### 2. Computational Efficiency, Wall-Clock & Parallelization Scaling
Evaluate runtime performance, resource overhead, and scaling behavior:
- **Worker & Parallelism Mechanics:** Asynchronous vs synchronous batches, thread/process contention, memory footprint, and deferred/decoupled I/O.
- **Redundancy Avoidance & Caching:** Memoization, surrogate gating, early stopping, or elite/duplicate skipping that avoids redundant work.
- **Empirical Speedup & Resource Budget:** Report measured wall-clock time, speedup ratios (`T_baseline / T_proposed`), evaluation/token/epoch counts, and compute environment (local workstation vs HPC cluster).

### 3. Model / Solution Complexity & Structural Trade-offs
Contrast parsimony, interpretability, and capacity allocation:
- **Capacity Bounds & Selection Rules:** Document principled hyperparameter/structural bounds (citations or domain derivations) vs fixed defaults.
- **Effective Complexity Achieved:** Compare active parameter counts, layer depths, selected features, or sparse/compact structures discovered per dataset/task.
- **Parsimony vs Accuracy Balance:** Highlight cases where smaller/simpler models match or outperform heavy baselines.

### 4. Convergence Dynamics & Failure-Mode / Landscape Robustness
Analyze stability, variance, and edge-case behavior across seeds or folds:
- **Sample/Evaluation Efficiency:** Generations, iterations, or queries required to reach near-optimal convergence.
- **Objective Alignment:** Confirm fair, identical evaluation splits (`train`/`val`/`test`) and unpenalized test metrics across all compared methods.
- **Failure Modes & Deceptive Landscapes:** Identify any seed collapses, local-minima traps, class-imbalance collapses, convergence timeouts, or high-variance regimes, explaining how the proposed method mitigates them.

### 5. Visual & Schematic Figure Validation
Verify all Markdown figure references co-located with `summary_report.md`:
- Use clean relative paths (e.g., `![<Method> <Plot Type>](./figures/<file>.png)`).
- Confirm every referenced `.png`/`.pdf`/`.svg` asset exists on disk and captions match the exact run configuration and numbers shown in tables.
