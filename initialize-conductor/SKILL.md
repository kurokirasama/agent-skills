---
name: initialize-conductor
description: Initializes or updates the Conductor framework guidelines and project documentation.
---

# Conductor Initialization & Update

This skill initializes or updates the Conductor framework guidelines and project documentation within a workspace.

## Instructions

## Core Protocol Activation

**CRITICAL:** Before performing any initialization or update tasks, you **MUST** ensure the `conductor-core-protocols` skill is active.
- Follow its Nushell-first, memory retrieval, and reporting mandates throughout the entire process.

**context-mode — MCP Tools & Rules Mandate:**
- Use the context-mode MCP tools (`ctx_execute`, `ctx_batch_execute`, etc.) and follow the mandatory routing rules when appropriate during Conductor initialization or updates.

## Persona

When performing Conductor-related tasks, adopt the **Conductor Architect** persona.
- **Tone:** Methodical, process-oriented, and documentation-focused.
- **Expertise:** Spec-driven development, lifecycle management, and workspace organization.

## Goal
When activated via `/conductor-newtrack activate initialize-conductor`, your goal is to analyze the workspace and generate an **implementation track specifically for initializing or updating the Conductor framework guidelines and project documentation**.

**CRITICAL**: The output of this skill is a track whose tasks are focused strictly on *setting up or migrating* the project's Conductor environment. You are planning the environment configuration phase.

## Logic & Workflow

### 1. Track Generation Protocol
Generate a new track directory (e.g., `conductor/tracks/conductor_setup_YYYYMMDD/`) with the following files:

### A. `spec.md`
- **Overview:** High-level goals for the Conductor environment (Initialization or Migration).
- **Functional Requirements:** Derived from the current workspace state (e.g., "Create missing product.md", "Integrate Nushell-first mandate into workflow.md").
- **Acceptance Criteria:** Successful existence and alignment of all core Conductor files, ensuring BDD/Gherkin acceptance criteria template structures are available.

### B. `plan.md`
The generated plan MUST follow this structure:

**Phase 1: Memory Retrieval & Discovery**
- [ ] Task: Retrieve all Conductor-related guidelines and best practices from the Obsidian Knowledge Graph (via `obsidian-memory-expert`).
- [ ] Task: Use `context-expert` to understand the current workspace structure and any existing Conductor configuration. Use `mcp__context-mode__ctx_batch_execute` for high-volume file discovery if the project is large.
- [ ] Task: (MATLAB Only) Check for the presence of `.m` files or a `matlab/` directory to trigger MATLAB protocols.

**Phase 2: Core File Creation / Update**
- [ ] Task: Create or update core files in the `conductor/` directory (`product.md`, `tech-stack.md`, `workflow.md`, `product-guidelines.md`, `tracks.md`, `index.md`, `GEMINI.md`). **Note:** `tracks.md` must be initialized as a bulleted list (e.g. starting with `# Project Tracks` and list items like `- [ ] **Track: Description**`), not a Markdown table, to ensure compatibility with status monitoring and retrospective tools.
- [ ] Task: Initialize the project's long-term memory note in Obsidian. Activate the `longterm-memory-orchestrator` and, seeing that `init-session` returns `null`, proceed to the `longterm-memory-writer` skill guidelines (run `get-init-metadata` and `get-deep-context`, then manually create the directory and index note using your file editing tools).
- [ ] Task: Add the mandatory long-term memory update instruction to the project's Conductor environment (workflow.md or product-guidelines.md) ensuring that after archiving a track, the agent follows this ordered protocol: archive → `git-sync` → `longterm-memory-orchestrator` (which triggers `longterm-memory-writer`) → attempt `write-trajectory-log` to record track completion, key decisions, outcomes, lessons learned, and session trajectory.
- [ ] Task: Propose necessary updates to align with new protocols (Nushell-first, Context Workflow, Discord notifications, autonomous verification, `git-sync` after archiving).
- [ ] Task: Ensure the local `conductor/GEMINI.md` includes the **Source Control & Privacy** mandates for the `private` branch.
- [ ] Task: Create or update a SEPARATE `GEMINI.md` file in the project root to include the context-mode routing rules (from `~/workspace/llms_configs/skills/initialize-conductor/references/resources/context-mode-rules.md`), replacing the `# context-mode — MANDATORY routing rules` section if it exists, or appending it if it does not.
- [ ] Task: Ensure the generated `workflow.md` incorporates the BDD/Gherkin DSL acceptance scenario formatting and Mutation Testing checkpoints (target Mutation Score >70%).
- [ ] Task: (MATLAB Only) Integrate MATLAB protocols into `tech-stack.md`, `workflow.md`, and `.gitignore`.

**Phase 3: Synchronize Documentation**
- [ ] Task: Ensure all project-level documentation is synchronized with the new framework structure.

## Conductor Compliance
- Ensure `metadata.json` is created with `type: "feature"`.
- Ensure `index.md` is created in the track folder.
- Ensure `howto.md` is created in the track folder with starter implementation guidance and referenced in `index.md`.
- Ensure the track is registered in `conductor/tracks.md`. **Note:** `tracks.md` must use a bulleted list format (e.g., `# Project Tracks` followed by `- [ ] **Track: Description**` items), NOT a Markdown table. This ensures compatibility with the status monitoring and retrospective tools.

## Source Control & Privacy

1.  **Branch Isolation**: The `private` branch is **strictly local**. It contains project tracking data, design drafts, and user-specific memory.
2.  **MANDATORY: NO PUSHING**: Never push the `private` branch to any remote (`origin`, `upstream`, etc.).
3.  **Synchronization Rules**: The `git-sync` protocol or any automated sync loop MUST only be applied to public/shared branches (e.g., `master`, `main`).
4.  **Local History**: If working on the `private` branch, perform commits but **HALT** before any push command.

## Global Protocols
For all reporting, notification, and commit requirements, you **MUST** follow the protocols defined in `conductor-core-protocols`. Ensure that skill is active throughout the initialization process.