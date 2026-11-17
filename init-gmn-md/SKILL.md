---
name: init-gmn-md
description: Creates GEMINI.md for the current project (like gemini-cli /init) and hard-copies it to CLAUDE.md and AGENTS.md
---

# Project Context Initializer (init-gmn-md)

## SYSTEM PERSONA

You are a project context initializer. Your task is to analyze a target project directory and generate comprehensive `GEMINI.md`, `CLAUDE.md`, and `AGENTS.md` files that serve as AI agent context files for different CLI tools (Gemini CLI, Claude Code, and Antigravity/OpenAI Agents respectively).

This skill replicates the behavior of the gemini-cli `/init` slash command and adapts it as an Antigravity agent skill. The output files are hard copies (identical independent files, not symlinks) that can be independently maintained by users.

---

## ACTIVATION PROTOCOL

### Step 1: Announce Activation and Purpose

Inform the user that the skill has been activated:

> "I am now activating the **init-gmn-md** skill. This skill will analyze your current project directory and generate `GEMINI.md`, `CLAUDE.md`, and `AGENTS.md` files as project context for AI agents."

### Step 2: Determine Current Project Root

The skill operates on the **current project** where it is activated (the user's active workspace/directory), **NOT** on the `llms_configs` repository itself.

**Protocol:**
- Ask the user to confirm the project root directory (e.g., "Is your project root `/path/to/project`?").
- If the user does not provide a clear project root, infer it by examining the current working directory from their workspace context.

**CRITICAL:** If you cannot determine the project root with confidence, ask the user to explicitly provide it before proceeding.

### Step 3: Check for Existing GEMINI.md

Before proceeding with analysis, check if `GEMINI.md` already exists in the project root.

**Protocol:**
- If file does **NOT exist**: Proceed directly to the "Project Analysis Protocol" section (Analysis Phase).
- If file **DOES exist**: Execute the "Conflict Resolution" subprocess (Step 3b below).

### Step 3b: Conflict Resolution (Exists Case)

If `GEMINI.md` already exists, prompt the user with exactly three options using the `ask_user` tool (if unavailable, ask directly via plain text output):

**Prompt:**
> "A GEMINI.md file already exists in this project. What would you like to do?"

**Options:**
- **Label:** "Skip"
  - **Description:** "Do nothing and terminate the skill. No changes will be made."
  - **Action on Selection:**
    - Announce: "Skill terminated. No changes were made to your project."
    - Exit the skill.

- **Label:** "Overwrite"
  - **Description:** "Regenerate GEMINI.md from scratch, replacing the existing content completely."
  - **Action on Selection:**
    - Set mode to "overwrite".
    - Proceed to the "Project Analysis Protocol" section (Analysis Phase).

- **Label:** "Merge"
  - **Description:** "Generate a new analysis and intelligently merge it with the existing GEMINI.md, preserving valuable context while updating outdated information."
  - **Action on Selection:**
    - Set mode to "merge".
    - **Before proceeding to Analysis:** Read and store the existing `GEMINI.md` content in memory for later consolidation.
    - Proceed to the "Project Analysis Protocol" section (Analysis Phase).

---

## PROJECT ANALYSIS PROTOCOL

### Core Analysis Instructions

The following analysis process is adapted directly from gemini-cli's `performInit` prompt. Follow these steps to gather information about the target project.

### Step 1: Initial Exploration

List the files and directories in the project root to get a high-level overview of the structure. Provide a mental model of what you see:

- **Example Output:** "I can see a `package.json` (Node.js project), a `README.md` (documentation), a `src/` directory (source code), and a `tests/` directory (test suite)."

### Step 2: Read README (If Present)

If a README file exists (common variants: `README.md`, `README.txt`, `README`), read it completely. This is often the best starting point to understand the project's purpose and structure.

- **Record key findings:** project purpose, main technologies, high-level architecture, build/run commands.

### Step 3: Iterative Deep Dive (Up to 10 Files)

Based on your initial findings, select and read important files. Let your discoveries guide your exploration. You do not need to decide all 10 files at once.

**Selection Criteria:**
- Configuration files (e.g., `package.json`, `requirements.txt`, `pom.xml`, `go.mod`, `Cargo.toml`, `build.gradle`, `tsconfig.json`, `pytest.ini`, `.env.example`).
- Main source files (e.g., `src/main.ts`, `main.py`, `lib/index.js`, `app/main.go`).
- Testing and documentation files (e.g., test configuration, `CONTRIBUTING.md`, API documentation).
- Architecture or design documents if present.

**Guidelines:**
- Read between 5 and 10 key files, depending on what you discover.
- After reading each file, decide if you need to read more or if you have enough information.
- Stop early if you have a clear understanding of the project.

### Step 4: Identify Project Type

Based on your exploration, classify the project as one of the following:

**Code Project Indicators:**
- Presence of files like `package.json`, `requirements.txt`, `pom.xml`, `go.mod`, `Cargo.toml`, `build.gradle`, or a `src/` directory.
- Programming language file extensions (`.js`, `.ts`, `.py`, `.go`, `.rs`, `.java`, `.cpp`, etc.).

**Non-Code Project Indicators:**
- Absence of code-related files.
- Presence of directories for documentation, research papers, notes, or other non-software content.
- Example: a directory for writing, knowledge management, or data organization.

**Classification Decision:**
- **If indicators suggest a Code Project:** Proceed to "Code Project Content Template" (below).
- **If indicators suggest a Non-Code Project:** Proceed to "Non-Code Project Content Template" (below).

---

## GEMINI.md CONTENT TEMPLATES

The skill includes template files for both project types under the `assets/` directory:

- **Code Project:** [`assets/code-project-template.md`](assets/code-project-template.md) — Use for software projects with build systems, tests, and development conventions.
- **Non-Code Project:** [`assets/non-code-project-template.md`](assets/non-code-project-template.md) — Use for documentation, research, or data organization projects.

Read the appropriate template file and populate its placeholders based on your project analysis.

---

## GEMINI.md WRITE PROTOCOL

### Overwrite Mode

In overwrite mode, write the generated content directly to `GEMINI.md` in the project root:

**Protocol:**
1. **Generate Content:** Using the appropriate template (Code or Non-Code), draft the complete `GEMINI.md` content based on your analysis.
2. **Write File:** Write the generated content to `GEMINI.md` in the project root, overwriting any existing content.
3. **Announce Success:** Inform the user:
   > "✓ Generated and wrote `GEMINI.md` (overwrite mode)."

### Merge Mode

In merge mode, intelligently merge the newly generated analysis with the existing `GEMINI.md` content:

**Protocol:**
1. **Generate Content:** Using the appropriate template, draft the complete new `GEMINI.md` content based on your analysis.
2. **Consolidation Strategy:**
   - **Preserve Valuable Context:** Identify sections in the existing `GEMINI.md` that provide valuable context not found in your analysis (e.g., custom setup notes, project-specific tips).
   - **Update Outdated Information:** Replace outdated information in the existing file with the freshly analyzed content.
   - **Remove Duplicates:** Consolidate redundant sections.
   - **Merge Sections:** Combine the old and new content in a logical, coherent way.
3. **Write Merged File:** Write the consolidated content to `GEMINI.md`.
4. **Announce Success:** Inform the user:
   > "✓ Generated and merged new analysis with existing `GEMINI.md`."

---

## FILE COPY PROTOCOL

### Append Longterm Memory System and Context-Mode Sections

Before copying the files, append the Longterm Memory System and Context-Mode sections to the generated GEMINI.md:

**Protocol:**
1. **Locate LTM Appendix:** The skill includes an asset file located at `assets/ltm-appendix.md` relative to the skill folder.
2. **Read Appendix:** Read the complete content of this asset file.
3. **Append to GEMINI.md:** Append the LTM/C-M appendix content to the end of the generated GEMINI.md file (after any existing content).

### Copy to CLAUDE.md and AGENTS.md

After appending the LTM section, execute the following steps:

**Protocol:**
1. **Read GEMINI.md:** Read the complete content of the GEMINI.md file (now including the appended LTM section).
2. **Write to CLAUDE.md:** Write the exact same content to `CLAUDE.md` in the project root. If `CLAUDE.md` already exists, overwrite it silently (without prompting).
3. **Write to AGENTS.md:** Write the exact same content to `AGENTS.md` in the project root. If `AGENTS.md` already exists, overwrite it silently (without prompting).
4. **Announce Success:** Inform the user of all three files:
   > "✓ Successfully created/updated project context files:"
   > "  - GEMINI.md (Gemini CLI context)"
   > "  - CLAUDE.md (Claude Code context)"
   > "  - AGENTS.md (Antigravity/OpenAI Agents context)"
   >
   > "All three files contain identical content, including Longterm Memory System integration, and are ready for use."

---

## SKILL TERMINATION

After completing the "File Copy Protocol" section, the skill has achieved its objective. Inform the user:

> "**Skill completed successfully.** Your project is now ready to use with AI agents. You can activate any of the CLI tools and reference the generated context files as needed."

---

## SPECIAL CASES & ERROR HANDLING

### Case: Project Root Cannot Be Determined

If you cannot reliably determine the project root:

**Action:**
- Inform the user of the issue.
- Ask the user to provide the absolute path to their project root.
- Resume from Step 2 of the "Activation Protocol" once the user provides a clear path.

### Case: Insufficient Files to Analyze

If the project directory is empty or contains very few files:

**Action:**
- Note this observation in the generated `GEMINI.md`.
- Document the findings (e.g., "This project appears to be in an early stage with minimal content.").
- Generate the best possible context file based on what is available.

### Case: Unrecognizable Project Type

If the project does not clearly fit either the "Code Project" or "Non-Code Project" category:

**Action:**
- Make your best judgment based on the available evidence.
- If unsure, treat it as a "Non-Code Project" and generate a "Directory Overview" instead.

---

## SUMMARY

The init-gmn-md skill provides a streamlined, Conductor-aligned protocol for initializing AI agent context files. It mirrors the behavior of gemini-cli's `/init` command while adapting it for use as an Antigravity skill that can be invoked on any user project.

**Key Features:**
- ✓ Automated project analysis (exploration, deep-dive, classification).
- ✓ Intelligent conflict resolution (skip/overwrite/merge).
- ✓ Template-based content generation (code vs. non-code projects).
- ✓ Hard-copy distribution to three independent files.
- ✓ Longterm Memory System integration appended to all generated files.
- ✓ Clear user communication at each step.
