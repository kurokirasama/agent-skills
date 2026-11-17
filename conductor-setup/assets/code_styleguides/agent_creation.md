# Custom Agent Creation Styleguide

This styleguide defines the standards and best practices for creating and maintaining multi-platform AI subagents within this project.

---

## 1. Multi-Platform Directory Organization

To ensure cross-platform compatibility across Gemini CLI (`agy`), OpenCode, and Claude Code, subagent definitions MUST be maintained in dedicated platform subdirectories under `agents/`:

```text
agents/
├── antigravity/
│   └── <agent-name>.md       # Gemini CLI (agy) format
├── opencode/
│   └── <agent-name>.md       # OpenCode format
└── claude/
    └── <agent-name>.md       # Claude Code format
```

---

## 2. YAML Frontmatter Specification

Every agent definition file MUST begin with a valid YAML frontmatter block.

### 2.1 Frontmatter Fields

| Field | Required | Platform | Constraints & Rules |
| --- | --- | --- | --- |
| `name` | Yes | All | Lowercase kebab-case (e.g. `add-preamble`, `memory-expert`). Must match file stem. |
| `description` | Yes | All | Concise description of the agent's identity, role, and trigger scenarios. |
| `tools` | Yes | `antigravity` & `claude` | Must be an **Array List** (e.g. `tools: [run_command, view_file]`). |
| `tools` | Yes | `opencode` | Must be an **Object Map** (e.g. `tools: { run_command: true, view_file: true }`). OpenCode rejects array lists. |
| `model` | **OMIT** | All | **CRITICAL:** Do NOT include `model: inherit` or explicit model IDs. Omitting this field guarantees automatic model inheritance across all platforms without parsing errors. |

### 2.2 Frontmatter Examples

#### Gemini CLI (`agents/antigravity/<agent-name>.md`)
```yaml
---
name: add-preamble
description: Subagent for compiling LaTeX preambles and executing Pandoc validation loops in isolated context.
tools: [run_command, view_file, replace_file_content, write_to_file]
---
```

#### OpenCode (`agents/opencode/<agent-name>.md`)
```yaml
---
name: add-preamble
description: Subagent for compiling LaTeX preambles and executing Pandoc validation loops in isolated context.
tools:
  run_command: true
  view_file: true
  replace_file_content: true
  write_to_file: true
---
```

---

## 3. System Prompt Architecture

The markdown body following the frontmatter defines the subagent's operational persona and instructions.

### 3.1 Required Sections
1. **Identity & Core Mission**: A sharp 1-2 sentence description of the agent's role and boundaries.
2. **Tool Scoping (Positive & Negative Guidance)**:
   - `### When to Use This Agent`: Clear scenarios when the agent should be invoked.
   - `### When NOT to Use This Agent`: Anti-patterns and scenarios better handled by the main thread.
3. **Execution & Context Isolation Protocol**:
   - Subagents run in isolated conversation threads.
   - Subagents MUST perform heavy IO, compilation loops, or analysis in their thread.
   - Subagents MUST return a concise, structured markdown summary (~150-250 tokens) to the calling parent agent upon task completion.
4. **Output & Token Efficiency**:
   - **Zero Filler**: No conversational preambles ("I will now execute...") or postambles ("I have completed...").
   - **Stop-on-Completion**: After editing files or achieving the task, stop immediately and yield control.

---

## 4. Subagent-Skill Fallback Protocol

To maintain maximum robustness, subagents and native skills MUST implement mutual fallback:
- **Skill-to-Agent Fallback**: The native skill (`skills/<skill-name>/SKILL.md`) should prioritize delegating work to the subagent (`@<agent-name>`) to shield the main context window. If subagent spawning fails or is unsupported by the platform, the primary agent MUST transparently fall back to executing the skill directly in the main thread.
- **Agent-to-Skill Fallback**: The subagent instructions MUST reference the native skill specification as its single source of truth for workflow logic.

---

## 5. Synchronization & Validation

Whenever an agent file is created or updated:
1. **Parity Check**: Ensure all 3 platform files (`agents/antigravity/`, `agents/opencode/`, `agents/claude/`) are updated simultaneously with identical system prompt logic and correct platform-specific frontmatter formatting.
2. **Run Link Sync**: Execute the Nushell `link-agents` helper command to deploy agent definitions to system configuration directories (`~/.gemini/agents/`, `~/.config/opencode/agents/`, `~/.claude/agents/`):
   ```bash
   nu --config ~/.config/nushell/config.nu --env-config ~/.config/nushell/env.nu -c "link-agents"
   ```
