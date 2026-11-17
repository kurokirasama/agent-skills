---
name: academic-evaluator
description: "Multi-modal academic evaluation orchestrator for university courses across oral presentations, written reports, and practical code repositories. Handles Canvas SpeedGrader compact text rubrics, Docker sandbox reproduction, claim verification, AI detection, TA reconciliation, and writing-expert draft humanization. Auto-activates on 'evaluar certamen', 'evaluar solemne', 'evaluar informe', 'evaluar presentacion', 'revisar evaluacion', 'academic-evaluator'."
---

# Academic Evaluator (`academic-evaluator`)

## Overview
`academic-evaluator` standardizes and automates the academic grading and feedback lifecycle for university courses. It synthesizes multi-modal evaluation protocols across three dedicated modes:

- **Mode A (`oral`)**: Oral presentations, slide decks (.pdf/.pptx), and segmented lecture audio transcripts.
- **Mode B (`written`)**: Written reports, essays, and mini-projects from LMS bulk ZIPs or emails, producing Canvas SpeedGrader-compliant text rubrics and humanized drafts.
- **Mode C (`practical`)**: Code repositories (GitHub), sandboxed container reproduction, claim verification, AI text/code heuristic analysis, oral defense questions, and co-grader reconciliation.

### Academic Evaluation Swarm Option
For batch student evaluations ($\ge 3$ submissions) or complex multi-modal submissions (code tests + report grading):
- **Approval Gate**: Send Discord alert (`to-discord $msg -p`), then prompt user:
  > "Found <N> submissions. Would you like to spawn an Academic Evaluation Swarm to grade and run tests in parallel?"
- **Roster Configuration (`workspace: "inherit"`)**:
  - `sandbox-runner`: Executes code in Docker/local test environment and records test pass rates and errors.
  - `rubric-grader`: Compares student report and test outputs against the Canvas SpeedGrader rubric criteria.
  - `feedback-polisher`: Adopts `writing-expert` standards to humanize and synthesize student feedback drafts into Spanish.
  - `monitor`: Stall watchdog running `swarm_monitor`.
- **Manual Slash Command**: Suggest: `/swarm Evaluate submissions in <folder> using rubric <rubric.md>`.

---

## Quick Reference & Helper Module
Before running evaluation pipelines in Nushell, activate `nushell-expert` and import the companion helpers:
```nu
use skills/academic-evaluator/mod.nu *
```
Helper commands:
- `format-speedgrader-item`: Formats a single rubric criterion line into compact bullet format.
- `format-speedgrader-rubric`: Formats an entire rubric evaluation into plain text for Canvas SpeedGrader.
- `calculate-final-grade`: Computes standard Chilean scale (1.0–7.0) grades with custom thresholds.
- `build-submission-manifest`: Builds `_manifest.json` from student submissions and repository metadata.
- `reconcile-ta-evaluations`: Compares professor vs. teaching assistant evaluations and flags deltas > 0.5.
- `segment-transcript-boundaries`: Splits session audio transcripts by group transition delimiters.

---

## Mode A: Oral Presentations (`oral`)

Use when evaluating student presentation sessions (slides + oral delivery).

### 1. Ingestion & Roster Resolution
1. Search Gmail (`work/Evaluaciones`, `WORK/Evaluaciones`) or read a designated local folder.
2. Match student senders against the course roster (`Solemne1.csv` or `students.json`) using email/`login_id`.
3. Download presentation slides (.pdf, .pptx) to `presentaciones/<dataset_slug>/` or `_tmp_descargas/`.

### 2. Transcript Segmentation
1. Load session transcript (`transcript.txt`).
2. Identify transition delimiters ("Siguiente grupo", "próximo grupo", dataset topic keywords).
3. Extract each group's section into `transcript_grupo.txt` inside their group folder.
4. Cross-reference slide titles and professor session notes to verify group membership.

### 3. Rubric & Feed-Forward Scoring
1. Evaluate presentation slides and transcript against official presentation rubrics.
2. Generate `rubrica_presentacion.csv` with criterion scores and evidence.
3. Generate `feedback.md` specifically oriented as **feed-forward**: highlight recommendations to guide the students' upcoming written report.

---

## Mode B: Written Reports (`written`)

Use when evaluating formal written project reports or assignments.

### 1. Extraction & Routing
1. Extract bulk LMS ZIP archives (`submissions_<course>.zip`) or isolated email attachments into temporary staging folders (`_tmp_informes/`).
2. Map submissions to student groups according to the course roster.
3. Move reports and annexes to `<course_dir>/informes/<dataset_slug>/`.
4. Audit deliverables against expected groups; flag missing submissions.
5. Clean up temporary staging folders.

### 2. Rubric Evaluation & SpeedGrader Plain Text Formatting
1. Evaluate reports against criteria in official rubrics (`import_rubric_*.csv`).
2. Generate `rubrica_informe.csv` with awarded points and detailed justifications.
3. **Canvas SpeedGrader Format (CRITICAL)**: Because Canvas SpeedGrader comment boxes do not render Markdown tables or HTML tags, format rubric feedback in compact plain text:
   ```text
   • Criterio 1 (Título): Pts/Max (Nivel) | Justificación breve y específica.
   • Criterio 2 (Título): Pts/Max (Nivel) | Justificación breve y específica.

   Comentarios Generales:
   Resumen cualitativo de la entrega.
   ```
4. Use `format-speedgrader-rubric` to generate this block automatically.

### 3. Draft Generation & Humanization
1. Generate `feedback.md` with technical evaluations and formulas.
2. Generate `draft.md` integrating the SpeedGrader plain text block.
3. Pass `draft.md` through the `writing-expert` skill/agent to establish a warm, encouraging, respectful, and pedagogical first-person tone ("He revisado su informe...", "Les sugiero profundizar...").
4. **Strict No-Dispatch Mandate**: Drafts remain local files. Never send automatic emails to students. The professor copies drafts manually into the university LMS.

---

## Mode C: Practical Code Repositories (`practical`)

Use when evaluating programming projects, certámenes, and computational pipelines delivered via Git/GitHub.

### 1. Submission Manifest & Clones
1. Retrieve repo URLs from Gmail (`work/Evaluaciones`) or student rosters.
2. Clone each repository into an untracked scratch folder (e.g., `_tmp_c1_repos/`).
3. Record commit SHAs and build `_manifest.json`:
   ```json
   [{"student": "...", "version": "v1", "dataset": "...", "repo": "...", "commit": "...", "cloned_at": "..."}]
   ```

### 2. Sandbox Container Reproduction
1. Execute pipelines inside an isolated container (e.g., `datasciencetoolbox/dsatcl2e`) or sandboxed virtual environment with timeout (default 30 min):
   ```bash
   docker run --rm -v "$PWD":/work -w /work datasciencetoolbox/dsatcl2e bash scripts/pipeline.sh
   ```
2. Capture stdout, stderr, and exit codes.
3. Audit report claims (row counts, distributions, metrics R²/MAE, plots) against actual execution outputs.
4. Log discrepancies in `hallazgos_reproduccion.md`. Without verified reproduction evidence, claims are marked unconfirmed.

### 3. AI Detection & Oral Defense Questions
1. **AI Text Detection**: Heuristic analysis of report text (uniform syntax, absence of personal voice, textbook phrasing). Rate likelihood as baja, media, or alta.
2. **AI Code Detection**: Heuristic analysis of code (generic comments, over-verbose variables, lack of human idiosyncrasy, absence of edge-case handling). Rate usage as menormente, medianamente, or altamente.
3. **Oral Defense Questions**: Formulate 3–4 targeted questions probing specific implementation choices in their code with expected answers.

### 4. Co-Grader / Teaching Assistant Reconciliation
1. Ingest co-grader / teaching assistant evaluations.
2. Compare criterion and final scores using `reconcile-ta-evaluations`.
3. Flag any student where `|prof_score - ta_score| > 0.5`.
4. Generate `comparacion_reconciliacion.csv` with deltas and proposed consensus grades.
5. **Approval Gate**: Halt and await explicit professor approval before recording grades.

### 5. Grade Registry Update
1. Once approved, write final grades (`nota = (puntaje + 10) / 10` or course formula) into the course registry (`students.json` or roster CSV).
2. Clean up scratch directories and remove evaluation email labels.

---

## Operational Guardrails
1. **Auditable Evidence**: Every assigned score must cite concrete evidence (file paths, line numbers, command output, or transcript quotes).
2. **Zero Pollution**: Never commit student repositories, cloned code, or heavy temporary datasets to the project repository.
3. **Humanization Mandate**: Outward-facing feedback drafts must be humanized with `writing-expert`.
4. **Safety & Privacy**: Never send automated emails to students. Never overwrite official grade records without explicit professor confirmation.
