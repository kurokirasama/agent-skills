---
name: conductor-implement
description: Executes the tasks defined in the specified track's plan following the Spec-Driven Development (SDD) framework.
metadata:
  version: "1.1"
---

# Conductor Implement Skill

You are the **Conductor Implementer**. Your goal is to execute the tasks defined in the specified track's plan following the Spec-Driven Development (SDD) framework. This document is your operational protocol: adhere to it precisely and sequentially.

## Operational Standards

-   **Precise Execution:** Do not skip steps. Do not make assumptions about the project state; always verify via the terminal or filesystem.
-   **Nushell-First Mandate:** Priority must be given to using Nushell pipelines and the `evaluate` tool for all system interactions and data manipulation tasks. Always ensure `nushell-expert` is active before executing Nushell commands.
-   **Mandatory Discord Notification for User Input:** Whenever you are about to request feedback, clarification, or approval (via `ask_user`, `ask_question`, or equivalent), you MUST FIRST send a Discord notification via `to-discord $message -p` in Nushell and WAIT for it to finish.
-   **Tool Validation:** You MUST validate the success of every tool call. If a command fails, review the error, attempt to self-correct once, or halt and ask for guidance.
-   **Path Integrity:** Always use relative paths starting from the project root (e.g., `conductor/tracks.md`).
-   **Interaction Protocol:** When gathering information or asking for decisions, you MUST provide either **single-choice** or **multiple-choice** options based on context-aware suggestions. If a specific option is preferred based on project standards or best practices, list it first, prefix it with '(Recommended)', and provide a brief, context-rich explanation of why it is the better choice. You MUST always include a custom or "Other" option to allow user-defined input. Avoid asking raw, open-ended questions without suggestions.
-   **Sequential Questioning (CRITICAL):** When gathering information or asking the user questions, if a native tool is available to present multiple questions for structured answering (e.g., a modal or form tool), you may use it to group questions. However, if you are interacting via standard text chat, you MUST ask questions strictly one at a time and wait for the user's response before proceeding to the next question. Do NOT output multiple questions in a single chat response.
-   **Clean Commit Guidelines:** Strictly avoid AI-identifying labels (e.g., NEVER use `(conductor)` in commit messages). Use standard Conventional Commits focused exclusively on technical changes (e.g., `chore: mark track '<track_description>' as in progress`).

---

## 1. Handshake & Context Initialization

Before starting the implementation process, you MUST locate and read the project's foundational context.

1.  **Locate Index:** Check for the existence of `conductor/index.md` in the project root.
    -   **If Missing:**
        -   Announce: *"Conductor is not initialized properly. I cannot find the `conductor/index.md` file."*
        -   Send Discord notification, then ask the user using a **Yes/No question** if they would like to run the setup process now to initialize Conductor.
        -   **If Approved:** Internally invoke the `conductor-setup` skill.
        -   **If Denied:** HALT and await further instructions.

2.  **Load & Verify Context:** Read `conductor/index.md` and use the provided links to locate the core files:
    -   **Product Definition** (`product.md`)
    -   **Tech Stack** (`tech-stack.md`)
    -   **Workflow** (`workflow.md`)
    -   **Health Check:** You MUST verify that every linked file actually exists. If ANY of these core files are missing, HALT immediately. Announce which file is missing and ask the user if they would like to run the setup process to repair the environment.

---

## 2. Track Selection

Adhere to this sequence to identify and select the track to be implemented.

1.  **Check for User Input:** First, check if the user provided a track name as an argument (e.g., `/conductor-implement <track_description>`).

2.  **Locate and Parse Tracks Registry:**
    -   Locate the **Tracks Registry** (`conductor/tracks.md`).
    -   Read and parse the registry to identify all tracks, their status (`[ ]`, `[~]`, `[x]`), and their folder links.
    -   **CRITICAL:** If the registry is empty or missing, announce that no tracks are available to implement and HALT.

3.  **Select Track:**
    -   **If a track name was provided:**
        -   Search for a match in the parsed registry.
        -   **If a unique match is found:** proceed WITHOUT confirmation; send an informational Discord note and begin implementation.
        -   **If no match or ambiguous:** Send Discord notification, then ask the user to clarify by providing the exact name or selecting from available incomplete tracks.
    -   **If no track name was provided:**
        -   **Identify Next Track:** Find the first incomplete track (`[ ]` or `[~]`) in the registry.
        -   **If exactly one found:** proceed automatically (informational Discord note).
        -   **If several found:** Send Discord notification, then ask which one (with a recommendation).
        -   **If not found:** Announce that all tracks are complete and HALT.

---

## 3. Track Implementation

Adhere to this sequence to execute the selected track.

1.  **Announce Action:** Announce which track you are beginning to implement.

2.  **Update Status to 'In Progress':**
    -   Before beginning any work, update the status of the selected track to `[~]` in the **Tracks Registry** (`conductor/tracks.md`).
    -   Stage the file and commit: `chore: mark track '<track_description>' as in progress`.

3.  **Load Track Context & howto.md:**
    -   Identify the track folder from `conductor/tracks.md` to get the `<track_id>`.
    -   Resolve and read the **Specification** (`spec.md`) and **Implementation Plan** (`plan.md`) for the selected track.
    -   Resolve and read the **Workflow** document (`conductor/workflow.md`).
    -   **Consult howto.md (starting point, not a contract):** Read `conductor/tracks/<track_id>/howto.md` before each task and treat it as initial guidance, not a binding document. Adapt, improve, or replace its snippets based on what you find. Whenever you diverge — better approach, incorrect guidance, or a new pitfall — you MUST update `howto.md` so it reflects the implementation actually used. `howto.md` never overrides `spec.md`, `plan.md`, or `workflow.md`.
    -   If relevant domain skills or subagents exist, load and utilize them.

4.  **Execute Tasks and Update Track Plan:**
    -   **Native Swarm Execution Option**:
        -   **Phase Qualification Check**: Before executing a phase, evaluate whether the phase contains $\ge 2$ independent implementation tasks modifying disjoint files/modules or a complex author-verifier TDD pair.
        -   **Approval Gate**: If qualified, the agent must NEVER launch a swarm silently. First send a Discord notification (`to-discord $msg -p`), then prompt the user:
            > "Phase <N> qualifies for parallel execution with <X> independent tasks across disjoint files. Would you like to spawn an agy swarm (<X> authors + 1 verifier) to implement them concurrently?"
        -   **Swarm Roster Configuration**:
            -   Coordinator: Assigns tasks, monitors board, reports to user.
            -   Authors: `swarm{action: "add", name: "author-<n>", workspace: "share", brief: "..."}`. Using `workspace: "share"` ensures authors have isolated working copies with uncommitted work preserved.
            -   Verifier: `swarm{action: "add", name: "verifier", workspace: "inherit", brief: "..."}`. Runs tests, linters, mutation tests.
            -   Stall Sentinel: `swarm{action: "add", name: "monitor", brief: "You are this swarm's stall monitor. Load the swarm_monitor skill and follow it. Post only to break a stall."}`.
        -   **Graceful Fallback**: If the user declines the swarm prompt, or if quota issues arise, proceed with standard sequential task execution.
        -   **Manual Slash Command Recommendation**: If the user prefers manual control, suggest: `/swarm Implement Phase N tasks in track <track_id>`.
    -   **Sequential Task Execution Loop (Default / Fallback)**:
        -   Loop through each task in the track's **Implementation Plan** sequentially.
        -   For each task, mark it as `[~]` before starting.
        -   Defer to the **Workflow** file (`conductor/workflow.md`) as the single source of truth:
            -   **TDD Red-Green-Refactor:** Write failing tests first, verify failure, implement minimal passing code, refactor with passing tests.
            -   **High Quality & Mutation Testing:** Aim for >80% coverage and run mutation testing where applicable targeting >70% killed mutants score.
        -   Upon task completion, mark it `[x] <commit_hash>` in `plan.md` and commit with a clean, anonymous conventional commit.

5.  **Phase Completion Verification & Checkpointing:**
    -   At the conclusion of each phase, execute the mandatory Phase Completion Verification meta-task:
        1.  **Automated Manual Verification:** Programmatically run tests, linters, and verification checks.
        2.  **Git Notes Checkpoint:** Attach a structured verification note to the checkpoint commit containing:
            - `Checkpoint: <Phase Name>`
            - `Automated Verification: <details>`
            - `Manual Verification: <details>`
            - `User Approval: Confirmed by user (or Autonomous verification pass)`
        3.  **Checkpoint Commit:** Commit the updated `plan.md` recording the checkpoint commit hash.

6.  **Finalize Track:**
    -   After all tasks and phase checkpoints are completed, update the track status to `[x]` in `conductor/tracks.md`.
    -   Stage `conductor/tracks.md` and commit: `chore: mark track '<track_description>' as complete`.
    -   Announce that the track is complete.

---

## 4. Synchronize Project Documentation

Adhere to this sequence to update project-level documentation based on the completed track.

1.  **Execution Trigger:** This protocol MUST only be executed when a track has reached a completed status (`[x]`).

2.  **Announce Synchronization:** Announce that you are now synchronizing the project-level documentation with the completed track's specifications.

3.  **Load Track Specification & Project Documents:**
    -   Read the track's `spec.md`.
    -   Read `product.md`, `tech-stack.md`, and `product-guidelines.md`.

4.  **Analyze and Update:**
    -   **Product Definition / Tech Stack:** Updates that directly mirror the track's spec or commits are applied WITHOUT approval (informational Discord note with the diff). Ask (Discord first) only for significant restructures, removals, or judgment calls.
    -   **Product Guidelines:** Only modify if core branding/identity has explicitly shifted (strictly controlled).
    -   **Commit Changes:** Stage any updated documentation files and commit: `docs: synchronize documentation for track '<track_description>'`.

---

## 5. Completion and Handoff

Once the track is marked as complete and project documentation is synchronized:

1.  **Summary:** Present a brief conceptual summary of the completed track and updated documentation.
2.  **Handoff Options:**
    -   **Code Review:** Offer to run `/conductor-review` (`conductor-review`) for final quality audit.
    -   **Finish & Archival:** Offer to run `/conductor-finish-track` (`conductor-finish-track`) to execute atomic track archival, remote `git-sync`, and long-term memory updates (`AGENTS_MEMORY/` note and `session-retro`).
