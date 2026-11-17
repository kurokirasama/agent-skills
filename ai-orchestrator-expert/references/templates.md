# Orchestrator Templates

This reference provides the standardized prompt structures for delegating tasks to external AI agents.

<a name="claude-code-template"></a>
## Claude Code Template

Structure the `claude code` prompt using the following markdown format:

```md
# Original Problem

    [A clear and concise restatement of the original programming, coding, or Linux task that `claude_code` needs to solve. Focus on the core challenge.]

# Context

    [Provide all relevant and necessary information from our conversation for `claude_code` to understand the problem fully. This includes specific code snippets, error messages, system configurations, specific constraints, and details of any previous attempts (both mine and yours) that led to the current situation. Be highly selective; include only genuinely helpful information and avoid unnecessary conversational filler.]

# Specific Request

    [Explicit, actionable instructions for `claude_code` on precisely what it needs to do. This must be a clear command. Examples:
    - 'Write a Python script that efficiently processes X data using Y library.'
    - 'Debug this C++ code snippet for the segmentation fault, identify the root cause, and provide the corrected, fully functional version.'
    - 'Provide the exact sequence of Linux commands to configure Z service, ensuring it starts automatically on boot.'
    - 'Explain the optimal algorithm for Q problem, providing a detailed breakdown and pseudocode implementation.']

# Output Style for claude_code:

    [Instructions for `claude_code` on how its response should be formatted, so you can work with it later]
```

<a name="gemini-cli-template"></a>
## Gemini CLI Template

Structure the `gemini` prompt using the following markdown format:

```markdown
# Original Problem

    [A clear and concise restatement of the task that the `consultation` tool needs to solve. Focus on the core challenge.]

# Context

    [Provide all relevant and necessary information from our conversation for the `consultation` tool to understand the problem fully. This includes the path to the files that need to be analyzed, any relevant code snippets, error messages, system configurations, specific constraints, and details of any previous attempts (both mine and yours) that led to the current situation. Be highly selective; include only genuinely helpful information and avoid unnecessary conversational filler.]

# Specific Request

    [Explicit, actionable instructions for the `consultation` tool on precisely what it needs to do. This must be a clear command. Examples:
    - 'Summarize the entire codebase in the provided path, focusing on the overall architecture and the main data flows.'
    - 'Analyze all the files in the provided path and identify the key components responsible for user authentication.'
    - 'Find all instances of the `process_data` function being used in the codebase and explain the purpose of each one.'
    - 'Based on the provided project files, generate a high-level overview of the project's purpose and functionality.']

# Output Style for consultation:

    [Instructions for the `consultation` tool on how its response should be formatted, so you can work with it later]
```