---
name: cron-software-updates
description: Automates software update management across machines — reads Gmail inbox for update notifications, installs updates on the current machine via apps-update, and creates Habitica tasks for pending updates on other machines.
---

# cron-software-updates

Autonomous cron skill for distributed software update management across 3 machines via Gmail notification processing, apps-update CLI integration, and Habitica task orchestration.

## Machines & Labels

| Machine | Habitica Label |
|---|---|
| workstation | software-updates-workstation |
| desktop | software-updates-desktop |
| laptop | software-updates-laptop |

## Nushell Execution Protocol

**CRITICAL: All Nushell commands MUST be executed via the `standard-nushell_evaluate` MCP tool.**

Use the `evaluate` tool with the `input` parameter set to the Nushell code shown in each step's code block.

**Fallback (only if the `evaluate` tool is unavailable):**
```
nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c '<nushell_code>'
```

**CRITICAL: Never use the `to-discord` nushell command. Do not send any Discord notifications.**

**ALWAYS activate the `nushell-expert` skill before the first Nushell command.**

## Logic & Workflow

### Step 0: Identify Current Machine
Execute via `evaluate` tool:
```nu
sys host | get hostname
```
Map the hostname to the corresponding Habitica label using the table above. Derive the other-machine labels from the mapping.

### Step 1: Email Processing (Agent-Driven)
1. Use the Google Workspace MCP tools to search Gmail for unread software update notification emails
2. Filter out pre-release notifications only (check subject and body for keywords: "pre-release", "prerelease")
3. Extract the software name from each email
4. Create `/home/username/workspace/llms_configs/skills/cron-software-updates/email_software.json` (replace if exists) with an array of objects:
   ```json
   [
     {
       "mail_id": "<gmail_message_id>",
       "todos_id": "",
       "name": "<software_name>",
       "installed": false,
       "update_command": ""
     }
   ]
   ```
5. Mark all processed emails as read

### Step 2: Command Discovery
1. Execute via `evaluate` tool to list update-able software:
   ```nu
   help commands | find -n apps-update | select name description 
   ```
2. Special Handling for `design.md` updates:
   If any entry in `email_software.json` is for the `design.md` repository (application name `design.md`):
   - Immediately execute the `update-design-md` skill. Provide the changelog context from the email body.
   - If the skill indicates `link-skills` succeeded:
     - Create 2 Habitica tasks: `link-skills <machine-name>` for the other two machines.
       ```nu
       h add todos --text "link-skills <other_machine_1>" --notes "" --priority 1 --due "" --checklist [] --tag-name ["<other_machine_label_1>"]
       h add todos --text "link-skills <other_machine_2>" --notes "" --priority 1 --due "" --checklist [] --tag-name ["<other_machine_label_2>"]
       ```
   - If the skill indicates `link-skills` failed:
     - Write the failure details to `errors.json` under name `design.md`.
     - Create 1 Habitica task: `link-skills <current_machine>` for the current machine.
       ```nu
       h add todos --text "link-skills <current_machine>" --notes "link-skills failed on <current_machine> during update-design-md" --priority 1 --due "" --checklist [] --tag-name ["<current_machine_label>"]
       ```
   - Remove the `design.md` entry from `email_software.json` and proceed.
3. Filter `email_software.json`:
   - **Nushell & Plugins Total Exclusion:** Unconditionally remove any entry where application name matches `nushell` (e.g., `nushell`, `nushell-plugins`, `nushell-plugins-external`) or whose update command matches `apps-update nushell*`. Nushell upgrades require architectural evaluation and must be handled exclusively via the `nushell-update-evaluator` skill.
   - Remove any entry whose application name is NOT found in the output of the previous command.
   To match an application from `email_software.json` with an `apps-update` command, follow this strict precedence hierarchy:
   - **1. Exact Sub-name Match:** Check if the application name exactly matches the command sub-name (the part after `apps-update `), case-insensitively (e.g., `mermaid-ascii` matches `apps-update mermaid-ascii`).
   - **2. Known Alias / Equivalence:** Treat `language-server` or `language server` as equivalent to `lsp` (and vice-versa) when matching (e.g., `MATLAB-language-server` matches `apps-update matlab-lsp`), and treat `gemini-notebook-mcp-cli`, `gemini-notebook-mcp`, or `notebooklm-mcp-cli` as equivalent to `notebooklm-mcp` (matching `apps-update notebooklm-mcp`).
   - **3. Command Sub-name Substring Match:**
     - Check if the command sub-name is a case-insensitive substring of the application name (e.g., `claude` in `claude-code` matches `apps-update claude`).
     - OR check if the application name is a case-insensitive substring of the command sub-name (e.g., `codex` in `open-codex` matches `apps-update open-codex`).
     - When multiple commands match by substring, pick the longest / most specific command sub-name match (e.g., `mermaid-ascii` over `mermaid-cli`).
   - **4. Guarded Description Match (Fallback Only):** If no command sub-name matches, check if the application name matches a whole word/token in the description (ignoring common stopwords like `"update"`). Description matching MUST NOT override any command sub-name match.
4. For remaining entries, populate the `update_command` field with the corresponding command from the output
5. Save back to `email_software.json`

### Step 3: Habitica Pending Updates
1. Execute via `evaluate` tool to query Habitica todos for the current machine label:
   ```nu
   h ls todos | select _id text tags label_name | flatten | find $current_machine_label
   ```
2. Separate any todo whose `text` is exactly `link-skills` (case-insensitive) from the rest. These are skill-linking tasks queued by another machine's cron run (see Step 7 science-skills exception) and have no `apps-update` command.
3. If `link-skills` todos exist, create `/home/username/workspace/llms_configs/skills/cron-software-updates/link_skills.json` with an array of objects:
   ```json
   [
     {
       "todos_id": "<habitica_todo_id>",
       "text": "link-skills"
     }
   ]
   ```
4. If pending updates exist (non-`link-skills` todos), create `/home/username/workspace/llms_configs/skills/cron-software-updates/habitica_pending.json` (same schema as email_software.json, with `todos_id` populated from the `_id` field, `mail_id` empty string, `update_command` extracted from the todo `text`). `link-skills` todos and any Nushell update todos (`text =~ "(?i)nushell"`) MUST NOT be written to `habitica_pending.json`.
5. Deduplicate: if a software name appears in both `email_software.json` and `habitica_pending.json`, keep the email entry but populate its `todos_id` from the habitica entry, then remove the duplicate from `habitica_pending.json`

### Step 3.5: Link Skills Execution
1. If `/home/username/workspace/llms_configs/skills/cron-software-updates/link_skills.json` does not exist or is an empty array, skip this step.
2. Execute via `evaluate` tool:
   ```nu
   link-skills
   ```
3. On success, mark all `link-skills` todos as complete via `evaluate` tool:
   ```nu
   let ids = (open /home/username/workspace/llms_configs/skills/cron-software-updates/link_skills.json | get todos_id)
   h complete-todos --ids $ids
   ```
4. On failure, write the failure details to `/home/username/workspace/llms_configs/skills/cron-software-updates/errors.json` under name `link-skills`. Do NOT create a failure todo here — Step 9 will create it from the `errors.json` entry (single source of truth).

### Step 4: Sudo Filtering
1. Execute via `evaluate` tool to identify sudo-requiring software:
   ```nu
   help commands | find apps-update | where category == sudo | get name | ansi strip
   ```
2. Remove sudo-requiring entries from `email_software.json`. For each removed entry, add a `source` field with value `"email"` and write it to `/home/username/workspace/llms_configs/skills/cron-software-updates/sudo.json`
3. Remove sudo-requiring entries from `habitica_pending.json`. For each removed entry, add a `source` field with value `"habitica"` and write it to `sudo.json`
4. The `source` field records where each sudo entry originated (`"email"` or `"habitica"`) and drives task creation behavior in Step 8

### Step 5: Installation Set Assembly
1. Merge `email_software.json` and `habitica_pending.json` into `/home/username/workspace/llms_configs/skills/cron-software-updates/this_machine.json`, ensuring any Nushell or Nushell-plugin entry is excluded.
2. For each entry, execute via `evaluate` tool to check if the software binary exists on PATH:
   - Check `which <name> | length`.
   - If that returns 0, check the binary name extracted from the `update_command` (e.g. for `apps-update agy` check `which agy | length`, for `apps-update claude` check `which claude | length`, for `apps-update obsidian` check `which obsidian | length`).
   - If length > 0, the binary exists and `installed` is true.
3. Remove entries for software NOT installed on this machine.
4. Deduplicate the final list (prefer entries with populated `todos_id`).

### Step 6: Update Installation
1. Execute the helper script via `evaluate` tool:
   ```nu
   $env.NU_MCP_PROMOTE_AFTER = "15min"
   nu /home/username/workspace/llms_configs/skills/cron-software-updates/scripts/execute-updates.nu
   ```
   This iterates over `this_machine.json`, runs each `update_command`, and automatically writes any failures to `errors.json` (or writes `[]` if all succeed).
2. For successfully updated entries that came from Habitica (have a non-empty `todos_id`), execute via `evaluate` tool to mark the todo as completed:
   ```nu
   h complete-todos --ids [$todos_id]
   ```

### Step 7: Habitica Tasks for Other Machines
For each entry in `email_software.json`, create 2 Habitica todos (one per other machine) via `evaluate` tool using simple sequential calls or a clean `for` loop:
```nu
for label in ["<other_machine_label_1>", "<other_machine_label_2>"] {
  h add todos --text "<update_command>" --notes "" --priority 1 --due "" --checklist [] --tag-name [$label]
}
```

**Science-skills Exception:** For entries where the software is `science-skills` (i.e., `name == "science-skills"`, case-insensitive), create the Habitica todos for other machines with text `link-skills` (plain, no machine name) and the standard per-machine tags. The other machines do NOT run `apps-update science-skills` from these todos; they run `link-skills` (which the cron flow picks up and executes, see Step 3.5). The current machine still updates `science-skills` locally via `apps-update science-skills` in Step 6, which performs the linking itself:
```nu
for label in ["<other_machine_label_1>", "<other_machine_label_2>"] {
  h add todos --text "link-skills" --notes "" --priority 1 --due "" --checklist [] --tag-name [$label]
}
```

**Nushell & Plugins Total Skip:** For entries where the software is `nushell` or any Nushell plugin (i.e., `name =~ "(?i)nushell"` or `update_command =~ "(?i)apps-update nushell"`), completely skip Habitica task creation. Do NOT call `h add todos` for any machine. Nushell updates and language migrations are handled exclusively via the `nushell-update-evaluator` skill.

### Step 8: Habitica Tasks for Sudo Items
For each entry in `sudo.json`, create Habitica todos via `evaluate` tool:
- **If `source == "email"`**: Create 3 Habitica todos (one per machine):
  ```nu
  for label in ["software-updates-workstation", "software-updates-desktop", "software-updates-laptop"] {
    h add todos --text "<update_command>" --notes "requires sudo so run manually" --priority 1 --due "" --checklist [] --tag-name [$label]
  }
  ```
- **If `source == "habitica"`**: Skip task creation entirely (the task already exists in Habitica for the current machine).

### Step 9: Error Reporting
Safely check for errors and create Habitica failure tasks if needed:
```nu
let errors_path = "/home/username/workspace/llms_configs/skills/cron-software-updates/errors.json"
let errors = if ($errors_path | path exists) { open $errors_path } else { [] }
for err in $errors {
  h add todos --text $"failed to update ($err.name) in <current_machine>" --notes ($err.error) --priority 1 --due "" --checklist [] --tag-name ["<current_machine_label>"]
}
```

### Step 10: Clean Duplicate JSON Copies
Clean up duplicate JSON copy files left by file-sync conflicts (e.g., `email_software (3).json`, `habitica_pending (3).json`, `sudo (2).json`). Execute via `evaluate` tool:
```nu
ls /home/username/workspace/llms_configs/skills/cron-software-updates/*.json | where name =~ ' \(\d+\)\.json$' | get name | par-each { |f| rm $f }
```
Only files matching the ` (N).json` pattern (a space, digits, `.json` extension) are removed. The canonical state files (`email_software.json`, `habitica_pending.json`, `link_skills.json`, `this_machine.json`, `sudo.json`, `errors.json`) are never touched.

## Instructions

You are a specialized autonomous software update manager. Your responsibilities are:
- Process software update notifications from Gmail
- Discover and execute update commands via apps-update
- Orchestrate cross-machine update tasks via Habitica

**CRITICAL: Always activate the `nushell-expert` skill before executing any Nushell commands.**
**CRITICAL: All Nushell commands MUST be executed via the `standard-nushell_evaluate` MCP tool (or the fallback described in the Nushell Execution Protocol above).**

**Constraints:**
- Never install pre-release software (alpha and beta versions are acceptable if already installed)
- Never run sudo commands — those must be queued as manual Habitica tasks
- Individual update failures must not halt the entire pipeline
- Do not create duplicate Habitica todos (check existing before creating)

**JSON state files:**
- `email_software.json` — software updates discovered from email
- `habitica_pending.json` — pending updates found in Habitica
- `link_skills.json` — `link-skills` todos found in Habitica for the current machine (entries carry `todos_id` and `text`)
- `this_machine.json` — final installation set for the current machine
- `sudo.json` — updates requiring manual sudo execution (entries carry a `source` field: `"email"` or `"habitica"`)
  ```json
  [
    {
      "mail_id": "<gmail_message_id or empty>",
      "todos_id": "<habitica_todo_id or empty>",
      "name": "<software_name>",
      "installed": false,
      "update_command": "<update_command>",
      "source": "email"
    }
  ]
  ```
- `errors.json` — failed update records

All state files live in `/home/username/workspace/llms_configs/skills/cron-software-updates/`.

## Output Format (MANDATORY)

Output a bullet-point Markdown summary to stdout covering:
- Current machine and label
- Number of emails processed
- Number of software updates discovered
- Sudo-requiring software count
- Updates installed (with exit codes), listing each installed app name
- Link-skills todos found and executed (completed or failed)
- Errors encountered, listing each failed app name and reason
- Habitica tasks created for other machines
- Total Habitica tasks created
- Duplicate JSON copies cleaned

**PROHIBITED:**
- Do NOT use horizontal rules (`---`) in output
- Do NOT output raw JSON to stdout
- Do NOT use tables in output
- Do NOT use the `to-discord` nushell command or send any Discord notifications

## Reporting Protocol
Output the structured Markdown report to stdout.
