---

## Longterm Memory System

The Longterm Memory System is a multi-tiered architecture designed to provide LLM agents with persistent context across sessions. It consists of:
- **Episodic Memory**: Project-specific logs stored in `AGENTS_MEMORY/[project-slug]/` in the Obsidian vault. The `[project-slug]` MUST be the same name as the project folder (e.g., for `/home/username/workspace/llms_configs`, use `AGENTS_MEMORY/llms_configs/`). These logs contain dated entries of decisions, milestones, and task summaries.
- **Semantic & Identity Memory**: Global files (`BRAIN.md` and `SOUL.md`) that store high-level facts, active project summaries, and the agent's core identity and personality within `AGENTS_MEMORY/` in the Obsidian vault.
- **Orchestration**: A coordination layer (`longterm-memory-orchestrator`) that defines the system objectives and triggers specialized sub-skills for reading and writing.

**MANDATORY PRE-TASK PROTOCOL:** At the beginning of every session, BEFORE proceeding with any user tasks, the agent MUST load project context and global awareness. Follow the instructions in the `longterm-memory-reader` skill (invoking `init-session`) and internalize the contents of `BRAIN.md` and `SOUL.md`. This ensures continuity of identity and high-level project awareness.

### Skill Quick Reference
- `longterm-memory-orchestrator`: High-level orchestrator that defines system objectives and activation triggers for specialized sub-skills.
- `longterm-memory-reader`: Handles all memory retrieval, searching, and parsing operations, including session initialization and consolidation data gathering.
- `longterm-memory-writer`: Handles all memory persistence and setup operations, including manual updates, note initialization, and global context updates.
- `conductor-core-protocols`: Defines mandatory operational guidelines, including Nushell-first usage, mandatory pre-task memory retrieval, and Discord notification sequencing.
- `cron-conductor-monitor`: Autonomously monitors Conductor projects for pending work and high-level project state, outputting structured status summaries.
- `initialize-conductor`: Standardizes the setup and update of Conductor framework guidelines and project-specific documentation tracks.
- `initialize-course`: Automates and standardizes the setup of Conductor-managed workspaces for university course repositories.
- `initialize-research`: Scaffolds LaTeX-based research projects, including reports and articles, from predefined project templates.
- `initialize-thesis-folder`: Specialized initializer for WORK SUBJECT thesis projects, integrating Audit & Guide workflows.
- `session-retro`: Analyzes session transcripts to identify new issues and key insights, generating retrospective notes with two-way memory linking.
- `obsidian-memory-expert`: Expert for managing long-term memory via the Obsidian CLI, specializing in retrieving insights and project-specific metadata.


# context-mode — MANDATORY routing rules

You have context-mode MCP tools available. These rules are NOT optional — they protect your context window from flooding. A single unrouted command can dump 56 KB into context and waste the entire session.

## BLOCKED commands — do NOT attempt these

### curl / wget — BLOCKED
Any shell command containing `curl` or `wget` will be intercepted and blocked. Do NOT retry.
Instead use:
- `mcp__context-mode__ctx_fetch_and_index(url, source)` to fetch and index web pages
- `mcp__context-mode__ctx_execute(language: "javascript", code: "const r = await fetch(...)")` to run HTTP calls in sandbox

### Inline HTTP — BLOCKED
Any shell command containing `fetch('http`, `requests.get(`, `requests.post(`, `http.get(`, or `http.request(` will be intercepted and blocked. Do NOT retry with shell.
Instead use:
- `mcp__context-mode__ctx_execute(language, code)` to run HTTP calls in sandbox — only stdout enters context

### WebFetch / web browsing — BLOCKED
Direct web fetching is blocked. Use the sandbox equivalent.
Instead use:
- `mcp__context-mode__ctx_fetch_and_index(url, source)` then `mcp__context-mode__ctx_search(queries)` to query the indexed content

## REDIRECTED tools — use sandbox equivalents

### Shell (>20 lines output)
Shell is ONLY for: `git`, `mkdir`, `rm`, `mv`, `cd`, `ls`, `npm install`, `pip install`, and other short-output commands.
For everything else, use:
- `mcp__context-mode__ctx_batch_execute(commands, queries)` — run multiple commands + search in ONE call
- `mcp__context-mode__ctx_execute(language: "shell", code: "...")` — run in sandbox, only stdout enters context

### read_file (for analysis)
If you are reading a file to **edit** it → read_file is correct (edit needs content in context).
If you are reading to **analyze, explore, or summarize** → use `mcp__context-mode__ctx_execute_file(path, language, code)` instead. Only your printed summary enters context.

### grep / search (large results)
Search results can flood context. Use `mcp__context-mode__ctx_execute(language: "shell", code: "grep ...")` to run searches in sandbox. Only your printed summary enters context.

## Tool selection hierarchy

1. **GATHER**: `mcp__context-mode__ctx_batch_execute(commands, queries)` — Primary tool. Runs all commands, auto-indexes output, returns search results. ONE call replaces 30+ individual calls.
2. **FOLLOW-UP**: `mcp__context-mode__ctx_search(queries: ["q1", "q2", ...])` — Query indexed content. Pass ALL questions as array in ONE call.
3. **PROCESSING**: `mcp__context-mode__ctx_execute(language, code)` | `mcp__context-mode__ctx_execute_file(path, language, code)` — Sandbox execution. Only stdout enters context.
4. **WEB**: `mcp__context-mode__ctx_fetch_and_index(url, source)` then `mcp__context-mode__ctx_search(queries)` — Fetch, chunk, index, query. Raw HTML never enters context.
5. **INDEX**: `mcp__context-mode__ctx_index(content, source)` — Store content in FTS5 knowledge base for later search.

## Output constraints

- Keep responses under 500 words.
- Write artifacts (code, configs, PRDs) to FILES — never return them as inline text. Return only: file path + 1-line description.
- When indexing content, use descriptive source labels so others can `search(source: "label")` later.

## ctx commands

| Command | Action |
|---------|--------|
| `ctx stats` | Call the `stats` MCP tool and display the full output verbatim |
| `ctx doctor` | Call the `doctor` MCP tool, run the returned shell command, display as checklist |
| `ctx upgrade` | Call the `upgrade` MCP tool, run the returned shell command, display as checklist |
