# Nushell Migration Guide (0.110 → 0.117)

<!-- covered-range: 0.110..0.117.0 -->

This is a curated guide for agent-written scripts. It covers the changes most likely to break or silently alter a pipeline; it is not an exhaustive changelog. Version labels use `(v0.NNN)`.

Run every example on the target binary. Items marked **source-checked** were confirmed in the Nushell source or release notes but were not re-executed here.

## Breaking Changes by Version

### 0.110

- `$nu.temp-path` → `$nu.temp-dir`; `$nu.home-path` → `$nu.home-dir`.
- `let` can terminate a pipeline: `ls | get name | let files`.
- `glob`, `mv`, `cp`, and `du` no longer match dotfiles with `*` (source-checked).

### 0.111

- `let` binds mid-pipeline without breaking the flow: `http get $url | let data | get items`.
- `pipefail` is on by default (source-checked).
- Environment variable names are case-insensitive (source-checked).

### 0.112

- `open file.md` parses Markdown into structured rows; use `open --raw` for text.
- `%name` reaches a builtin even when a custom command shadows it.
- `random dice` moved to `std/random` (source-checked).
- `to nuon --list-of-records` emits a list-of-records layout (source-checked).

### 0.113

- `parse` no longer auto-splits streams. `"a\nb" | parse "{x}"` yields one row containing `a\nb`.
- `from md` defaults to concise rows; `open --raw file.md | from md --verbose` restores the full AST.
- `kill -0` is no longer shorthand for signal 0; use `kill --signal 0 <pid>` (source-checked).
- `mkdir --verbose`, `mv --verbose`, and `rm --verbose` return structured tables.
- `to csv` / `to tsv` stream output and fail on schema drift (source-checked).
- `ls` no longer sets `source` metadata (source-checked).
- New: `idx` for fast discovery and `peek` for stream inspection.

### 0.114

- Submodules are no longer implicitly imported. Re-export them with `export use` (source-checked).
- The `catch` error record's `json` field is replaced by `details`; read `$e.details` instead of parsing `$e.json`.
- `std/iter scan` uses `--fold`: `[1 2 3] | scan --fold 0 {|x, acc| $x + $acc}` → `[0 1 3 6]`.
- `--` ends flag parsing (source-checked).
- `is-terminal` defaults to `--stdout` and detects redirection (source-checked).
- New: `union`, `intersect`, `difference`, `combinations`, `permutations`; `append` accepts multiple values (source-checked).

### 0.115

- `from yaml` / `to yaml` default to YAML 1.2. Unsupported keys and tags now error: `'true: enabled' | from yaml` fails.
- `$ans` is a reserved variable name; `let ans = 5` fails. Use another name.
- `take while` / `take until` accept `--include`; put flags before the closure.
- `scope commands` exposes `deprecation_info`; audit with `where not ($it.deprecation_info | is-empty)`.
- `update cells --recursive` and `default` fill nested fields (source-checked).
- `any` / `all` accept row conditions (source-checked).
- `commandline complete` queries Nushell's own completions (source-checked).
- `matrix` is a custom value; use `matrix map` and `matrix reduce`.

### 0.116

- Unified completers: parameter completers take `[token: record]` (`$token.text | default ""`); external completers take `$place.command` or `[place: record]`.
- `@interactive` runs terminal-owning completers on the line-editor thread.
- Record spread into named flags: `cmd ...$flags`. A `null` value omits the flag unless the parameter accepts `nothing`.
- `nu --dap` provides native DAP debugging; `tui` provides pipeline-built terminal interfaces.
- External arguments starting with `{` are parsed as records or closures. Quote literal braces: `^find . -exec cat '{}' ';'`.
- `;` is rejected in list literals and `match` list patterns (source-checked).
- `take while` / `take until`: a flag after the closure is a parse error; put it first.
- `flatten` renames a nested field that clashes with a top-level column: `[{a: 1 b: {a: 2}}] | flatten` → `{a: 1, b_a: 2}`.
- `into float` accepts a comma as the decimal separator: `"1,5" | into float` → `1.5`.
- `lines --skip-empty` works on strings and byte streams.
- `mkdir --fail-if-exists`; `save --force` creates missing parent directories (source-checked).
- `default` column arguments are cell paths (source-checked).
- `format pattern` / `parse` reject an unclosed `{` (source-checked).

### 0.117

- **Keybindings & Menus List Replacement:** Direct assignment `$env.config.keybindings = [...]` or `$env.config.menus = [...]` completely replaces built-in defaults (Tab completion, help, history navigation). Always use `++=` or explicit append to preserve interactive editing.
- **`not` Operator Precedence:** `not $a == $b` parses as `not ($a == $b)`. Previously `not` bound only to `$a`.
- **Value Negation Syntax:** `-$x` and `-(expr)` negate values instead of constructing string literals.
- **Process List Normalization (`ps`):** `ps` returns uniform columns on every platform (`pid`, `ppid`, `name`, `user`, `status`, `cpu`, `cpu_time`, `mem`).
- **`group-by --to-table` Typed Keys:** Preserves the source column name (e.g. `keycode`) instead of renaming to `group`, and preserves non-string typed values.
- **Spread Cell Paths in `get`:** `get ...$paths` accepts a list of cell paths.
- **`update cells` Rest Arguments:** Column names passed directly as rest arguments; `--columns (-c)` deprecated.
- **Dynamic Builtin Calls (`%$cmd`, `%($cmd)`):** Flag-like arguments parsed as flags; `--` separator no longer passed through.
- **Loop Piping Prohibited:** `while` and `loop` cannot be piped into downstream commands.
- **Pipeline Aliases Prohibited:** Aliases cannot contain `|` or redirections; use `def` instead.
- **Dotted Module Names:** `use a.b` creates module `a.b`.
- **Reserved Keyword `type`:** `type` is a reserved keyword for type aliases (`type Name = <type>`); commands/aliases cannot be named `type`.
- **Removed Flags/Stubs:** Removed `--ignore-errors (-i)` on `get/select/reject` (use `-o`); removed `get -s`; deleted removal stubs for `date format`, `let-env`, `fetch`, `post`, `benchmark`.
- **New Features:** Reusable type aliases (`type Name = <type>`, `export type`), `@structured` on `extern`, `record where`/`record each`/`record apply`/`record walk`, native dotenv (`from dotenv`, `to dotenv`, `open .env | load-env`, automatic `$env.ENV_CONVERSIONS`), `ansi opt`, `generate completions <tool>`, `older-than` / `newer-than`.

## Behavior Changes That Silently Alter Results

- `parse` no longer splits streams.
- `open *.md` returns structured data; `save` can write that structure instead of the source text.
- `flatten` renames clashing nested fields.
- `from yaml` is strict about YAML 1.2 keys and tags.
- `into float` treats a comma as a decimal separator.
- `to csv` / `to tsv` fail on schema drift instead of adapting.
- `glob`/`mv`/`cp`/`du` no longer match dotfiles with `*`.
- `ls` no longer sets `source` metadata.

## Still Encountered from 0.100–0.109

- Integer division returns a float: `2 / 2` → `1.0`; use `//` for integer floor division (v0.100).
- `++` is concatenation only (v0.101).
- `timeit` requires a closure: `timeit { ls }`, not `timeit (ls)` (v0.101).
- Command signatures require an input type: `def foo []: any -> string { ... }` (v0.101).
- `into value` → `detect type` (v0.108).
- `find` is case-sensitive by default (v0.107).
- `split column` uses 0-indexed names (v0.109).
- `open file.md` changed from raw text to structured Markdown (v0.112).

## New Idioms

- `let` at the end or middle of a pipeline.
- `get --optional` to preserve positions; `items` for key/value iteration.
- `scan` for stateful transforms; `window` for adjacent elements.
- `group-by ... --to-table`; `par-each --keep-order`.
- `@example`, `@category`, and `@search-terms` on exported commands.
- `%` to reach a shadowed builtin.
- `idx` for discovery; `peek` for stream inspection.
- `run` to use a script as a pipeline stage; `tui` for terminal interfaces.

## Verification Notes

- Everything not marked **source-checked** was run on Nushell 0.117.0.
- When the release notes and the source disagree, the source at the release tag wins.
- A claim you cannot run should be written with its verification status, never as plain fact.
