---
name: cron-pixel-wallpapers
description: Automates downloading new pixel-art live wallpapers from moewalls.com, extracting their first frame, and moving it to the wallpaper folder. Use when checking for new pixel-art wallpapers or running the weekly wallpaper sync.
---

# cron-pixel-wallpapers

Autonomous cron skill for moewalls.com pixel-art wallpaper management: scans the newest wallpapers, downloads new mp4s, extracts the first frame via `media get-frame`, moves it to the wallpaper folder, and deletes the mp4s.

## Nushell Execution Protocol

**CRITICAL: All Nushell commands MUST be executed via the `standard-nushell_evaluate` MCP tool.**

**Fallback (only if the `evaluate` tool is unavailable):**
```
nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c '<nushell_code>'
```

**CRITICAL: Never use the `to-discord` nushell command. Do not send any Discord notifications.**

**ALWAYS activate the `nushell-expert` skill before the first Nushell command.**

## Configuration
- **Source:** `https://moewalls.com/category/pixel-art/?order=newest` (pagination: `https://moewalls.com/category/pixel-art/page/N/?order=newest`)
- **Wallpaper folder:** `/home/username/workspace/Wallpapers_pixels`
- **Downloads folder:** `/home/username/workspace/Downloads`
- **Download endpoint:** `https://go.moewalls.com/download.php?video=<data-url>` (data-url from the `#moe-download` element on each detail page)
- **Frame extraction:** `media get-frame` (default time 00:00:00, outputs `<stem>.png` next to the source; parallelizes multiple videos)

## Agent Workflow (Mandatory)

The workflow is split into three stages. The deterministic discovery/download and finalize logic lives in the script; frame extraction uses the user's `media get-frame` command (available in the evaluate session context) because it parallelizes multiple videos and honors the user's config.

1.  **Discover and download** via `evaluate` tool:
    ```nu
    nu /home/username/workspace/llms_configs/skills/cron-pixel-wallpapers/scripts/check-wallpapers.nu --download
    ```
    The script fetches the newest list, paginates until a known wallpaper is found (existence key `<title>-moewalls-com`, extension-agnostic), and downloads each new mp4 to `~/workspace/Downloads/<title>-moewalls-com.mp4`. It prints the summary and the list of downloaded mp4 files.
2.  **Extract first frames** via `evaluate` tool — pipe the downloaded mp4s directly (no name filtering):
    ```nu
    cd /home/username/workspace/Downloads/
    ls *.mp4 | media get-frame 00:00:00
    ```
    This creates `<title>-moewalls-com.png` next to each mp4, in parallel.
3.  **Finalize** via `evaluate` tool:
    ```nu
    nu /home/username/workspace/llms_configs/skills/cron-pixel-wallpapers/scripts/check-wallpapers.nu --finalize
    ```
    The script moves each PNG to the wallpaper folder (idempotent — skips already-present keys), deletes the mp4s on success, and prints the summary.
4.  **Handle failures:** If the script reports errors or fails to parse (e.g. moewalls changed its HTML), inspect the page markup, update the script's regexes, and re-run.
5.  **Report:** Print the script's summary to stdout.

## Naming Convention
- Folder stem = `<title>-moewalls-com` where `<title>` is the detail-URL slug minus the trailing `-live-wallpaper`.
- Existence is checked extension-agnostically (`<stem>.*`), so existing `.jpg` files and new `.png` frames never collide or re-download.

## Schedule
Recommended: **weekly** (moewalls publishes ~4 pixel-art wallpapers/month, irregularly). The crontab wiring is the user's responsibility.

## Output Format (MANDATORY)

Output a bullet-point Markdown summary to stdout covering:
- New wallpapers found
- Mp4s downloaded
- Frames extracted and moved
- Mp4s deleted
- Errors encountered (if any)

**PROHIBITED:**
- Do NOT use horizontal rules (`---`) in output
- Do NOT output raw JSON to stdout
- Do NOT use tables in output
- Do NOT use the `to-discord` nushell command or send any Discord notifications

## Reporting Protocol
Output the structured Markdown report to stdout.
