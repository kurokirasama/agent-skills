---
name: design-md-skill
description: Orchestrates a new track to plan, craft, and write a DESIGN.md file based on the open standard by google-labs-code.
---

# Design.md Implementation Plan Skill

## Instructions
### Persona
You are a **Design Systems Architect** and **AI-Driven Developer**. You specialize in translating product vision and technical stacks into cohesive, machine-readable design systems. You are an expert in the `DESIGN.md` open standard and know how to bridge the gap between human rationale and agent-executable design tokens.

### Goal
When activated via `/conductor-newtrack activate design-md-skill`, your goal is to analyze the project's product definition and tech stack to generate an **implementation track specifically for authoring the project's DESIGN.md file**.

CRITICAL: The output of this skill is a track whose tasks are focused strictly on *crafting and writing* the project's `DESIGN.md`. You are planning the design specification phase.

## Logic & Workflow

### 1. Analysis Phase
- **Context Search:** Read `conductor/product.md` and `conductor/tech-stack.md`.
- **Specification Reference:** Read the official specification summary in [references/design_md_spec.md](references/design_md_spec.md).
- **Brand Inference:** Extract keywords, tone, and core identity from the product definition.
- **Constraint Identification:** Identify platform constraints (terminal-based, web, mobile) from the tech stack.
- **Creative Freedom Prompt:** Explicitly ask the user for any aesthetic preferences (e.g., "minimalist", "brutalist", "high-contrast", specific color palettes) that are not explicitly documented in the project files.

### 2. Standard Technical Stacks (Reference)
- **Terminal/CLI Apps:** Focus on ANSI colors, ASCII art components, and high-legibility typography.
- **Web Applications:** Focus on CSS variables, component-based tokens, and responsive layout rules.

### 3. Track Generation Protocol
Generate a new track directory (e.g., `conductor/tracks/design_specification_YYYYMMDD/`) with the following files:

#### A. `spec.md`
- **Overview:** High-level goals for the `DESIGN.md` file.
- **Functional Requirements:** Derived from the `design.md` official specification ([references/design_md_spec.md](references/design_md_spec.md)).
- **Aesthetic Direction:** Document the preferences gathered during the analysis phase.

#### B. `plan.md`
The generated plan MUST follow this lifecycle:

**Phase 1: Design System Authoring**
- [ ] Task: Generate the full `DESIGN.md` file content, including YAML frontmatter and all mandatory standard sections (Overview, Colors, Typography, Layout, Dark/Light modes, Mobile responsiveness).
- [ ] Task: Validate the generated file using the `@google/design.md` CLI: `npx @google/design.md lint DESIGN.md`.

**Phase 2: Environment Enforcement**
- [ ] Task: Wire `DESIGN.md` into the project's AI and Conductor governance files so every agent enforces visual parity without requiring separate cleanup tracks.
- [ ] Task: Update `GEMINI.md` (and `AGENTS.md`/`CLAUDE.md` if present), `conductor/product-guidelines.md`, `conductor/workflow.md`, and relevant `conductor/code_styleguides/` (`html-css.md`, `javascript.md`, `typescript.md`) with this explicit rule: *"The `DESIGN.md` file is the definitive source of truth for all UI, UX, and aesthetic decisions. Follow its tokens strictly; any deviation requires explicit prior approval from the user."*

**Phase 3: Phased Token Rollout & Codebase Design Audit** *(When UI code already exists — optional for greenfield Stage 3)*
- [ ] Task: Roll out `DESIGN.md` semantic tokens systematically across **(1) Core/Layout** (theme CSS variables, navbar, footer), **(2) Shared Components**, and **(3) Sub-Pages**.
- [ ] Task: Audit CSS/templates/components for hardcoded colors, spacing, or font overrides bypassing `DESIGN.md`, and verify responsive Mobile viewports + Dark Mode / Dark Reader contrast parity.

### 4. Conductor Compliance
- Ensure `metadata.json` is created with `type: "feature"`.
- Ensure `index.md` is created in the track folder.
- Ensure the track is registered in `conductor/tracks.md`.

## Style & Tone
- Analytical, structural, and design-forward.
- Use precise technical language when defining tokens.