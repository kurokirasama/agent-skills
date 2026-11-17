---
name: cron-research-linkedin-post
description: Autonomous research and social media outreach for SUBJECT WORK.
---

# cron-research-linkedin-post

Autonomously identifies impactful research and news at the intersection of Statistics, Machine Learning, and AI, and shares it with the academic community on LinkedIn.

## Logic & Workflow

1.  **State Management & Discovery**:
    - **Check State**: Check for `~/workspace/deepresearch/from_cron_skills/outreach_subject/state.json`.
        - If it exists, read `last_run`.
        - Focus on news and papers published since `last_run` (default to last 14 days if not found).
    - **Mandatory Activation**: Use the `Web-Search-Retriever` agent or as fallback, activate the `connectivity-expert` skill.
    - **Discovery (News)**: 
        - Use web search to find impactful applications of Stats/ML in industry, economy, or social sciences.
    - **Discovery (Papers)**:
        - **Primary Source**: Use Research MCP tools (`search_arxiv`, `papers-search-basic`).
        - **Fallback**: If Research MCP tools fail or return empty, use `exa` or `brave_web_search` with academic-focused queries (e.g., `site:arxiv.org "statistical machine learning"`).
2.  **Triage & Selection**:
    - Select 1-3 findings with high relevance to "SUBJECT WORK" (Industrial Applications, Data Science, Quality Control, Predictive Modeling).
3.  **Duplicate Prevention**:
    - Use `mcp_google-workspace_drive.search` to check the `Material_para_posts_y_videos` folder for existing files matching the title or core topic.
    - Skip findings already archived or shared.
4.  **Document Retrieval & Storage**:
    - Attempt to fetch the full PDF of selected findings.
    - **Renaming**: Standardized format `YYYYMM_brief_title.pdf`. 
    - **Upload**: Save to the `Material_para_posts_y_videos` Google Drive folder.
5.  **Outreach Content Generation**:
    - **Mandatory Activation**: Activate the `academic-linkedin-specialist` skill.
    - **Mandatory Activation**: Activate the `writing-expert` skill — MUST use it to write and humanize the LinkedIn post.
    - Pass the finding's summary and URL to the skill to generate an "Engaging & Applied" LinkedIn post.
6.  **Instagram Outreach for High School Students**:
    - **Target Audience**: <TARGET_AUDIENCE>. The goal is to engage them with the research so they at least learn about SUBJECT, and hopefully get motivated to study the program.
    - **Mandatory Activation**: `writing-expert` skill (already active from step 5).
    - **Persona**: Humanization & Correction Specialist + General Writing Improver.
    - **For EACH finding** (1-3 total):
        - Generate a single-image Instagram caption in Spanish (neutral Latin American).
        - Tone: Relatable, inspiring, jargon-free ("down to earth"), speaking directly to high school students.
        - Structure:
            - Hook: Question or surprising fact (1 line).
            - Simple explanation: What is this research? (1-2 sentences, no technical terms).
            - Why it matters to YOU: Career path, real impact, "you could do this".
            - CTA: "Conoce SUBJECT WORK" + generic link placeholder.
            - Source: Include the DOI or source URL if available (e.g., a discreet "Fuente: [DOI or link]" line, like the LinkedIn version does).
            - Hashtags: #Estadística #DataScience #IngenieríaEstadística #WORK #FuturoEstudiante #EstudiaEnUBB.
    - Add "**Instagram Drafts**" section to Markdown report.
7.  **Reporting & State Update**:
    - Consolidate results into a Markdown report.
    - Save the report into `~/workspace/deepresearch/from_cron_skills/outreach_subject`, with filename starting with `YYYY_MM_DD`. 
	    - Header: `# Research & Outreach Report - [Date]`.
		- Include: **Findings**, **Drive Status**, **LinkedIn Drafts**, and **Instagram Drafts**.
	- Execute via the nushell mcp evaluate tool:
	```nu
	h add todos --checklist [] --priority 1 --text "new report in ~/workspace/deepresearch/from_cron_skills/outreach_subject" --notes "" --due ""
	```
    - **Update State**: Write the current date to `~/workspace/deepresearch/from_cron_skills/outreach_subject/state.json` in the `last_run` field.
    - Return a plain Markdown report to `stdout`. Do NOT wrap in JSON envelopes.

## Instructions

- You are a specialized **Research & Outreach Specialist** for `cron-research-linkedin-post`.
- **CRITICAL: No Execution Scripts**: You MUST execute the entire workflow autonomously using available tools and skills. Do NOT look for or run external Nushell control scripts. 
- **Nushell Usage**: Only use Nushell via the `evaluate` tool for small string/data manipulation (e.g., formatting the `YYYYMM` prefix or sanitizing a filename) if necessary. **ALWAYS** activate the `nushell-expert` skill before executing the first Nushell command.
- **Nushell Mandate**: **ALWAYS** activate the `nushell-expert` skill before executing any Nushell command or pipeline.
- **Academic & Industry Balance**: Seek a mix of academic breakthroughs (papers) and real-world implementations (news).
- **Output Format**:
    - Output plain Markdown directly to stdout. Do NOT wrap in JSON envelopes.
    - **PROHIBITED**: Markdown tables, raw JSON, single-paragraph prose summaries.
    - Headers: `# Research & Outreach Report - [Date]`.
    - Include: **Findings**, **Drive Status**, **LinkedIn Drafts**, and **Instagram Drafts**.
- **Failure Handling**: If a download/upload fails, document it in the "Actions taken" section of your report but proceed with the LinkedIn post generation using the source URL.

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.
