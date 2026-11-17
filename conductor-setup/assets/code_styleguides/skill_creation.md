# Skill Creation Styleguide

This styleguide defines the standards and best practices for creating Gemini CLI Skills within this project. It is based on the official [Agent Skills Specification](https://agentskills.io/specification) and associated guides.

## 1. Directory Structure

A skill is a self-contained directory named using lowercase letters, numbers, and hyphens only (e.g., `my-custom-skill`).

```text
skill-name/
├── SKILL.md          # REQUIRED: Metadata and instructions
├── scripts/          # OPTIONAL: Executable code (Nushell, Python, Bash)
├── references/       # OPTIONAL: Detailed documentation (REFERENCE.md, FORMS.md)
├── assets/           # OPTIONAL: Static resources (templates, images, data)
├── evals/            # OPTIONAL: Test cases and evaluation data
└── ...               # Additional files (as needed)
```

## 2. `SKILL.md` Specification

The `SKILL.md` file is the heart of a skill, containing both machine-readable metadata and human-readable (agent-readable) instructions.

### 2.1 Frontmatter (YAML)

| Field | Required | Constraints |
| --- | --- | --- |
| `name` | Yes | Max 64 characters. Lowercase, numbers, and hyphens only. No leading/trailing hyphens. |
| `description` | Yes | Max 1024 characters. Non-empty. Must describe *when* the skill is useful. |
| `license` | No | License name or reference to a bundled file. |
| `compatibility` | No | Max 500 characters. Environment/system requirements. |
| `metadata` | No | Arbitrary key-value mapping for additional info. |
| `allowed-tools` | No | (Experimental) Space-separated string of pre-approved tools. |

**Example:**
```yaml
---
name: csv-cleaner
description: Cleans and standardizes CSV files, handling missing values and date formatting.
metadata:
  version: "1.0.0"
  author: Conductor Team
---
```

### 2.2 Body Content (Markdown)

The body should provide clear, step-by-step instructions. Recommended sections:
- **Overview**: High-level goal of the skill.
- **Workflow / Steps**: Logical sequence of actions.
- **Examples**: Sample inputs and expected outputs.
- **Edge Cases**: How to handle errors or unusual data.
- **Available Scripts**: List and describe scripts in `scripts/`.

**Best Practices:**
- **Progressive Disclosure**: Keep `SKILL.md` under 500 lines. Move detailed reference material to `references/`.
- **Full Path Mandate**: When referencing a resource or sub-skill within a skill using a path (e.g., in `activate_skill` calls or when describing file-based dependencies), you MUST use the **full path** (e.g., `/home/username/workspace/llms_configs/skills/skill-name/`) instead of a relative path (e.g., `./skill-name`). Referencing a skill by its **simple name** (e.g., `nushell-expert`) without any path indicators is acceptable.
- **Local File References**: For files contained *within* the same skill directory (e.g., a script in `scripts/`), use paths relative to the skill root (e.g., `nu scripts/process.nu`).

## 3. Description Optimization

The `description` field is the primary mechanism for skill activation.
- **Focus on Triggering**: Clearly state the specific tasks or scenarios where the skill should be used.
- **Avoid Over-breadth**: Be specific enough to avoid false triggers for simple tasks the agent can handle alone.
- **Iterative Refinement**: Test the skill against `should-trigger` and `should-not-trigger` queries. If it fails to trigger, broaden the description. If it false-triggers, add specificity or constraints.

## 4. Instruction Engineering

- **Grounded in Expertise**: Do not rely on general LLM knowledge. Provide project-specific API patterns, schemas, and conventions.
- **Show, Don't Just Tell**: Use concrete examples of tool calls and command flags.
- **Action-Oriented & Concise**: Focus on achieving specific outcomes with minimal token overhead.
- **Negative Guidance (When NOT to Use)**: Specify anti-patterns, common pitfalls, and scenarios where the skill or tool should NOT be triggered. Provide Good vs BAD query examples with explicit reasoning.
- **Stop-on-Completion (Zero Filler)**: Instructions should tell the agent to respond concisely without conversational preamble ("Here is what I will do...") or postamble ("I have updated the file..."). After executing a file edit, the agent should yield immediately.
- **Dependency Verification Protocol**: Instruct the agent to inspect project manifest files (`package.json`, `Cargo.toml`, `pyproject.toml`) before importing third-party libraries.
- **Test Integrity Mandate**: Prohibit altering test assertions or commenting out broken tests to force a green build. Fix the underlying logic instead.


## 5. Scripts and Automation

### 5.1 Project Standard: Nushell First
- **Preference**: Use Nushell (`.nu`) for complex logic and automation.
- **Activation**: If a skill uses Nushell, the instructions MUST include a step to activate the `nushell-expert` skill before the first `evaluate` call.
- **Syntax**: Adhere to the latest Nushell assignment syntax (`let a = ...`) and avoid unnecessary parentheses.
- **Code Blocks**: Always format Nushell code blocks in markdown using ` ```nu ` instead of ` ```nushell `.

### 5.2 Script Protocols
- **Self-Contained**: Scripts should ideally handle their own dependencies (e.g., Python scripts using `uv` with inline PEP 723 metadata).
- **Error Handling**: Provide helpful, actionable error messages that allow the agent to self-correct.
- **Relative Execution**: Instructions should run scripts using relative paths (e.g., `nu scripts/process.nu`).

## 7. Cron & Autonomous Skills

Autonomous skills designed to run on a schedule (e.g., via `crontab`) or in the background MUST follow the **Script-First** and **Self-Contained** patterns to ensure reliability across environments.

### 7.1 Script-First Architecture
- **Deterministic How**: All logic for "plumbing" (backups, regex parsing, atomic file writes, LLM synthesis calls, and logging) MUST live in a standalone Nushell (`.nu`) script.
- **Agentic When/Why**: The `SKILL.md` acts as a thin wrapper that tells the agent *when* and *why* to trigger the script. It should NOT duplicate the script's logic in natural language.

### 7.2 Persistent State Management
- **State Files**: Use a persistent JSON file (e.g., `.consolidation_state.json`) stored in the `AGENTS_MEMORY` directory to track progress, last execution times, or incremental offsets.
- **Success-Gated Updates**: Update the state file ONLY after all critical file writes (e.g., `BRAIN.md`, `SOUL.md`) have been successfully completed.

### 7.3 Cron Portability (Self-Containment)
- **Dependency Isolation**: Scripts intended for cron execution MUST be self-contained. Embed all necessary helper functions (e.g., `get-vault`, `parse-frontmatter`) directly into the script.
- **No Relative Imports**: Do NOT use relative module imports (e.g., `use ../...`) as cron jobs may be triggered from various working directories.

### 7.4 Execution Protocol
- **Fallback Commands**: Instructions MUST provide a specific environment-loading fallback for non-interactive execution (e.g., when the Nushell MCP is unavailable):
    ```bash
    nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c "source path/to/script.nu; main"
    ```
- **Nushell Mandate**: Ensure the `nushell-expert` skill is active before executing any part of the cron workflow.

---

## 8. Exceptions for Cloned Skills

Skills that are cloned from external repositories (e.g., as git submodules or embedded repos like `science-skills` or `gemini-api-skills`) are exempt from the following rules to preserve upstream compatibility:
- **Kebab-case naming**: They may retain their original naming convention (e.g., `snake_case`).
- **Directory Structure**: They may contain unauthorized top-level directories or nested skills.
- **`name` match**: The `name` field in `SKILL.md` does not need to match the folder name.

These skills should still adhere to the **Full Path Mandate** for cross-skill references where applicable.