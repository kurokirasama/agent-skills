# Non-Parametric Statistical Significance Testing Reference

Use this guide when synthesizing Section 2 (`## Statistical Significance Analysis`) of `insights_report.md` across multi-dataset or multi-seed experimental benchmarks where parametric normality cannot be assumed (following Demšar, 2006; García et al., 2010; Derrac et al., 2011).

---

## 1. Paired Two-Method Comparison: Wilcoxon Signed-Rank Test
Use for comparing `Proposed Method` vs a single `Baseline` across $N$ independent datasets or paired seeds ($i = 1, \dots, N$).

### Formulation
1. Compute paired differences: $d_i = x_{\text{proposed},i} - x_{\text{baseline},i}$ (align sign convention with minimization vs maximization).
2. Discard zero differences ($d_i = 0$), yielding $N_r \le N$ non-zero pairs.
3. Rank $|d_i|$ in ascending order (assign mid-ranks for ties).
4. Compute signed rank sums:
   $$W^+ = \sum_{d_i > 0} \text{rank}(|d_i|), \quad W^- = \sum_{d_i < 0} \text{rank}(|d_i|), \quad W = \min(W^+, W^-)$$
5. Compute exact two-tailed or one-tailed $p$-value (preferred for small $N \le 25$) or normal approximation with tie correction; report whether significance holds at $\alpha = 0.05$ and $\alpha = 0.01$.
6. Also report **Win / Tie / Loss counts** (`W/T/L`) explicitly.

---

## 2. Multi-Method Comparison ($k \ge 3$ Methods): Friedman & Post-Hoc Tests
When comparing $k \ge 3$ algorithms across $N$ datasets/benchmarks:
1. **Average Ranks:** Rank each method $j \in \{1,\dots,k\}$ on each dataset $i \in \{1,\dots,N\}$ (rank 1 = best; average mid-ranks for ties), obtaining mean rank $R_j = \frac{1}{N}\sum_{i=1}^N r_i^j$.
2. **Omnibus Test:** Compute the Friedman $\chi^2_F$ statistic (and Iman–Davenport $F_F$ correction, which is less conservative). If $p < \alpha$, reject the null hypothesis that all methods perform equivalently.
3. **Post-Hoc Pairwise Comparisons:**
   - **All-vs-Control (Proposed vs every baseline):** Holm, Hochberg, or Shaffer step-down $p$-value adjustment (more powerful than Bonferroni–Dunn).
   - **All-Pairs Comparison:** Nemenyi test with **Critical Difference (CD)** visualization:
     $$\text{CD} = q_{\alpha} \sqrt{\frac{k(k+1)}{6N}}$$
     Report which cliques have statistically indistinguishable mean ranks.

---

## 3. Effect Size & Practical Significance
Pair $p$-values with non-parametric effect sizes so practical magnitude is clear:
- **Matched-Pairs Rank-Biserial Correlation ($r$):** $r = \frac{W^+ - W^-}{W^+ + W^-}$ for Wilcoxon paired tests.
- **Vargha–Delaney $\hat{A}_{12}$ or Cliff's $\delta$:** For multi-seed stochastic runs on individual benchmarks (quantifying probability that Method A beats Method B on a random seed).
- **Relative Speedup / Improvement Factor:** Median and IQR of ratios across tasks.

---

## 4. Reporting Checklist & Prose Template
Every statistical table/paragraph in `insights_report.md` MUST verify and state:
- Sample unit and size ($N$ datasets or $M$ independent seeds; avoid pseudoreplication by clearly distinguishing per-dataset cross-seed means from pooled seeds).
- Exact test name, one- vs two-tailed hypothesis, multiple-testing correction, test statistic, $p$-value, and effect size.

```markdown
To assess whether performance and runtime differences generalize across the <N> evaluated
benchmarks, non-parametric tests were applied following Derrac et al. (2011). Across all
<k> compared methods, the Friedman test (with Iman–Davenport correction) indicated
significant overall differences (<metric>: F_F = <val>, p = <p_val>). Pairwise post-hoc
Wilcoxon signed-rank tests with Holm correction confirmed that <Proposed> significantly
outperforms <Baseline> on <win>/<N> benchmarks (W = <W>, adjusted p = <p_adj>, rank-biserial
r = <r>), while reducing median wall-clock runtime by <speedup>x (p = <p_time>).
```
