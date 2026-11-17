---
name: deep-research
description: High-level orchestrator for end-to-end research, parallelizing native Gemini Deep Research with the retrieval/synthesis pipeline.
---
# Deep Research Orchestrator

## Objective
Your objective is to conduct an exhaustive, end-to-end research task on a specific topic. You will orchestrate a multi-track pipeline that parallelizes native background research with a deep retrieval and synthesis workflow.

## 1. Preparation & Cost Approval
**CRITICAL**: This pipeline utilizes the `gemini-deep-research` skill, which incurs a cost. You MUST explicitly ask the user for approval for the entire pipeline before proceeding.

- **Unified Topic Definition**: Clearly define the research topic and classification (Scientific vs. Knowledge).
- **Approval Prompt**: "The `deep-research` orchestrator will parallelize the native Gemini Deep Research Nushell command with a multi-phase retrieval and synthesis pipeline. This process incurs a cost. Do you approve its usage for this task?"
- **Fallback**: If the user declines, proceed using ONLY standard, non-cost-bearing logic for both `deep-retrieval-task` and `source-retrieval-task`.

## 2. Parallel Execution Phase
Once approved, you must initiate the parallel tracks:

### Deep Research Swarm Option
For extensive multi-domain research, the orchestrator may deploy a **Deep Research Swarm**:
- **Approval Gate**: Send Discord alert (`to-discord $msg -p`), then prompt user:
  > "Multi-domain research topic detected. Would you like to spawn a Deep Research Swarm with sharded research workers across scholarly and web sources?"
- **Roster Configuration (`workspace: "inherit"`)**:
  - `scholar-worker`: Queries academic databases (arXiv, Europe PMC, OpenAlex) for peer-reviewed literature.
  - `web-worker`: Executes deep web scraping, documentation indexing, and news retrieval.
  - `synthesis-worker`: Chunks, indexes, and organizes findings on the shared board.
  - `monitor`: Stall watchdog running `swarm_monitor`.
- **Manual Slash Command**: Suggest: `/swarm Research topic <topic_query>`.

### Dual Track Execution (Default / Fallback)
### Track A: Native Gemini Deep Research
- Activate and use the **`gemini-deep-research`** skill.
- Initiate background research using the Nushell command `ai deep-research start "<refined_prompt>" --max`.
- Note the Research ID and continue to Track B.

### Track B: Retrieval Pipeline
- Immediately execute the **`deep-retrieval-task`** skill to find a comprehensive list of source URLs.
- Once Track B is complete, immediately trigger the **`source-retrieval-task`** skill.
- Provide the list of URLs from Track B as input for content extraction and RAG-based synthesis.

## 3. Monitoring & Convergence
- Periodically check the status of the native background research from Track A using the Nushell command `ai deep-research status --id "<id>"`.
- Simultaneously monitor the progress of the retrieval/synthesis pipeline in Track B.
- Ensure that the final synthesis in `source-retrieval-task` is performed once all relevant sources are downloaded.

## 4. Final Consolidation
Once both the native report (from Track A) and the grounded synthesis (from Track B) are complete:
- Retrieve the native report using the Nushell command `ai deep-research retrieve`.
- Combine the insights from both sources.
- Present a final, comprehensive package that includes:
    1. The native Deep Research report.
    2. The grounded synthesis based on the retrieval pipeline.
    3. The consolidated list of sources.
