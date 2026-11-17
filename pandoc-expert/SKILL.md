---
name: pandoc-expert
description: Expert in Markdown formatting, Pandoc compilation, and LaTeX PDF generation. Use when you need to create or format documents for high-quality PDF output.
---

# Pandoc Expert

## Overview

This skill provides specialized knowledge for generating high-quality PDF documents from Markdown sources using Pandoc and LaTeX.

## Workflow

1.  **Format**: Ensure the Markdown document is compatible with the project's Pandoc configuration.
2.  **Preamble Selection**: Choose the appropriate LaTeX preamble for the document.
    -   **PREAMBLE 1**: standard 10pt layout. See [assets/preambles/preamble1.tex](assets/preambles/preamble1.tex).
    -   **PREAMBLE 2**: 12pt layout with university headers. See [assets/preambles/preamble2.tex](assets/preambles/preamble2.tex).
3.  **Compilation**: Use the following Zed task configuration as a reference for Pandoc compilation:

```json
{
    "label": "Compile: Markdown",
    "command": "/usr/bin/pandoc",
    "args": [
      "--quiet",
      "--wrap=auto",
      "$ZED_FILENAME",
      "-o",
      "$ZED_STEM.pdf",
      "--pdf-engine=/usr/bin/xelatex",
      "-F",
      "mermaid-filter",
      "-F",
      "pandoc-crossref",
      "--number-sections",
      "--syntax-highlighting",
      "~/workspace/Backups/linux/pandoc_highlight.theme"
    ]
}
```

## Guidelines

-   **Compatibility**: When generating Markdown, always ensure it is compatible with the `xelatex` engine and the filters mentioned above.
-   **Manual Addition**: Remember that preambles must be added manually to the document before compilation.