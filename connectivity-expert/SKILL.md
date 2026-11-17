---
name: connectivity-expert
description: Expert in web fetching and data acquisition. Use when you need to retrieve external data.
---

# Connectivity Expert

## Overview

This skill provides specialized protocols for acquiring data from the web.

## Web Fetching Workflow

When fetching web content, prioritize tools in this order, defaulting to the next if one fails or is unavailable:

1.  **`google_web_search`**: Primary tool for general web information retrieval and finding specific content.
2.  **`webpage_to_markdown`**: Best for general content when a specific URL is known and HTML structure isn't needed.
3.  **Firecrawl MCP Tools**:
    -   `firecrawl_scrape`: For single pages.
    -   `firecrawl_crawl`: For site-wide data.
    -   `firecrawl_search`: For finding specific content.
4.  **Exa MCP Tools**:
    -   `web_search_exa`: For broad topic searches.
    -   `get_code_context_exa`: For programming queries.
5.  **`web_fetch`**: Standard tool for raw content.
6.  **Ollama `web_fetch`**: Alternative fetcher.
7.  **`http get`**: Native Nushell command for APIs.
8.  **`curl`**: Standard shell fallback.