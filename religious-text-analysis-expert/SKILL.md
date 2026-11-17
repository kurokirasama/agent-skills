---
name: religious-text-analysis-expert
description: Orchestrates full multi-stage analysis of religious and biblical texts by coordinating biblical-assistant, debunk-expert, main-idea-extractor, and biblical-analyst into a single consolidated report. Use when the user provides a religious or biblical text to analyze.
---

# Religious Text Analysis Expert

## Overview
This skill acts as the senior orchestrator for deep, multi-dimensional theological and textual analysis of religious and biblical documents. It replicates the automated analysis chain of `ai analyze_religious_text`, coordinating false-claim extraction, targeted counter-argument debunking, scripture cross-referencing, core message distillation, and comprehensive synthesis into a single report.

**Nushell Mandate:** ALWAYS activate the `nushell-expert` skill before executing the first Nushell command or pipeline.

---

## 1. Input Processing & Ingestion

1. **Input Types**:
   - Accepts plain text, markdown notes, theological transcripts, or pasted sermon excerpts.
2. **Text Normalization**:
   - Strip OCR or transcription noise inline (preserving scripture chapter:verse citations, theological terminology, and grammatical integrity).
   - Identify the source language (the final report MUST be delivered in the input's original language).

---

## 2. Multi-Stage Theological Analysis Pipeline

### Religious Text Analysis Swarm Option
For extensive theological documents, sermons, or multi-chapter commentaries:
- **Approval Gate**: Send Discord alert (`to-discord $msg -p`), then prompt user:
  > "Extensive theological text detected. Would you like to spawn a 4-agent Religious Text Analysis Swarm (`biblical-assistant`, `debunk-expert`, `main-idea-extractor`, `biblical-analyst`) to evaluate the text concurrently?"
- **Roster Configuration (`workspace: "inherit"`)**:
  - `biblical-assistant`: Scriptural cross-referencing and false claim extraction.
  - `debunk-expert`: Targeted counter-arguments and logical fallacy deconstruction.
  - `main-idea-extractor`: Primary thesis, core argument flow, and hidden assumptions.
  - `biblical-analyst`: Comprehensive doctrinal synthesis and scriptural alignment scoring.
  - `monitor`: Stall watchdog running `swarm_monitor`.
- **Coordinator Consolidation**: Synthesize board posts into the final consolidated markdown report.
- **Manual Slash Command**: Suggest: `/swarm Analyze theological text <file_path>`.

### Sequential Multi-Stage Pipeline (Default / Fallback)

Execute the analytical pipeline sequentially, activating each specialized toolkit skill prior to executing its corresponding step:

```
[Religious Text Input]
          │
          ▼
┌────────────────────────────────────────────────────────┐
│ Step 1: biblical-assistant                             │
│ Extract false doctrinal or factual claims (JSON)       │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 2: debunk-expert                                  │
│ Refute each identified false claim with evidence       │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 3: biblical-assistant                             │
│ Extract explicit biblical references & passages (JSON) │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 4: biblical-assistant                             │
│ Discover new related biblical references (JSON)        │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 5: main-idea-extractor                            │
│ Distill primary theological theme & moral message      │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│ Step 6: biblical-analyst                               │
│ Consolidate all findings into a unified report         │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
          [Final Report in Original Language]
```

### Step 1: False Claim Identification
- **Active Skill**: Activate `biblical-assistant`.
- **Action**: Analyze the text for unbiblical, doctrinally questionable, or fallacious claims and output them in structured JSON format.

### Step 2: Targeted Refutation & Debunking
- **Active Skill**: Activate `debunk-expert`.
- **Action**: Execute the debunking protocol against each extracted false claim, demonstrating why the claim is problematic using sound logic and scriptural refutation.

### Step 3: Scriptural Reference Extraction
- **Active Skill**: Activate `biblical-assistant`.
- **Action**: Parse all direct scripture citations, verses, and allusions explicitly mentioned in the text into structured JSON.

### Step 4: Contextual Cross-Referencing
- **Active Skill**: Activate `biblical-assistant`.
- **Action**: Discover complementary scripture passages and contextual verses that illuminate, qualify, or support the themes addressed.

### Step 5: Core Message Distillation
- **Active Skill**: Activate `main-idea-extractor`.
- **Action**: Extract the central homiletic message, practical moral application, and core doctrinal thesis of the passage.

### Step 6: Final Synthesis & Reporting
- **Active Skill**: Activate `biblical-analyst`.
- **Action**: Synthesize the refutations, scripture citations, contextual connections, and core theme into a polished, comprehensive analysis report.

---

## 3. Delivery Guidelines

- **Language Mandate**: The final report MUST be delivered in the **original language** of the input text (e.g., Spanish input produces Spanish analysis).
- **Format**: Return the complete, structured analysis in clean markdown to the user.
