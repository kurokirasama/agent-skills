---
name: deep-retrieval-task
description: Performs deep URL discovery using web search, crawling, and academic search tools.
---

# Deep Retrieval Task

When the user asks for a _deep retrieval task_, you will consider what is established in this section.

## Objective

Your objective is to conduct deep, comprehensive research on a specific topic the user will provide. You are to identify and collect all relevant source URLs, organizing them systematically for potential future retrieval. **Your task is strictly limited to URL collection and organization - you must NOT write reports on the findings.**

## Research Classification

Before commencing, you will classify the research into one of two categories based on the provided topic. Your approach and source prioritization will be strictly guided by this classification:

- **Scientific Deep Research**: Focus primarily on up-to-date scientific literature (peer-reviewed articles, scientific books, scholarly databases). You can use web search, web scraping, and research paper search tools to discover related topics, identify specific paper names, or find references.
- **Knowledge Deep Research**: Cover a broader spectrum of sources (news articles, reputable blogs, educational YouTube videos, general web pages, and relevant social media posts). You may include scientific literature relevant to the topic as secondary sources if applicable.

## Autonomous Iteration Protocol

**You will operate autonomously in iterative cycles until the stopping criteria is met. Do not wait for user approval between iterations - continue the research process automatically.**

## Execution Protocol for Deep Research URL Collection

1.  **Topic Definition & Scope Refinement:** Clearly define the core research topic. As your understanding evolves through initial searches, identify and incorporate any new, highly relevant sub-topics or keywords that warrant further investigation.

2.  **Source Identification & URL Collection:** Utilize your integrated web search, web crawling, research paper search, and other discovery tools to compile a comprehensive list of diverse source URLs based on searches of the identified keywords/sub-topics. Prioritize sources based on their authority, relevance, and the specific research classification (Scientific vs. Knowledge).

3.  **Iterative URL Discovery & Expansion:** **Continue autonomously through multiple search cycles:**
    - After each search cycle, analyze the discovered URLs and their metadata
    - Extract new keywords, concepts, and research directions
    - Identify potential information gaps or unexplored angles
    - Conduct additional searches using newly discovered terms
    - **Repeat this process automatically until stopping criteria are met**

4.  **URL Documentation:** Create a markdown file named `research_sources_[topic].md` containing all discovered URLs organized by:
    - **Source Type** (Scientific Papers, News Articles, Blog Posts, YouTube Videos, etc.)
    - **Relevance Score** (High/Medium/Low)
    - **Brief Description** of what each source covers (URL metadata only - no content analysis)
    - **Discovery Method** (which search terms or tools led to finding this source)

5.  **URL List Structure:** The markdown file should follow this format (within the code block):

```md
# Deep Research Sources

Main Research Topic: [Topic Name]
Research Classification: [Scientific/Knowledge Deep Research]
Date: [ISO date]
Total Sources Found: [Number]
Search Iterations Completed: [Number]

## Search Strategy Evolution

- Iteration 1: [Initial keywords used]
- Iteration 2: [Refined/additional keywords]
- Iteration N: [Final search terms]

## Potential Research Gaps Identified

- [Gap 1]
- [Gap 2]
- etc

## High Priority Sources

### Scientific Papers

- **Title:** [Paper Title]
    - **URL:** [Full URL]
    - **Source:** [Journal/Conference/Repository]
    - **Discovery Method:** [Search terms/tools used]

### Web Articles

- **Title:** [Article Title]
    - **URL:** [Full URL]
    - **Source:** [Website/Publication]
    - **Discovery Method:** [Search terms/tools used]

### YouTube Videos

- **Title:** [Video Title]
    - **URL:** [Full URL]
    - **Channel:** [Channel Name]
    - **Discovery Method:** [Search terms/tools used]

## Medium Priority Sources

[Same structure as above]

## Low Priority Sources

[Same structure as above]
```

## Error Handling

- If a search fails or yields no results, document this in the markdown file
- Continue autonomously with alternative search strategies or terms
- Report any inaccessible URLs but keep them in the list for potential future availability

## Stopping Criteria

**You will automatically conclude the iterative deep retrieval task process when ALL of the following conditions are satisfied:**

- **Exhaustive Coverage:** The core research topic has been thoroughly explored across multiple search iterations, with no significant unexplored critical avenues remaining based on the identified classification.
- **Diminishing Returns:** Recent search iterations (last 2-3 cycles) yield fewer than 10% new, relevant URLs compared to previous iterations.
- **Keyword Saturation:** No new meaningful keywords or research directions emerge from the most recent search cycles.
- **Source Diversity:** Adequate representation across different source types appropriate to the research classification.
- **Number of Sources:** At least 20 unique sources have been collected.

**Important: You determine when these criteria are met - do not ask the user for permission to continue or stop.**

## Final Output

Present the user with **ONLY**:

1. The complete markdown file with all collected URLs in the format described before.
2. A brief summary stating:
    - Total URLs collected
    - Number of search iterations completed
    - Research classification used
    - Confirmation of what stopping criteria was used
