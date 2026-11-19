# Generic Empirical Ground-Truth & Citation Auditor for LaTeX Manuscripts

def strip-tex-comments [text: string]: nothing -> string {
  $text
    | lines
    | each {|ln|
        if ($ln | str trim | str starts-with "%") {
          ""
        } else {
          $ln | str replace -r '(?<!\\)%.*$' ''
        }
      }
    | str join "\n"
}

# Extract all BibTeX entry keys from a .bib file, ignoring commented entries.
export def extract-bib-keys [bib_path: path]: nothing -> list<string> {
  if not ($bib_path | path exists) {
    error make { msg: $"BibTeX file not found: ($bib_path)" }
  }
  let cleaned = (open --raw $bib_path | strip-tex-comments $in)
  $cleaned
    | lines
    | each {|ln|
        let m = ($ln | parse --regex '@(?!(?:string|preamble|comment)\b)[A-Za-z]+\s*\{\s*(?P<key>[^,\s}]+)\s*,')
        if ($m | is-empty) { null } else { $m.0.key | str trim }
      }
    | where {|k| $k != null and ($k | str length) > 0 }
    | uniq
}

# Extract all \cite...{...} citation occurrences from a .tex file with 1-based line numbers.
export def extract-tex-citations [tex_path: path]: nothing -> table<file: string, line: int, key: string> {
  if not ($tex_path | path exists) {
    error make { msg: $"LaTeX file not found: ($tex_path)" }
  }
  let fname = ($tex_path | path basename)
  let raw_lines = (open --raw $tex_path | lines)
  mut rows = []
  mut line_num = 1
  for raw_ln in $raw_lines {
    let ln = (if ($raw_ln | str trim | str starts-with "%") {
      ""
    } else {
      $raw_ln | str replace -r '(?<!\\)%.*$' ''
    })
    let matches = ($ln | parse --regex '\\cite[a-zA-Z*]*\s*(?:\[[^\]]*\]\s*)*\{(?P<keys>[^}]+)\}')
    for m in $matches {
      let split_keys = ($m.keys | split row "," | each {|k| $k | str trim } | where {|k| ($k | str length) > 0 })
      for k in $split_keys {
        $rows = ($rows | append { file: $fname, line: $line_num, key: $k })
      }
    }
    $line_num = $line_num + 1
  }
  $rows
}

# Audit all .tex files in a directory against a verified .bib file and optional P0 key list.
export def audit-citations [
  tex_dir: path
  bib_path: path
  required_p0: list<string> = []
]: nothing -> record {
  let root = ($tex_dir | path expand)
  if not ($root | path exists) {
    error make { msg: $"TeX directory not found: ($root)" }
  }
  let bib_keys = (extract-bib-keys $bib_path)
  let tex_files = (glob ($root | path join "**" "*.tex") --exclude ["**/.git/**"])

  mut occurrences = []
  for tf in $tex_files {
    let cites = (extract-tex-citations $tf)
    $occurrences = ($occurrences | append $cites)
  }

  let cited_unique = ($occurrences | get -o key | default [] | uniq)
  let verified_cited = ($cited_unique | where {|k| $k in $bib_keys })
  let hallucinated = ($cited_unique | where {|k| not ($k in $bib_keys) })
  let uncited = ($bib_keys | where {|k| not ($k in $cited_unique) })
  let missing_p0 = ($required_p0 | where {|k| not ($k in $cited_unique) })

  let gen_count = ($cited_unique | length | into float)
  let bib_count = ($bib_keys | length | into float)
  let tp = ($verified_cited | length | into float)

  let precision = if $gen_count > 0.0 { $tp / $gen_count } else { 0.0 }
  let recall = if $bib_count > 0.0 { $tp / $bib_count } else { 0.0 }
  let f1 = if ($precision + $recall) > 0.0 { (2.0 * $precision * $recall) / ($precision + $recall) } else { 0.0 }

  {
    pass: (($hallucinated | is-empty) and ($missing_p0 | is-empty))
    precision: $precision
    recall: $recall
    f1: $f1
    cited_count: ($cited_unique | length)
    bib_count: ($bib_keys | length)
    hallucinated_keys: $hallucinated
    uncited_keys: $uncited
    missing_p0_keys: $missing_p0
    occurrences: $occurrences
  }
}

def clean-cell-text [cell: string]: nothing -> string {
  $cell
    | str replace -a -r '\\(?:textbf|textit|emph|underline|mathrm)\{([^}]*)\}' '$1'
    | str replace -a '\\%' ''
    | str replace -a '%' ''
    | str replace -a '**' ''
    | str replace -a '`' ''
    | str replace -a '$' ''
    | str trim
}

def parse-num-or-null [cell: string]: nothing -> any {
  let cleaned = (clean-cell-text $cell | str replace -a ',' '')
  if ($cleaned =~ '^[+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?$') {
    try { $cleaned | into float } catch { null }
  } else {
    null
  }
}

def extract-md-numeric-rows [gt_md_path: path]: nothing -> table<key: string, nums: list<float>> {
  let lns = (open --raw $gt_md_path | lines)
  mut rows = []
  for ln in $lns {
    let trimmed = ($ln | str trim)
    if not ($trimmed | str starts-with "|") { continue }
    if ($trimmed =~ '^\|[\s:|-]+\|$') { continue }
    let cells = ($trimmed | split row "|" | slice 1..-2 | each {|c| clean-cell-text $c })
    if ($cells | length) < 2 { continue }
    let key = ($cells | get 0)
    if ($key | is-empty) { continue }
    let nums = ($cells | slice 1.. | each {|c| parse-num-or-null $c } | where {|x| $x != null })
    if not ($nums | is-empty) {
      $rows = ($rows | append { key: $key, nums: $nums })
    }
  }
  $rows
}

# Cross-check LaTeX table rows (&-delimited) against Markdown ground-truth table rows by matching row keys.
export def audit-tex-tables [
  tex_dir: path
  gt_md_path: path
  --tol (-t): float = 0.01
]: nothing -> list<record> {
  let root = ($tex_dir | path expand)
  if not ($root | path exists) {
    error make { msg: $"TeX directory not found: ($root)" }
  }
  if not ($gt_md_path | path exists) {
    error make { msg: $"Ground-truth Markdown file not found: ($gt_md_path)" }
  }

  let gt_rows = (extract-md-numeric-rows $gt_md_path)
  let tex_files = (glob ($root | path join "**" "*.tex") --exclude ["**/.git/**"])
  mut discrepancies = []

  for tf in $tex_files {
    let fname = ($tf | path basename)
    let raw_lines = (open --raw $tf | lines)
    mut line_num = 1
    for raw_ln in $raw_lines {
      let trimmed = ($raw_ln | str trim)
      if not ($trimmed | str starts-with "%") and ($trimmed | str contains "&") {
        let no_end = ($trimmed | str replace -r '\\\\.*$' '')
        let cells = ($no_end | split row "&" | each {|c| clean-cell-text $c })
        if ($cells | length) >= 2 {
          let row_key = ($cells | get 0)
          let gt_match = ($gt_rows | where key == $row_key)
          if not ($gt_match | is-empty) {
            let gt_nums = ($gt_match | get 0.nums)
            let tex_nums = ($cells | slice 1.. | each {|c| parse-num-or-null $c } | where {|x| $x != null })
            let pair_len = ([($gt_nums | length), ($tex_nums | length)] | math min)
            for idx in 0..<$pair_len {
              let gv = ($gt_nums | get $idx)
              let pv = ($tex_nums | get $idx)
              let diff = (($pv - $gv) | math abs)
              if $diff > $tol {
                let denom = (if ($gv | math abs) > 1e-12 { ($gv | math abs) } else { 1.0 })
                let rel_pct = (100.0 * $diff / $denom)
                let sev = if $rel_pct > 5.0 { "CRITICAL" } else if $rel_pct > 1.0 { "MAJOR" } else { "MINOR" }
                $discrepancies = ($discrepancies | append {
                  file: $fname
                  line: $line_num
                  scope: $row_key
                  metric: $"Col_($idx + 1)"
                  paper_value: ($pv | into string)
                  ground_truth_value: ($gv | into string)
                  severity: $sev
                })
              }
            }
          }
        }
      }
      $line_num = $line_num + 1
    }
  }
  $discrepancies
}

# Generate a formatted audit_discrepancy_matrix.md report.
export def generate-discrepancy-matrix [
  discrepancies: list<record>
  citation_audit: record
  output_path: path
  --gt-source (-g): string = "summary_report.md"
  --tex-target (-x): string = "manuscript/"
]: nothing -> record {
  let now_str = (date now | format date "%Y-%m-%d %H:%M:%S")
  let disc_count = ($discrepancies | length)
  let hallucinated_count = ($citation_audit.hallucinated_keys? | default [] | length)
  let missing_p0_count = ($citation_audit.missing_p0_keys? | default [] | length)
  let total_issues = $disc_count + $hallucinated_count + $missing_p0_count

  let table_rows = if ($discrepancies | is-empty) {
    ["| _None_ | - | - | - | - | - | PASS |"]
  } else {
    $discrepancies | each {|d|
      $"| ($d.file) | ($d.line) | ($d.scope) | ($d.metric) | `($d.paper_value)` | `($d.ground_truth_value)` | ($d.severity) |"
    }
  }

  let h_str = if ($citation_audit.hallucinated_keys? | default [] | is-empty) { "None" } else { $citation_audit.hallucinated_keys | str join ", " }
  let p0_str = if ($citation_audit.missing_p0_keys? | default [] | is-empty) { "None" } else { $citation_audit.missing_p0_keys | str join ", " }
  let unc_str = if ($citation_audit.uncited_keys? | default [] | is-empty) { "None" } else { $citation_audit.uncited_keys | str join ", " }

  let prec_r = ($citation_audit.precision? | default 0.0 | math round --precision 4)
  let rec_r = ($citation_audit.recall? | default 0.0 | math round --precision 4)
  let f1_r = ($citation_audit.f1? | default 0.0 | math round --precision 4)

  let lines = ([
    "# Empirical Audit Discrepancy Matrix"
    $"Generated on: ($now_str)"
    $"Ground Truth Source: `($gt_source)`"
    $"Target Manuscript: `($tex_target)`"
    ""
    "## Summary of Identified Discrepancies & Inconsistencies"
    $"- **Total Discrepancies/Inconsistencies Detected:** ($total_issues)"
    $"- **Table & Numerical Discrepancies:** ($disc_count)"
    $"- **Hallucinated / Unverified Citations:** ($hallucinated_count)"
    $"- **Missing P0 Citations:** ($missing_p0_count)"
    ""
    "## Detailed Discrepancy Inventory"
    "| File | Line | Scope | Metric | Paper Value | Ground Truth Value | Severity |"
    "| :--- | :--- | :--- | :--- | :--- | :--- | :--- |"
  ] | append $table_rows | append [
    ""
    "## Citation Grounding \(Citation F1\)"
    $"- **Unique Cited Keys:** ($citation_audit.cited_count? | default 0) | **BibTeX Keys:** ($citation_audit.bib_count? | default 0)"
    $"- **Precision:** ($prec_r) | **Recall:** ($rec_r) | **F1:** ($f1_r)"
    $"- **Hallucinated Keys:** `($h_str)`"
    $"- **Missing P0 Keys:** `($p0_str)`"
    $"- **Uncited BibTeX Keys:** `($unc_str)`"
    ""
  ])

  $lines | str join "\n" | save -f $output_path
  {
    output_path: ($output_path | into string)
    total_issues: $total_issues
    pass: ($total_issues == 0)
  }
}

# CLI entrypoint to run table + citation audit and emit audit_discrepancy_matrix.md.
export def main [
  tex_dir: path
  bib_path: path
  gt_md_path: path
  output_path: path = "audit_discrepancy_matrix.md"
  --tol (-t): float = 0.01
] {
  let disc = (audit-tex-tables $tex_dir $gt_md_path --tol $tol)
  let cites = (audit-citations $tex_dir $bib_path)
  generate-discrepancy-matrix $disc $cites $output_path --gt-source ($gt_md_path | into string) --tex-target ($tex_dir | into string) | to json
}
