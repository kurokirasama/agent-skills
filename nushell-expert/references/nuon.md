# NUON (Nushell Object Notation)

NUON is Nushell's native data format. It is valid Nushell data syntax and supports most Nushell types that JSON cannot represent.

## Type Coverage

| Feature | JSON | NUON |
|---|---|---|
| Strings | `"text"` | `"text"` or `'text'` |
| Numbers | `123`, `1.5` | `123`, `1.5`, `0xff`, `0o755`, `0b1010` |
| Booleans | `true` / `false` | same |
| Null | `null` | same |
| Lists | `[1, 2, 3]` | `[1 2 3]` (commas optional) |
| Records | `{"a": 1}` | `{a: 1}` |
| Dates | — | `2024-01-15T10:30:00Z` |
| Durations | — | `5min`, `2hr`, `100ms` |
| File sizes | — | `64mb`, `512kb`, `2gib` |
| Binary | — | `0x[DEADBEEF]` |
| Ranges | — | `1..5`, `0..<10` |
| Comments | — | `# comment` |
| Closures / blocks | — | not supported |

NUON cannot serialize closures or blocks. Use `to nuon --serialize` to render a closure as its source string; it deserializes as a string, not a closure.

Nearly all JSON is valid NUON, with two exceptions that `from nuon` rejects: duplicate keys and `\uXXXX` escapes (NUON uses `\u{41}`). Parse those with `from json`.

## Converting

```nu
# Convert to and from NUON
{name: 'test' count: 42} | to nuon
'{name: test, count: 42}' | from nuon

# Indentation
$data | to nuon --pretty          # 0.114+: shorthand for --indent 2
$data | to nuon --indent 4
$data | to nuon --tabs 1
$data | to nuon --raw             # same as --indent 0
```

`to nuon` writes durations in nanoseconds and file sizes in bytes. A hand-written `30sec` round-trips as `30000000000ns`; the type survives, the spelling and comments do not.

## Common Patterns

### Configuration Files

```nu
# config.nuon
{
    timeout: 30sec
    max_size: 10mb
    ports: [8080 8443]
    debug: false
    # Comments are allowed
    created: 2024-01-15T00:00:00Z
}
```

```nu
let config = open config.nuon
$config.timeout      # 30sec, a duration value
```

### Inline Data

```nu
const endpoints = [
    {host: 'api.example.com' port: 443 timeout: 10sec}
    {host: 'backup.example.com' port: 443 timeout: 30sec}
]
```

### Serialization

```nu
$results | to nuon | save results.nuon
open results.nuon | where status == 'passed'
```

### Validation

```nu
def is-valid-nuon []: string -> bool {
    try {
        $in | from nuon | ignore
        true
    } catch {
        false
    }
}
```

## Tables

```nu
# Compact table syntax
[
    [name age];
    ['Alice' 30]
    ['Bob' 25]
]

# List of records
[
    {name: 'Alice' age: 30}
    {name: 'Bob' age: 25}
]
```

With an indentation flag, `to nuon` aligns table columns (0.114+).

## NUON vs JSON

Use NUON when the workflow is Nushell-only, you need durations/sizes/dates, the file is a Nushell config, or a human edits it.

Use JSON when another tool consumes the data, an API requires it, or the format is a cross-language exchange.

## Common Commands

```nu
open file.nuon              # parse by extension
$data | save file.nuon      # serialize by extension
$data | to nuon             # string
'...' | from nuon           # parse
$data | to nuon --pretty    # readable
```
