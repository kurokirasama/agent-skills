# Nushell MCP Server

Nushell includes a built-in MCP server, started with `nu --mcp`. It exposes shell evaluation, command discovery, and command help as tools.

## Transport

- stdio: `nu --mcp` (default since 0.110)
- HTTP: `nu --mcp --mcp-transport http` (since 0.111), port 8080 by default

```bash
nu --mcp --mcp-transport http --mcp-port 3000
```

Since 0.116 the HTTP server binds `127.0.0.1` only (source-checked). `--mcp-host` is listed in `nu --help` in 0.116.0 but rejected at runtime, so the bind address cannot be changed in that release.

## Tools

- `evaluate` — execute Nushell or shell commands and return structured output
- `list_commands` — list or search native Nushell commands
- `command_help` — show flags, types, and examples for a command

## Persistent State

Variables and environment changes persist between `evaluate` calls:

```nu
# First call
let x = 42

# Later call
$x   # 42
```

## Structured Output

Native Nushell commands return structured data. Do not pipe results to `to json` just to satisfy the tool. Since 0.114 results are emitted as NUON directly and are also exposed as MCP `structuredContent` for clients that support it.

## History

`$history` holds previous command outputs as `list<any>`:

```nu
$history.0          # first output in the buffer
$history | last     # most recent output
```

It is a ring buffer; configure its size with `$env.NU_MCP_HISTORY_LIMIT`.

`$ans` does not work in an MCP session. It is filled by the interactive REPL loop, so it stays `null` here; use `$history` instead.

## Truncation and Background Jobs

Responses larger than 10kb are truncated, but the full output remains in `$history`. Adjust the limit with:

```nu
$env.NU_MCP_OUTPUT_LIMIT = 100kb
```

A long `evaluate` call is promoted to a background job after the promote timeout (default 120 seconds) or when the client cancels it. The tool returns a job id; collect the result with `job recv`, inspect with `job list`, and stop with `job kill`. Widen the window before a known long command:

```nu
$env.NU_MCP_PROMOTE_AFTER = 10min
```

## Version Lag

The MCP server can be an older Nushell than the binary on `PATH`. For version-sensitive work, verify behavior in a fresh process:

```bash
nu -c 'version | get version'
```

Do not trust a long-lived session for command availability or new syntax.
