---
name: cron-nnet-ga-researcher
description: Autonomous scientific paper research on Feedforward Neural Networks and Genetic Algorithms, outputting a Markdown summary to stdout.
---

# cron-nnet-ga-researcher

Autonomously researches recent scientific papers related to Feedforward Neural Networks (FNN) and Genetic Algorithms (GA), processing them for key insights and generating a consolidated Markdown summary.

## Logic & Workflow

1.  **State Management & Search Discovery**:
    - **Check State**: Check for `~/workspace/deepresearch/from_cron_skills/nnet_and_ga/update.json`.
        - If it exists, read the `last_run` date and search for papers published from that date onwards.
        - If it does not exist, search for papers published in the last 12 months.
    - **Discovery**: Use Research MCP tools (`search_arxiv`, `papers-search-basic`).
    - **Keywords**: "Feedforward Neural Network", "Genetic Algorithm", "Optimization", "Hybrid AI".
2.  **Deduplication & Filtering**:
    - Normalize and compare paper titles and DOIs to avoid processing duplicates.
    - Filter results based on relevance and quality (e.g., citation count or journal reputation if available).
3.  **Paper Processing**:
    - For each selected paper, retrieve the abstract and full text (if accessible).
    - Use LLM-based extraction to identify:
        - **Problem**: The core optimization or architectural challenge.
        - **Method**: The specific hybrid approach or innovation.
        - **Results**: Performance improvements or theoretical findings.
4.  **Consolidation**:
    - **Mandatory Activation**: Activate the `writing-expert` skill — MUST use it to write and humanize the final report.
    - Merge insights from multiple papers into a cohesive Markdown report.
    - Format the report with clear sections and citations.
5.  **Output & Persistence**:
    - **Save Report**: Save the final Markdown report to `~/workspace/deepresearch/from_cron_skills/nnet_and_ga/YYYY_MM_DD.md` (using the current date).
    - **Update State**: Update `~/workspace/deepresearch/from_cron_skills/nnet_and_ga/update.json` with the current timestamp in the `last_run` field.
    - **Create Todo**: Execute via the nushell mcp evaluate tool:
	```nu
	h add todos --checklist [] --priority 1 --text "new report in ~/workspace/deepresearch/from_cron_skills/nnet_and_ga" --notes "" --due ""
	```
    - **Standard Output**: Return the final Markdown report to `stdout`.
6.  **Error Handling**:
    - If a major failure occurs, capture the error and output a Markdown failure report to `stdout`.

## Instructions

- You are a specialized assistant for the `cron-nnet-ga-researcher` skill.
- **Academic Rigor**: Maintain a high standard of accuracy and proper citation.
- **Data Persistence:**
    - Always check the `update.json` file to determine the search timeframe.
    - Ensure both the new report file and the updated `update.json` are successfully written to `~/workspace/deepresearch/from_cron_skills/nnet_and_ga/`.
- **Output Format:**
    - Output plain Markdown directly to stdout. Do NOT wrap in JSON envelopes.
    - **PROHIBITED**: Markdown tables, raw JSON, horizontal rules.
    - Format the report in Markdown.
    - Use headers: `# NNET & GA Research Summary - [Date]`.
    - Use sub-headers for each paper: `## [Paper Title]`.
    - Include a structured breakdown for each:
        - **Authors**: ...
        - **DOI**: ...
        - **Summary**: ...
        - **Key Innovation**: ...
- **Failure Reporting**: If any step fails, capture the error and output a Markdown failure report to `stdout`.

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.
