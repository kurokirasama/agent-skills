---
name: paper-analysis-expert
description: Orchestrates full scientific paper analysis by coordinating paper-analyzer, paper-summarizer, and paper-wisdom-consolidator into a single consolidated report saved to disk. Use when the user provides a paper (PDF/text) or asks to analyze a paper.
---

# Paper Analysis Expert

## Overview
This skill serves as the primary meta-skill orchestrator for scientific and academic paper analysis. It replicates the automated pipeline of `ai analyze_paper`, systematically chaining specialized toolkit skills to generate an in-depth scientific rigor evaluation, an executive summary, and a wisdom-consolidated synthesis section.

**Nushell Mandate:** ALWAYS activate the `nushell-expert` skill before executing the first Nushell command or pipeline.

---

## 1. Input Preparation & Text Extraction

1. **Format Detection & Extraction**:
   - **PDF Inputs**: Convert to plain text using system extraction utilities:
     ```bash
     pdftotext -layout "<paper_path>.pdf" "<paper_stem>.txt"
     ```
     Or use available MCP conversion tools if local tools are not present.
   - **Markdown / Plain Text Inputs**: Read the source directly without format conversion.
2. **Inline Artifact Sanitization**:
   - Clean page headers, page footers, repeated running titles, and OCR hyphenation artifacts inline.
   - Retain complete author affiliations, abstracts, methodology sections, figures/tables descriptions, and bibliography citations.

---

## 2. Multi-Stage Analysis Pipeline

### Paper Analysis Swarm Option
When processing comprehensive or lengthy research papers ($>8$ pages), the orchestrator may deploy a **Paper Analysis Swarm**:
- **Approval Gate**: Send Discord alert (`to-discord $msg -p`), then prompt user:
  > "Lengthy research paper detected (<N> pages). Would you like to spawn a 3-agent Paper Analysis Swarm (`paper-analyzer`, `paper-summarizer`, `wisdom-extractor`) to analyze the text in parallel?"
- **Roster Configuration (`workspace: "inherit"`)**:
  - `paper-analyzer`: Rigor, hypotheses, sample size, statistical validity, experimental control design.
  - `paper-summarizer`: Motivation, section-by-section breakdown, key quantitative metrics.
  - `wisdom-extractor`: Lasting mental models, counter-intuitive findings, cross-domain applications (`paper-wisdom-consolidator`).
  - `monitor`: Stall watchdog running `swarm_monitor`.
- **Coordinator Consolidation**: The coordinator takes the board posts from all 3 workers and compiles the unified `<paper_stem>.md` deliverable.
- **Manual Slash Command**: Suggest: `/swarm Analyze research paper <paper_path>`.

### Sequential Multi-Stage Pipeline (Default / Fallback)

Execute each analytical stage sequentially, ensuring the corresponding specialist skill is activated prior to executing the step:

```
[Input Document]
       │
       ▼
┌──────────────────────────────────────────────┐
│ Stage 1: paper-analyzer                      │
│ Primary findings & scientific rigor analysis │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ Stage 2: paper-summarizer                    │
│ Structured executive summary                 │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────┐
│ Stage 3: paper-wisdom-consolidator           │
│ Unified consolidation of analysis + summary  │
└──────────────────────┬───────────────────────┘
                       │
                       ▼
            [Saved to <stem>.md]
```

### Stage 1: Scientific Rigor & Findings Analysis
- **Active Skill**: Activate `paper-analyzer`.
- **Actions**:
  - Extract the core research questions, theoretical frameworks, and central hypotheses.
  - Evaluate methodological rigor, dataset integrity, experimental control design, and statistical validity.
  - Document key scientific findings, potential biases, and boundary conditions.

### Stage 2: Comprehensive Summarization
- **Active Skill**: Activate `paper-summarizer`.
- **Actions**:
  - Distill the paper into an executive summary highlighting motivation, key contributions, quantitative results, and practical implications.
  - Structure the summary with clear headings and concise bullet points.

### Stage 3: Wisdom Consolidation & Synthesis
- **Active Skill**: Activate `paper-wisdom-consolidator`.
- **Actions**:
  - Synthesize the outputs from Stage 1 (rigor analysis) and Stage 2 (summary) into a unified, high-value reference document.
  - Extract lasting takeaways, actionable insights, and cross-domain connections.

---

## 3. Output Persistence & Delivery

1. **File Persistence**:
   - Combine the scientific rigor analysis, structured summary, and consolidated wisdom section.
   - Save the full markdown document to `<stem>.md` in the target directory:
     ```bash
     # Destination pattern
     <paper_stem>.md
     ```
2. **User Notification**:
   - Present a concise conceptual overview of the paper's findings and confirmation of the saved `<stem>.md` file path.
