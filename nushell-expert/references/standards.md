# Nushell Coding Standards & Best Practices

This document establishes the authoritative coding standards for all Nushell development within this workspace.

## Core Philosophy

-   **Data > Text**: Always prefer structured data (Tables, Records, Lists) over string manipulation.
-   **Fail Fast**: Use robust error handling to halt execution immediately upon encountering invalid states.
-   **Discoverability**: Use consistent naming and thorough documentation.

## Naming Conventions

-   **Commands**: Use `kebab-case` (e.g., `get-weather-data`).
-   **Variables**: Use `snake_case` (e.g., `let user_id = 123`).
-   **Assignment Syntax**: Do NOT use parentheses when assigning the output of a command or pipeline to a variable.
    - *Idiomatic:* `let a = commands | command`
    - *Non-Idiomatic:* `let a = (commands | command)`
-   **Environment Variables**: Use `SCREAMING_SNAKE_CASE` (e.g., `$env.API_KEY_GEMINI`). Exception: `$env.MY_ENV_VARS.*` and `$env.CONSTANTS.*` in `env_vars.nu` use `snake_case` keys as a centralized path/constant registry (`| upsert linux_backup … | upsert nu_scripts …` with cross-platform `is_windows` branching).
-   **Flags**: Use `kebab-case` with single-letter aliases in parentheses (e.g., `--force(-f)`).

## Code Structure

-   **Public API**: Use `export def` for functions intended for external use.
-   **Internal Helpers**: Functions used only within a single file should not be exported.
-   **Dependencies**: Avoid using `use` statements inside function bodies.

## Pipelines & Data Handling

-   **Native Filters**: Avoid legacy tools (`grep`, `awk`, `sed`) when native filters exist (`where`, `select`).
-   **The `$in` Variable**: Use `$in` to reference the pipeline input when it is not automatically passed.
-   **Lazy Streams**: Use filters early in the pipeline to reduce memory footprint.
-   **Verbose Operations**: Prefer `-v` (verbose) flags for `mkdir`, `mv`, and `rm` to return structured tables for programmatic verification.
-   **YAML 1.2 Strictness**: Ensure structures are cleanly serializable before `to yaml`.
-   **Matrix Operations**: Use `matrix map` and `matrix reduce` for matrix manipulations.
-   **Custom Completers (v0.116.0+)**: Parameter completers MUST follow the unified `[token: record]` signature (`$token.text | default ""`). Completers that launch interactive terminal pickers (`fzf`, `input list`) MUST be annotated with `@interactive` above `def`.
-   **DAP Debugging (v0.116.0+)**: Debugging must use native `nu --dap` with a dedicated minimal `dap.nu` config to avoid interactive startup latency and hook side-effects.

## Command Choices

-   **Filtering**: Prefer `where`; avoid `filter` (deprecated) and `each { if ... } | compact`.
-   **Row conditions**: Prefer `where $it =~ ...` or `where status == 'active'`; avoid closure forms for simple predicates (`where { $in =~ ... }`).
-   **Parallel order**: Use `par-each --keep-order` when output order matters.
-   **Dispatch**: Use `match` instead of long `if`/`else if` chains.
-   **Record iteration**: Use `items {|k v| ... }` instead of extracting keys and indexing.
-   **Record operations (v0.117.0+)**: Use `record where` and `record each` instead of `transpose` roundtrips when filtering or transforming records.
-   **Type declarations (v0.117.0+)**: Use `type Name = <type>` and `export type Name = <type>` for domain types; never name commands or functions `type` (reserved keyword).
-   **Keybindings & Menus (v0.117.0+)**: Use `++=` when configuring `$env.config.keybindings` or `$env.config.menus` to preserve default interactive bindings.
-   **Structured externs (v0.117.0+)**: Use `@structured` on `extern` definitions to provide structured tables when piped.
-   **Grouping**: Use `group-by ... --to-table` instead of building groups manually. Note in v0.117.0+ the grouping column retains its source name.
-   **Line joining**: Use `str join (char nl)` instead of `to text` when joining lines.
-   **Syntax check**: Use `nu-check file.nu` (returns a boolean) instead of `source file.nu`.
-   **Membership**: Use the `in` operator instead of chained `or` comparisons.
-   **Emptiness**: Use `is-empty` / `is-not-empty` instead of `($x | length) == 0`.
-   **Field extraction**: Use `get --optional` instead of `each { $in.field? } | compact`; `each` drops nulls and loses positions.
-   **Negation**: Prefer `$x !~ ...` over `not ($x =~ ...)`.
-   **List element operations**: `$list | str trim` works directly; avoid `$list | each { str trim }` when the command accepts `list<string>`.
-   **Flags in code**: Spell flags out (`save --force`, `sort-by --reverse`, `parse --regex`); short flags are for interactive typing.
-   **Redundant `$in`**: Omit `$in |` when a pipeline command receives input directly.

## Error Handling & Auditing

-   **Defensive Programming**: Use `try`/`catch` blocks for external API calls and file system writes.
-   **User-Facing Errors**: Use the project's custom `return-error` command for consistent error reporting.
-   **Deprecation Auditing**: Use `scope commands | where not ($it.deprecation_info | is-empty)` to maintain zero deprecated command usages. (v0.115.1+: `deprecation_info` is an empty list — not null — for clean commands, so `!= null` false-positives.)
-   **Semver Comparisons**: Since v0.115.1 semver comparisons parse as `bool` and compose directly in boolean expressions; prefer direct comparison over sort-based workarounds.

## Formatting & Aesthetic

-   **Indentation**: 2 spaces. No tabs.
-   **Line Length**: 80-100 characters.
-   **Brace Spacing**: Always place spaces inside braces: `{ |it| $it + 1 }`. Single-expression closures keep the space: `{ str trim }`.
-   **Empty Blocks**: Empty branches keep a space: `} else { }` and `| if $in == null { } else { ... }`.
-   **Pipeline Spacing**: Always place spaces around the pipe: `source | filter | sink`.
-   **Pipeline Continuation**: Put `|` at the start of continuation lines, indented one level from the line that opens the pipeline. Prefer one transformation per line.
-   **Flag Spacing**: Separate a short alias from the long name with a space: `--keep-order (-k)`, not `--keep-order(-k)`.
-   **Document Flags**: Put a one-line `#` comment after a flag or parameter to populate `help`: `--all # include passing tests`.
-   **Multi-line Records**: One field per line; avoid mixing a newline with a trailing field on the opening line.
-   **Variable Declarations**: No `$` prefix on the left-hand side: `let x = ...`, not `let $x = ...`.
-   **Startup Profiling**: Use `nu-rich` to format `$nu.startup-time` in interactive configurations.