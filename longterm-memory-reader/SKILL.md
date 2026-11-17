---
name: longterm-memory-reader
description: Handles locating and parsing Obsidian memory notes (episodic and semantic).
---

# Long-Term Memory Reader

## Overview
This skill is responsible for searching the Obsidian vault to find the memory note corresponding to the current project path, parsing its frontmatter, and reading the global `BRAIN.md` and `SOUL.md` context. It relies on the vault structures defined by the `obsidian-memory-expert` skill.

**MANDATORY:** Before executing commands related to memory retrieval, ensure the `obsidian-memory-expert` skill is active to understand the vault structure and search conventions.

### Architectural Decision: Native Nushell vs context-mode MCP
While this skill provides native Nushell helpers for fast, structured access to project metadata, the agent **MUST** leverage `context-mode` MCP tools for all data-heavy operations to protect the context window.

- **Vault Discovery**: For large-scale folder scans or searching across many project notes, use `mcp__context-mode__ctx_batch_execute` to run `ls` or `rg` in the sandbox.
- **Large File Analysis**: When reading `BRAIN.md`, `SOUL.md`, or project logs for analysis or summarization, use `mcp__context-mode__ctx_execute_file`. This ensures only the derived summary enters your conversation. **ONLY** read these files if they haven't already been read.
- **Boot Time Performance**: Use the Nushell `init-session` command (details below) for the *initial* project path resolution and context loading (it returns a clean, token-optimized Markdown string), but transition to `context-mode` for subsequent deep exploration.

## Vault Path Convention

**CRITICAL:** The vault path MUST point to the specific vault directory, NOT its parent. The `get-vault` helper returns `$env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT` or falls back to `~/workspace/obsidian/vaults`. The `AGENTS_MEMORY/` folder is expected at `<vault>/AGENTS_MEMORY/`.

## Instructions

## Logic & Workflow

### Environment load
Activate the `nushell-expert` skill if not already activated.

Always prepend this nushell instructions before any command described below:
```nu
let llms = try { $env.MY_ENV_VARS.llms_configs } catch { "~/workspace/llms_configs" } | path expand
use $"($llms)/skills/longterm-memory-reader/mod.nu"
```

### 1. `get-vault` — Resolve Vault Path
Returns the configured vault path from `$env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT` or the default fallback.
```nu
let vault = get-vault  # => "~/workspace/obsidian/vaults"
```

### 2. `get-note-path` — Compute Note File Path
Given a slug, returns the expected absolute path of the note in `AGENTS_MEMORY/`.
```nu
let p = get-note-path "my_project" --vault $vault
# => "~/workspace/obsidian/vaults/AGENTS_MEMORY/my_project/my_project.md"
```

### 3. `get-context` — Locate and Parse Long-Term Memory
Given an absolute project path, finds its `AGENTS_MEMORY` note, parses it, and loads global context.

**Usage:**
```nu
let ctx = get-context '~/my/project/path/'
$ctx | to yaml
```

**context-mode Optimization (MANDATORY for heavy loads):**
If `get-context` returns a large amount of data or if you need to analyze the history beyond the last 30 days, you MUST use the sandbox `context-mode` mcp server tool:
```json
{
  "name": "mcp__context-mode__ctx_execute_file",
  "arguments": {
    "path": "/path/to/note.md",
    "language": "shell",
    "code": "grep -A 100 '## 2026-05' note.md"
  }
}
```

**Return Record (or `null` if no note found or directory missing):**
```
{
  project_name:    string   # From frontmatter
  path:            string   # Absolute path stored in note
  description:     string   # One-sentence summary
  uses_conductor:  bool     # Whether the project uses Conductor
  uses_git:        bool     # Whether the project has a .git directory
  last_updated:    string   # YYYY-MM-DD date
  slug:            string   # Note filename without extension
  file_path:       string   # Absolute path to the note file
  recent_entries:  string   # Last ~8000 chars of body (last 30 days of activity by default)
  brain:           string   # Full contents of BRAIN.md (Use context-mode if >5000 chars)
  soul:            string   # Full contents of SOUL.md (Use context-mode if >5000 chars)
}
```

### 4. `init-session` — Session Initialization Workflow
At the start of a session, identify the current path and invoke `init-session` in Nushell to load project context and global awareness. **Note:** This command outputs a clean Markdown string instead of a structured record, specifically optimized to prevent context bloat during the mandatory session start.

**Command (run via subshell to handle dynamic module paths):**
```nu
init-session $env.PWD
```

**Handling Missing Memory:**
If `init-session` returns `"null"` (meaning no note exists OR the `AGENTS_MEMORY/` folder does not exist yet), you MUST manually initialize the long-term memory note using the guidelines in `longterm-memory-writer`.

### 5. `gather-unconsolidated-memories` — Data Gathering for Consolidation
Gathers entries from episodic memory notes since the last consolidation.

**Usage:**
```nu
gather-unconsolidated-memories --limit 10
```
Returns a table of `{project_name, last_updated, recent_body, slug}` for the most recent unconsolidated entries.

### 6. `load-trajectory-logs` — Load Trajectory Logs
Loads trajectory log entries (from `YYYY-MM-DD-log.md` files) in a project folder, capped by default to the last 30 days of activity.

**Usage:**
```nu
let logs = load-trajectory-logs 'path/to/project/folder' --days 30
```
