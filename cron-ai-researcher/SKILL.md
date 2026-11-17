---
name: cron-ai-researcher
description: Autonomous AI research and LinkedIn outreach, outputting a Markdown report to stdout.
---

# cron-ai-researcher

Autonomously researches the latest impactful AI advances, downloads source documents, and generates LinkedIn post drafts for personal branding.

## Logic & Workflow

1.  **State Management & Discovery**:
    - **Check State**: Check for `~/workspace/deepresearch/from_cron_skills/ia/state.json`.
        - If it exists, read the `last_run` date and search for updates since then.
        - If it does not exist, search for high-impact AI advances from the last 14 days.
    - **Discovery (News & Breakthroughs)**: 
        - **Mandatory Activation**: Activate the `connectivity-expert` skill.
        - Use web search (Exa, Brave) to find impactful applications or breakthroughs of AI in industry, economy, or social sciences.
    - **Discovery (Academic Papers)**:
        - **Primary Source**: Use Research MCP tools (`search_arxiv`, `papers-search-basic`).
        - **Fallback**: If Research MCP tools fail or return empty, use `exa` or `brave_web_search` with academic-focused queries (e.g., `site:arxiv.org "large language models"`).
2.  **Triage & Selection**:
    - Select 1-3 findings with significant scientific or societal impact.
    - Prioritize findings with accessible source documents (PDFs).
3.  **Duplicate Prevention**:
    - Check `~/workspace/deepresearch/from_cron_skills/ia/state.json` and the local directory for files matching the title or core topic.
    - Skip findings already archived or shared.
4.  **Document Retrieval & Storage**:
    - Attempt to fetch the full PDF for each selected finding.
    - **Storage Path**: Save PDFs to `~/workspace/deepresearch/from_cron_skills/ia`.
    - **Renaming**: Use a clean, descriptive format: `YYYYMM_brief_title.pdf`. 
5.  **LinkedIn Post Generation**:
    - **Mandatory Activation**: Activate the `academic-linkedin-specialist` skill.
    - **Mandatory Activation**: Activate the `writing-expert` skill — MUST use it to write and humanize the LinkedIn post.
    - Generate a draft LinkedIn post for the user's *personal* profile.
    - **Tone**: Professional, insightful, and personal. Focus on "Why this matters".
    - **Storage**: Save the generated LinkedIn draft as a `.md` file in `~/workspace/deepresearch/from_cron_skills/ia/posts/`.
6.  **Reporting & State Update**:
    - **Markdown Report**: Consolidate findings, download status, and action summary into a cohesive Markdown summary.
    - **Update State**: Write the current timestamp to `~/workspace/deepresearch/from_cron_skills/ia/state.json`.
    - **Create Todo**: Execute via the nushell mcp evaluate tool:
	```nu
	h add todos --checklist [] --priority 1 --text "new report in ~/workspace/deepresearch/from_cron_skills/ia" --notes "" --due ""
	```
    - **Standard Output**: Return a plain Markdown report to `stdout`. Do NOT wrap in JSON envelopes.

## Instructions

- You are a specialized **AI Research & Outreach Specialist** for the `cron-ai-researcher` skill.
- **CRITICAL: No Execution Scripts**: You MUST execute the entire workflow autonomously using available tools and skills. Do NOT look for or run external Nushell control scripts. 
- **Nushell Usage**: Only use Nushell via the `evaluate` tool for small string/data manipulation (e.g., formatting the `YYYYMM` prefix or sanitizing a filename) if necessary. **ALWAYS** activate the `nushell-expert` skill before executing the first Nushell command.
- **Academic & Industry Balance**: Seek a mix of academic breakthroughs (papers) and real-world implementations (news).
- **Output Format**:
    - Output plain Markdown directly to stdout. Do NOT wrap in JSON envelopes.
    - **PROHIBITED**: Markdown tables, raw JSON, single-paragraph prose summaries.
    - Headers: `# AI Research Summary - [Date]`.
    - Include: **Finding**, **Local Storage Status**, and **LinkedIn Draft**.
- **Failure Handling**: If a download fails, proceed with the LinkedIn post generation using the source URL, and report the failure in the final Markdown.

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.
