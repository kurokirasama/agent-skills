# Conductor Finish Track Reference

## Overview
The `conductor-finish-track` skill coordinates the end-of-track lifecycle for Conductor projects. It automates two critical post-implementation tracks:

1. **Track Archival & Source Control Synchronization:**
   - Moves track folder from `conductor/tracks/<track_id>` to `conductor/archive/<track_id>`.
   - Records `status: "archived"` and `completed_at` timestamp in `metadata.json`.
   - Cleans up `conductor/tracks.md` registry.
   - Triggers `git-sync` to ensure clean working tree and remote synchronization.

2. **Long-Term Memory & Retrospective Orchestration:**
   - Triggers `longterm-memory-orchestrator` / `@memory-expert`.
   - Persists session trajectory log (`write-trajectory-log`).
   - Appends completion entry to project episodic memory in `AGENTS_MEMORY/<project>/<project>.md`.
   - Evaluates `session-retro` triggers (new issues, high effort, strategic lessons) and generates an `INSIGHTS/` note in Obsidian if applicable.

## Subagent Parallelism
When running on an agent environment that supports subagent threads (e.g. `invoke_subagent` or multi-agent delegation), these two tasks run in parallel. When subagents are unavailable, the skill executes them sequentially in the main thread without interruption.
