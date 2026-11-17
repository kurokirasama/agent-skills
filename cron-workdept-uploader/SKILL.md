---
id: cron-workdept-uploader
name: cron-workdept-uploader
description: Autonomous skill to select, summarize, optimize, and upload WORK SUBJECT thesis/general videos, generate and publish YouTube Shorts with virality metadata, and audit token health with automated dual alerts.
stateful: true
---

# WORK DEPT Video & Shorts YouTube Uploader Skill

Expert autonomous agent for cataloging, summarizing, optimizing, and publishing undergraduate thesis presentation videos (*Proyectos de Título*), general academic videos, and viral YouTube Shorts from the Work University SUBJECT program to the official YouTube channel (`@workdept`).

**MANDATORY:** You MUST activate the `nushell-expert` skill before executing any command or step in this skill. All pipeline commands (`aimsy`, `yt-get-access-token`, `media cut-video`, `media crop-video`, `ai video2text`, etc.) are Nushell commands and MUST be executed in the Nushell environment via the Nushell MCP server (`standard-nushell` `evaluate` tool) or the Nushell fallback command (`nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c '<nushell_code>'`).

---

## 1. Directory Structure & Staging Paths

- **Pending Videos (Staging)**: `/home/username/workspace/Downloads/videos_titulos/to_upload`
- **Completed Videos (Archive)**: `/home/username/workspace/Downloads/videos_titulos/uploaded`
- **Shorts Download Cache**: `/tmp/workdept_shorts_cache`
- **Skill State**: `state.json` (in this skill directory)
- **Execution Log**: `log.txt` (in this skill directory)
- **Virality Heuristics & Research**: `references/virality_research.md`
- **Setup & Prerequisites**: `references/setup_guide.md`

---

## 2. Core Logic & Two-Phase Pipeline Workflow

Each autonomous pulse executes with strict operational ordering:

```
[Pulse Start]
      │
      ▼
0. Token Health Pre-Flight Check ────(Unattended renewal failed)───► [Discord Alert + Email to user@example.com] ──► [Abort Pulse]
      │ (Valid or auto-refreshed)
      ▼
1. Full Video Upload Pipeline (Strict Precedence)
   ├─ Check to_upload/ for pending .mp4 files
   ├─ If found: Classify -> Deduplicate -> Aimsy Summary -> Thumbnails -> Upload Resumable -> Move to uploaded/ -> Update state
   └─ If none found: Log and proceed directly to Phase 2
      │
      ▼
2. YouTube Shorts Generation & Upload Pipeline
   ├─ Select candidate from uploaded/ (fallback: YouTube channel via yt-dlp)
   ├─ Generate timestamped SRT transcript via `ai video2text --srt`
   ├─ Select 30–50s non-overlapping highlight via AI analysis
   ├─ Cut video (`media cut-video`) and crop to 1:1 centered (`media crop-video`)
   ├─ Build viral metadata (`<hook> #Shorts`) and upload to YouTube
   ├─ Persist interval in state.json under `shorts`
   └─ Clean up intermediate cut and cropped files
      │
      ▼
3. Unified Output Reporting (Stdout Markdown summary)
```

---

### Step 0: Token Health Pre-Flight & Dual Alerting

1. **Verify Token Status**: Call `check-token-health "workdept"`.
2. **Unattended Renewal**: If expired, attempt unattended renewal via `yt-get-access-token workdept` (calling `yt-oauth-refresh-token`).
3. **Dual Alert Dispatch**: If the token cannot be renewed unattended (missing/expired refresh token):
   - Dispatch immediate Discord notification via `to-discord -p`.
   - Send notification email to `user@example.com` with subject `[URGENT] WORK DEPT YouTube OAuth Token Expired`.
   - Immediately abort execution pulse to prevent downstream failures.

---

### Step 1: Full Video Upload Pipeline (Strict Precedence)

If uncompleted videos remain in `to_upload/`, they MUST be processed before any Shorts generation.

1. **Scan Directory**: Check `/home/username/workspace/Downloads/videos_titulos/to_upload` for `.mp4` video files.
2. **Classify & Parse**:
   - **Thesis Video (`type: "thesis"`)**: Matches `{year}_{title}_-_{student}_final[_final].mp4`.
   - **General Video (`type: "general"`)**: Any other academic `.mp4`.
3. **Filter & Deduplicate**: Filter out files marked `"completed"` in `state.json`. Prioritize thesis videos (oldest year first), then general videos.
4. **Content Analysis & Summary**: Execute `aimsy` to extract content analysis with deterministic working directory and pre-flight cleanup of intermediate files. (Never paste raw summary into description; derive topic hashtags and brief insights).
5. **Thumbnails & Metadata**:
   - Extract candidate frames via `ffmpeg` and pick the best frame by visual entropy.
   - Activate and invoke the `youtube-thumbnail` skill to design and composite an optimized 16:9 thumbnail cover (1280x720) using `photocraft-cli mcp` or image tools:
     - Apply title hook typography (1–4 words, high contrast).
     - Protect the bottom-right timestamp exclusion zone (safe margin $\ge 60$px).
     - Preserve speaker identity and natural skin tones without distorting generative artifacts.
   - Build virality-optimized metadata (tags, category 27, SEO description).
6. **Upload & Move**: Resumable upload to `@workdept`, upload custom thumbnail, move `.mp4` to `uploaded/`, update `state.json.videos`.

---

### Step 2: YouTube Shorts Generation & Upload Pipeline

1. **Candidate Discovery**:
   - Check local archive `uploaded/` first. Select video with fewest existing shorts in `state.json.shorts` (tie-breaking randomly).
   - If `uploaded/` is empty, query published videos from YouTube channel `@workdept` and download via `yt-dlp` into `/tmp/workdept_shorts_cache/`.
2. **SRT Transcription**:
   - Execute `ai video2text --srt $video_path` with deterministic CWD in video directory, pre-flight cleanup of stale intermediates to eliminate interactive ffmpeg prompts, and post-consumption cleanup.
   - Parse subtitle blocks containing `{ index, start, end, text }`.
3. **Highlight Selection & Deduplication**:
   - Query existing extracted intervals from `state.json.shorts.<stem>`.
   - AI evaluates subtitle blocks to select a compelling 30–50 second highlight (strictly $\le 60$ seconds) with high statistical insight, conclusion, or hook.
   - Strictly skips any interval overlapping previously recorded clips (`is-interval-overlapping`).
4. **Media Editing (Cut & 1:1 Crop)**:
   - **Cut**: `media cut-video $video_path $start_time $end_time -o $cut_file -r`
   - **Centered 1:1 Crop**:
     - Compute dimensions: `height:height`, `left = (width - height) / 2`, `top = 0`.
     - Execute: `media crop-video $cut_file --size $"($H):($H)" --left $"($L)" --top "0" -a "short_1x1"`
5. **Metadata Construction**:
   - **Title**: `<hook> #Shorts` (concise hook + `#Shorts`).
   - **Description**: Institutional context and virality hashtags (`#Shorts #SUBJECT #WORK #DataScience #Estadistica ...`). AI rationale is strictly clean and omitted from public descriptions.
   - **Tags & Category**: YouTube Category `27` (Education), public privacy status.
6. **Upload & State Persistence**:
   - Upload cropped short via `upload-video-resumable`.
   - Record segment in `state.json.shorts.<stem>` with timestamps, duration, video ID, and URL.
   - Clean up temporary `$cut_file` and `$cropped_file`.

---

### Step 3: Email Notification (live uploads only)

- NEVER run during dry-run.
- After a successful live full video upload, execute the notification protocol per `references/email_notification_guide.md`.
- **Pre-Flight Verification Gate**:
  - If `state.json.email_verified` is false (or missing):
    1. Send test email to `user@example.com` (`[TEST]` subject + banner).
    2. Verify `From` header via `gmail.get` and inbox reading.
    3. If `From = user@work.example.edu`: set `email_verified: true` (auto-approve) in `state.json` and proceed to production notification in the same pulse. Send informational Discord notification for visibility.
    4. If `From` is NOT `user@work.example.edu`: halt production, report failure via Discord alert, and do NOT send to `colleague@work.example.edu`.
- **Production Notification**:
  - If `state.json.email_verified` is true: send notification email to `colleague@work.example.edu` following the template in `references/email_notification_guide.md` with `<url> = https://youtu.be/<video_id>`.
- **Failure Resilience**: On any email dispatch failure, log the error to `log.txt` and report in stdout. Do NOT fail the upload pulse.

---

### Step 4: State Format

The `state.json` file maintains both full video uploads, Shorts extractions, and the email verification gate:

```json
{
  "email_verified": false,
  "last_uploaded": {
    "id": "<video_id>",
    "filename": "<filename>",
    "uploaded_at": "<iso_timestamp>"
  },
  "queue": [],
  "videos": {
    "<stem>": {
      "status": "completed",
      "type": "thesis",
      "video_id": "<video_id>",
      "url": "https://youtu.be/<video_id>",
      "year": 2023,
      "student": "Student Name",
      "uploaded_at": "<iso_timestamp>",
      "thumbnail_uploaded": true
    }
  },
  "shorts": {
    "<stem>": [
      {
        "video_id": "<short_id>",
        "url": "https://youtu.be/<short_id>",
        "start_time": "00:01:15",
        "end_time": "00:01:55",
        "start_sec": 75,
        "end_sec": 115,
        "duration": 40,
        "title": "Modelos Predictivos Avanzados #Shorts",
        "uploaded_at": "<iso_timestamp>"
      }
    ]
  }
}
```

---

## 3. Resilience & Error Handling

- **Token Expiration**: Automatically attempts unattended refresh. If manual re-auth is needed, triggers immediate Discord (`to-discord -p`) and Email alerts (`user@example.com`) and aborts cleanly.
- **Deduplication Safety**: Never extracts overlapping clips from the same source video.
- **Resource Cleanliness**: Automatically deletes intermediate cut (`_cut.mp4`) and cropped (`_cut_short_1x1.mp4`) files after upload or on failure.
- **Non-Destructive**: Never deletes or modifies original videos in `uploaded/`.
- **Dry-Run Mode**: Supports `--dry-run` across all scripts, simulating token checks, aimsy summarization, SRT transcription, highlight selection, media editing, and metadata generation without modifying disk state or YouTube channels.
