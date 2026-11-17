---
name: cron-manga-download-checker
description: Automates manga download verification via RSS notification emails from fanfox.net. Use when you need to check for missing manga chapters by scanning starred RSS emails and verifying local download directories.
---

# cron-manga-download-checker

Automated manga download verification via RSS notification emails.

## Verify available tools
FIRST verify that you have available the tools of the google-workspace mcp. If you don't, wait for 1 minute (via `sleep 60` shell command or `/schedule` command if available) and verify again, If you still don't have access to the tools, then inform the user that you don't and don't proceed with the request.

## Overview
This skill empowers the agent to autonomously verify manga downloads by checking starred RSS notification emails from fanfox.net. The agent identifies missing chapters and updates Gmail labels to alert the user.

## Agent Workflow (Mandatory)

1.  **Discovery**: Search for starred emails with the `rss` label using Gmail tools.
    -   Query: `is:starred label:rss`
2.  **Filtering**: For each email found, check the body or snippet for a link to `fanfox.net`.
    -   **Action**: If `fanfox.net` is NOT present, **IGNORE** the email. Do **NOT** unstar or modify it, as it may not be related to this skill.
3.  **Extraction**: For valid `fanfox.net` emails:
    -   Get the email body.
    -   Use the `text_processor.nu` script to strip HTML and extract the manga name, chapter, and direct URL. **ALWAYS** activate the `nushell-expert` skill before executing the first Nushell command.
    -   **Command**: `nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c 'use skills/cron-manga-download-checker/scripts/text_processor.nu *; let text = (strip-html \"<EMAIL_BODY>\"); parse-manga-info $text | to json'`
    -   **Nushell Mandate**: **ALWAYS** activate the `nushell-expert` skill before executing any Nushell command or pipeline.
4.  **Verification**: Check if the chapter folder exists in the local manga directory.
    -   **Path**: `~/workspace/Manga/<Manga_Name>/<Manga_Name> <Chapter_Number>`
    -   **Action**: Use `list_directory` or `ls` (via `evaluate` with `nushell-expert` active) to confirm existence.
5.  **Mutation & JDownloader Integration**:
    -   Update Gmail labels based on the result:
        -   **If found**: Remove the `STARRED` label.
        -   **If missing**: Remove the `STARRED` label, add `UNREAD`, and add `INBOX`.
    -   **Crawljob Creation**: If any missing chapter folders are verified:
        -   Collect all direct chapter URLs extracted from those emails.
        -   Invoke `generate-crawljob` to write a JDownloader crawljob file containing non-duplicate URLs in `/home/username/cloud/Aplicaciones/Gmail/folderwatched`.
        -   **Command**: `nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c 'use skills/cron-manga-download-checker/scripts/text_processor.nu *; generate-crawljob $urls'`

## Scripts

### `text_processor.nu`
Utility for HTML stripping, Regex extraction (manga info and chapter URLs), deduplication against existing folderwatched files, and properties-formatted JDownloader crawljob file generation.

## Configuration
- **Gmail Label**: `rss`
- **Manga Directory**: `~/workspace/Manga`
- **Search Query**: `is:starred label:rss`

## Output Format (MANDATORY)

- Use bullet-point lists for ALL items. NEVER use tables, raw JSON, or prose paragraphs.
- Output directly to stdout as plain markdown.
- Format: `- Manga Name: Chapter X — MISSING | FOUND`
- **PROHIBITED**: Raw JSON (`{"key": "value"}`), markdown tables, horizontal rules.

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.
