# Canonical Examples

End-to-end patterns that combine the rules in this skill.

## Typed Command with Attributes

```nu
# Count rows per status and return a table.
@category data
@example 'summarize two rows' {
    [{status: done} {status: open}] | summarize-status
} --result '[[status, count]; [done, 1], [open, 1]]'
export def summarize-status []: table -> table {
    group-by status --to-table
    | each {|group| {status: $group.status, count: ($group.items | length)}}
}
```

## Data Pipeline

```nu
export def active-users [path: path]: nothing -> table {
    open $path
    | where status == 'active'
    | get name email --optional
    | where {|row| $row.email | is-not-empty }
}
```

- `where` uses a row condition for the simple comparison and a closure for the piped check.
- `get --optional` preserves positions when a field is missing.

## Safe Error Handling

```nu
export def read-config [path: path]: nothing -> record {
    if not ($path | path exists) {
        error make {msg: $"missing config: ($path)"}
    }
    try {
        open $path
    } catch {|err|
        error make {msg: $"invalid config: ($err.msg)"}
    }
}
```

## Test

```nu
use std/assert

def test-summarize-status [] {
    let actual = [{status: done} {status: open}] | summarize-status
    assert (($actual | get 0.count) == 1)
}

def main [] {
    test-summarize-status
    print 'ok'
}
```

## Script Entry Point

```nu
export def main [] { }

export def 'main build' [--release] {
    if $release { print 'release' } else { print 'debug' }
}
```

Run as `nu script.nu build --release`. In module mode, call `script main build --release`.
