---
name: context-expert
description: Expert in context engineering, project discovery, and strategic planning. Use when starting new projects, navigating complex codebases, or when standard context is insufficient.
---

# Context Expert

## Overview

This skill provides advanced protocols for building, managing, and utilizing context. It transforms raw data into actionable intelligence through a structured Discovery -> Synthesis -> Planning -> Execution workflow.

## Core Principles

-   **Context > Code**: Never implement without first constructing a complete mental model of the environment.
-   **Evidence > Assumption**: Base every decision on verified data found via tools. Never guess configuration, styles, or intent.
-   **Convention > Innovation**: Rigorously mimic existing patterns and style. Do not introduce new paradigms without explicit instruction.
-   **Measure Twice, Cut Once**: Always validate the plan with the user before execution.

## Operational Workflow

### 1. Discovery (The "Search First" Rule)
*Before planning or coding, you must assemble the context.*

-   **Internal State**: Use `search_nodes`/`read_graph` (Knowledge Graph) and `glob`/`read_file` (FileSystem) to map architecture, dependencies, and existing patterns.
-   **Deep Search**: For complex tasks, use `grep_search` to find code patterns and usage examples.
-   **External Wisdom**: Use `web_search`, `ref_search_documentation`, `context7`, or `deepwiki` to validate libraries, best practices, and up-to-date APIs.
-   **Synthesis**: Cross-reference sources. Identify gaps. If something is missing, find it before proceeding.

### 2. Context Management
*Curate the information to maximize signal-to-noise ratio.*

-   **Filter & Compress**: Discard irrelevant files. Summarize verbose documentation into key constraints.
-   **State Tracking**: For complex tasks, use `sequentialthinking` to maintain a structured, evolving understanding.

### 3. Strategic Planning & Alignment
*Define the path forward and align with the user.*

-   **Draft Plan**: Create a detailed technical approach derived *strictly* from the assembled context.
-   **Actionable To-Do List**: Break the plan into granular, checkable steps.
-   **Mandatory Confirmation**: Present the Plan and To-Do List to the user. **STOP** and wait for explicit approval.
    -   *If rejected*: Ask the user for specific guidance on how to proceed (e.g., revise the plan, gather different context).

### 4. Execution & Persistence
*Execute the approved plan transparently.*

-   **Execute**: Perform the tasks using established project conventions.
-   **Progress Tracking**: After *each* significant step, inform to the user the updated To-Do List.
-   **Persist**: Store new insights (patterns, decisions, architectural choices) into the Knowledge Graph (`create_entities`) to accelerate future tasks.