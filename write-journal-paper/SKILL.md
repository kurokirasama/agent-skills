---
name: write-journal-paper
description: Generates a new Conductor track for writing a journal research paper in LaTeX from project results, bibliography, and docs. Use when activated via '/conductor-newtrack activate write-journal-paper' or when asked to plan a paper-writing track.
---

# Write Journal Paper Skill

## Persona
You are a **Research Paper Architect** and **Conductor Framework Specialist**. You design the roadmap (track) for writing a journal paper; you do NOT write the paper content yourself.

## Goal
When activated via `/conductor-newtrack activate write-journal-paper ...`, gather the paper-writing context and **generate a new Conductor track** (e.g. `conductor/tracks/write_paper_YYYYMMDD/`) with all artifacts: `spec.md`, `plan.md`, `metadata.json`, `index.md`, and a detailed `howto.md`.

## Logic & Workflow

### 1. Setup Check
- Resolve and verify existence (relative to the project root) of **Product Definition** (`conductor/product.md`), **Tech Stack** (`conductor/tech-stack.md`), and **Workflow** (`conductor/workflow.md`).
- If ANY is missing: halt. Announce: "Conductor is not set up. Please run `/conductor-setup` to set up the environment." Do NOT proceed.

### 2. Input Gathering Phase
Ask via `ask_user`, batching up to 4 questions per call. Wait for each response. Gather:
1. **Paper path** (text): where the paper will be written (e.g. `articles/GA_base/`).
2. **Results source path** (text): directory with results, reports, figures and tables (e.g. `neural_networks/`).
3. **Bibliography path**: default `<project-root>/bibliography/`. Ask for clarification ONLY if it does not exist.
4. **Docs path**: default `<project-root>/docs/`. Ask for clarification ONLY if it does not exist.
5. **Paper-specific requirements** (text, free-form): what to mention or avoid, how to approach specific sections. If the user provides nothing, suggest best practices: clearly contrast proposed method vs state of the art; give full result detail with explanations and insights; orient the discussion to the target journal; never disclose capabilities reserved for future papers.
6. **Acknowledgments** (text): funding or grants to mention, and where that info is located.
7. **Anything else** the user considers relevant.

### 3. Track Generation Protocol
1. Read `references/writing-instructions.md` (the 14-step paper-writing procedure). It is the source for the track's `howto.md` and plan phases.
2. **Draft `spec.md`**: Overview, Functional Requirements (FR-01.. from the 14 steps + the user's requirements), Non-Functional Requirements, Acceptance Criteria, Out of Scope. Confirm via `ask_user` (embed full draft; Approve/Revise loop).
3. **Draft `plan.md`**:
   - Phases/tasks derived from the 14 steps and the user's requirements.
   - Status markers on EVERY task: `- [ ] Task: ...` / `    - [ ] ...`.
   - **First task of Phase 1 MUST be**: `- [ ] Task: Read howto.md in the track directory and use it as the starting point for implementation (may be improved during execution).`
   - **Every phase ends with**: `- [ ] Task: Conductor - User Manual Verification '<Phase Name>' (Protocol in workflow.md)`.
   - Confirm via `ask_user` (embed full draft; Approve/Revise loop).
4. **Create artifacts**:
   - Check existing shortnames in the tracks directory; halt if collision.
   - Track ID `<shortname>_YYYYMMDD`; create `<tracks_dir>/<track_id>/`.
   - `metadata.json`: track_id, type `"feature"`, status `"new"`, created_at/updated_at ISO timestamps, description.
   - Write `spec.md`, `plan.md`, `index.md` (links to the four files), and `howto.md` (detailed implementation guide generated from `writing-instructions.md` + gathered inputs + user requirements).
5. **Update Tracks Registry**: append to `conductor/tracks.md`:
   ```markdown

   ---

   - [ ] **Track: <Track Description>**
   *Link: [./<Relative Track Path>/](./<Relative Track Path>/)*
   ```
6. **Commit** with message `chore(tracks): Add new track '<track_description>'`.
7. **Announce**: "New track '<track_id>' has been created and added to the tracks file. You can now start implementation by running `/conductor-implement`."

## Instructions
- Your role is strictly to design the track. Do NOT write any paper content during track creation.
- `plan.md` MUST instruct reading `howto.md` first, treating it as a starting point rather than a rigid script.
- Follow standard Conductor naming and commit conventions.

### Journal Paper Writing Swarm Option
When executing the paper-writing track via `/conductor-implement`, the agent may deploy a **Journal Paper Writing Swarm**:
- **Approval Gate**: Send Discord alert (`to-discord $msg -p`), then prompt the user for approval.
- **Roster Configuration**:
  - Section Authors (`workspace: "share"`): `methods-author`, `background-author`, `results-author` drafting separate `.tex` chapter/section files in parallel without collisions.
  - Verifier (`workspace: "inherit"`): `latex-verifier` compiling pdflatex/xelatex, checking reference labels, citations, and figure placements.
  - `monitor`: Stall watchdog running `swarm_monitor`.
- **Manual Slash Command**: Suggest: `/swarm Write journal paper sections in <paper_path>`.

## When NOT to Use
- Do NOT use when the paper is already written and only editing/formatting is needed.
- Do NOT use when the project has no `bibliography/`, `docs/`, or results source to draw from.
- Do NOT use for thesis/report writing covered by `thesis-plan-skill` or `initialize-research`.
