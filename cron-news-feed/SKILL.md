---
name: cron-news-feed
description: Autonomous news search and outputting a bulleted Markdown summary to stdout for diverse topics.
---

# cron-news-feed

Autonomously searches for the latest and most relevant news across 7 categorized groups (AI & Tech, Science, Politics, etc.), generating a Markdown summary for each.

## Logic & Workflow

1.  **News Discovery:** For each of the following 7 categories, perform a high-quality news search using `exa_web_search_exa`:
    - **Group 1: AI & Tech**
    - **Group 2: Science & Space**
    - **Group 3: Global Politics & Economics**
    - **Group 4: Cybersecurity & Privacy**
    - **Group 5: Environment & Sustainability**
    - **Group 6: Health & Biotechnology**
    - **Group 7: Culture & Societal Trends**
2.  **Triage & Selection:**
    - For each category, evaluate the search results.
    - Select the top 3-5 most impactful, surprising, or significant news items.
    - Prioritize stories with high relevance to technical innovation and global impact.
3.  **Summarization:**
    - For each selected news item, extract the core information.
    - Create a concise summary (Title + Key Takeaway + Source Link).
4.  **Markdown Generation:**
    - Construct a professional Markdown report for each category.
    - Return the report as plain Markdown to `stdout`.
5.  **Final Summary:** Output a summary indicating the total number of categories and news items processed.
6.  **Error Handling:** If any major failure occurs, capture the error and output a failure report in Markdown to `stdout`.

## Instructions

- You are a specialized assistant for the `cron-news-feed` skill.
- **Search Queries:**
    - Use `mcp_standard-exa_web_search_exa(query: "latest news in [Category Name] [Current Date]", type: "auto")`.
- **TRIAGE Guidelines:**
    - **Filter:** Aim for high signal-to-noise. Ignore clickbait or minor updates.
    - **Diversity:** Ensure a broad range of topics within each category.
- **Output Guidelines:**
    - Format each category report in Markdown.
    - Use clear headers: `## News Feed: [Category Name]`.
    - Use bullet points for news items:
        - **[News Title]**
        - *Key Takeaway:* [1-2 sentences]
        - *Link:* <Source URL>
    - **CRITICAL**: Source links MUST be the EXACT, full URLs retrieved from the search results. Use the literal URL without any modification. Format them using angle brackets (e.g., `<https://example.com/very/long/url/here>`). Do NOT use markdown link syntax like `[text](url)`. This ensures the links are clickable.
    - **CRITICAL**: NEVER use markdown horizontal rules (e.g., `---`, `***`, `___`) to separate sections, as they will cause the output to be truncated by external reporting tools. Use simple line breaks or header hierarchy instead.
    - **CRITICAL**: NEVER use markdown horizontal rules (e.g., `---`, `***`, `___`) to separate sections.
    - **CRITICAL FORMATTING**: Output plain Markdown directly to stdout. Do NOT wrap in JSON envelopes.
    - **MANDATORY**: NEVER save output to a file — always print to stdout.
    - **PROHIBITED**: Markdown tables, raw JSON, single-paragraph prose summaries.
- **Failure Reporting**: If any step fails, capture the error and output a Markdown failure report to `stdout`.

## Reporting Protocol
This skill MUST output its final results directly to stdout for external handling and MUST NOT use the to-discord command for automated reporting.
