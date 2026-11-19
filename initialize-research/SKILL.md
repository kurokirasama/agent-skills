---
name: initialize-research
description: "Expert in scaffolding LaTeX-based research projects (reports or articles) from predefined templates."
---

# Research Architect

## Instructions

## Core Protocol Activation

**CRITICAL:** Before performing any initialization tasks, you **MUST** ensure the `conductor-core-protocols` skill is active.
- Follow its Nushell-first, memory retrieval, and reporting mandates throughout the entire process.

## Persona

Adjoin the **Research Architect** persona.
- **Tone:** Professional, efficient, and precise.
- **Expertise:** Academic writing standards, LaTeX (article and report classes), and project organization.

## Goal
When activated via `/conductor-newtrack activate initialize-research`, your goal is to analyze the research requirements and generate an **implementation track specifically for scaffolding the research workspace and LaTeX environment**.

**CRITICAL PREREQUISITE (`conductor-setup` First):** `initialize-research` is a `/conductor-newtrack` skill — it requires an initialized `conductor/` workspace (`conductor/index.md`, `product.md`, `tech-stack.md`, `workflow.md`).
- **Always verify `conductor/index.md` exists BEFORE generating the track.**
- If missing: HALT track creation, send a Discord alert (`to-discord $msg -p`), and instruct/invoke `conductor-setup` first (since `conductor-setup` scaffolds `conductor/` and public/private git privacy, while `initialize-research` scaffolds the research directories and LaTeX template).

**CRITICAL**: The output of this skill is a track whose tasks are focused strictly on *selecting the correct template and initializing the clean research folder structure*. You are planning the research setup phase.

## Logic & Workflow

### 1. Track Generation Protocol
Generate a new track directory (e.g., `conductor/tracks/research_scaffold_YYYYMMDD/`) with the following files:

#### A. `spec.md`
- **Overview:** High-level goals for the research project and LaTeX artifact (Report or Article).
- **Functional Requirements:**
    - Confirm `conductor/index.md` is initialized (`conductor-setup` completed).
    - Determine LaTeX project type (Report vs Article) and target paper slug (`<paper_slug>`, e.g., `articles/main_paper/`).
    - Scaffold standard research workspace folders (`articles/`, `bibliography/`, `docs/`, `scripts/`, `shell/`) alongside modular LaTeX assets (`articles/<paper_slug>/`).
- **Acceptance Criteria (BDD/Gherkin):** Valid `conductor/` configuration plus modular LaTeX structure under `articles/<paper_slug>/main.tex` (or chosen target path) and standard top-level research directories.

#### B. `plan.md`
The generated plan MUST follow this structure:

**Phase 1: Project Type & Layout Selection**
- [ ] Task: Verify `conductor/index.md` exists (if not, run `conductor-setup` first).
- [ ] Task: Determine project type (Report vs Article) and `<paper_slug>` (defaulting articles to `articles/<paper_slug>/` rather than cluttering the repo root) by checking prompt/project-plan keywords or using `ask_user` (Discord first).

**Phase 2: Workspace & Template Scaffolding**
- [ ] Task: Create standard research workspace directories if absent: `articles/<paper_slug>/`, `bibliography/`, `docs/`, `scripts/`, `shell/`.
- [ ] Task: Copy the contents of the appropriate template folder (resolving `$env.MY_ENV_VARS.llms_configs` fallback `~/workspace/llms_configs`, under `skills/initialize-research/assets/template_tex_report/` or `assets/template_tex_article/`) into `articles/<paper_slug>/` (or target directory) using Nushell (`cp -r ...`).
- [ ] Task: Initialize the project's long-term memory note in Obsidian. Activate `longterm-memory-orchestrator` and, if `init-session` returns `null`, follow `longterm-memory-writer` guidelines to create the project memory folder and note.
- [ ] Task: Add the mandatory long-term memory update instruction to the project's Conductor environment (`workflow.md` or `product-guidelines.md`) ensuring that after archiving a track, the agent follows: archive → `git-sync` → `longterm-memory-orchestrator` → `write-trajectory-log`.

**Phase 3: Final Verification**
- [ ] Task: Verify existence of `articles/<paper_slug>/main.tex`, standard research directories (`bibliography/`, `docs/`, `scripts/`, `shell/`), and core LaTeX subfolders (`figures/`, `tables/`, chapters/sections).

## Conductor Compliance
- Ensure `metadata.json` is created with `type: "feature"`.
- Ensure `index.md` is created in the track folder.
- Ensure `howto.md` is created in the track folder with starter implementation guidance and referenced in `index.md`.
- Ensure the track is registered in `conductor/tracks.md`. **Note:** `tracks.md` must use a bulleted list format (e.g., `# Project Tracks` followed by `- [ ] **Track: Description**` items), NOT a Markdown table. This ensures compatibility with the status monitoring and retrospective tools.

## Global Protocols
For all reporting, notification, and commit requirements, you **MUST** follow the protocols defined in `conductor-core-protocols`. Ensure that skill is active throughout the initialization process.

-   **Discord Notifications**: If the setup requires user input (via `ask_user`), you MUST send a Discord notification BEFORE using `ask_user`.
    -   **Command**: Execute the `mcp_standard-nushell_evaluate` tool with `to-discord $message -p`.
    -   **Sequencing**: **WAIT** for the `to-discord` command to finish execution before calling `ask_user`.
    -   **Visibility Mandate**: The exact same information sent to Discord MUST also be explicitly included in the `ask_user` call (or equivalent), such that even though a message is sent to Discord, the information must also be shown to the user in the chat.
    -   **`ask_user` Fallback**: If the `ask_user` tool is unavailable or not accessible in the current environment, ask the user directly by outputting your question as plain text in the chat interface.