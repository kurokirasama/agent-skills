---
name: cron-habitica-todos-summary
description: Automates fetching, filtering, prioritizing, and outputting Habitica todos as a bulleted Markdown summary to stdout.
---

# cron-habitica-todos-summary

Automates the management of Habitica todos, fetching them via the Habitica API, filtering for relevance, prioritizing, and generating a Markdown summary.

## Logic & Workflow

1.  **Habitica Task Retrieval:**
    - Use the Nushell command `todos` via the standard `evaluate` tool to fetch real-time tasks from Habitica. This ensures accurate and up-to-date data. **ALWAYS** activate the `nushell-expert` skill before executing the first Nushell command.
2.  **Filtering & Prioritization:**
    - Filter out completed tasks.
    - Identify high-priority tasks (e.g., those with upcoming due dates or marked as "urgent").
    - Group tasks by tag or category if applicable.
3.  **Markdown Generation:**
    - Construct a prioritized list of todos in Markdown format.
    - Include task names, due dates, and priority levels.
    - Return the report as plain Markdown to `stdout`.
4.  **Summary Reporting:** Output a final summary indicating the total number of todos processed.
5.  **Error Handling**: If any step fails, capture the error and output a failure report in Markdown to `stdout`.

## Instructions

- You are a specialized assistant for the `cron-habitica-todos-summary` skill.
- When activated, your goal is to fetch and summarize Habitica todos.

**CRITICAL: Always activate the `nushell-expert` skill before executing any Nushell commands.**
**CRITICAL: All Nushell commands MUST be executed via the `standard-nushell_evaluate` MCP tool.**

### Recommended Nushell Processing Pipeline
Execute the following pipeline via the `evaluate` tool in a single call to produce the complete Markdown report:

```nu
let pending = (todos | where completed == false | sort-by createdAt)
let top = ($pending | first 10)
let groups = ($top | group-by {|r| if ($r.label_name | is-empty) { "General" } else { $r.label_name } })
let sections = ($groups | items {|label, rows|
  let lines = ($rows | each {|r|
    let d = ($r.createdAt | into datetime | format date "%Y-%m-%d")
    "- [ ] " + $r.text + " (Due: " + $d + ") [Priority: Medium]"
  } | str join "\n")
  "## " + $label + "\n\n" + $lines
} | str join "\n\n")

let out = "# Habitica Todos Summary\n\n" + $sections + "\n\nTotal incomplete todos processed: " + ($pending | length | into string) + " (showing top 10 oldest pending)"
print $out
```

### Output Guidelines
- Output plain Markdown directly to `stdout`. Do NOT wrap in JSON envelopes.
- **PROHIBITED**: Markdown tables, raw JSON, horizontal rules (`---`).
- Do NOT use the `to-discord` nushell command or send any Discord notifications.

## Reporting Protocol
Output the structured Markdown report directly to stdout for external capture.