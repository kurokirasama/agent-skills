---
name: nushell-expert
description: Expert in Nushell scripting, automation, nu_plugin_polars data processing, Nushell MCP usage, testing, debugging, regex, NUON, TUI, completions, and version migration. Supports dual profiles for personal scripts and standalone projects.
---

# Nushell Expert

<!-- covered-range: 0.110..0.117.0 -->

## Overview

This skill provides specialized knowledge and workflows for interacting with the user's system using Nushell. It focuses on structured data, powerful pipelines, and project-specific architectural consistency.

**CRITICAL MANDATE:** Before writing any Nushell code or pipelines, you MUST always read the `references/` directory (specifically `standards.md`, `syntax.md`, and `migration.md`) to ensure full compliance with the established coding standards, idiomatic patterns, and version-specific behavior.

## Dynamic Profile Selection

Before providing guidance or writing code, determine the current profile based on the target path:

-   **Personal Scripts Profile**: Use when working in `~/workspace/my_scripts/nushell`. Focused on productivity, global namespace, and interactive efficiency. See [references/personal.md](references/personal.md).
-   **Standalone Projects Profile**: Use when working in complex projects like `ProjectA` or `ProjectB` (e.g., `~/cloud/Research/`). Focused on modularity, type safety, and rigorous quality gates. See [references/projects.md](references/projects.md).

## Core Workflows

1.  **Context Gathering**: Identify the current profile and gather environment context using `ls`, `ps`, `glob`, and `idx` (for fast in-memory search). Use `peek` to inspect streams without collection.
2.  **Logic Construction**: Develop pipelines that prioritize native Nushell filters (`where`, `select`, `parse`) over legacy Unix tools.
3.  **Advanced Syntax**: Use leading `|` on continuation lines, aligned with `let`. Use `Empty { }` for pass-through branches.
4.  **Verification**: Leverage structured table output from `mkdir -v`, `mv -v`, and `rm -v` to confirm operations programmatically.

## Agent Pitfalls

These are the traps agents hit most often. Each example is verified against Nushell 0.117.x.

### Bash tools escape `!`

Some Bash wrappers turn `!` into `\!`, which breaks `!=` and `!~` inside `nu -c`. Use a heredoc with a single-quoted delimiter or a temporary script:

```bash
nu -c "$(cat <<'NU'
[1 2] | where $it != 2
NU
)"
```

The same pattern works for any operator containing `!`.

### Literal parentheses in interpolation

In `$"..."`, `(` starts a subexpression. Escape a literal parenthesis as `\(`; this escape works only in double-quoted interpolation. `$'...'` cannot escape parentheses at all.

```nu
$"($header), changed \(trailing whitespace only\)"   # H, changed (trailing whitespace only)
```

If the string needs both interpolation and literal parentheses, use `$"..."`.

### `open` on Markdown is structured

Since 0.112, `open file.md` parses Markdown into structured rows. Use `--raw` when you want text:

```nu
open README.md                       # table<element, content, content_span, attributes>
open README.md --raw                 # text/byte stream
open README.md --raw | from md --verbose
```

`open file.md | save out.md` can silently write the parsed structure instead of the original text. `hide 'from md'` disables the conversion.

### Regex is fancy-regex

`=~`, `!~`, `find --regex`, `parse --regex`, `split * --regex`, and `str replace --regex` use fancy-regex, not the plain Rust regex crate. Lookahead, variable-length lookbehind, backreferences, atomic groups, and recursion work:

```nu
['# comment' 'value'] | where $it =~ '^(?!\s*#)'      # lookahead
'a:b:c' | str replace --regex '(?<=a:)b' 'B'           # lookbehind
```

The exception is `idx search --regex`, which uses the ripgrep engine and silently matches nothing for those constructs.

### Syntax checks

Use `nu --ide-check <n> file.nu` for structured diagnostics and `nu-check file.nu` for a boolean result. Run them in a fresh process:

```bash
nu --ide-check 10 script.nu
```

### 0.116 parse changes

An external argument that starts with `{` is parsed as a record or closure. Quote literal braces. In `take while` and `take until`, put flags before the closure:

```nu
^find . -exec cat '{}' ';'
[1 2 3 4 5] | take while --include 1 {|x| $x < 3 }   # [1, 2, 3]
```

### 0.117 keybindings and menus list replacement

Assigning `$env.config.keybindings = [...]` or `$env.config.menus = [...]` completely replaces built-in defaults (Tab completion, help, history navigation). Always use `++=` or explicit appends to preserve interactive defaults:

```nu
$env.config.keybindings ++= $my_bindings
$env.config.menus ++= $my_menus
```

### 0.117 `not` precedence and keyword `type`

`not $a == $b` parses as `not ($a == $b)` (previously bound only to `$a`).
`type` is now a reserved parser keyword for type aliases (`type Name = <type>`). Never name commands or aliases `type`.

### User Config Shadowing Builtins

When the user's `config.nu` wildcard-imports `std/assert` or other modules, builtin commands like `length`, `each`, `where` can be shadowed, causing `nu::parser::missing_positional` errors inside `standard-nushell_evaluate`. For clean module invocations (especially in skills that `use` mod.nu files), always use:
```nu
nu --no-config-file --no-std-lib -c "use path/to/mod.nu *; your-command"
```
This bypasses user config entirely and prevents stdlib shadowing. Document this in trajectory logs as a known pitfall so future sessions don't rediscover it.

## Nushell Migration Specialist

Audit and refactor codebases for compatibility and optimization following a Nushell version update.

1.  **Critical Review**: Read the release highlights. Identify breaking changes, deprecations, and new features.
2.  **Live Verification**: Use the `help` command or `command_help` tool for any suspicious or new commands.
3.  **Empirical Prototyping**: Before proposing a change, test the pattern using the `evaluate` tool.
4.  **Impact Audit**: Search the codebase for identified high-risk patterns.
5.  **Refactoring**: 
    -   Replace external system calls with native Nushell equivalents (e.g., `idx` for `find`).
    -   Update pipelines to use new error handling logic (`complete`, `try/catch`) and stream inspection (`peek`).
    -   Adopt new syntax sugar (spread operator, new closure syntax).
    -   **0.113.0 Updates**: Prioritize `idx` for file discovery and `peek` for stream debugging. Replace text-parsing of `mkdir/mv/rm` output with structured table filtering.
    -   **0.115.0 Updates**: Enforce YAML 1.2 strictness in serialization (`to yaml`). Use `matrix map` / `matrix reduce` for matrix transformations. Use `$ans.last` for REPL answer debugging with `$env.config.max_last_result_size`. Use `scope commands` deprecation metadata to audit deprecated syntax. Use `--no-watch` with `idx init` when filesystem watching is unneeded.
    -   **0.115.1 Updates**: Semver comparisons parse as `bool` in boolean contexts (`or`/`and`, `let`, `bool` params) — replace sort-based version workarounds with direct comparison. Audit deprecations with `where not ($it.deprecation_info | is-empty)` (empty list ≠ null now). Use `HelixChangeMode` events paired with `ViChangeMode` inside `until` lists for unified vi/helix bindings. When overriding default keybindings by name, filter against a list of name strings (record-list filters never match and leave shared-name duplicates). `update col { ... }` works on lazy SQLite tables. `$ans.last` survives type errors on itself. Verify new-version behavior with a fresh `nu -c` subprocess — the nushell MCP evaluate session can lag behind an upgrade.
    -   **0.116.0 Updates**: Unified custom completers model: parameter completers take `[token: record]` (query in `$token.text | default ""`); external completers take `$place.command` or `[place: record]`. Terminal-owning completers (e.g. `fzf`, `input list`) MUST use `@interactive` attribute above `def` to run on the line-editor thread with TTY ownership instead of the background worker thread (`background-completions` experimental option removed). Record spread into named flags (`cmd ...$flags`) with null value omission semantics. Native DAP debugging via `nu --dap` over stdio with minimal `dap.nu` and Zed IDE integration. Native TUI framework (`tui run`, `tui split`, etc.). Accurate startup time profiling via `$nu.startup-time` and `nu-rich`.
    -   **0.117.0 Updates**: Direct assignment `$env.config.keybindings = [...]` or `$env.config.menus = [...]` replaces all defaults — use `++=`. Reusable type aliases (`type Name = <type>`, `export type`). `type` is a reserved parser keyword. Direct record operations (`record where`, `record each`, `record apply`) replace `transpose` roundtrips. `@structured` on `extern` supplies structured tables when piped. Native dotenv (`open .env | load-env`, automatic `$env.ENV_CONVERSIONS`). `group-by --to-table` retains the grouping column's original name. Standard `not` operator precedence (`not ($a == $b)`). `update cells` rest arguments syntax.
    -   **Full migration reference**: See [references/migration.md](references/migration.md) for the curated 0.110–0.117 changes and verification labels.

## Advanced References

-   **Syntax & Patterns**: String interpolation, flag handling, pipeline patterns, and module structure. See [references/syntax.md](references/syntax.md).
-   **Coding Standards**: Naming, formatting, command choices, and error handling. See [references/standards.md](references/standards.md).
-   **Canonical Examples**: End-to-end typed commands, data pipelines, error handling, and tests. See [references/example_reference.md](references/example_reference.md).
-   **Testing**: `std/testing`, `@example`, assertions, snapshots, coverage, and CI. See [references/testing.md](references/testing.md).
-   **Debugging**: `nu --ide-check`, diagnostics, and `nu-check`. See [references/debugging.md](references/debugging.md).
-   **Regex**: fancy-regex capabilities and exceptions. See [references/regex.md](references/regex.md).
-   **Migration**: Curated breaking changes and new idioms for 0.110–0.117. See [references/migration.md](references/migration.md).
-   **NUON**: Nushell Object Notation. See [references/nuon.md](references/nuon.md).
-   **MCP**: Nushell MCP server, tools, and persistent state. See [references/mcp.md](references/mcp.md).
-   **TUI**: Terminal interfaces with the `tui` command family. See [references/tui.md](references/tui.md).
-   **Completions**: Custom completers, attributes, and menus. See [references/completions.md](references/completions.md).
-   **Polars Data Processing**: DataFrames, LazyFrames, expressions, and Parquet/CSV pipelines. See [references/polars.md](references/polars.md).

## Data Processing with Polars (`nu_plugin_polars`)

Leverage `nu_plugin_polars` for memory-efficient and multithreaded data processing on large tabular datasets:

1.  **Ingestion & I/O**: Use `polars open` to stream Parquet, CSV, JSON, and Arrow directly, or convert native tables using `polars into-df`.
2.  **Lazy Evaluation**: Convert DataFrames to LazyFrames with `polars into-lazy` to benefit from query optimization, predicate pushdown, and vectorized execution.
3.  **Modern Selectors & Expressions**: Use `polars col` for column transforms and `polars selector` subcommands (`polars selector numeric`, `polars selector string`) for dynamic schema projection.
4.  **Reshaping & Aggregations**: Use `polars group-by` paired with `polars agg`, and `polars unpivot` for reshaping wide tables into long format.
5.  **Execution**: Materialize query results by collecting them with `polars collect`.

For full patterns, code recipes, and the decision matrix, see [references/polars.md](references/polars.md).

## Errors and Alternatives

If you can't run the nushell mcp tools, or if they aren't available, use the shell command:
`nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c '<nushell_command>'`

**Always confirm the command success and inform the user of any persistent failures.**

## Credits

Knowledge in this skill was informed by the `nushell-prophet/nushell-skills` marketplace, which declares no license. All prose here is independently written, and every example was verified against Nushell 0.117.0 unless labeled otherwise.
