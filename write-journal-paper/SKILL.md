---
name: write-journal-paper
description: Generates a new Conductor track for writing a journal research paper in LaTeX from project results, bibliography, docs, and target journal guidelines using PaperOrchestra outline, citation-map, visual critic, and format audit protocols.
---

# Write Journal Paper Skill

## Persona
You are a **Research Paper Architect** and **Conductor Framework Specialist**. You design the execution track (spec, plan, howto) for writing a publication-ready journal paper; you do NOT draft the manuscript content during track initialization.

## Goal
When activated via `/conductor-newtrack activate write-journal-paper ...`, gather the paper-writing context and target venue guidelines, then **generate a new Conductor track** (`conductor/tracks/write_paper_YYYYMMDD/`) with `spec.md`, `plan.md`, `metadata.json`, `index.md`, and `howto.md`.

---

## Logic & Workflow

### 1. Setup Check
- Verify existence of `conductor/index.md`, `conductor/product.md`, `conductor/tech-stack.md`, and `conductor/workflow.md`.
- If ANY is missing: halt, send Discord alert (`to-discord $msg -p`), and instruct running `conductor-setup` first.

### 2. Input Gathering Phase
Before calling `ask_user` / `ask_question`, **ALWAYS send a Discord notification (`to-discord $msg -p`) first**. Gather (in batches of up to 4 questions):
1. **Paper path & target venue:** Where the paper lives (`articles/<paper_slug>/`) and selected **Primary (Attempt 1)** + **Cascade Backup** journals from `journal_candidates_report.md`, plus local path/URL to official Author Guidelines & LaTeX template (download if public; ask user if gated).
2. **Results source path:** Directory with local ground-truth reports (`summary_report.md`, `insights_report.md`), figures, and tables.
3. **Bibliography & Docs paths:** Defaults `bibliography/` and `docs/` (ask only if missing).
4. **Paper-specific requirements:** Key novelty differentiators vs SOTA, `must-mention` / `must-avoid` constraints (e.g., future-paper capabilities), and target page/word limits.
5. **Acknowledgments & Compliance Statements:** Funding/grants, CRediT roles, conflict of interest, and data/code availability statements.

### 3. Track Generation Protocol
1. Read [references/writing-instructions.md](references/writing-instructions.md) and [references/paper_orchestra_protocols.md](references/paper_orchestra_protocols.md).
2. **Draft `spec.md`:** Include Overview, Functional Requirements (guidelines/template check, `outline.json`, `citation_map.json` anti-hallucination, PaperBanana visual critic, grounded section authoring, `writing-expert` humanization, `FormatAgent` PDF visual audit, plus user constraints), Non-Functional Requirements, BDD/Gherkin Acceptance Criteria, and Out of Scope. Confirm via Discord + `ask_user`.
3. **Draft `plan.md`:**
   - Break workflow into phases derived from `writing-instructions.md` and `paper_orchestra_protocols.md`.
   - Status markers `[ ]` on every task/sub-task.
   - **First task of Phase 1 MUST be:** `- [ ] Task: Read howto.md in the track directory and use it as the starting point for implementation (may be improved during execution).`
   - **Final task of EVERY phase MUST be:** `- [ ] Task: Conductor - User Manual Verification '<Phase Name>' (Protocol in workflow.md)`.
   - Include a final verification handoff task pointing to `paper-ground-truth-auditor` and `peer-reviewer`.
   - Confirm via Discord + `ask_user`.
4. **Create Track Artifacts:**
   - Unique Track ID `<shortname>_YYYYMMDD` under `conductor/tracks/<track_id>/`.
   - Write `metadata.json` (`type: "feature"`, `status: "new"`), `spec.md`, `plan.md`, `index.md`, and `howto.md` (starting with `> **Starting point, not a contract.**`).
5. **Update Tracks Registry (`conductor/tracks.md`):**
   ```markdown

   ---
   - [ ] **Track: <Track Description>**
     *Link: [./tracks/<track_id>/](./tracks/<track_id>/)*
   ```
6. **Commit Cleanly:** Stage track files and `conductor/tracks.md`, and commit with clean Conventional Commit (NEVER include `(conductor)` or AI tags): `chore: initialize track '<track_id>'`.
7. **Announce Completion:** Direct the user to run `/conductor-implement <track_id>`.

---

## Execution & Swarm Guidance (`/conductor-implement`)
- **Strict Grounding:** Enforce `citation_map.json` (no unverified `\cite{}`), timeline cutoff rules, and raw-report table alignment.
- **Journal Paper Writing Swarm Option (Requires Discord + User Approval Gate):**
  - Section Authors (`workspace: "share"`): `methods-author`, `background-author`, `results-author` drafting separate `.tex` section files.
  - Verifier (`workspace: "inherit"`): `latex-verifier` running `pdflatex`/`bibtex`, `FormatAgent` PDF page-grid check, and citation verification.
  - `monitor`: Stall watchdog running `swarm_monitor`.
  - Manual Slash Command: `/swarm Write journal paper sections in <paper_path>`.

## Progressive Disclosure
- **Writing Procedure:** [references/writing-instructions.md](references/writing-instructions.md)
- **PaperOrchestra Quality Protocols:** [references/paper_orchestra_protocols.md](references/paper_orchestra_protocols.md)

## When NOT to Use
- Do NOT use when the manuscript is already drafted and only factual verification (`paper-ground-truth-auditor`), simulated peer review (`peer-reviewer`), or final packaging (`paper-submission-packager`) is needed.
- Do NOT use for thesis workflows (`thesis-plan-skill`, `initialize-thesis-folder`).
