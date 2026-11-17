---
name: conductor-core-protocols
description: Mandatory operational guidelines for Conductor-managed tasks, including Nushell-first, memory management, and Discord notifications.
---

# Conductor Core Protocols

This skill defines the mandatory operational guidelines and protocols for all Conductor-managed tasks. It ensures consistency, efficiency, and proper reporting across the project.

## Quick Reference — Critical Rules

1.  **Long Term Memory Orchestration**: Ensure the `longterm-memory-orchestrator` skill is active at the very start of EVERY session. Follow the instructions in the `longterm-memory-reader` skill to load project context and global awareness.
2.  **Nushell Timing**: Ensure `nushell-expert` is active BEFORE the first Nushell system call in a session.
3.  **`to-discord` Type**: `to-discord` is a Nushell command; `nushell-expert` MUST be active to use it.
4.  **Discord Sequencing**: ALWAYS execute `to-discord` and WAIT for it to finish BEFORE requesting user input via an interactive tool.
5.  **Auto Git-Sync**: Ensure `git-sync` is executed automatically after archiving or deleting a track.
6.  **Track Archival & conductor-finish-track**: When completing or archiving a track, trigger `conductor-finish-track` (`/conductor-finish-track`). It executes track completion checks, atomic archival, and runs parallel subagents for `git-sync` (remote sync) and `longterm-memory-orchestrator` (episodic memory, trajectory log, and `session-retro` evaluation).
7.  **Retro Triggers**: Execute `session-retro` if an issue is new, high-effort, or uniquely interesting.
8.  **howto.md Consultation**: Each track's `howto.md` contains per-task implementation guidance (code snippets, patterns, pitfalls, verification commands). BEFORE implementing each task in `plan.md`, the agent MUST consult the relevant section. `howto.md` is a **starting point, not a contract**: it never overrides `spec.md`, `plan.md`, or `workflow.md`. Whenever implementation diverges from it — better approach, incorrect guidance, or a new pitfall — the agent MUST update `howto.md` to reflect what was actually done.
9.  **BDD/Gherkin Acceptance Criteria**: Functional/user-facing track requirements in `spec.md` MUST be defined using BDD/Gherkin scenarios (`Given-When-Then`) to ensure an executable, testable specification.
10. **Mutation Testing Checks**: Verification stages in project workflows should optionally leverage mutation testing to check test suite quality and target a Mutation Score of `>70%` on new/modified code.
11. **Autonomy First**: Complete every step the agent can execute itself, especially simple verifications (see "Automated Manual Verification"). Ask the user ONLY for: (a) actions requiring the user's physical access (manual commands, OAuth/browser approvals, hardware), (b) destructive/irreversible decisions, (c) genuine preference choices, (d) persistent failures after Auto-Fix & Retry once. Discord notifications remain mandatory before every ask; informational Discord notes are recommended for autonomous actions.
12. **Native Swarm Governance**: Swarms (`/swarm` or native `swarm` tool) are multi-agent and Quota Heavy. Autonomous swarm activation requires a Mandatory Approval Gate (send Discord notification, then prompt with proposed roster and workspaces). Enforce Hybrid Workspace Isolation (`workspace: "share"` for authors, `workspace: "inherit"` for verifiers). Never blind-fallback models on quota exhaustion; manage the 3 quota pools (Gemini 3.x, Gemini 4, Claude/GPT) by asking the user to switch pool or pause. Always attach `swarm_monitor` on launch.

## BDD / Gherkin Acceptance Scenarios

To minimize ambiguity, all user-facing or functional features defined during track planning MUST contain acceptance criteria structured using the Gherkin DSL:

```gherkin
Scenario: [Title of scenario]
  Given [Initial state or preconditions]
  When [Action is performed or event occurs]
  Then [Expected results and assertions]
```

These scenarios form the blueprint for unit and integration test generation during the TDD "Red" phase. Non-functional specifications (e.g. chores or simple refactoring) may use standard checklists.

## Mutation Testing Quality Protocols

To ensure that high code coverage metrics (`>80%`) represent high assertion quality rather than trivial line execution:
1.  **Run Mutation Testing**: For new or modified code, run the project's mutation testing runner (e.g. `mutmut` for Python, `stryker` for JavaScript, `cargo-mutants` for Rust).
2.  **Killed Mutants Score**: Aim for a Mutation Score of `>70%`. If mutants survive, analyze the target code and tests. Write additional unit or integration tests with tighter assertions until the mutants are killed.
3.  **Audit Checkpoint**: Since mutation testing is computationally heavy, it should be executed as a final check before closing/finalizing a task or phase, rather than on every file edit.

## howto.md Lifecycle

The `howto.md` file is a companion document created at track creation time alongside `spec.md` and `plan.md`. It provides executable implementation guidance as a **starting point** — the implementing agent is free to diverge, improve, or replace content during implementation if better options are found or if the original guidance produces errors. It is guidance, not a contract: `spec.md`, `plan.md`, and `workflow.md` always take precedence.

### Lifecycle Stages
1. **Creation**: Generated during track initialization as part of `conductor-newtrack`. Referenced in the track's `index.md`.
2. **Consultation**: At the start of each task in `plan.md`, the agent reads the relevant section of `howto.md` for implementation hints.
3. **Mutation**: During implementation, if the agent discovers:
   - A better approach than documented
   - An error in the original guidance
   - Additional patterns or pitfalls worth recording
   The agent MUST update `howto.md` to reflect the improved knowledge.
4. **Archival**: When a track is archived or deleted, its `howto.md` is preserved alongside the other track artifacts for future reference.

## Nushell-First Guidelines

Priority must be given to using Nushell pipelines for all system interactions and data manipulation tasks. This leverages Nushell's structured data capabilities for more efficient and predictable operations. **CRITICAL:** Ensure the `nushell-expert` skill is active BEFORE the first Nushell command in any session. This is a mandatory sequential requirement that applies even to implicit Nushell calls like `to-discord`.

> **Note on `to-discord`**: The `to-discord` command is a Nushell custom command, NOT a standalone binary. Therefore, the `nushell-expert` skill MUST be active before any attempt to send notifications via Discord.

Standard shell commands should only be used as a fallback if Nushell-based attempts fail after multiple tries. The transition to shell commands should be silent unless the failure indicates a persistent issue requiring user attention. The agent should always explore if a task can be accomplished using Nushell's native commands (e.g., `ls`, `where`, `par-each`, `save`) before resorting to `bash` or other external tools.

## General Behavior

**ALWAYS DO THIS FIRST** before proceeding with any task or user request that may require an specific system instruction, system prompt or persona.

**CHOOSE** the appropriate general behavior guideline/persona/system prompt/system instruction, depending on the situation or task at hand.

In order to choose the appropriate persona, identify a matching skill in the available library. Once a skill is identified, ensure its instructions are active to guide your interactions. Adhere to the skill's detailed procedures or full workflow ONLY if the user has explicitly requested a specific task defined within that skill or the comprehensive execution of the skill itself.

If the task requires an expertise not defined in any available skill, use an appropriate tool or persona to draft a new one and inform the user of the full description.

ALWAYS inform the user what persona you are taking on.

**Then, load from all memories any information regarding the task at hand.**

## Memory Management

We call to obsidian notes accessible trough `obsidian cli` simply _notes_ or _memories_.

Before executing any task that might need or could use prior knowledge, but after the appropiate persona and/or pre-prompt have been chosen, **ALWAYS** retrieve _all memories_ or _notes_ that could be associated with the current task or subject.

For detailed retrieval and storage protocols, refer to the `obsidian-memory-expert` skill.

## Long Term Memory Management

**MANDATORY PRE-TASK PROTOCOL:** At the beginning of every session, BEFORE proceeding with any user tasks, the agent MUST:
1.  Identify the current absolute path.
2.  Ensure the `longterm-memory-orchestrator` skill is active.
3.  Invoke `init-session "<current_path>"` using the reader module. Since Nushell `use` paths must be parse-time constants, construct the command string and run it in a subshell:
    ```nu
    let llms = try { $env.MY_ENV_VARS.llms_configs } catch { "~/workspace/llms_configs" } | path expand
    nu -c $"use '($llms)/skills/longterm-memory-reader/mod.nu' *; init-session '<current_path>'"
    ```
4.  **Handle Initialization**: If `init-session` returns `null` (indicating no existing note), immediately execute the `longterm-memory-writer` protocol to create the initial `AGENTS_MEMORY/<slug>/<slug>.md` note and directory.
5.  Apply the retrieved context to maintain continuity across sessions.

**MANDATORY POST-SESSION PROTOCOL:** At the end of every active session (before closing, archiving, or finishing work), the agent MUST update the project's episodic memory note in `AGENTS_MEMORY/` to summarize the work completed, decisions made, and any next steps:
1.  If the session qualifies for a retrospective (e.g. track finalization, new issues, high effort, strategic interest), follow the **Retrospective Protocol** below (which includes appending the memory update).
2.  Otherwise, manually update the project's episodic memory note in `AGENTS_MEMORY/` by following the **Long-Term Memory Update** instructions in the `longterm-memory-writer` skill (including updating `last_updated` and appending a new dated section).

**Configuration:** To ensure portability, the agent MUST use `$env.MY_ENV_VARS.OBSIDIAN_VAULT_ROOT` (set in `env_vars.nu` under `MY_ENV_VARS`) to resolve the Obsidian vault path via the `get-vault` helper in `longterm-memory-reader/mod.nu`. The skills will fallback to `~/workspace/obsidian/vaults` if the variable is missing.

## Context Engineering Protocols

For new projects or complex coding tasks, you **MUST** perform a systematic discovery and planning phase. Utilize specialized tools from the `context7`, `deepwiki`, `ref_search_documentation`, and `grep_search` mcp servers to build a complete mental model before implementation.

For the detailed Discovery -> Synthesis -> Planning -> Execution workflow, refer to the `context-expert` skill.

## Context Mode & Session Continuity

To protect the context window from flooding, **ALWAYS** prefer using the following sandbox tools for data-heavy operations:

- **Web Research:** Use `mcp__context-mode__ctx_fetch_and_index(url, source)` then `mcp__context-mode__ctx_search(queries)` instead of `web_fetch`.
- **Large File Analysis:** If reading files for analysis/summarization (not editing), use `mcp__context-mode__ctx_execute_file(path, language, code)`.
- **Heavy Command Output:** For bash commands expected to produce >20 lines of output, use `mcp__context-mode__ctx_execute(language: "shell", code: "...")`.
- **Batching:** Use `mcp__context-mode__ctx_batch_execute(commands, queries)` to run multiple commands and searches in one call.

**Session Continuity:** This server automatically tracks file edits, tasks, and decisions. If the conversation is compacted, your state will be restored.

## Automated Manual Verification

When a workflow or task requires manual verification (e.g., Phase Completion), you **MUST** evaluate if the verification steps are "simple":
- **Read-Only**: Does not modify the codebase or critical system state.
- **Non-Destructive**: Safe to execute as a background process or standalone check.
- **Fast Execution**: Expected to complete quickly.
- **Examples**: Checking file contents, executing scripts (tests, linters), analyzing stdout/stderr or log files.

If the verification steps meet these criteria, you **MUST execute these steps autonomously** instead of asking the user for confirmation.
- **Fallback & Error Handling**: If an automated verification step fails, attempt an **Auto-Fix & Retry once**. If the retry fails, halt and ask the user for manual intervention.
- **Logging**: All automated verification outcomes must be clearly documented in your task or phase summaries and git notes.

## Status Reporting & Notifications

### Standard Task Summary
After every successful task completion, provide a very brief summary in English of what was done and how.
- **Tone:** Conceptual description, including technical details only where appropriate for clarity.
- **Exception:** Do NOT provide a summary for trivial tasks unless explicitly requested.

### Mandatory Discord Notification for User Input (CRITICAL)
Whenever you are about to use the `ask_user` tool to request feedback, clarification, or approval, you **MUST** first send a Discord notification. This ensures the user is alerted that the agent is blocked and waiting for input. 

**CRITICAL:** ALWAYS execute `to-discord` and WAIT for it to finish BEFORE executing the `ask_user` tool. This sequential ordering is mandatory to ensure the user is notified that the agent is blocked and waiting.

- **Notification Content**:
    - **Exact Question**: Include the literal question(s) being asked via `ask_user`.
    - **Task Metadata**: State the current Track ID, Phase Name, and Task Description.
    - **Context for Review/Opinion**: If asking for a review or opinion on changes:
        - List the modified files.
        - Provide a high-level conceptual summary of the changes.
        - Include a simplified `git diff` (markdown code block ````diff````) focusing on relevant logic.
- **Visibility Mandate**: The exact same information sent to Discord (question, metadata, context) MUST also be explicitly included in the `ask_user` call (or equivalent), such that even though a message is sent to Discord, the information must also be shown to the user in the chat.
- **Diff Management**: If the diff or total message exceeds 2000 characters, split it into several messages.

- **Command**: Execute the `evaluate` tool from the `standard-nushell` MCP server with `to-discord $message -p`.
- **Fallback Mechanism**: If the `evaluate` tool is unavailable or fails, use the following syntax to ensure local config/env are loaded:
  `nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c 'to-discord "<message>" -p'`
- **Timing**: Send the notification **immediately before** calling `ask_user`.
- **`ask_user` Fallback**: If the `ask_user` tool is unavailable or not accessible in the current environment, ask the user directly by outputting your question as plain text in the chat interface.
- **Nushell Activation**: **ALWAYS** activate the `nushell-expert` skill before executing the first nushell command.

## Retrospective Protocol

The agent **MUST** execute the `session-retro` skill and follow its Operational Lifecycle in any of the following mandatory scenarios:
1.  **Track Finalization**: Before completing or archiving any Conductor track.
2.  **New Issues**: When an issue is encountered that is new (not found in existing Obsidian memory).
3.  **High Effort**: When a task required significant work, multiple attempts, or complex debugging to solve.
4.  **Strategic Interest**: When an issue or solution is interesting, unique, or provides high-value insights for future sessions.

### Operational Lifecycle:
1. Run `python3 ~/workspace/llms_configs/skills/session-retro/retro.py --transcript <transcript_path> --slug <slug> --project-slug <project_slug> --vault <vault_path> --open-obsidian` to parse the transcript, generate the baseline note, and automatically synchronize/open it in Obsidian.
2. Manually review the generated note and perform cognitive synthesis of the lessons learned by editing the file (using your file editing tools) to enrich the Overview and Resolution sections.
3. Ensure the generated note includes an Obsidian wikilink to the project's episodic memory note: `[[<slug>|Long-Term Memory Note]]` (the `project-slug` argument to the script handles this automatically).
4. **MANDATORY — Long-Term Memory Update:** When a retrospective is generated, both `longterm-memory-writer` (for procedural updates) and `session-retro` (for insightful updates) can append to the episodic memory note. For the `session-retro` portion, you MUST:
   - Use the `slug` and `file_path` from the session initialization context to locate the project's `AGENTS_MEMORY` note.
   - Manually append a consolidated insight update (using your file editing tools) that includes: a summary of the key lessons learned, and a wikilink to the newly created `INSIGHTS/` note (use the exact filename printed by the script, since a suffix like `_1.md` may have been appended).


## Track Cleanup & Synchronization (conductor-finish-track)

**CRITICAL:** After completing a track, invoke `conductor-finish-track` (`/conductor-finish-track`). The skill automatically validates completion and reviews, moves the track to `conductor/archive/<track_id>`, cleans `conductor/tracks.md`, and runs parallel subagents (or sequential fallback) for:
1. Execute `git-sync` to synchronize the remote origin
2. Activate `longterm-memory-orchestrator` skill (or spawn `@memory-expert`)
3. Follow the orchestrator's guidance to activate `longterm-memory-writer`
4. Use `longterm-memory-writer`'s `write-trajectory-log` function to persist a trajectory log of the session
5. Evaluate `session-retro` triggers for newly discovered lessons or high-effort resolutions

This ensures that track completion, key decisions, outcomes, lessons learned, and the session trajectory are recorded in the project's episodic memory.

## Private Conductor Directory Management

In public repositories, the `conductor/` directory MUST remain private to protect the project's internal planning, specifications, and metadata. Other elements that must remain private are files GEMINI.md, CLAUDE.md and equivalents, as well as any other defined by the user.

1.  **Stop Tracking:** If `conductor/` is already tracked, it MUST be removed from the Git index using `git rm -r --cached conductor/` and committed to the current branch.
2.  **Git Ignore:** Ensure `conductor/` is added to the project's `.gitignore` file.
3.  **No Forced Staging:** NEVER use `git add -f conductor/` in public repositories.
4.  **Local-Only Tracking:** Changes to the `conductor/` directory should remain local-only or be managed in a dedicated, non-pushed private branch.
5.  **Memory Preservation:** Record the private status of the `conductor/` directory in the project's persistent memory to maintain this behavior across sessions.

**ALWAYS** ask the user if the current project will be public or not.

## MATLAB Orchestration

For all MATLAB-related tracks and tasks, you **MUST** activate and load the `matlab-expert` orchestrator skill. This skill acts as the **exclusive entry point** for all MATLAB development. All specialized toolkit skills (testing, debugging, code review, etc.) MUST be routed through and activated by `matlab-expert`.

- **Exclusive Entry Point**: Never activate individual MATLAB toolkit skills directly. Always load `matlab-expert` first.
- **Toolkit Activation**: The `matlab-expert` skill is responsible for activating specialized toolkit skills using `activate_skill` before delegating tasks.
- **Toolkit Verification**: Always use the verification logic in `matlab-expert` to ensure the environment is ready.

## Connectivity & Reasoning

For tasks involving external data acquisition, you **MUST** adhere to the structured web fetching protocols. For detailed tool priority, refer to the `connectivity-expert` skill.

## Native Swarm Governance

Antigravity CLI (agy) v1.5.5 introduced native swarms, transforming the primary agent into a **coordinator** overseeing workers collaborating via an asynchronous shared message board. Because swarms instantiate multiple concurrent agents consuming quota and tokens, their use must follow strict operational governance:

### 1. Mandatory Approval Gate
- **No Unprompted Swarm Spawning:** An agent must **NEVER** initiate a swarm autonomously without explicit user confirmation.
- **Pre-flight Proposal:** When a track task, code review, or multi-perspective analysis qualifies for swarm execution, the agent must FIRST send a Discord notification (`to-discord $msg -p`), then present the user with:
  - The proposed swarm title and roster (roles, model assignments).
  - The workspace mode for each worker.
  - The specific division of labor.
  - An Approve/Decline choice. If declined, the agent must seamlessly fall back to sequential single-agent execution.

### 2. Quota Pool Management
There are three distinct API quota pools in the environment:
1. **Gemini 3.x** (e.g. Gemini 3.8 Flash, Gemini 3.5 Flash)
2. **Gemini 4** (e.g. Gemini 4 Carbon Low/Med/High)
3. **Claude/GPT** (e.g. Claude 3.7 Sonnet, GPT-4o)

- **No Blind In-Pool Fallback:** When a worker's model is exhausted, switching to another model within the *same* quota pool will fail. The coordinator must NOT cycle through models in the exhausted pool.
- **User Gate on Quota:** When a worker hits quota limits, the coordinator must alert the user via Discord/chat and prompt whether to:
  - Switch the worker to an alternative active pool (`swarm{action: "model", name: "<worker>", model: "<new_model>"}`).
  - Pause the swarm until the quota pool resets.

### 3. Hybrid Workspace Isolation
To prevent git merge collisions and lost worktree states:
- **Code Authors (`workspace: "share"`)**: Workers writing code, editing files, or compiling build targets MUST use `workspace: "share"`. This gives each author its own working copy branched from the parent while preserving uncommitted/staged files.
- **Reviewers & Verifiers (`workspace: "inherit"`)**: Workers performing read-only inspection, test suite execution, or external literature searches MUST use `workspace: "inherit"`.
- **Atomic Work Landing**: Before calling `swarm{action: "kill"}` on any author, the coordinator must ensure the author's work is staged, tested, and merged into the main working copy.

### 4. Stall Sentinel Requirement
Every spawned swarm MUST include a dedicated `monitor` worker running the `swarm_monitor` skill (`name: "monitor"`, brief: `"You are this swarm's stall monitor. Load the swarm_monitor skill and follow it. Post only to break a stall."`) initialized in the very same turn the swarm is created.

### 5. Slash Command Suggestions
When interacting with the user or in non-autonomous contexts, suggest user-facing slash commands tailored to the task:
- Implementation: `/swarm Implement Phase N tasks in track <track_id>`
- Review: `/swarm Review track <track_id> with security, architecture, and test verifiers`
- Peer Review: `/swarm Peer-review manuscript <path_to_paper> for target journal <journal>`

## Commit Guidelines

When generating or proposing commit messages, you **MUST** consider the following:
- **Prohibited Patterns:** Never use `(conductor)` references or any other labels that identify the author as an AI (e.g., avoid `chore(conductor): ...`).
- **Strict Anonymity:** Commit messages must focus exclusively on the technical changes, features, or fixes being applied. Never mention "conductor" (case-insensitive) or implementation metadata in git commit messages. For internal tracking updates, use generic descriptions like "chore: update implementation tracking" or "docs: update development notes".
