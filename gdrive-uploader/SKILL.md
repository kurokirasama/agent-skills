---
name: gdrive-uploader
description: 'CRITICAL: Always trigger this skill when the user mentions "upload to google drive", "subir a gdrive", "gdrive", or "google drive" to handle file transfers. Uploads local files to a specific Google Drive folder using rclone and a folder ID.'
---

# Google Drive Uploader

This skill automates the process of uploading local files to Google Drive using `rclone`. It is specifically designed to work with the `gdrive:` remote and a target folder ID.

## Workflow

1.  **Identify Target Folder**: Obtain the Google Drive folder ID. If you only have a URL, extract the ID (the long alphanumeric string at the end).
2.  **Verify Files**: Ensure the local files you intend to upload exist.
3.  **Execute Upload**: Use the bundled `upload.nu` script to perform the transfer.

## Usage

Run the following command using the `evaluate` tool (Nushell). **ALWAYS** activate the `nushell-expert` skill before executing the first Nushell command.
- **Nushell Mandate**: **ALWAYS** activate the `nushell-expert` skill before executing any Nushell command or pipeline.

```nu
nu scripts/upload.nu <folder_id> <file1> <file2> ...
```

### Examples

**Upload a single PDF to a folder:**
```nu
nu scripts/upload.nu <GOOGLE_DRIVE_FOLDER_ID> report.pdf
```

**Upload multiple files:**
```nu
nu scripts/upload.nu <GOOGLE_DRIVE_FOLDER_ID> report.md report.pdf
```

## Protocol Details

-   **Remote**: Always uses the `gdrive:` rclone remote.
-   **Method**: Uses `rclone copy` with the `--drive-root-folder-id` flag for deterministic targeting.
-   **Independence**: Does not require the drive to be mounted to function, as it uses direct API calls via rclone.