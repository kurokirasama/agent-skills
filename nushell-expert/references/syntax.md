# Nushell Syntax & Advanced Patterns

This reference provides detailed information on Nushell syntax, string interpolation, flag handling, and advanced functional patterns.

## Pipeline Continuity & Layout

-   **Leading Pipes**: On continuation lines, always start with the `|` symbol. Align it with the preceding `let` or the start of the expression.
-   **Continuations**: Avoid backslashes for line breaks; use the pipeline or open braces to signal continuation.

```nu
let results = ls **/*.md
    | where size > 1kb
    | sort-by modified
```

## Functional Patterns

-   **Pass-Through Branches**: Use `Empty { }` for branches that should not transform data (e.g., in a conditional transform).
    ```nu
    $data | if $cond { } else { transform }
    ```
-   **Explicit Filtering**: Use `where` for filtering instead of `each { if ... } | compact`.
-   **Type Dispatch**: Use `match` for clean type dispatching.
-   **Stateful Transforms**: Use `scan` for stateful data processing across a stream.

### Closure Parameters

Use `$in` for a single operation; use a named parameter when the closure has multiple operations or references the value more than twice.

```nu
$data | each { str trim }                  # single operation
$data | each {|row| $row.a + $row.b }      # multiple references
```

### Data-First Filtering

Build the data first, then filter with `where`; avoid spread-with-conditionals.

```nu
[
    [--env-config $nu.env-path]
    [--config $nu.config-path]
]
| where {|i| $i.1 | path exists }
| flatten
```

### Conditional Append

Start empty and append conditionally; an empty `{ }` passes through.

```nu
[]
| if $cond1 { append [a b] } else { }
| if $cond2 { append [c d] } else { }
```

## Data Access Patterns

### `get --optional`

`get --optional` preserves positions by returning `null` for missing fields.

```nu
$rows | get content --optional        # [null, "result", null]
$rows | get input.file_path --optional
```

Avoid `each { $in.field? } | compact`, which drops nulls and loses positions.

### Row Conditions

For simple predicates, use `where` row conditions with `$it`:

```nu
$lines | where $it =~ '(?i)error'
$rows | where status == 'active'
$rows | where ($it.path | path exists)
```

A pipe in the condition needs parentheses. Keep a closure for a predicate stored in a variable.

### Record Iteration

Use `items` to iterate key/value pairs:

```nu
$record | items {|k v| {key: $k value: $v} }
```

### Cell Paths as Values

Cell paths are first-class values. Use `$.a.b`, `split cell-path`, and `into cell-path` to build or inspect paths safely:

```nu
let loose = $.a.b | split cell-path | update optional true | into cell-path
{} | get $loose        # null
```

## Type Signatures

Mandatory type signatures for all public commands. Use the format `[ input ]: nothing -> output { ... }`.

```nu
# Calculate file stats.
export def get-file-stats []: nothing -> table {
    ls | select name size modified
}
```

### Optional Returns and Attributes

Declare `oneof<T, nothing>` for a value-or-null return. Use `@example`, `@category`, and `@search-terms` on exported commands:

```nu
@category math
@search-terms 'multiply' 'scale'
@example 'double five' { 5 | double } --result 10
export def double []: int -> int { $in * 2 }
```

## Modules & Scripts

-   When a file is named after its command (e.g., `greet.nu`), the exported command must be named `main`, not `greet`.
-   Script mode (`nu script.nu sub`) strips `main`; module mode (`use script.nu; script main sub`) keeps it. Prefer script mode when in doubt.
-   Define subcommands as `export def 'main sub' [] { ... }` and keep an entry point `export def main [] { }`.
-   Since 0.115, a command name cannot be a parser keyword (`def def` fails). Builtins remain shadowable; use `%name` to call the builtin from a shadowing module.
-   Use `%` at the call site to reach a shadowed builtin: `%update file { ... }`.

## String Interpolation

Use `$"...(expr)..."` syntax. Variables/expressions must be in parentheses inside `$"..."` strings.

```nu
# GOOD - use $"..." with parentheses around expressions
let name = "world"; echo $"hello ($name)"       # Prints: hello world
ls $"($env.HOME)/Documents"                     # Expands path correctly
cargo build $"--jobs=(sys cpu | length)"        # Dynamic flag value
```

## Command-line Flags with Variables

When building flags that include variable values, the entire flag must be an interpolated string.

```nu
# GOOD - entire flag as interpolated string
mysql $"-p($env.DATABASE_PASSWORD)" mydb        # Password correctly embedded
curl -H $"Authorization: Bearer ($token)"       # Header with variable
```

## String Types

| Format | Syntax | Escapes | Use Case |
|--------|--------|---------|----------|
| Single-quoted | `'hello'` | None | Simple strings, Windows paths |
| Double-quoted | `"hello\n"` | `\n \t \" \\` etc. | Strings needing escape sequences |
| Raw string | `r#'hello'#` | None | Strings with `'` or `"`, multi-line |
| Bare word | `hello` | None | Command arguments (word chars only) |
| Backtick | `` `hello world` `` | None | Paths/args with spaces, globs |
| Interpolated | `$"($var)"` | Depends on quotes | Embedding variables/expressions |

## ANSI Escape Codes

Use `ansi strip` to remove ANSI color/formatting codes from output. Do NOT use `\u001b` or similar unicode escapes.

```nu
# GOOD - use ansi strip to remove ANSI codes
$output | ansi strip                         # Removes all ANSI escape sequences
^rg pattern | ansi strip                     # Strip colors from external command output
```

## Stderr Redirection

Use `o+e>` or `out+err>` instead of bash-style `2>&1`.

```nu
# GOOD - nushell redirection syntax
command o+e>| other_command                     # Redirect stderr to stdout, pipe
command o+e>| ignore                            # Discard both stdout and stderr
```

## Parallel Iteration

Prefer `par-each` over `each` for better performance on large lists.

```nu
# GOOD - parallel processing
ls **/*.rs | par-each { |f| wc -l $f.name }
```

## Advanced Discovery & Inspection (v0.113.0+)

### Fast Indexing with `idx`
Use `idx` for high-speed file discovery without repeated disk scanning.

```nu
# GOOD - fast indexing
idx init . --wait                            # Initialize index for current dir
idx find config --files                      # Find files matching 'config'
idx search --regex 'def\s+main'              # Content search across files
```

### Stream Inspection with `peek`
Inspect streams without collecting or consuming them.

```nu
# GOOD - stream inspection
1..100 | peek 5 | where $it > 50            # Sample 5 items from the stream
```

## REPL & Matrix Features (v0.115.0+)

### REPL Answer Variable `$ans`
Access the last pipeline output, execution duration, and command string.

```nu
# Enable caching up to 10MB in config.nu:
$env.config.max_last_result_size = 10mb

# Inspect previous result
$ans.last                                    # Output of last command
$ans.duration                                # Execution duration
$ans.exit_code                               # Exit status code
```

Since v0.115.1, invalid operations on `$ans.last` (e.g. `$ans.last | str length` on a table) no longer clobber `.last` or break later `$ans` display; `.exit_code`, `.duration`, `.command` still update for the failed line.

### Keybindings with Helix Support (v0.115.1+)
Pair `ViChangeMode` and `HelixChangeMode` in an `until` list — a mode event is inapplicable in the other editor's state machine:

```nu
$env.config.keybindings ++= [
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
]
```

### Matrix Iteration
Always use `matrix map` and `matrix reduce` when working with matrix data structures.

```nu
# GOOD - native matrix operations
$matrix | matrix map { |x| $x * 2 }
$matrix | matrix reduce --fold 0 { |acc, x| $acc + $x }
```

## Language Modernization & Completions (v0.116.0+)

### Record Spread into Named Flags
Records can now be spread directly into command flags using `...`:

```nu
# GOOD - flag spreading
let opts = { recursive: true, max-depth: 3 }
find-files ...$opts
```

### Null Handling in Command Flags
- Passing `null` as a flag argument completely omits the flag if the target parameter type does not accept `nothing`.
- If the target parameter explicitly accepts `nothing` (e.g. `opt?: string`), `null` is passed through.

### Unified Custom Completers
Parameter completers take a unified token record `[token: record]` where `$token.text` contains the prefix:

```nu
# GOOD - custom completer
def complete-tags [token: record] {
    let prefix = $token.text | default ""
    ["tag1", "tag2", "tag3"] | where { $in | str starts-with $prefix }
}
```

### Terminal-Owning Completers (`@interactive`)
Completers invoking interactive terminal pickers (`fzf`, `input list`) MUST be annotated with `@interactive` so they run on the line-editor thread with direct TTY access instead of on the background completion worker:

```nu
# GOOD - interactive completer
@interactive
def pick-file [token: record] {
    ls | get name | to text | ^fzf --query $token.text | lines
}
```

## Language Modernization & Built-ins (v0.117.0+)

### Reusable Type Aliases
Declare reusable type aliases using the `type` keyword:

```nu
# GOOD - reusable type definitions
type Coordinate = record<x: float, y: float>
type UserId = int
export type Status = string

def plot-point [pt: Coordinate] { ... }
```
- **Reserved Keyword:** Because `type` is a parser keyword, commands, subcommands, or aliases must NEVER be named `type`.

### Structured External Commands (`@structured`)
External commands can decode structured tables when piped downstream:

```nu
# GOOD - structured external output
@structured [--porcelain] { lines | parse -r '^(?<status>..) (?<file>.+)$' }
extern "git status" []

# Piped execution returns structured table; direct terminal call streams raw output
git status | where status == "M "
```

### Direct Record Manipulation
Avoid verbose `transpose` roundtrips; use native `record` commands:

```nu
# Filtering fields
{a: 10, b: 25, c: 5} | record where value > 20
$env | record where key in ["SSH_CLIENT", "SSH_TTY"]

# Transforming fields
{host: "localhost", port: 8080} | record each {|k, v| {($k | str uppercase): $v}}
```

### Native Dotenv Support
Load `.env` files directly into the environment:

```nu
# Open and load dotenv
open .env | load-env
```
- Variables defined in `.env` automatically trigger registered `$env.ENV_CONVERSIONS` on `load-env` or `with-env`.

### `not` Operator Precedence
`not` has standard precedence: `not $a == $b` parses as `not ($a == $b)`. Explicit parentheses remain recommended for clarity.