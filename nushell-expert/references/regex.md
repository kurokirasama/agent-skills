# Regex: fancy-regex

Nushell's regex engine is [`fancy-regex`](https://docs.rs/fancy-regex), not the plain Rust `regex` crate. Simple patterns are delegated to `regex`; the backtracking engine is used only for the extra features.

## Features You Can Use

- Lookahead: `(?=...)`, `(?!...)`
- Lookbehind: `(?<=...)`, `(?<!...)`, including variable-length lookbehind
- Backreferences: `\1`, `\k<name>`
- Atomic groups: `(?>...)`
- Recursion: `(?R)`

```nu
# Drop comment lines without `not (...)`
['# comment' 'value'] | where $it =~ '^(?!\s*#)'

# Replace only the second field with a lookbehind
'a:b:c' | str replace --regex '(?<=a:)b' 'B'

# Collapse a doubled word with a backreference
'word word' | str replace --regex '\b(\w+)\s+\1\b' '$1'
```

## Where It Applies

`=~`, `!~`, `find --regex`, `parse --regex`, `split * --regex`, `str contains --regex`, and `str replace --regex` all use fancy-regex.

## Exception

`idx search --regex` delegates to the ripgrep engine. Lookaround and backreferences silently match nothing there.

## Cost

The backtracking engine is slower than the plain `regex` crate. Prefer simple patterns on large inputs, and pre-filter with `where` before applying an expensive expression.
