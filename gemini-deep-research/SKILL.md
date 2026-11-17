---
name: gemini-deep-research
description: Orchestrates autonomous deep research tasks using the ai deep-research Nushell commands.
---
# Gemini Deep Research Skill

## Overview
This skill enables the agent to perform autonomous, multi-step deep research using the `ai deep-research` Nushell commands. It handles the full research lifecycle, from prompt refinement and planning to status monitoring and report retrieval.

## Instructions

### 1. Initial Prompt Refinement & Steerability
Before starting a research task, you must act as a Research Consultant to ensure the best possible results.

- **Clarify vague prompts**: If the user's request is broad (e.g., "research AI"), ask clarifying questions about the specific goal (technical, investment, academic), target audience, and any constraints (region, timeframe).
- **Suggest Report Formats**: Offer the following formats to steer the research output:
    1. **Executive Brief**: Summary, key findings, strategic recommendations.
    2. **Technical Deep Dive**: Architecture overview, comparative analysis (with tables), implementation details.
    3. **Market Analysis**: Trends, competitor landscape, SWOT analysis, future outlook.
    4. **Comprehensive Research Report**: Detailed background, multi-perspective analysis, extensive citations.

### 2. Cost Approval
**CRITICAL**: Before starting any research task, you MUST explicitly ask the user for cost approval.
- **Instruction**: Inform the user that the task uses the Gemini Deep Research feature which requires a paid API key and incurs costs.
- **Prompt**: "This deep research task will utilize the paid Gemini Deep Research extension. Do you approve its usage and the associated costs?"
- **Fallback**: If the user declines, inform them that you cannot proceed with deep research and suggest using standard search tools instead.

### 3. Grounding & Data Gathering
- Check for relevant files in the current workspace or Obsidian vaults.
- If specific data is provided or available in a file search store (if applicable), ensure the research prompt includes instructions to ground findings in those sources.

### 4. Workflow Orchestration

#### Autonomous Mode (Default)
Use this mode for standard research tasks where the user wants the agent to handle everything.
1. **Start Research**: Run the Nushell command `ai deep-research start "<refined_prompt>" --max`.
2. **Monitor Status**: Periodically run the Nushell command `ai deep-research status --id "<id>"`.
3. **Retrieve Report**: Once completed, run the Nushell command `ai deep-research retrieve --output "<file>.md"`.

#### Collaborative Mode (Planning)
Use this mode if the user explicitly asks for "planning" or a "research plan".
1. **Start with Planning**: Run the Nushell command `ai deep-research start "<refined_prompt>" --max --planning`.
2. **Retrieve Plan**: When the Nushell command `ai deep-research status` indicates a plan is ready, find the `plan-<id>.json` file in the current directory or check the status output.
3. **Present Plan**: Present the proposed research steps to the user for review.
4. **Respond to Plan**: Use the Nushell command `ai deep-research plan-respond "<feedback>" --id "<id>"` based on user approval or revisions.
5. **Finalize**: Once the plan is approved, proceed to monitor the status as in Autonomous Mode.

### 5. Retrieving and Saving Results
1. **Completion**: Once the Nushell command `ai deep-research status` shows the job is `completed`, the report is ready.
2. **Download**: Run the Nushell command `ai deep-research retrieve --id "<id>" --output "<topic_slug>.md"`.
3. **Verification**: Confirm the file was saved correctly and inform the user of its location.

### 6. Configuration & Settings

| Setting | Default | Flags | Description |
| :--- | :--- | :--- | :--- |
| **Depth** | **Max** | `--max` | High comprehensiveness (10-30+ mins). Use by default unless the user asks for a quick/standard summary. |
| **Workflow** | **Autonomous** | (None) | Run research to completion. Use `--planning` for collaborative planning. |
| **Output** | **Local File** | `--output` | Save the final report as a `.md` file in the current working directory. |

### 7. Common Commands Quick Reference
- `ai deep-research start "<prompt>"`: Starts research.
- `ai deep-research status`: Checks and auto-refreshes incomplete jobs.
- `ai deep-research retrieve`: Opens interactive menu to retrieve completed reports.
- `ai deep-research plan-respond "Approve"`: Approves a research plan.

### 8. Robust Polling & Patience
Deep research is a long-running process, especially in `--max` mode.
- **Expected Duration**: 10 - 30+ minutes for `--max`.
- **Instruction**: Do NOT give up early. If `ai deep-research status` shows a job is still `processing`, wait at least 3-5 minutes before checking again.
- **Background Task**: The research runs on the server; your session remains active. You can perform other tasks while waiting, but remember to periodically check the status.
