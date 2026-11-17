# Nushell Coding Style Guide

## Overview
This document defines the coding standards and conventions for the project. It aligns with official Nushell best practices while respecting established local patterns.

## Naming Conventions

### Commands & Functions
- **Case:** Use `kebab-case` for all command names.
    - *Good:* `chatpdf-add`, `get-weather`
    - *Bad:* `chatpdf_add`, `getWeather`
- **Subcommands:** Use quoted strings with spaces to define subcommands directly.
    - *Pattern:* `export def "parent child" [] { ... }`
    - *Example:* `export def "t start" [] { ... }`
- **Aliases:** Keep them short and memorable, but use them sparingly for public interfaces.
    - *Example:* `alias gmn = google-ai`

### Variables & Parameters
- **Case:** Use `snake_case` for local variables and parameters.
    - *Good:* `$user_id`, `$file_path`
    - *Bad:* `$userId`, `$FilePath`
- **Environment Variables:** Use `SCREAMING_SNAKE_CASE` for global environment variables.
    - *Example:* `$env.MY_ENV_VARS`

### Flags
- **Case:** Use `kebab-case` for flag names.
- **Short Flags:** Always provide a single-letter alias.

## Code Structure & Modules

### Exports
- Use `export def` for all functions intended to be used outside the module.
- Private helper functions (not exported) should be defined at the bottom of the file or prefixed with `_`.

### Sourcing & Master Loader (`all.nu`)
- The project uses a modular master loader ([`all.nu`](file:///home/username/workspace/my_scripts/nushell/all.nu)) organized into domain submodules (`modules/core.nu`, `modules/system.nu`, `modules/ai.nu`, `modules/tools.nu`) to bring all scripts into the global namespace with sub-second parsing efficiency.
- **Relative Path Resolution:** Sourced files and domain submodules within `all.nu` use relative paths (`./modules/<domain>.nu`), which Nushell resolves relative to `all.nu`'s file location, ensuring reliable loading regardless of the user's current working directory.
- **Modular Topology:** All domain loaders export their modules (`export use ../<script>.nu *`) so functions remain globally accessible while parser AST scope is isolated per submodule to prevent $O(N^2)$ compilation slowdowns.
- **Top-Level Non-Blocking Standard:** Scripts must never execute blocking operations (synchronous network calls like `http get`, un-cached GPG decryptions, or heavy recursive directory scans) at file load time. Credentials must use RAM-disk caching (`/dev/shm/.nu_creds_cache_*.json` with 0600 mode) or lazy retrieval.
- **Strict Rule:** `use` statements for project-internal modules are **forbidden** inside non-test scripts. Symbols are expected to be available globally via the modular registry strategy.
- **Exceptions:**
    - `use` is allowed (and often required) in test scripts (`tests/*.nu`).
    - `use` for external libraries (such as `std`, `std-rfc`, and `nu-rich`) is encapsulated inside `all.nu`.
    - Temporary usage for debugging is permitted but must be removed before completion.
- **Bootstrap Management (`update-nu-config`):** Configuration files in `$nu.config-path` should never be manually appended with 60+ individual file paths. Instead, use `update-nu-config` to generate the standardized bootstrap block:
    ```nu
    source ~/.cache/carapace/init.nu
    source-env /path/to/my_scripts/nushell/env_vars.nu
    use /path/to/my_scripts/nushell/all.nu *
    source-env /path/to/my_scripts/nushell/config.nu
    ```
- **`evaluate` Tool Context:** Note that when using the Nushell `evaluate` tool, all scripts in the workspace are already loaded (not recursively), so exported commands are available without explicit `source` or `use` in the eval string.

## Pipelines & Data Handling

### Structured Data First
- **Avoid Text Parsing:** Do not use `grep`, `awk`, or `sed` if a native Nushell filter (`where`, `select`, `parse`, `split`) can do the job.
    - *Bad:* `ls | to text | grep "json"`
    - *Good:* `ls | where name =~ "json"`
- **Return Types:** Functions should return structured data (Table, List, Record) to ensure composability.

### Pure Nushell First & Safe Plugin / External Tool Guidelines
- **Pure Nushell Priority:** Always prioritize native Nushell parsing and manipulation (`parse -r`, `split row`, `lines`, `where`, `find`, `get -o`). Pure Nushell executes in-memory, eliminates external process invocation overhead, and maintains cross-machine portability.
- **Safe Plugin Usage (`query web`, etc.):** Commands from external plugins (e.g. `query web` from `nu_plugin_query`) require compile-time plugin registration. They must never be used in a way that breaks cold shell startup (`nu -n`, subshells, or minimal environments where `plugin.msgpackz` is not yet loaded). Prefer native regex/string extraction for HTML/XML parsing; if `query web` is used for complex DOM hierarchies, ensure fallback handling so module import remains clean.
- **Python as a Strict Last Resort:** Only invoke external Python helpers (`python3 -c`) when a task is fundamentally impossible with native Nushell or supported plugins. Never default to Python for routine data, table, string, or HTML parsing tasks.

### File Handling & Breaking Changes
- **`open` on Markdown:** Since Nushell v0.112.1, `open` on `.md` files returns a structured AST. If you need the raw text content (e.g., for string concatenation or passing to an LLM), you **MUST** use `open --raw`.
    - *Idiomatic:* `let content = open --raw prompt.md`
    - *Non-Idiomatic:* `let content = open prompt.md` (will fail if string behavior is expected)

### Function Calls & Parentheses
- **Modern Syntax:** In current and future versions of Nushell, parentheses are unnecessary for function calls with arguments unless needed for precedence or when passing the result of a subexpression as an argument.
- **Variable Assignments:** Do NOT use parentheses when assigning the output of a command or pipeline to a variable (`let`, `mut`, `const`) unless required for multi-line expression grouping (like boolean logic with `or`/`and`) or precedence.
    - *Good:* `let a = ls | length`
    - *Avoid:* `let a = (ls | length)`
    - *Multi-line Example:*
        ```nu
        let a = command
            | command 2
            | command 3
        ```

### The `$in` Variable
- Use `$in` explicitly when piping to commands that expect specific input placement.
- *Example:* `echo "text" | some-cmd $in`

## Error Handling

### User-Facing Errors
- Use the custom `return-error` command for all expected failure states. This ensures consistent formatting (red text) and exit behavior.
    - *Pattern:* `if $condition { return-error "Meaningful message" }`

### System Errors
- Use `try` / `catch` blocks for operations involving external I/O (network, filesystem) that might fail unpredictably.
    - *Pattern:*
        ```nu
        try {
            http get $url
        } catch {
            return-error "Failed to reach server"
        }
        ```

## Documentation

### Docstrings
- Every `export def` **MUST** have a comment block immediately preceding it.
- **Format:**
    1.  **Summary:** One-line description.
    2.  **Parameters:** Brief explanation of complex parameters.
    3.  **Example:** A usage example if non-obvious.

### Comments
- Focus on *why*, not *what*.
- Comments explaining a workaround or specific logic choice are highly encouraged.

## formatting
- **Indentation:** 2 or 4 spaces (be consistent within the file).
- **Spacing:**
    - Space after `|`: `ls | where ...`
    - Space inside `{`: `{ || ... }`

## Breaking Changes & Gotchas

These are real issues discovered in practice. Always check this section before debugging mysterious parse errors.

### 1. `get -i` → `get -o` (deprecated in v0.106.0)

The `--ignore-errors` short flag was renamed to `--optional`.

```nu
# Bad (deprecated, will be removed)
$data | get -i some.nested.key

# Good
$data | get -o some.nested.key
```

### 2. `str upcase` → `str uppercase` (deprecated in v0.114.0)

```nu
# Bad
"hello" | str upcase

# Good
"hello" | str uppercase
```

### 3. Negative numbers after `default` must be parenthesized

Nushell parses `-1` after `default` as a flag, not a number. Always wrap negative literals in `()`.

```nu
# Bad — parser error: "The `default` command doesn't have flag `-1`"
$list | get 0?.index? | default -1

# Good
$list | get 0?.index? | default (-1)
```

This applies to any command that accepts a flag followed by a number: if the number is negative, use parens.

### 4. Single quotes inside `$"..."` string interpolation break the parser

When a variable interpolation `($var)` is adjacent to a single-quoted substring `'...'` inside a `$"..."` string, the parser mis-identifies the closing `'` as the end of a subexpression and fails with "Invalid characters after closing delimiter" or "Unexpected end of code".

```nu
# Bad — parser breaks on the '($action)' pattern
let cmd = $"setupAgenticToolkit('($action)')"

# Good — use string concatenation instead
let cmd = "setupAgenticToolkit('" + $action + "')"
```

This is a known Nushell parser limitation. When you need to embed a variable inside single-quoted text within a double-quoted interpolated string, always switch to `+` concatenation.

### 5. YAML 1.2 Strict Serialization (v0.115.0+)

`from yaml` defaults to YAML 1.2 and supports multi-document streams. `to yaml` strictly rejects non-round-trippable types such as closures or unsupported AST nodes. Always sanitize records before converting to YAML:

```nu
# Good — clean serializable data
let payload = { name: "agent", timeout: 30sec }
$payload | to yaml
```

### 6. Matrix Iterator Operations (v0.115.0+)

Standard list iterators (`each`, `par-each`, `reduce`) fail when given matrix structures. Use native matrix operations:

```nu
# Good
$mat | matrix map { |x| $x * 2 }
$mat | matrix reduce --fold 0 { |acc, x| $acc + $x }
```

### 7. Programmatic Deprecation Audits

Use `scope commands` deprecation metadata to inspect or enforce zero deprecated usages in scripts:

```nu
# v0.115.1+ idiom — deprecation_info is an EMPTY LIST (not null) for clean commands,
# so `!= null` false-positives on every command.
scope commands | where not ($it.deprecation_info | is-empty) | select name deprecation_info
```

### 8. CLI Formatting & Visualization (`nu-rich` as Default)

Use `nu-rich` commands as the default standard for all terminal feedback, section dividers, and summaries:

- **Section Dividers & Headers:** Use `rich rule "<Title>" --style "bold cyan"` instead of raw `echo-g "==> Step ..."` or `print "--- ... ---"`.
- **Status & Completion Reports:** Use `rich panel` (`"message" | rich panel --title "<Title>" --box rounded --border-style green/yellow/red`) for command completion summaries, status cards, and important notifications.
- **Itemized Logs & Status Checkmarks:** Use `rich print` with inline markup syntax (`[bold green]✓[/]`, `[bold red]✗ Error:[/]`, `[cyan]...[/]`, `[bold]...[/]`).
- **Data Inspection:** Use `rich table` for styled table outputs and `rich pretty` for complex JSON/records.
- **Graceful Fallback Pattern:** When adding rich formatting to scripts that might run in headless/minimal environments, wrap rich calls with `try { rich ... } catch { fallback }` to ensure zero disruption.
- **Parser Precedence Rule:** In string interpolations with literal parentheses adjacent to subexpressions, use `+` concatenation or `\(` escaping to prevent parser misinterpretation (e.g. `" (v" + $ver + ")"` instead of `$" (v($ver))"`).

### 9. Helix Keybinding Support (v0.115.1+)

Use `HelixChangeMode` for Helix editor mode switching. Combine with `ViChangeMode` in an `until` list for unified bindings — a mode event is inapplicable in the other editor's state machine:

```nu
{
    name: leave_insert_mode
    modifier: control
    keycode: char_g
    mode: [vi_insert helix_insert]
    event: { until: [
        { send: ViChangeMode, mode: normal }
        { send: HelixChangeMode, mode: normal }
    ] }
}
```

### 10. Keybinding Shared-Name Warning & Merge Filter (v0.115.1+)

Nushell now warns when two keybindings share a name. When replacing default bindings (e.g. `completion_menu`), filter against the **names list** (strings), never the record list — string-vs-record comparison silently matches nothing and leaves duplicate defaults in place:

```nu
# Good — filters default completion_menu/ide_completion_menu out before append
$env.config.keybindings = $env.config.keybindings | where name not-in $new_keybinds_names | append $new_keybinds

# Bad — records list, filter is always false, defaults stay → shared-name warning
$env.config.keybindings = $env.config.keybindings | where name not-in $new_keybinds | append $new_keybinds
```

Also fixed in 0.115.1: mode spellings `emacs` and `[emacs]` match when merging, and `$env.config.keybindings = []` clears the list again.

### 11. Semver Comparisons Return Bool in Boolean Contexts (v0.115.1+)

Semver (and other custom-value) comparisons now parse as `bool`, so they compose directly with `or`/`and`, `let` bindings, and `bool` parameters. No sort-based workarounds:

```nu
# Good — direct comparison
let outdated = ('0.9.0' | into semver) < ('1.0.0' | into semver)
(which tool | is-empty) or ((tool --version | into semver) < ('1.0.0' | into semver))

# Bad (legacy workaround) — sorting to compare versions
let sorted = [($v1 | into semver), ($v2 | into semver)] | sort | each { into string }
```

### 12. `$ans` Resilience After Errors on `$ans.last` (v0.115.1+)

Invalid operations on `$ans.last` no longer clobber `$ans.last` or break later `$ans` display; `$ans.exit_code`, `$ans.duration`, `$ans.command` still update for the failed line.

### 13. SQLite `update` Closures on Lazy Tables (v0.115.1+)

`update col { ... }` now works on tables taken from an opened SQLite database (`open foo.db | get my_table | update expiry { into datetime }`) — previously reported a missing column.

### 14. Terminal-Owning Completers & `@interactive` (v0.116.0+)

The legacy `background-completions` experimental option has been removed in v0.116.0. Completers that need to drive interactive terminal pickers (such as `fzf`, `input list`, or interactive menus) must use the `@interactive` attribute above their `def` command declaration. This tells Nushell to execute the completer on the line-editor thread with exclusive access to stdin/TTY, rather than on the background completion worker:

```nu
@interactive
def pick-file [token: record] {
    ls | get name | to text | ^fzf --query $token.text | lines
}

def open-file [path: string@pick-file] { open $path }
```

### 15. Unified Custom Completions Model (v0.116.0+)

In v0.116.0 (#18791), custom parameter completers are unified:
- Parameter completers migrate from the legacy `[line: string, pos: int]` signature to `[token: record]` (extracting query via `$token.text | default ""`).
- External completers and menu sources receive `$place.command` or `[place: record]` instead of raw positional spans.
- Example pattern:
```nu
def "__z_complete" [token: record] {
    let prefix = $token.text | default ""
    let data = try { ^zoxide query $prefix --list | lines } catch { [] }
    {
        completions: $data,
        options: {
            completion_algorithm: "fuzzy",
            positional: false
        }
    }
}
```

### 16. Record Spread into Named Flags & Null Semantics (v0.116.0+)

Records can now be spread directly into command flags using the `...` spread operator:
```nu
let flags = { verbose: true, max-depth: 2 }
my-cmd ...$flags
```
- **Null handling in flags:** Passing `null` as a flag value omits the flag entirely if the command parameter type does not accept `nothing`. If the parameter accepts `nothing`, `null` is passed through.

### 17. Native DAP Debugging & Zed Integration (v0.116.0+)

Nushell v0.116.0 (#18738) includes a native Debug Adapter Protocol (DAP) server via `nu --dap` over stdio:
- Supports breakpoints, step-in, step-over, call stack inspection, variables, and watch expressions.
- Configured via a minimal `dap.nu` in the repository root to avoid interactive startup overhead.
- Registered in Zed editor via `~/.config/zed/settings.json` under `"dap"` and `.zed/debug.json` / `~/.config/zed/debug.json` for launch configuration:
```nu
nu --config dap.nu --dap
```