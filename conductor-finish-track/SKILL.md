---
name: conductor-finish-track
description: Verifies completion, archives the active Conductor track, and coordinates parallel git-sync and longterm-memory-orchestrator tasks via subagents. Use when finishing or completing a Conductor track, or when user runs /conductor-finish-track.
---

# Conductor Finish Track

This skill automates the safe, verified finalization and teardown of Conductor development tracks. When invoked (via `/conductor-finish-track` or direct trigger), it validates that all tasks and reviews are completed, then delegates archival/git synchronization and long-term memory updates to parallel subagents (with transparent sequential fallback).

## Core Protocol & Prerequisites

**CRITICAL MANDATE:** Before executing any part of this workflow, ensure the `conductor-core-protocols` skill is active.
Ensure the `nushell-expert` skill is active before any Nushell evaluation.

## Workflow

### Step 1: Pre-Archival Gatekeeper (Verification)

Before modifying any track files or git state, verify the track's completion status:

1. **Locate Track Plan:** Resolve the active track folder in `conductor/tracks/<track_id>/` and read `plan.md`.
2. **Task Completion Check:**
   - Verify that all tasks and subtasks in `plan.md` are marked complete (`[x]`).
   - If any tasks remain pending (`[ ]` or `[~]`), **HALT immediately** and notify the user of the pending tasks.
   - *Bypass*: If the user explicitly provided `--force`, proceed with a warning.
3. **Review Verification:**
   - Verify that the track has undergone review (all phase checkpoints completed, review tasks checked off, or explicit user sign-off).
   - If not reviewed (and no `--skip-review`/`--force`): run `conductor-review` automatically; if it yields High/Critical findings, HALT and report; otherwise continue with archival.
   - Incomplete plan: HALT (user action or `--force` required), unchanged.

You can execute the verification check programmatically using the helper script:
```nu
use skills/conductor-finish-track/scripts/finish_track.nu *
let res = verify-plan-completed "conductor/tracks/<track_id>/plan.md"
if not $res.completed {
    print $"Pending tasks: ($res.pending | str join ', ')"
}
```

---

### Step 2: Parallel Subagent Delegation Engine (PRIMARY)

If the runtime supports concurrent subagent spawning (e.g. `invoke_subagent` or multi-threaded agent execution), spawn **two parallel tasks concurrently**:

#### Subagent Task 1: Track Archival & Source Control Synchronization
- **Goal:** Perform atomic track archival and complete git synchronization.
- **Actions:**
  1. Move `conductor/tracks/<track_id>` to `conductor/archive/<track_id>`.
  2. Update `conductor/archive/<track_id>/metadata.json` setting `status: "archived"` and `completed_at` timestamp.
  3. Remove the track entry from `conductor/tracks.md`.
  4. Activate and execute the `git-sync` skill to stage all changes, generate conventional commit messages, and synchronize with the remote origin.

```nu
# Executed by Subagent A
use skills/conductor-finish-track/scripts/finish_track.nu *
archive-track-folder "<track_id>"
update-track-metadata "<track_id>"
cleanup-tracks-registry "<track_id>"
```

#### Subagent Task 2: Long-Term Memory & Retrospective Orchestration
- **Goal:** Update episodic memory, record session trajectory, and evaluate retrospective insights.
- **Actions:**
  1. Activate and execute the `longterm-memory-orchestrator` skill (or spawn `@memory-expert`).
  2. Follow the orchestrator to persist a trajectory log via `write-trajectory-log` and append track completion details to `AGENTS_MEMORY/<project>/<project>.md`.
  3. Evaluate retrospective triggers: if the track introduced new issues, required high effort, or yielded strategic architectural lessons, trigger the `session-retro` skill to generate and link an Obsidian `INSIGHTS/` note.

---

### Step 3: Sequential Fallback Strategy (on Subagent Spawn Failure)

If subagent spawning is unavailable, unsupported in the current CLI environment, or fails with errors (e.g. quota limits or thread restrictions), **transparently execute the workflow sequentially in the primary thread**:

1. **Archival:** Run `nu skills/conductor-finish-track/scripts/finish_track.nu <track_id>`.
2. **Git Synchronization:** Activate the `git-sync` skill and execute the stage-commit-push loop.
3. **LTM Orchestration:** Activate the `longterm-memory-orchestrator` skill and record the completion and trajectory log.
4. **Retrospective Evaluation:** If qualifying criteria are met, execute the `session-retro` skill.

---

## When NOT to Use

- Do NOT use on incomplete tracks unless `--force` is explicitly provided by the user.
- Do NOT use when the user only wants to pause or switch tracks without archiving (use track switching instead).
- Do NOT bypass `git-sync` or long-term memory updates; both are mandatory post-archival protocols.
