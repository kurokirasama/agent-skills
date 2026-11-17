---
name: mine-innovations
description: Mines Conductor archives and Git history for innovative fixes and technical insights to generate Deep Dive Reports in Obsidian.
---

# Mine Innovations

This skill enables Gemini CLI to autonomously identify and document "clever" or "innovative" technical insights from a project's Conductor archives and Git history.

## Workflow

1.  **Discovery Phase**:
    - Scan `conductor/archive/` and `conductor/tracks/` for completed tracks.
    - Examine `git log` for commits with significant architectural changes or complex logic (e.g., advanced Nushell pipelines, MCP integrations).
2.  **Innovation Filtering**:
    - For each candidate (track or commit), analyze the `spec.md`, `plan.md`, or `git show` content.
    - Use the following criteria to identify an "innovation":
        - **Creative Fix**: Solves a persistent or complex issue in a non-standard way, or in a way not already stored in the obsidian memory.
        - **Novel Integration**: Combines multiple tools (e.g., Nushell + specialized MCPs) to achieve a high-impact outcome.
        - **Process Improvement**: Introduces a reusable pattern that significantly reduces turns or manual effort (like Automated Manual Verification).
3.  **Deduplication**:
    - Check the Obsidian `INSIGHTS` folder for existing reports with similar titles or themes to avoid redundancy.
4.  **Deep Dive Generation**:
    - Populate the `references/template.md` with the identified insight's details.
5.  **Storage**:
    - Use `obsidian-memory-expert` or the `obsidian cli` directly to save the report to the `INSIGHTS` folder.

## Best Practices

- **Context-Aware Mining**: Prioritize areas relevant to the current project's core technologies (e.g., in this repo, focus on Skill Creation and Conductor Protocols).
- **Concise Reporting**: Focus on the *why* and the *how* of the innovation, not just the code.
- **Search First**: Always use `obsidian search` before creating a new report.

## Deep Dive Report Template

The reports generated should follow the structure defined in [references/template.md](references/template.md).