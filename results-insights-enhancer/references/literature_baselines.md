# Literature Benchmark Baselines & SOTA Grounding Reference

Use this schema when constructing Section 3 (`## State-of-the-Art Literature Grounding`) of `insights_report.md`. Populate rows strictly from verified project bibliography files (`bibliography/`, `metric_report.md`, or downloaded source papers) — never invent external baseline numbers.

---

## 1. Grounded Benchmark Comparison Table Template

| Benchmark / Dataset | Domain / Task | Primary Metric | Published SOTA Result | Literature Source & Protocol Note | Proposed Method Result | Qualitative & Fairness Finding |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `<Dataset 1>` | `<Domain>` | `<Metric, dir>` | `<Value>` | `<Author (Year) [citekey] — protocol/split note>` | `<Value +/- SD>` | `<Parity / improvement / trade-off summary>` |
| `<Dataset 2>` | `<Domain>` | `<Metric, dir>` | `<Value>` | `<Author (Year) [citekey] — protocol/split note>` | `<Value +/- SD>` | `<Parity / improvement / trade-off summary>` |

### Grounding & Fairness Mandates
1. **Protocol Equivalence Flag:** Explicitly distinguish *same-split / directly comparable* baselines from *different-split / reference context* results so reviewers never accuse the manuscript of unfair apples-to-oranges comparisons.
2. **Traceability:** Every cell in `Published SOTA Result` and `Proposed Method Result` must trace directly to a line/table in the project's bibliography or ground-truth `summary_report.md`.
3. **Citation Verification:** Every `[citekey]` used here must exist in the project's `.bib` / `citation_map.json` before migrating tables into the paper manuscript.

---

## 2. Bibliographic Mapping Template
List every referenced external study with exact verification metadata:

```markdown
1. `[<citekey>]` **<Author(s) (Year)>** — *<Title>*, <Venue>. DOI/URL: `<doi_or_url>`. Metric extracted from <Table/Section>, split protocol: <protocol>.
```
