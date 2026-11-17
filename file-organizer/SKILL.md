---
name: file-organizer
description: Analyzes the content of files located in the current working directory and determines the most appropriate subfolder for each file based on its purpose, category, or project role.
---

# Objective
Analyze the content of files located in the **current working directory** and determine the most appropriate subfolder for each file based on its purpose, category, or project role.

# Steps
1. **Directory Discovery**: Identify the current working directory and its existing subfolder structure.
2. **Content Analysis**: For each file in the current directory's root, **ALWAYS** READ and ANALYZE its content, metadata, and filename. You can use the `mcp_standard-mcp-server-markdonify_pdf-to-markdown` or the `read_file` tools.
3. **Category Identification**: Based on the analysis, identify if the file belongs to an existing subfolder or if a new subfolder should be created. Always read to the most nested subfolder, and only then determine to which subfolder to move.
4. **Target Determination**: Determine the best destination for each file, aiming for a logical and deep structure where appropriate. ALWAYS verify first the existence of the target folder before moving, in order to not lose files.
5. **Proposed Action**: Generate a command or a plan to move each file into its determined subfolder.

# OUTPUT INSTRUCTIONS
- Provide a clear list of files to be moved and their target destinations.
- Use the format: `mv [file] [subfolder]/`
- Ensure the destination folders are deep enough to maintain a logical structure.
- Do NOT move essential configuration files (e.g., `.gitignore`, `package.json`, `GEMINI.md`, `config.yaml`, `.env`) from the root unless specified.