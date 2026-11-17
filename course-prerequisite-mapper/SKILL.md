---
name: course-prerequisite-mapper
description: Maps educational course prerequisites from local files to verified YouTube playlists and videos. Use when Gemini CLI needs to identify foundational knowledge for a curriculum and find stable instructional resources on high-quality channels like Matemáticas Profe Alex, Matemóvil, or Daniel Carreón.
---

# Course Prerequisite Mapper

## Overview

This skill enables Gemini CLI to bridge the gap between local curriculum requirements and online educational resources. It systematically identifies what a student needs to know before starting a new course and maps those needs to specific, verified YouTube content.

## Workflow Decision Tree

### 1. Context Gathering
- Identify prerequisite files (e.g., `prerrequisitos_*.md`) and target curriculum files (e.g., `tercero/contenidos.md`).
- Extract specific Learning Objectives (OAs) or technical topics.

### 2. Search & Discovery
- Use `googlesuit-youtube_searchVideos` to find candidate playlists or videos.
- **Priority:** Search within preferred channels (see [preferred_channels.md](references/preferred_channels.md)).
- If a playlist is found, extract its ID.

### 3. Scraping & Filtering
- Use `firecrawl_scrape` with the playlist URL to list all video titles.
- **Filtering Logic:** Only include videos that directly match the prerequisite topics. Discard introductory fluff or advanced content that belongs to the target course itself.

### 4. Link Validation
- **MANDATORY:** Verify that links are public and functional.
- If a playlist ID fails (e.g., "The playlist does not exist"), try searching for the specific video titles or use the fallback prompt for Gemini Web.
- **Fallback Prompt:** If links are unstable, provide the user with a prompt for Gemini Web/Search to validate links in real-time.

### 5. Synthesis & Reporting
- Generate a Markdown file (e.g., `videos_probabilidad.md`) with the following structure:
  - Section for each OA or major topic.
  - Playlist link at the top of the section.
  - Checklist (` - [ ]`) of specific video titles with their direct URLs.
  - "Identified Gaps" section for prerequisites not found in the searched sources.

## Best Practices

- **Concise Lists:** Do not dump the entire playlist. Select only what is strictly necessary.
- **Regional Context:** For Chilean curriculum, include keywords like "OA", "1ro Medio", "2do Medio" in searches to ensure alignment.
- **Preferred Sources:** Always check [preferred_channels.md](references/preferred_channels.md) before searching generic terms.
