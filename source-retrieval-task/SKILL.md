---
name: source-retrieval-task
description: Downloads source content and performs RAG-based synthesis from provided documents.
---

# Source Retrieval Task

## Objective

When you are presented with a list of URLs sources and possibly additional information, and asked explicitly to download them or asked for a _source retrieval task_, you are to gather and download the full content of all of them that have not been already processed/downloaded, formatting them meticulously as markdown files. Usually, a _source retrieval task_ goes after a _deep retrieval task_.

## Execution Protocol

1. **Create Download Directory:** Create a new directory in the root of the current project, named appropriately for the research topic, to store all downloaded sources. The main research topic will be provided together with the list of URLs. Most likely the information (urls and main research topic) will be provided in a file, but if it isn't, create a new file with the provided information. To this file, whether provided or creates, we'll call it _original source text_.

2. **Source Content Extraction & Markdown Formatting:** For each identified source url, that hasn't been already processed/downloaded, extract/download its content and convert it into a standalone markdown file using the appropriate strategy based on source type. You can know an url has been processed by looking at the end of the line it is writted in the _original source text_, it will have the word DONE next to it. The status of an extraction process is represented by the label DONE, which can be further specified as DONE/FULL, DONE/PARTIAL, or DONE/FAILED.

3. **Grounded Synthesis (RAG):** If requested to synthesize findings from the downloaded sources:
    - Instruct your internal model to generate a comprehensive synthesis based *only* on the provided documents in the download directory.
    - Focus on identifying key themes, data points, and cross-source validations.
    - Provide a "Super Summary" as part of your final output.

### Extraction Status Reference

These designations indicate whether the content was completely extracted, partially extracted, or if the extraction process encountered a failure, respectively. For instance, in this example:

- **Title:** Decoding the genetic landscape of autism: A comprehensive review
    - **URL:** https://pmc.ncbi.nlm.nih.gov/articles/PMC11438927/ DONE/FULL
    - **Source:** PMC
    - **Discovery Method:** research_paper_search: "genetic basis of autism spectrum disorder"
- **Title:** Genetics and genomics of autism spectrum disorder: embracing complexity
    - **URL:** https://pmc.ncbi.nlm.nih.gov/articles/PMC4675826/ DONE/PARTIAL
    - **Source:** PMC
    - **Discovery Method:** research_paper_search: "genetic basis of autism spectrum disorder"
- **Title:** Genetics of autism
    - **URL:** https://pmc.ncbi.nlm.nih.gov/articles/PMC123456/ DONE/FAILED
    - **Source:** PMC
    - **Discovery Method:** research_paper_search: "genetic basis of autism spectrum disorder"
- **Title:** Genes in autism
    - **URL:** https://pmc.ncbi.nlm.nih.gov/articles/PMC654321/
    - **Source:** PMC
    - **Discovery Method:** research_paper_search: "genetic basis of autism spectrum disorder"

In this example,

- The first source was processed and the content fully extracted.
- The second source was processed but the content was partially extracted.
- The third source was processed and the content couldn't be extracted or it failed.
- The fourth source was not processed yet.

### Scientific Papers Processing Workflow:

0. **Verification of direct PDF link:** Check if the provided URL directly points to a PDF file (for instance, the url can actually ends with "pdf"). If it does, proceed to step 4 . Otherwise, proceed to step 1.
1. **Initial Download:** Download the full content of the provided URL using the webpage-to-markdown tool. If it fails, retry with another available web scraping/search tool.
2. **PDF Link Analysis:** Analyze the downloaded content to search for links to PDF files (look for patterns like .pdf extensions, download links, or academic paper identifiers).
3. **PDF URL Discovery:** If a PDF file URL is not found in the initial content:
    - Use crawling or search tools to search for PDF URLs on the same domain.
    - Search for DOI links and resolve them to find PDF sources.
    - Look for repository links (arXiv, ResearchGate, institutional repositories).
    - If no pdf is found, make use of the paper search tools to find the PDF source.
4. **PDF Download:** If a PDF URL is found, download it using the `terminal` tool with `wget` or `curl`:
    ```bash
    wget -O "paper_title.pdf" "https://example.com/paper.pdf"
    ```
5. **PDF Content Extraction:** Extract the PDF content using:
    - Primary: pdf-to-markdown tool
    - Fallback: Use terminal/shell tool with pdftotext command if the primary method fails:
        ```bash
        pdftotext "paper_title.pdf"
        ```
6. **Content Prioritization:** If PDF extraction succeeds, use the PDF content as primary source. If PDF URL is not found or extraction fails, use the original webpage content.

### Other Source Types:

- **Web Pages:** Extract the primary content of the page and format it as a markdown file. Ensure proper markdown syntax for headings, paragraphs, lists, links, and code blocks.
- **YouTube Videos:** Obtain the complete transcript, using the getTranscripts tool or another strategy. Then, generate a comprehensive summary of the video's content, formatted as a markdown file, capturing key points and timestamps where appropriate.

### Mandatory Metadata Structure:

Every markdown generated file _must_ have this structure (within the code block):

```md
# [Source Title]

Main Research Topic: [Main Research Topic Name]
Authors: [Author Names, if applicable]
URL: [Full Source URL]
PDF URL: [Full PDF URL, if applicable, otherwise 'N/A']
Content Source: [webpage/pdf/transcript - indicating primary content source]

# Content

[Full markdown content of the source]
```

### Update of progress

Each time you process an url, you'll add the word DONE (don't forget the space before the D), NEXT to the corresponding source url in the _original source text_. This way, if the iterative process fails for whatever reason, you can easily identify which sources were successfully processed and which ones need further attention. Also, you'll update the user with a small message before processing the next url, indicating the progress so far in format xx/XX, where xx represents the number of processed sources urls and XX represents the total number of sources urls. Include in the xx count the number of sources that were already processed (DONE) when this task started.
You will also indicate whether the content was successfully extracted or not, adding the words FULL/PARTIAL/FAILED, when the content was extracted completely, partially (for instance, only abstract or introduction), or failed.

### Error Handling:

- If a source is inaccessible or content extraction fails, skip it but log the issue.
- Continue processing remaining sources without halting.
- Report all problematic URLs in the final summary.

### File Naming Convention:

- Use descriptive names based on source title or main topic
- Replace special characters with underscores or hyphens
- Include source type indicator when helpful (e.g., `paper_`, `video_`, `web_`)

## Final Summary

After processing all sources, provide a summary including:

1. **Processing Statistics:**
    - Total sources processed
    - Successfully downloaded sources
    - Failed downloads with reasons
    - PDF files found and processed
    - Fallback methods used

2. **Failed Sources Report:** Detailed list of problematic URLs and failure reasons
