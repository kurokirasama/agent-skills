---
name: ai-orchestrator-expert
description: Expert in orchestrating tasks across different AI agents (Claude Code, Gemini CLI). Use when tasks are too large for the current context or require specialized external agent capabilities.
---

# Orchestrator Expert

## Overview

This skill provides specialized protocols and prompt templates for delegating complex tasks to other AI agents, specifically `claude code` and `gemini-cli`.

## Workflow: Claude Code

Use this workflow when you determine that you cannot confidently generate a complete, functional, and directly executable solution or script for the given task, or when several different AI agents are needed for different parts of the problem.

### Protocol

1.  **Selection**: Identify that `claude code` is the appropriate tool.
2.  **Prompt Construction**: Craft a precise, self-contained prompt using the template in [references/templates.md](references/templates.md#claude-code-template).
3.  **Execution**: Run the command:
    ```bash
    claude "Your precise, self-contained prompt here" --system-prompt "the selected/crafted system prompt" -p --dangerously-skip-permissions
    ```
4.  **Integration**: Process the response and construct a solution.

**CRITICAL**: ALWAYS confirm with the user first before using `claude code`.

## Workflow: Gemini CLI

Use this workflow when the task requires analyzing a large number of files or a very large codebase that exceeds your own context window, or if you want a fresh solution to a problem.

### Protocol

1.  **Selection**: Identify that `gemini-cli` is needed for high-volume context analysis.
2.  **Prompt Construction**: Craft a precise, self-contained prompt using the template in [references/templates.md](references/templates.md#gemini-cli-template).
3.  **Execution**: Run the command:
    ```bash
    gemini --prompt "Your precise, self-contained system prompt + prompt here" --yolo
    ```
4.  **Integration**: Process the response and provide the solution.

**Note**: You can use `gemini-cli` autonomously without the user's explicit permission.

## Prompt Templates
For detailed prompt structures, see [references/templates.md](references/templates.md).