# Gemini Skills Expert Knowledge Base

## Core Architecture
- **Skill Folder:** A self-contained directory with a mandatory `SKILL.md`.
- **SKILL.md:**
  - **Frontmatter (YAML):** `name` (unique, hyphen-case) and `description` (single-line trigger).
  - **Body (Markdown):** Detailed instructions loaded only after activation.
- **Resources (Optional):**
  - `scripts/`: Executable tools (JS/Nushell/Python).
  - `references/`: Docs/examples loaded on-demand.
  - `assets/`: Templates/binary files.

## Creation & Migration Workflow
1. **Scaffold:** Use `init_skill.cjs` to create the structure.
2. **Map:** Existing system prompts -> Specialists; Pre-prompts -> Tasks.
3. **Bundle:** Group related personas and tasks into "Expert Bundles".
4. **Triggers:** Craft the `description` carefully to ensure accurate auto-activation.
5. **Validate:** Use `package_skill.cjs` to check for YAML errors and TODOs.
6. **Register:** Use `gemini skills link skills/` to make the skill visible.

## Best Practices
- **Progressive Disclosure:** Keep `SKILL.md` lean; put details in `references/`.
- **No Guessing:** Verify information using scripts/tools rather than internal model weights.
- **Explicit Context:** Prefer `@file` references for precision.
- **Naming:** Short, verb-led phrases in hyphen-case (e.g., `git-diff-summarizer`).
- **Description:** Be specific about *when* the skill should trigger (e.g., "Use when asked to analyze log files...").

## Troubleshooting
- **Not Triggering:** Check the `description` field; ensure it's a single-line string and clearly describes the context.
- **Validation Failed:** Check for `TODO` placeholders or invalid YAML syntax in `SKILL.md`.
- **Link Error:** Ensure the path to the skill directory is correct when using `gemini skills link`.