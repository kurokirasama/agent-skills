---
name: longterm-memory-orchestrator
description: High-level orchestrator for the Long-Term Memory system. Explains objectives and activation triggers, spawning the memory-expert agent (agent-first) with fallback to reader/writer skills.
---

# Long-Term Memory Orchestrator

## Overview
This skill acts as the high-level coordination layer for the Obsidian-based Long-Term Memory (LTM) system. Its primary purpose is to define the system's objectives and provide detailed guidance on when to **spawn the `memory-expert` agent** (agent-first strategy) or fall back to the specialized LTM sub-skills. It ensures that the agent maintains a consistent identity and project awareness across different workspaces and sessions.

## Objectives
- **Session Continuity**: Ensure the agent can pick up where it left off by loading project-specific context at the start of every session.
- **Project Awareness**: Maintain detailed, dated logs of decisions, milestones, and technical findings for every project.
- **Global Identity**: Evolve a global semantic memory (BRAIN) and agent personality (SOUL) by consolidating insights from across all projects.
- **Context Efficiency**: Leverage agent isolation and context-mode to manage memory data without flooding the active context window.

## Agent-First Strategy (PRIMARY)

For ALL LTM operations below, first **spawn the `memory-expert` agent** with the appropriate instructions. The agent handles both reader and writer workflows in an isolated thread:
- **Reader ops** → `@memory-expert` (instructions: run init-session / get-context / gather-unconsolidated-memories / load-trajectory-logs / search)
- **Writer ops** (track archival, phase completion, trajectory log, project init, BRAIN/SOUL consolidation) → `@memory-expert` (instructions: write trajectory log / append update / update BRAIN/SOUL)

**Invocation pattern:** delegate the operation to the agent using the `task` tool (OpenCode) or `@memory-expert` reference (Gemini CLI / agy), passing a precise instruction of which reader/writer workflow to run and for which project path.

### 1. Reader Operations (`@memory-expert`)
Spawn the agent for these triggers:
- **Start of Session (Mandatory):** As part of the Mandatory Pre-Task Protocol, spawn `@memory-expert` to run `init-session $env.PWD` and return project context + BRAIN/SOUL summary. `init-session` returns a concise Markdown string. For deep research into historical logs, instruct agent to use `context-mode`.
- **Project Switch:** On moving to a different workspace directory, spawn the agent to re-read context for the new path (`get-context`).
- **Historical Lookup:** "how did we do X before?" / "what was the fix for Y?" → spawn agent to search project logs (`load-trajectory-logs`).
- **Architectural Discovery:** before proposing major changes, the agent checks `BRAIN.md` for existing patterns or technical debt.
- **Personality Check:** when unsure about tone/style, the agent checks `SOUL.md`.
- **Consolidation Data:** `gather-unconsolidated-memories` → spawn agent to gather entries.

### 2. Writer Operations (`@memory-expert`)
Spawn the agent for these:
- **Track Lifecycle Events:** append update to project log when a Conductor track is started, archived, or deleted.
- **Track Archival (CRITICAL):** When a Conductor track is archived or completed, this orchestrator MUST be activated AFTER `git-sync` completes. Spawn `@memory-expert` with instructions: write trajectory log (`write-trajectory-log`) and append a completion update to the project's episodic memory. This orchestrator is the mandatory entry point — never write memory directly for track archival without first ensuring this orchestrator is active. ALWAYS attempt the trajectory log via the agent's writer workflow.
- **Phase Completion:** spawn agent to record summary, key decisions, and current state.
- **Cognitive Decisions:** spawn agent to record the "why" and "how" for future sessions.
- **First-Time Setup:** if a project has no existing note, spawn agent to initialize the folder and index note.
- **Global Consolidation:** spawn agent to run `gather-unconsolidated-memories`, analyze, and update `BRAIN.md` / `SOUL.md`.

## Fallback to Skills (on Agent Spawn Failure)

If the `memory-expert` agent fails to spawn, **transparently fall back** to activating the corresponding skill. Detect the failure patterns per platform:

| Platform | Error Patterns Triggering Fallback | Fallback Skill |
|----------|-----------------------------------|----------------|
| OpenCode | `Unknown agent type`, `Model not found: inherit/`, `task` tool error, `Agent would be spawned with zero tools` | `longterm-memory-reader` (read) or `longterm-memory-writer` (write) |
| Gemini CLI / agy | agent not in `agy agent` list, `Agent execution terminated`, `RESOURCE_EXHAUSTED (429)`, quota errors | `longterm-memory-reader` / `longterm-memory-writer` (synced to `~/.gemini/antigravity-cli/skills/`) |
| Claude Code | `Agent would be spawned with zero tools`, `not found`, permission denial | activate `longterm-memory-reader` / `longterm-memory-writer` skill |

**Fallback execution:** When the agent fails to spawn, immediately `activate_skill("longterm-memory-reader")` (for read ops) or `activate_skill("longterm-memory-writer")` (for write ops). The skills provide the identical workflows in the main thread. Never leave a memory operation incomplete.

## Workflow Summary
- **Intent:** The orchestrator defines which LTM operation is needed.
- **Primary path:** Spawn the `memory-expert` agent with precise instructions (reader vs writer workflow + project path). The agent executes in isolation and returns a concise summary.
- **Fallback path:** If the agent fails to spawn (any platform pattern above), `activate_skill` the corresponding reader/writer skill and run the workflow directly in the main thread.
- **Archival chain:** `git-sync` → this orchestrator → spawn agent (or fallback to `longterm-memory-writer`) → `write-trajectory-log`.
- **Safe Archival Guarantees:** `write-trajectory-log` is merge-safe and idempotent (parallel sessions append under session headers, never clobber; atomic `.bak` backups before each write). Insight notes must also be registered in the `INSIGHTS/INSIGHTS.md` waypoint index via `append-insight-waypoint` (see `longterm-memory-writer`).