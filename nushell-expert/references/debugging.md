# Debugging & Static Analysis

## `nu --ide-check`

`nu --ide-check <n> file.nu` parses a script and emits JSON diagnostics with line and span information. It catches undefined variables, type mismatches, missing arguments, unknown flags, and pipeline input type errors without executing the script.

```bash
nu --ide-check 10 script.nu
```

Filter the JSON lines to diagnostics:

```nu
nu --ide-check 10 script.nu
| lines
| each { from json }
| where type == "diagnostic"
```

Run the check in a fresh process. A long-lived MCP session can be an older Nushell than the binary on `PATH`.

## `nu-check`

`nu-check file.nu` returns a boolean for a syntax check. It is the quick human-facing gate; use `--ide-check` when you need the diagnostic details.

```nu
nu-check script.nu
```

## `nu --dap`

For interactive debugging, `nu --dap` speaks the Debug Adapter Protocol over stdio. Keep a minimal `dap.nu` configuration to avoid interactive startup hooks and slow loads; see [personal.md](personal.md) for the Zed integration.

## `$env.config.status_line` (v0.117.0+)

Nushell v0.117.0 adds an optional interactive status line in the REPL. When enabled, it provides real-time diagnostics, type signature hints, and const evaluation previews directly above the prompt during interactive typing:

```nu
# Enable the interactive status line in config.nu:
$env.config.status_line = true
```

## Common Pitfalls

- `nu-check` validates syntax only; it does not perform the deeper type checks that `--ide-check` reports.
- `--ide-check` expects a file path, not a snippet passed on stdin.
- Keep paths relative to the project root so diagnostic spans stay stable.
- A parse error can suppress later diagnostics; fix the first error and re-run.
