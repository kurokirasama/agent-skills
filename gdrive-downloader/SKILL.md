---
name: gdrive-downloader
description: Downloads files and folders from Google Drive (including view-only restricted videos) preserving folder structure, with optional Whisper transcription. Use when the user asks to download a Drive folder, a Drive video/file, or provides a drive.google.com URL.
---

# Google Drive Downloader

Downloads files and directory trees from Google Drive preserving folder structures, with automatic failover across a three-tier download ladder (google-workspace MCP, rclone, and yt-dlp for view-only restricted videos) and optional Whisper transcription.

**Nushell Mandate:** ALWAYS activate the `nushell-expert` skill before executing the first Nushell command or pipeline.

---

## 1. URL Parsing & Identification

1. **Extract Target ID**:
   - Folder URL: `drive.google.com/drive/(u/N/)?folders/<ID>`
   - File URL: `drive.google.com/file/d/<ID>/view...`
   - Regex ID Pattern: `[A-Za-z0-9_-]{20,}` (strip query parameters like `?t=`, `?usp=sharing`).
2. **Handle Google Drive Shortcuts**:
   - Shortcuts point to a target ID elsewhere in Drive.
   - In rclone: `lsjson` identifies shortcuts (`ID: "<target>\t<shortcut>"`).
   - In MCP: inspect `drive_search` metadata to resolve the underlying file/folder target ID.

---

## 2. Preconditions & Health Checks

Before initiating downloads, verify the execution environment:

1. **rclone Remote (`gdrive:`)**:
   - Check connection: `rclone lsd gdrive:`
   - If error is `invalid_grant` / expired token:
     > [!IMPORTANT]
     > `rclone config reconnect gdrive:` requires an interactive browser session. Send a Discord notification (`to-discord $msg -p`) and alert the user to authorize rclone in their terminal before proceeding.
2. **Disk Space Verification**:
   - Check available destination space (`df -h <dest_path>`).
   - Compare with Drive folder size: `rclone size --json --drive-root-folder-id <ID> gdrive:`.
3. **Restricted Video Tooling (`yt-dlp`)**:
   - Verify yt-dlp binary: `which yt-dlp`
   - Requires access to Chrome browser cookies for authenticated stream extraction.
4. **Transcription Tooling (`whisper`)**:
   - Only required if transcription is explicitly requested (default is OFF).
   - Use the isolated GPU venv (`/home/username/.local/bin/whisper`), never the global system python.

---

## 3. Three-Tier Download Ladder

```
[Target URL / ID]
       │
       ▼
┌──────────────────────────────────────────────┐
│ Tier 1: google-workspace MCP                 │
│ Single files, non-folder downloads, metadata │
└──────────────────────┬───────────────────────┘
                       │ (Folder bulk or bulk structure needed)
                       ▼
┌──────────────────────────────────────────────┐
│ Tier 2: rclone (`gdrive:` remote)              │
│ Full folder inventory, directory preservation│
└──────────────────────┬───────────────────────┘
                       │ (403 cannotDownloadFile on view-only videos)
                       ▼
┌──────────────────────────────────────────────┐
│ Tier 3: yt-dlp Streaming Helper              │
│ Browser-cookie parallel download (3 workers) │
└──────────────────────────────────────────────┘
```

### Tier 1 — google-workspace MCP
- **Use Case**: Single file downloads, quick metadata lookups, inventory fallbacks.
- **Commands**:
  - Search/inventory: `mcp_google-workspace_drive.drive_search`
  - Download single file: `mcp_google-workspace_drive.drive_downloadFile`
- **Constraint**: Cannot preserve deep folder structures on bulk operations. Fallback to Tier 2 for full directories.

### Tier 2 — rclone (`gdrive:` Remote)
- **Use Case**: High-throughput bulk downloads, nested subfolder structure preservation.
- **Commands**:
  - List remote folder:
    ```bash
    rclone lsjson -R --files-only --drive-root-folder-id <FOLDER_ID> gdrive: > /tmp/drive_inventory.json
    ```
  - Copy folder contents preserving structure:
    ```bash
    rclone copy --drive-root-folder-id <FOLDER_ID> gdrive: "<DESTINATION_PATH>" -v --stats 10s
    ```
- **Error Handling**: If rclone encounters view-only restricted files, it fails with:
  `Failed to copy: googleapi: Error 403: This file cannot be downloaded by the user., cannotDownloadFile`
  Collect these failed file IDs and route them to Tier 3.

### Tier 3 — Restricted Videos (yt-dlp Helper)
- **Use Case**: View-only Google Drive video files blocked by `cannotDownloadFile` permission flags.
- **Execution**:
  Use the generalized bundled script `scripts/download_videos.sh`:
  ```bash
  bash skills/gdrive-downloader/scripts/download_videos.sh <tsv_file> <dest_base_dir> <log_file>
  ```
  - **TSV Input Format**: `<drive_file_id>\t<relative_path>` (tab-separated).
  - **Behavior**: Spawns up to 3 parallel workers using yt-dlp with Chrome cookies to stream and merge 1080p/720p streams into MP4s.
  - **Markers**: Appends `OK <id>` or `FAIL <id>` to `<log_file>`, terminating with `DONE <timestamp>`.
- **Non-Video Restricted Files**: If non-video files (e.g., restricted PDFs, ZIPs) return 403, there is no streamable route; flag them in the final report and instruct the user to ask the owner for download permissions.

---

## 4. Optional Whisper Transcription

Transcription is **opt-in** (only executed when the user explicitly requests transcriptions).

- **Execution**:
  ```bash
  bash skills/gdrive-downloader/scripts/transcribe_videos.sh <videos_dir> <transcriptions_dir> <language> <log_file>
  ```
- **Behavior**:
  - Waits for the `DONE` marker in `<log_file>`.
  - Iterates over all downloaded `.mp4` files, skipping any that already have a `.txt` in `<transcriptions_dir>`.
  - Transcribes audio using `whisper` (`--model large-v3-turbo --language <lang> --output_format txt`).
  - Mirrors the nested video directory structure inside `<transcriptions_dir>`.

---

## 5. Verification & Inventory Reporting

Upon task completion, generate a structured markdown report:
1. **Inventory Reconciliation**: Compare total remote files discovered vs. local files present.
2. **Video Integrity Check**: Run `ffprobe` or verify file sizes on downloaded videos to ensure complete streams.
3. **Execution Summary**:
   - Total files requested / discovered
   - Downloaded via rclone (Tier 2)
   - Downloaded via yt-dlp (Tier 3)
   - Transcripts generated (if enabled)
   - Failed files & specific remedies (e.g., restricted non-video files)

---

## References

For the complete technical specification, architectural decision matrix, and recovery procedures:
- [bulk_downloader_spec.md](references/bulk_downloader_spec.md)
