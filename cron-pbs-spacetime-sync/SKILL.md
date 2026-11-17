---
id: cron-pbs-spacetime-sync
name: cron-pbs-spacetime-sync
description: Autonomous skill to scan PBS Space Time channel, download transcripts, generate AI summaries, and sync to Obsidian.
stateful: true
---

# PBS Space Time Channel Sync Skill

Expert autonomous agent for syncing PBS Space Time channel content to a local Obsidian vault.

**MANDATORY:** You MUST activate the `nushell-expert` skill before executing any command or step in this skill. All command steps below (`ai yt-get-transcription`, `aimsc`, `h add todos`) are Nushell commands and MUST be executed in the Nushell environment via the Nushell MCP server (`standard-nushell` `evaluate` tool) or the Nushell fallback command (`nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c '<nushell_code>'`). Do NOT attempt to run them as standalone bash/sh binaries in PATH.

## Logic & Workflow

### 1. Discovery
- **Action**: Use `googlesuit-youtube_searchVideos(query: "from:@pbsspacetime", maxResults: 50)` (or equivalent) to obtain the latest video details.
- **Reference**: Cross-reference found video IDs/URLs with the local state (`/home/username/workspace/llms_configs/skills/cron-pbs-spacetime-sync/state.json`).
- **Logic**: Any video ID not present in the `videos` object of the state is added to the `queue`.
- **Status Update**: Mark existing entries in `videos` that have `download_status: "pending"` for re-processing if needed.

### 2. Processing Pipeline
- **Sequential Execution Loop**: Iterate through EACH video in the `queue`. Do NOT stop until the queue is empty or a quota limit is reached.
- For each video in the queue:
    - **Logging**: Before every step, write a descriptive entry to `log.txt` in the skill's directory explaining what is about to happen and why.
    - **Step 1: Download Transcript**:
        - Execute synchronously in Nushell via the `evaluate` tool (or `nu -c` fallback):
          ```nu
          ai yt-get-transcription $"($url)" --language "en" --force-mp3
          ```
        - **MANDATORY**: Wait for the command to finish and capture the output. Do NOT send to background (`&` is forbidden).
        - Log the success or failure of this step immediately.
    - **Step 2: Summarization**:
        - **Method A (File)**: If transcript exists, execute synchronously in Nushell via the `evaluate` tool (or `nu -c` fallback):
          ```nu
          aimsc $"($transcript_path)"
          ```
        - **Method B (Fallback)**: If transcript download failed, execute synchronously in Nushell via the `evaluate` tool (or `nu -c` fallback):
          ```nu
          aimsc $"($url)"
          ```
        - **MANDATORY**: Wait for the command to finish and capture the output.
        - Log the outcome and any errors.
    - **Step 3: State Update & Loop Persistence**: 
        - Update `state.json` and `log.txt`.
        - **Resilience**: If Nushell execution fails for a video (after retries), log the detailed error in `log.txt`, mark the video entry with `download_status: "failed"` and timestamped error details in `state.json`, and **IMMEDIATELY proceed to the next video in the queue**. Do NOT attempt ad-hoc non-Nushell scripts, manual subtitle scraping, or agent-native fallback summarization. Marking as `failed` ensures the video is cleanly preserved in state for subsequent scheduled cron runs to retry.
    - **Step 4: Create Todo to inform the user**: Execute via the nushell mcp evaluate tool (or `nu -c` fallback):
	```nu
	h add todos --checklist [] --priority 1 --text "new PBS SPACE TIME video processed" --notes "" --due ""
	```

### 3. Resilience & Error Handling
- **Model Exhausted**: On receiving this error from `aimsc`, pause for 60 seconds and retry up to 3 times. Log each retry attempt.
- **Quota Exceeded**: On receiving this error, log the event and immediately stop the execution pulse. Save the current `queue` to the state to resume in the next scheduled run.
- **Individual Failures**: If a specific video fails all retries, log the detailed error, mark it as `failed` (`download_status: "failed"`) in `state.json` with a timestamp and error message, and move to the next video in the queue. The video remains in state and will be picked up for re-processing in subsequent cron executions. Do NOT resort to manual ad-hoc subtitle downloads or agent-native summarization.

### 4. Organization & Storage
- **Vault Path**: `~/workspace/obsidian/vaults/PBS_SPACE_TIME`
- **Action**: Move finalized files to the corresponding year subdirectory.
    - **Naming**: Ensure files follow `YYYY_MM_DD_title.txt` and `YYYY_MM_DD_title_summary.md`.
- **Cleanup**: Delete any `-clean.txt` or temporary MP3 files created during the process. Keep only the final `.txt` transcript and `.md` summary in the vault.
- **Log Rotation**: (Optional) If `log.txt` exceeds 1MB, archive it to `log.old.txt`.

## Cron Wakeup Behavior
1. **Initialize**: Load state from `/home/username/workspace/llms_configs/skills/cron-pbs-spacetime-sync/state.json`. Ensure `log.txt` is ready for writing.
2. **Discovery Pulse**: Run the discovery logic to update the queue. Log number of new videos found.
3. **Execution Pulse**: Process the queue sequentially until complete or blocked by quota. Log every major transition.
4. **Finalize**: Update state and generate a plain Markdown report to stdout containing a summary of the run, including a snippet of the recent logs. Do NOT wrap in JSON envelopes.

## Expert Instructions
- **Strict Synchronicity**: NEVER use background operators (`&`) or asynchronous execution flags. Every tool call must be awaited and its output processed before moving to the next.
- **Persistent Looping**: The execution must continue until the entire `queue` is processed. Stopping after a single video is considered a failure.
- **Comprehensive Logging**: Maintain a real-time `log.txt` within the skill directory. Every decision, command start, command completion, and error must be logged with a timestamp and rationale.
- Prioritize native Nushell tools for file management and state manipulation.
- Ensure all `aimsc` calls are properly escaped for filenames with special characters.
- Maintain strict directory mirroring in the Obsidian vault.
- Follow the Conductor spec-driven development guidelines for any internal logic updates.

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.
