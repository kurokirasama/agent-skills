---
name: longterm-skillopt-optimizer
description: Analyzes trajectory logs, manages the rejected-edit buffer, drafts improvement plans, and applies approvals/rejections.
---

# Long-Term SkillOpt Optimizer

## Overview

This skill implements the trajectory-driven self-improvement loop for custom agent skills and global agents instructions. It is designed to run periodically (e.g., once a week via cron) to analyze recent execution logs, identify command or tool failures, and propose highly targeted, bounded instructions updates (patches) to custom skills under `skills/` and global agents instructions to prevent future failures.

## Objectives
- **Error Mitigation**: Proactively update skill instructions based on actual execution errors (e.g. CLI quirks, missing options, flag deprecations) encountered in recent sessions.
- **Safety Gate**: Draft proposals in `_draft_improvements/` for user review (approval/rejection) before applying them.
- **Deduplication**: Read previously rejected proposals from `_draft_improvements/processed_improvements/` to avoid repeating bad instructions edits.
- **Patch Budget**: Restrict changes to a maximum of 3 patches per skill file, targeting only custom skills.

## Core Commands

Always prepend these imports before calling nushell functions/commands:
```nu
const llms = "/home/username/workspace/llms_configs"
use $"($llms)/skills/longterm-skillopt-optimizer/mod.nu" *
```

### 1. Process Approvals & Gather Context
Run the Nushell optimizer script to archive rejected plans, output approved plans, and gather trajectory event context:
```nu
process-skillopt-logs "/home/username/workspace/llms_configs"
```

## Instructions

You are the AI agent executing this optimization skill. You are responsible for manually implementing approved plans, archiving rejections, and analyzing trajectory events to propose new drafts.

### Definitions

A **patch** is a structured instruction representing a single edit to a target skill file. Each patch consists of:
- **Type**: The operation type:
  - `replace`: Replaces the target block with the new content.
  - `insert_before`: Inserts the new content directly before the target block.
  - `insert_after`: Inserts the new content directly after the target block.
  - `delete`: Deletes the target block.
- **Target**: The exact, contiguous block of text in the original file to match (including leading/trailing whitespace and line endings) exactly.
- **Content**: The new text content to replace, insert before, or insert after (empty/omitted for `delete`).

### Workflow:

1.  **Process Pending Plans & Gather Context**:
    Run `process-skillopt-logs "/home/username/workspace/llms_configs"` as shown above. This will archive decided drafts and output current context:
    - **Approved plans to manually implement** (items marked `- [x] Approved` by the user in previous drafts).
    - **Recent trajectory events** (logged command/tool executions, including successful sessions, failures, errors, retries, warnings, or inconsistencies).
    - **Rejected improvements buffer** (to prevent proposing edits that were previously rejected).
    - **Active custom skills** contents.
    - **`gemini-bak.md`** guidelines contents.

2.  **Manually Implement Approved Plans (including gemini-bak.md)**:
    If there are items under `APPROVED PLANS TO MANUALLY IMPLEMENT`:
    - For each plan, read the target skill files (or `gemini-bak.md`) and manually apply the specified patches using your file-editing tools.
    - If the plan modifies a skill file under `skills/`, run the static audit to validate the modified skill:
      ```nu
      nu $"($llms)/scripts/audit-skill.nu" skills/<skill-name>
      ```
    - If the plan modifies `gemini-bak.md`, apply the patches directly to `gemini-bak.md` at the project root, and then execute nushell command `update-gemini-md` via the nushell mcp server evaluate tool.
    - Mark the draft plan as implemented: edit the draft file (e.g. `AGENTS_MEMORY/_draft_improvements/<draft-file>`) and change `implemented: false` to `implemented: true` in the frontmatter.
    - Run `process-drafts "/home/username/workspace/llms_configs"` to archive the implemented draft to `_draft_improvements/processed_improvements/` and record the approved and rejected chunks in `processed_improvements.md`.

3.  **Analyze Log Context & Rejected Buffer**:
    If there are trajectory events under `RECENT TRAJECTORY EVENTS`:
    - Analyze the trajectory events (both successful and failed executions) to identify failures, errors, retries, warnings, inconsistencies, or sub-optimal workflows.
    - Review successful executions to find room for optimization (e.g., merging steps, reducing tool calls, streamlining procedures).
    - Check the current instructions of those custom skills, and check the rules in `gemini-bak.md` (which are loaded under the `=== GEMINI-BAK GUIDELINES ===` section).
    - Evaluate if any recent failures, errors, or sub-optimal behaviors are caused by contradictions, gaps, or lack of clarity in either the custom skills or `gemini-bak.md` guidelines.
    - Formulate patches to clarify instructions, fix command syntax, resolve tool issues, streamline workflows, or correct inconsistencies in `gemini-bak.md`.
    - Check your proposals against the rejected improvements buffer. If a proposal matches a previously rejected edit, discard it or formulate a different approach.

4.  **Propose Bounded Patches**:
    - **Edit Constraints (Strict)**:
      - Max 3 patches per skill/guideline file.
      - Target only files under `skills/` and the `gemini-bak.md` file located at the project root.
      - If multiple skills/guidelines need coordinated updates, update them in the same draft.

5.  **Save the Draft Plan & Create Habitica Todo**:
    - Use the file writer tool to save the drafted plan to the Obsidian vault directory:
      Path: `AGENTS_MEMORY/_draft_improvements/YYYY-MM-DD.md` (e.g. `/home/username/workspace/obsidian/vaults/AGENTS_MEMORY/_draft_improvements/2026-06-20.md`)
    
    - Immediately after saving the draft, you MUST create a Habitica todo task:
      - **Todo Title**:
        - `"new gemini-bak.md draft improvement available"` if the draft contains patches targeting `gemini-bak.md`.
        - `"new skill draft improvement available"` otherwise.
      - **Priority**: `1.0`
      - **Checklist**: Add the list of names of all skills or guidelines (e.g., `gemini-bak.md`) being improved.
      - **Command** (via nushell mcp server evaluate tool):
        ```nu
        h add todos --text $todo_text --priority 1.0 --notes "" --due "" --checklist $checklist
        ```
      - **Environment Fallback Command**: If running outside of the persistent Nushell session, you must invoke the command using:
        ```nu
        nu --config /home/username/.config/nushell/config.nu --env-config /home/username/.config/nushell/env.nu -c 'h add todos --text "<title>" --priority 1.0 --notes "" --due "" --checklist ["<skill1>", "<skill2>"]'
        ```

    Format the draft file exactly as follows:

    ```markdown
    ---
    date: YYYY-MM-DD
    implemented: false
    ---
    # Proposed Skill Improvements

    ### 1. `skill-name`
    - [ ] Approved
    - [ ] Not Approved
    - **Rationale:** Propose fix based on event: [describe event/issue].
    - **File:** skills/skill-name/SKILL.md or gemini-bak.md
    - **Patches:**
      - **Type:** replace
      - **Target:** exact target text to match
      - **Content:** new content
    ```

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.

## Output Format

After completing all steps (process approvals, implement plans, analyze logs, propose patches, and save draft), output a Markdown summary to stdout. The summary must include:

- Number of approved plans implemented (if any)
- Number of new draft improvements proposed (if any)
- Names of affected skills or guidelines
- A brief one-sentence status per action taken

Example output:

```markdown
## SkillOpt Result

- **Approved Plans Implemented:** 2
- **New Draft Improvements Proposed:** 1
- **Affected Skills:** cron-conductor-monitor, gemini-bak.md
- **Status:** All approved patches applied, 1 new draft saved to _draft_improvements/2026-07-14.md
```
