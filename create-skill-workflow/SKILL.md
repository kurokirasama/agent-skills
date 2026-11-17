---
name: create-skill-workflow
description: Automates the creation and registration of new Gemini CLI skills from Markdown files.
---

# Create Skill Workflow

## Overview
This skill streamlines the process of turning Markdown documentation into registered Gemini CLI skills. It handles preamble injection, title customization, PDF compilation via Pandoc, and registry updates.

## Workflow
1.  **Selection**: Choose Markdown files in the current directory.
2.  **Preamble**: Execute `add-preamble` and clean it (remove author).
3.  **Title**: Assign a custom title to the preamble.
4.  **Compilation**: Compile to PDF using `pandoc-expert` standards.
5.  **Registration**: Append the new skill to the global `available_skills.md`.

## Instructions
-   **Execution**: Run the `create-skill-workflow` command.
-   **Interactive**: Be prepared to provide titles for each document when prompted.
-   **Validation**: Ensure `pandoc-expert` is available for compilation.
