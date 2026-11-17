# Testing Nushell Scripts

Two approaches work: a dependency-free runner for small modules, and `nutest` for larger suites. Use the first unless you need discovery, parallelism, or snapshot helpers.

## Dependency-Free Tests

Write a normal script that imports `std/assert` and calls each test from `main`:

```nu
# tests/test_normalize.nu
use std/assert

def test-normalize-name [] {
    assert (('  Alice  ' | normalize-name) == 'alice')
}

def test-normalize-empty [] {
    assert (('' | normalize-name) == '')
}

def main [] {
    test-normalize-name
    test-normalize-empty
    print 'ok'
}
```

Run it with `nu tests/test_normalize.nu`. A failing assertion exits non-zero, so this works in CI without any runner.

## Assertions

This build exposes the universal `assert <condition> (message)` command. Use a boolean expression for equality; `assert equal ...` is not available in every std version.

Import the module without `*`. The wildcard also brings in assert subcommands such as `length`, which shadow builtins and break ordinary pipelines.

```nu
use std/assert

assert (($result) == 'expected')
assert (($result | length) == 3)

assert ($result | str starts-with '# => ')
assert ($result =~ 'pattern')
assert ($result !~ 'unwanted')

assert ('item' not-in $list)
assert ($filtered | is-empty)

assert ($errors | is-empty) 'should have no errors'
```

## Optional: `nutest`

`nutest` adds test discovery, setup/teardown hooks, and parallel execution. It is not installed by default; install it separately if the suite outgrows the manual runner.

```nu
# tests/test_commands.nu
use std/assert
use std/testing *

@test
def 'command-name handles a specific case' [] {
    let result = 'input' | command-name
    assert (($result) == 'expected')
}

@before-each
def setup [] {
    let temp = mktemp --directory
    {temp: $temp}
}

@after-each
def cleanup [] {
    let context = $in
    rm --recursive $context.temp
}

@test
def 'suite files with the default glob' [] {
    let temp = $in.temp
    touch ($temp | path join 'test_foo.nu')
    assert ((ls $temp | length) == 1)
}
```

Run with `nutest run-tests --path tests/ --returns table`. A test file must `use std/testing *`; without it, the first `@test` is an unknown command.

### Test names are prose

`nutest` re-parses test names. Use letters, digits, spaces, and hyphens only. Apostrophes, backticks, quotes, parentheses, brackets, pipes, and `#` can take down every test in the file. Rewrite possessives and contractions: `the signer's key` → `the key of the signer`, `doesn't` → `does not`.

### Setup context comes through the pipeline

```nu
@test
def 'reads the fixture context' [] {
    let context = $in   # from @before-each
    assert (($context.temp | path type) == 'dir')
}
```

`@before-each` output is piped into the test; it is not returned by calling `setup`.

## `@example` Attributes

`@example` is built into Nushell and needs no import. Use it to document commands with executable examples:

```nu
@example 'double five' { 5 | double } --result 10
export def double []: int -> int { $in * 2 }
```

## Snapshot and Integration Tests

Compare a stable rendering of the output:

```nu
use std/assert

def test-report-shape [] {
    let actual = [{name: 'a' count: 1}] | to nuon
    assert (($actual) == '[[name, count]; [a, 1]]')
}
```

For command output, normalize first (`ansi strip`, `str trim`, `to nuon`) so the assertion does not depend on terminal width or colors.

## Coverage

There is no built-in coverage tool. Track it with a simple inventory:

```nu
let exported = scope commands | where {|c| $c.name | str starts-with 'my-module '} | get name
let tested = open --raw tests/test_module.nu | lines | where {|l| $l =~ '^def test-'}
{
    exported: ($exported | length)
    tested: ($tested | length)
}
```

For a small module, a checklist of exported commands and one test per command is enough.

## CI

```yaml
# .github/workflows/test.yml
- name: Test
  run: |
    for file in tests/test_*.nu; do
      nu "$file"
    done
```

Use `nu -c` with a heredoc when the command contains `!` and the CI wrapper escapes it:

```bash
nu -c "$(cat <<'NU'
[1 2] | where $it != 2
NU
)"
```

## Common Pitfalls

- A missing `@test` annotation means `nutest` never discovers the test.
- Test names with punctuation can break the whole suite file.
- `@before-each` context arrives by pipeline (`$in`), not by calling `setup`.
- Shared state needs serial execution; pass `--strategy {threads: 1}` to `nutest` or avoid shared files.
- Run examples in a fresh process; the MCP evaluate session can lag behind an upgrade.
