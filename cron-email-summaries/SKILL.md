---
name: cron-email-summaries
description: Automates fetching and summarizing unread emails from specific categories and outputs a Markdown summary to stdout.
---

# cron-email-summaries

Automates fetching and summarizing unread emails from specific categories, generating a consolidated Markdown report.

## Verify available tools
FIRST verify that you have available the tools of the google-workspace mcp. If you don't, inform the user that you don't and don't proceed with the request.

## Logic & Workflow

1.  **Gmail Search & Retrieval:** Perform three distinct searches using `mcp_google-workspace_gmail.search`:
    *   **WORK Unread:** `in:inbox is:unread label:work -label:delete-me`
    *   **WORK Pending:** `label:work/Department/Pendientes`
    *   **Other important emails:** `in:inbox is:unread -label:work -label:rss -label:Delete-me`
2. **TRIAGE & Actionable Detection**: 
    - For each category, determine which email messages to keep based on relevance and urgency.
    - **Actionable Item Detection (WORK Unread)**: Analyze the content of unread WORK emails for actionable items:
        - Information/data/document requests.
        - Direct task assignments.
        - Meeting or scheduling requests.
3. **Label Application (Using Google Workspace MCP Tools)**: For any identified actionable email in the "WORK Unread" category, use `google-workspace_gmail_modify` to apply the `work/Department/Pendientes` label and mark it as read. First, resolve the label ID via `google-workspace_gmail_listLabels` (create it with `google-workspace_gmail_createLabel` if it doesn't exist).
4.  **Summarization:** For each filtered email in each category, retrieve the full email content and generate a concise summary (Sender + Summary of content).
5.  **Markdown Generation:**
    *   Construct a Markdown report with sections for each category and a dedicated section for "Actionable Items Identified".
    *   Output the report to `stdout`.
6.  **Summary Reporting:** Output a final summary indicating the total number of categories and actionable items processed.
7.  **Error Handling**: If any major failure occurs during execution, capture the error and output a failure report in Markdown to `stdout`.

## Instructions

- You are a specialized assistant for the `cron-email-summaries` skill.
- **Gmail Search & Retrieval:**
    - Perform three distinct searches using `mcp_google-workspace_gmail.search`:
        - WORK Unread: `in:inbox is:unread label:work -label:delete-me`
        - Software Updates: `is:unread in:inbox -label:work -label:rss (subject:"update" OR subject:"release" OR subject:"vulnerability" OR subject:"security")`
        - WORK Pending: `label:work/Department/Pendientes`
    - Use `mcp_google-workspace_gmail.get` to retrieve full content for analysis.
    - Use `mcp__context-mode__ctx_execute` with `javascript` to batch these calls if many emails are found.
- **Actionable Item Detection:**
    - Carefully read the body of unread WORK emails.
    - Identify specific requests for data, tasks you need to perform, or meeting coordination.
    - If found, record the Message ID and a brief description of the action required.
- **Labeling Process (Using Google Workspace MCP Tools):**
    - For every actionable item found in the "WORK Unread" category, apply the label using the Google Workspace MCP Gmail tools:
    - **Step 1: Find or Create Label**:
      Call `google-workspace_gmail_listLabels` to retrieve all labels and find the label ID for `work/Department/Pendientes`. If it doesn't exist, call `google-workspace_gmail_createLabel` with:
      ```json
      {
        "name": "work/Department/Pendientes",
        "labelListVisibility": "labelShow",
        "messageListVisibility": "show"
      }
      ```
    - **Step 2: Apply Label to Message**:
      Call `google-workspace_gmail_modify` with:
      ```json
      {
        "messageId": "<gmail_message_id>",
        "addLabelIds": ["<label_id_from_step_1>"],
        "removeLabelIds": ["UNREAD"]
      }
      ```
    - **Note**: The Google Workspace MCP tools handle authentication automatically. No local credentials, Python scripts, or virtual environments are needed.
- **TRIAGE Guidelines:**
    - For each category, first list the senders and subjects of all found emails.
    - **Filter:** Select only the most relevant or urgent messages.
    - For "Software Updates", prioritize major releases, security patches, or features from frequently used tools (e.g., GitHub, VS Code, etc.).
    - For "WORK Pending", focus on items that require immediate attention or have been pending for a while.
    - Aim for at least 10 summarized emails in each category when available, with a total of no more than 30 summarized emails across all categories.
- **Output Format:**
    - CRITICAL: Output plain Markdown directly to stdout. Do NOT wrap in JSON envelopes.
    - **PROHIBITED**: Markdown tables (`| --- |`), raw JSON (`{"key": "value"}`), horizontal rules (`---`).
    - Use bullet-point lists for ALL items: `- **From:** subject — summary`
    - Include headers: `## WORK Unread`, `## Software Updates`, `## WORK Pending Actions`, and `## Actionable Items Identified`.
    - The "Actionable Items Identified" section should list the Message ID and the brief action required for each new item labeled.
    - If a category has no emails, you MUST still output a message stating: "No unread [Category] emails found."
- **Failure Reporting**: If any step fails, capture the error and output a Markdown failure report to `stdout`.

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.
rting.
