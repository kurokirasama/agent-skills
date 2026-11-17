---
name: cron-conductor-monitor
description: Monitors Conductor projects for pending work and outputs a bulleted Markdown summary to stdout.
---

# cron-conductor-monitor

Monitors `conductor` projects for pending tracks and todos, generating a detailed Markdown summary for each project. Uses a pre-computed JSON project list (`conductor_projects.json`) derived from trusted workspaces instead of filesystem globbing.

## Logic & Workflow

This skill relies on a set of robust Nushell scripts located in `skills/cron-conductor-monitor/scripts/` to handle the heavy lifting of discovery and status parsing.

1.  **Monitor Execution:**
    - Execute the `monitor.nu` script using the `evaluate` tool from the `standard-nushell` MCP server.
    - Run the script against the pre-computed project list:
      ```nu
      nu ~/workspace/llms_configs/skills/cron-conductor-monitor/scripts/monitor.nu --json-file ~/workspace/llms_configs/skills/cron-conductor-monitor/scripts/conductor_projects.json --report
      ```
    - The `--report` flag automatically formats the output as Markdown and outputs it to `stdout`.
      > **FLAW-10 fix — Prerequisites for `--report`:** This flag ensures structured reporting.
      > For debugging, combine with `--dry_run` to preview the report markdown.
    - **Legacy fallback:** If `--json-file` is not provided, the `--root` flag enables glob-based discovery.

2.  **Project List Maintenance:**
    - `conductor_projects.json` is generated from trusted workspaces in `~/workspace/Backups/linux/settings_antigravity.json`.
    - Only paths containing a `conductor/` directory are included.
    - To regenerate: run the extraction pipeline or re-run `conductor-implement` Phase 1 Task 1.

## Instructions

- You are a specialized assistant for the `cron-conductor-monitor` skill.
- **Action:**
    - You do NOT need to manually parse `tracks.md` or `todos.md`. 
    - Simply run the `monitor.nu` script with `--json-file` and `--report` as shown in the Workflow.
- **Nushell Mandate**: Ensure the `nushell-expert` skill is active before executing any Nushell command or pipeline.
- **Nushell output analysis**: After running the `monitor.nu` script, analyze the output and craft a high-level report. The report MUST have a section for each conductor enabled project, and inside each section, a list of pending tracks or todos, and a brief one sentence description.
- **Error Handling**: If the script execution fails, capture the error and report it via `stdout`.

## Output Format (MANDATORY)

- Use bullet-point lists for ALL items. NEVER use tables, raw JSON, or prose paragraphs.
- Output directly to stdout as plain markdown. Do NOT wrap in JSON envelopes.
- Format tracks as: `- [Status] Title`
- Format todos as: `- [ ] Todo description`

**PROHIBITED:**
- Markdown tables (`| --- |`)
- Raw JSON (`{"key": "value"}`)
- Horizontal rules (`---`, `***`, `___`)

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.
