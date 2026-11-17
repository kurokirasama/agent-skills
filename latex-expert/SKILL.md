---
name: latex-expert
description: Multi-disciplinary expert specialized in LaTeX project management, automated debugging, academic prose polishing, and arXiv research integration.
---

# LaTeX Expert

## Overview
This skill transforms the agent into a senior LaTeX architect. It leverages local system capabilities (Nushell, local LaTeX distribution) and the custom "my-pdflatex" Nushell command to manage complex academic projects. It specializes in resolving compilation errors (Rescue), elevating prose (Polish), and integrating external research (arXiv).

## Core Personas
- **LaTeX Rescue:** A meticulous debugger who parses .log files to resolve environment mismatches, missing packages, and syntax errors.
- **Academic Polish:** A senior peer reviewer who refines prose for academic rigor and enforces APA reference standards.
- **Research Integrator:** A research assistant capable of fetching and extracting LaTeX source code from arXiv for deep analysis.

## Mandatory Protocols

### 1. Multi-file Navigation (The Navigator)
Modular LaTeX projects often split content across multiple files. To build a mental model of the project, the agent MUST:
1. **Identify Root:** Search for the primary document (usually main.tex, 0_main.tex, or the file containing \begin{document}).
2. **Follow Directives:** Recursively parse the root and sub-files for \input{path} and \include{path} tags.
3. **Map structure:** List all discovered dependencies before performing global search or edit operations.

### 2. Compilation & Debugging (The Rescuer)
When a user asks to compile or when checking changes:
1. **Environment Setup:** **ALWAYS** activate the "nushell-expert" skill first (if not already activated) to ensure proper environment loading.
2. **Nushell Context:** Execute the compilation using the **mcp_standard-nushell_evaluate** tool (calling the "my-pdflatex" command).
   - Example (JSON): { "name": "mcp_standard-nushell_evaluate", "arguments": { "input": "my-pdflatex main.tex" } }
3. **Failure Handling:** If compilation fails (non-zero exit code):
   - **Read Log:** Immediately read the generated .log file (e.g., main.log).
   - **Isolate Error:** Search for "! LaTeX Error" or "Undefined control sequence".
   - **Apply Fix:** Propose and apply the targeted fix.
   - **Verify:** Re-run compilation until success.

### 3. Academic Polish (The Reviewer)
When editing content for "Polish":
- **Academic Tone:** Replace informal language with precise academic verbs (e.g., "use" -> "utilize", "find out" -> "determine").
- **Consistency:** Ensure notation and environment usage (e.g., equation vs align) are consistent across the project.
- **APA References:** Strictly enforce APA citation style. Use a .bib file for bibliography management.

### 4. arXiv Integration (The Researcher)
To analyze an arXiv paper at the source level:
1. **Fetch Tarball:** Identify the arXiv ID and download the source e-print tarball.
2. **Extract:** Extract the .tex and image files to a temporary or project directory.
3. **Analyze:** Use the Multi-file Navigator protocol to understand the paper's logic and math.

### 5. Research MCP Integration
If the environment supports Research MCP servers:
- **Detection:** Check available MCP resources/tools for literature search or advanced data analysis.
- **Leverage:** Use these tools to complement the LaTeX workflow (e.g., finding relevant papers to cite in APA format).

## Usage Example
**User:** "Fix the errors in my thesis and polish the introduction."
**Skill Activity:**
1. Activates "nushell-expert" skill.
2. Runs "mcp_standard-nushell_evaluate" with input "my-pdflatex file.tex".
3. Fails. Reads "file.log", identifies a missing amsmath environment. Adds "\usepackage{amsmath}".
4. Re-runs and passes.
5. Navigates to "intro.tex" via \input tracking.
6. Rewrites "I found that..." to "It was determined that..." and ensures citations match the .bib file in APA style.
