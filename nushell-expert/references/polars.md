# Data Processing with Polars (`nu_plugin_polars`)

## Overview & Architecture

Nushell integrates with [Polars](https://pola.rs/) via `nu_plugin_polars`, offering high-performance, multithreaded columnar data processing built on Apache Arrow.

### DataFrames vs LazyFrames

- **DataFrame (`polars into-df`)**: An eager, in-memory columnar data structure. Transformations are evaluated immediately.
- **LazyFrame (`polars into-lazy`)**: A deferred logical query plan. Operations are queued and optimized (predicate pushdown, projection pushdown, parallel execution) and only materialized upon calling `polars collect`.

> **Key Rule**: Commands such as `polars group-by ... | polars agg`, `polars select`, and `polars unpivot` yield a LazyFrame query plan. Always append `| polars collect` when you need the evaluated DataFrame.

---

## 1. Data Ingestion & I/O

### Direct File Loading (`polars open`)
`polars open` inspects and streams structured tabular files without converting them through raw text pipelines:
```nu
# Open Parquet, CSV, JSON, Arrow, NDJSON directly
let df = polars open data.parquet
let csv_df = polars open sales.csv
```

### Conversion from Native Nushell Data
```nu
# Convert native table to eager DataFrame
let df = [[dept name salary]; ["IT" "Alice" 50000] ["IT" "Bob" 45000] ["HR" "Charlie" 70000]] | polars into-df

# Convert DataFrame to LazyFrame for optimization
let lazy_df = $df | polars into-lazy
```

### Saving & Exporting
```nu
# Export DataFrame to persistent formats
$df | polars to-parquet "output.parquet"
$df | polars to-csv "output.csv"
```

---

## 2. Expressions, Projections & Selectors

Polars expressions (`polars col`) allow defining transformations across columns with type inference and vectorized execution.

### Column Expressions & Calculations
```nu
# Reference column and alias resulting series
$lazy_df | polars with-column ((polars col salary) * 1.15 | polars as adjusted_salary)

# Cast data types
$lazy_df | polars with-column ((polars col salary | polars cast f64) | polars as salary_f64)
```

### Modern Selectors (`polars selector *`)
In Nushell 0.116+, use `polars selector` subcommands instead of manual string lists when filtering column types:
```nu
# Select all numeric columns (i64, f64, etc.)
$df | polars select [(polars selector numeric)] | polars collect

# Select string columns
$df | polars select [(polars selector string)] | polars collect

# Combine and exclude selectors
$df | polars select [(polars selector not (polars selector temporal))] | polars collect
```

---

## 3. Filtering & Sorting

```nu
# Filter rows using column comparison expressions
let filtered = $lazy_df | polars filter ((polars col salary) >= 50000)

# Sort rows
let sorted = $filtered | polars sort-by [salary] --reverse [true]

# Materialize result
$sorted | polars collect
```

---

## 4. Grouping & Aggregations

Group-by queries compute multi-column summary statistics in parallel:
```nu
# Group by department and compute mean salary and headcount
let summary_df = $df
    | polars group-by [dept]
    | polars agg [
        (polars col salary | polars mean | polars as mean_salary)
        (polars col salary | polars max | polars as max_salary)
        (polars col name | polars count | polars as headcount)
    ]
    | polars collect
```

### Fast Exploration & Metrics
```nu
# View DataFrame shape: [rows columns]
$df | polars shape

# Comprehensive descriptive statistics
$df | polars summary

# Inspect schema types
$df | polars schema
```

---

## 5. Reshaping & Joins

### Joining DataFrames
```nu
let depts = [[dept location]; ["IT" "Floor 4"] ["HR" "Floor 2"]] | polars into-df

# Perform a left join on the dept column (--inner, --left, --full, --cross)
let joined = $df | polars join --left $depts dept dept | polars collect
```

### Unpivot (Wide to Long)
> **Note**: In modern `nu_plugin_polars`, use `polars unpivot` instead of the legacy `melt` operation:
```nu
let wide = [[id q1 q2]; [1 100 200] [2 150 250]] | polars into-df

# Transform columns q1 and q2 into rows
let long = $wide | polars unpivot --index [id] --on [q1 q2] | polars collect
```

---

## 6. Decision Matrix: Native Nushell vs. `nu_plugin_polars`

| Criterion | Native Nushell Tables (`where`, `each`, `group-by`) | `nu_plugin_polars` (`polars *`) |
| :--- | :--- | :--- |
| **Dataset Size** | Small to Medium (< 50,000 records) | Large to Massive (50,000 to millions of rows) |
| **Memory Footprint** | Heap-allocated record values | Apache Arrow contiguous memory buffer |
| **Execution Model** | Eager Nushell pipeline evaluation | Lazy query graph optimization (`polars collect`) |
| **File Formats** | Standard text, CSV, JSON, TOML, YAML | Parquet, Arrow, Avro, large CSV, NDJSON |
| **Use Cases** | CLI orchestration, config parsing, sysadmin | Heavy analytics, grouped stats, join engines |

Use native Nushell pipelines for everyday script automation; switch to `nu_plugin_polars` whenever handling tabular files over 50 MB, Parquet datasets, or computationally intensive multi-column aggregations.
