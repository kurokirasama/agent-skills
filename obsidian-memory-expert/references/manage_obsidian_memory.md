# Manage Obsidian Memory

This task focuses on grounding Gemini CLI's responses in the user's Obsidian vault and consolidating new insights for long-term retrieval.

## Operational Protocol

### 1. Search Strategy
- **Search INSIGHTS Folder First:** Before providing a response, always search for relevant context within the **INSIGHTS/** folder. Since the graphical Obsidian app does not output search results to the terminal, use the native Nushell query fallback:
  ```nu
  let vault = $env.OBSIDIAN_VAULT_ROOT? | default "~/workspace/obsidian/vaults"
  glob $"($vault)/INSIGHTS/**/*.md" | where { |f| (open --raw $f | str contains "<search term>") }
  ```
- **Vault Expansion:** If the INSIGHTS folder search returns insufficient results, expand the search to the entire vault using a glob on all markdown files.

### 2. Retrieval
- **Open and Read:** Use native Nushell `open --raw "<absolute_path>"` to bring the note's content into the current session.

### 3. Storage & Consolidation Logic
- **Naming Convention:** All new notes and consolidated insights MUST be saved in the **INSIGHTS/** folder. Use lowercase and underscores for filenames (e.g., `ai_skill_development.md`).
- **Safety First (Backups):** Before modifying an existing note, create a temporary backup using absolute paths:
  ```nu
  let vault = $env.OBSIDIAN_VAULT_ROOT? | default "~/workspace/obsidian/vaults"
  let file = $"($vault)/INSIGHTS/filename.md"
  cp $file $"($file).bak"
  ```
- **Updating Notes:** 
  - If a file already exists, review its content.
  - Append new information using headings that match the existing hierarchy.
  - Only refactor existing content if the new information explicitly improves or corrects it.
- **Citations:** Include a "Sources" section at the bottom for any external URLs or documents used.
- **Cleanup:** Once the note is successfully updated, delete the backup file:
  ```nu
  rm $"($file).bak"
  ```
- **Relationships:** Use `[[wikilinks]]` to connect related notes. Keep distinct topics in separate files.

### 4. UI Synchronization
- After any write or update operation, run the desktop Obsidian launcher using the relative path from the vault root to ensure the note is active and visible in the desktop application:
  ```bash
  obsidian open path="INSIGHTS/filename.md"
  ```

## Formatting Guidelines (Obsidian Flavored Markdown)

### Properties (Frontmatter)
All notes in **INSIGHTS/** should include frontmatter:
```yaml
---
title: My Note Title
date: YYYY-MM-DD
tags:
  - category
  - status
aliases:
  - Alternative Name
---
```

### Callouts
Use callouts for highlighted or structured information:
> [!note]
> Basic callout.

> [!tip]
> Important insight.

Common types: `note`, `abstract`, `info`, `todo`, `tip`, `success`, `question`, `warning`, `failure`, `danger`, `bug`, `example`, `quote`.

### Embeds
Use `![[wikilink]]` to embed related content or images:
- `![[Other Note]]` (Full note embed)
- `![[Other Note#Heading]]` (Section embed)
- `![[image.png|300]]` (Image embed with width)

## Constraints
- **Silent Execution:** All commands and reasoning should be executed silently.
- **Final Response:** Conclude with a brief confirmation of the memory operation (e.g., "Memory updated in INSIGHTS/obsidian_cli_notes.md").
