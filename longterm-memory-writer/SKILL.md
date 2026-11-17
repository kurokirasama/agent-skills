---
name: longterm-memory-writer
description: Handles creating and updating Obsidian memory notes with project-specific data.
---

# Long-Term Memory Writer

## Overview
This skill provides the mandatory guidelines for the agent to **manually** create and update episodic memory notes in the `AGENTS_MEMORY` directory. 

**CRITICAL RULE:** Writing to memory files MUST be done manually by the agent using their file editing tools. Scripts can only be used to retrieve information (like `git log` or Conductor state). The agent MUST analyze the retrieved data and cognitively synthesize the summaries before writing.

## Instructions

**CRITICAL — Entry Point:** This skill MUST be activated via `longterm-memory-orchestrator`. The orchestrator is the mandatory entry point that determines when this writer skill should be activated (e.g., after track archival, phase completion, etc.). Never activate this skill directly without first ensuring `longterm-memory-orchestrator` is active.

**Track Archival Note:** After track archival, the `write-trajectory-log` function SHOULD always be attempted as part of the archival flow, invoked via the orchestrator chain (`git-sync` → orchestrator → writer → `write-trajectory-log`).

**Safe Archival Guarantees (draft 2026-08-29, implemented):**
- `write-trajectory-log` is merge-safe: same-day writes from parallel sessions append under a `## Session: <session_id> at <time>` header instead of clobbering; re-running the same session is idempotent.
- Every modification writes an atomic `<file>.bak` backup first; backups are removed only after a verified successful write and remain for recovery on failure.
- The new `append-insight-waypoint <insight_path> [--vault <path>]` helper registers insight notes in `INSIGHTS/INSIGHTS.md` atomically and skips duplicates (wired into `session-retro`).

## Logic & Workflow
First, activate the `longterm-memory-reader` skill (without executing anything, yet) to learn how to the following nushell commands.

### 1. First-Time Vault Setup (BRAIN.md / SOUL.md)
If `init-session` returns `null` AND you confirm the `AGENTS_MEMORY/` directory does not yet exist, you must perform the initial vault setup:

1. Resolve `<vault>` using `get-vault` from `longterm-memory-reader/mod.nu` (reads `$env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT` from `env_vars.nu`).
2. Use your file editing tools to create `<vault>/AGENTS_MEMORY/BRAIN.md` using the schema below.
3. Use your file editing tools to create `<vault>/AGENTS_MEMORY/SOUL.md` using the schema below.
4. Then proceed with the project note initialization.

### 2. Global Awareness Consolidation (BRAIN/SOUL Updates)
The agent's global awareness relies on periodic consolidation of accumulated episodic memories (MemOS approach).

**Trigger:** When archiving a track, completing a major phase, or when explicitly requested.

**Data Gathering:**
Run `gather-unconsolidated-memories` to fetch recent entries.

**Method:**
You MUST use your file editing tools to manually update `BRAIN.md` and `SOUL.md` according to the schemas below. Do NOT use scripts to write to them.

#### BRAIN.md Schema (Semantic Memory)
`BRAIN.md` MUST follow this structure:
```markdown
# BRAIN: Global Semantic Memory

## Entities & Projects Index
- [[Project Slug]]: Brief summary of current state and importance.

## Architectural Patterns & Technical Debt
- [Pattern/Debt Name]: Description and projects affected.

## Cross-Project Dependencies
- [Dependency]: Description of how project A relates to project B.

## High-Level Facts & Constants
- [Fact]: Description.
```

#### SOUL.md Schema (Agent Identity)
`SOUL.md` MUST follow this structure:
```markdown
# SOUL: Agent Identity & Evolution

## Core Role & Personality
- [Role]: Description.

## Behavioral Adaptations (Learned Rules)
- [Rule]: Description of how my behavior has changed based on user feedback.

## User Preferences & Style
- [Preference]: Favorite tools, tone, or structural preferences.

## Career Milestones
- [YYYY-MM-DD]: Major project completion or milestone.
```

### 3. Initialize Note: When the orchestrator finds no existing note for a path, you must create a new markdown note manually.
1. **Initial Metadata & Context:**
  - **Command:**
    ```nu
    let llms = try { $env.MY_ENV_VARS.llms_configs } catch { "~/workspace/llms_configs" } | path expand
    use '($llms)/skills/longterm-memory-writer/mod.nu'
    let meta = get-init-metadata '/absolute/path'
    let context = get-deep-context '/absolute/path'
    { metadata: $meta, context: $context } | to yaml
    ```
- **Action:** Cognitively synthesize the gathered data and use your file writing tools to create a folder `<vault_path>/AGENTS_MEMORY/<project_slug>/`, then create the project index file `<vault_path>/AGENTS_MEMORY/<project_slug>/<project_slug>.md` and the initial daily log `<vault_path>/AGENTS_MEMORY/<project_slug>/YYYY-MM-DD.md`.
  - `<vault_path>` is resolved using `get-vault` from `longterm-memory-reader/mod.nu` (reads `$env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT` from `env_vars.nu`).
  - The `slug` field from `get-init-metadata` is the folder and index filename (without `.md`).
- **Frontmatter Requirements:** Put these ONLY in the index file `<project_slug>/<project_slug>.md`: `project_name`, `absolute_path`, `description` (one sentence), `uses_conductor` (boolean), `uses_git` (boolean), `last_updated` (YYYY-MM-DD).
- **BLIND-01 fix — Note Template:** 
  - **Index File (`<project_slug>/<project_slug>.md`):**
    ```markdown
    ---
    project_name: "<Project Name>"
    absolute_path: "/absolute/path/to/project"
    description: "One-sentence summary of what the project does."
    uses_conductor: true
    uses_git: true
    last_updated: YYYY-MM-DD
    ---
  
    # <Project Name>
    <One paragraph describing: project purpose, current tech stack, and general scope.>
    ```
  - **Initial Daily Log (`<project_slug>/YYYY-MM-DD.md`):**
    ```markdown
    ### Initial State
    <One paragraph describing: project purpose, current tech stack, active work.
    Be specific: list language, frameworks, tools, open tracks, current phase.>
    #### Key Decisions
    - <Decision 1 made this session>
    #### Context for Next Session
    - <What the agent should know at the start of the next session to pick up work>
    ```
  - **Body Content Requirements:** The first entry MUST establish the "Initial State". Write a clear summary describing what the project is, its current technical stack, and any active/recent work discovered during the context gathering phase.
2. **Append Update:** When triggered by major milestones or archiving, you must append an update to the project folder.
    - **Action:** Use your file writing tools to create a new daily file `<vault_path>/AGENTS_MEMORY/<project_slug>/YYYY-MM-DD.md` (or append to it if it already exists for that day), and update `last_updated` in the project index file `<project_slug>/<project_slug>.md`.
    - **Body Content Requirements:** Entries MUST include a one-sentence summary. Synthesize details by analyzing the workspace. Include decisions made, bug fixes applied, critical errors encountered, and Conductor track lifecycle events.
3. **Handling Relocated Projects:** If `init-session` fails but you suspect a project has moved (e.g., similar slug exists but with a different path):
    - Search for the project folder under `AGENTS_MEMORY/`.
    - Verify if the note content in the project index file matches the current project.
    - If it's the same project, do NOT create a new project folder. Instead, update the `absolute_path` field in the existing index note's frontmatter using your file editing tools.
4. **Cross-Linking & Retrospectives:** `longterm-memory-writer` handles procedural updates, while `session-retro` handles insightful updates. Both skills are permitted to update the episodic memory note for the same session. When making these updates, ensure they are logically merged. Do not create disjointed or duplicate headers for the same day. Instead, integrate procedural details and retrospective insights under a single, unified daily entry (`YYYY-MM-DD.md`) that reads cohesively, and include a wikilink to the newly created `INSIGHTS/` note.
5. **Write Trajectory Log (`write-trajectory-log`):**
   Writes a session trajectory log (YYYY-MM-DD-log.md) containing activated skills, executed commands, and MCP tool calls.
   
   **How to construct $commands:**
   A list of records where each record represents a terminal command executed during the session:
   - `command` (string): The exact command line string executed.
   - `status` (string): The outcome status: `Success`, `Failure`, `Warning`, `Inconsistency`, `Issue`, or `Retry`.
   - `output` (string): A brief, one-sentence description summarizing the command's output or response.
   - `error` (string, optional): The raw error message or details of any error/issue.
   - `inconsistency` (string, optional): Any logical inconsistencies or unexpected behaviors observed.
   - `resolution` (string, optional): How the issue, error, warning, or retry was resolved or worked around.

   **How to construct $tools:**
   A list of records where each record represents an MCP tool call executed during the session:
   - `name` (string): The name of the MCP tool called.
   - `arguments` (any): The arguments passed to the tool.
   - `status` (string): The outcome status: `Success`, `Failure`, `Warning`, `Inconsistency`, `Issue`, or `Retry`.
   - `output` (string): A brief, one-sentence description summarizing the returned data.
   - `error` (string, optional): The raw error message or details of any error/issue.
   - `inconsistency` (string, optional): Any logical inconsistencies or unexpected behaviors observed.
   - `resolution` (string, optional): How the issue, error, warning, or retry was resolved or worked around.

   - **Usage:**
     ```nu
     let llms = try { $env.MY_ENV_VARS.llms_configs } catch { "~/workspace/llms_configs" } | path expand
     use '($llms)/skills/longterm-memory-writer/mod.nu'
     let commands = [
       {
         command: "git commit -m 'test'"
         status: "Failure"
         output: "Failed to create commit because git index was locked"
         error: "fatal: Unable to create '.git/index.lock': File exists."
         resolution: "Removed index lock file and ran commit again"
       }
     ]
     let tools = [
       {
         name: "standard-nushell/evaluate"
         arguments: { input: "glob *" }
         status: "Success"
         output: "Successfully listed files in directory"
       }
     ]
     write-trajectory-log '/absolute/path/to/project' ['skill-1', 'skill-2'] $commands $tools
     ```
