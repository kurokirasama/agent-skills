# Custom Completions

## Quick Reference

- `string@[a b c]` — inline static list (0.108+)
- `string@$const_list` — const variable (0.108+)
- `string@completer` — custom completer command
- `@complete completer` — command-wide completer (0.108+)
- `@complete external` — send the command to the external completer (0.108+)
- `@interactive` — the completer owns the terminal (0.116+)
- `commandline complete` — reuse Nushell's own suggestions (0.114+); `--input` shows what a completer receives (0.116+)

## Inline Completions

```nu
def go [direction: string@[left up right down]] { $direction }

const directions = [left up right down]
def go2 [direction: string@$directions] { $direction }
```

## Completer Inputs (0.116+)

A completer names the positional parameters it reads. Three names are recognized, in any order, each optional:

- `token: record` — the word at the cursor: `text`, `kind` (`head`, `flag`, `value`), `span`.
- `place: record` — `cursor`, `target`, `kind`, `index`, `flag`, `shape`, and `command` (the command at the cursor as shell words).
- `buffer: string` — the whole line up to the cursor.

```nu
'git checkout mai' | commandline complete --input
# => {token: {text: mai, ...}, place: {command: [git, checkout, mai], ...}, buffer: "git checkout mai"}
```

The head is one item even when it has spaces. For a bare external, `git checkout mai` is `[git, checkout, mai]`; once `extern "git checkout"` exists, it becomes `["git checkout", mai]`.

### Deprecated Inputs

The old `context`/`pos`/`spans` parameters still work but emit a deprecation warning. Migrate:

- `[context: string]` → `[place: record]`, read `$place.command`
- `pos: int` → `$place.cursor`
- `[spans: list<string>]` → `[place: record]`
- menu `{|buffer, position| ...}` → `{|buffer, place| ...}`

## Custom Completers

```nu
def "nu-complete git remotes" [] {
    git remote | lines
}

def "nu-complete git branches" [place: record] {
    let remote = $place.command | get 1?
    if $remote in (git remote | lines) {
        git branch --remotes --format='%(refname:short)' | lines
        | where { str starts-with $remote }
    } else {
        git branch --format='%(refname:short)' | lines
    }
}

def my-cmd [
    remote: string@"nu-complete git remotes"
    branch: string@"nu-complete git branches"
] { }
```

One completer can serve several slots by branching on `place.kind` and `place.flag`. Return nothing to decline a slot.

## Command-Wide Completers

```nu
@complete "nu-complete my-cmd"
def my-cmd [--profile: string, target?: string] { ... }
```

`@complete external` hands the whole command to `$env.config.completions.external.completer`.

## Interactive Completers (0.116+)

Completers run on a background worker. A completer that needs the terminal (`input list`, `fzf`) must carry `@interactive`; it then runs on the line-editor thread.

```nu
@interactive
def "nu-complete pick-file" [token: record] {
    ls | get name | input list --fuzzy
}

def open-file [path: string@"nu-complete pick-file"] { open $path }
```

Interactive results are not cached. `commandline complete` refuses to run an interactive completer outside the REPL; test it with `--input`.

## External Completer

```nu
$env.config.completions.external.completer = {|place|
    let head = $place.command.0 | split row ' '
    let rest = $place.command | skip 1
    let argv = $head ++ $rest
    carapace $argv.0 nushell ...$argv | from json
}
```

Return `null` to decline and let file completion answer; return `{completions: [...], fallback: true}` to show file completion beneath your list.

## Menus (0.116+)

```nu
$env.config.menus ++= [{
    name: words_menu
    only_buffer_difference: false
    marker: "? "
    type: {layout: list, page_size: 10}
    style: {}
    source: {|token| [one two three] | where { str starts-with $token.text } }
}]
```

## Testing with `commandline complete`

```nu
# What a completer would receive at this spot
'git checkout mai' | commandline complete --input

# All suggestions as records
'%ls --al' | commandline complete --detailed

# One built-in source: directory, path, glob, command, variable, env-var
'./a' | commandline complete --type directory
```

`--input` cannot be combined with `--detailed` or `--type`. With `--type`, pipe the token text, not the whole line.

## Generating Completions (`generate completions`, v0.117.0+)

Nushell v0.117.0 introduces native completion generators from external definitions:

```nu
# Generate Nushell extern definitions and completers:
generate completions <tool>
```
- Supports sourcing flags and arguments from carapace, fish, zsh, man pages, or `--help`.

## Custom Completer Options & Algorithms (v0.117.0+)

Custom completers returning an `options` record should use `completion_algorithm`:
- Supported algorithms: `"prefix"` (default), `"substring"`, `"fuzzy"`.
- **Note:** The legacy `positional: false` option key has been removed in v0.117.0 and must not be included.

```nu
def my-completer [token: record] {
    {
        completions: ["app-prod", "app-stage", "app-dev"],
        options: {
            completion_algorithm: "substring"
        }
    }
}
```

## Best Practices

1. Prefer inline lists for small static options.
2. Use `const` for reusable static lists.
3. Name completers `nu-complete <command> <what>`.
4. Keep completers private; export only the command.
5. Declare only the inputs you read.
6. Return `[]` to suppress completions and `null` to fall back to files.
7. Test from a script with `commandline complete`.
