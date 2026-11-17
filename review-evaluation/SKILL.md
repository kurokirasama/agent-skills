---
name: review-evaluation
description: "Automates the evaluation of student work submissions from Gmail. Supports group-based (Google Sheets roster + per-group reports) and individual evaluation modes. Handles attachment download, code compilation/execution with auto language detection, AI-generation detection (text + code), grading (1.0-7.0), and oral exam question generation. Auto-activates on keywords like evaluar trabajos, corregir entregas, revisar evaluaciones, calificar estudiantes, review-evaluation. Must ask user for output_dir, input_dir, spreadsheet_url (grupal only), and mode."
---

# Review Evaluation Skill

Orchestrates end-to-end student work evaluation from Gmail submissions. Two modes:
**VERSION GRUPAL** (group-based via Google Sheets roster) and **VERSION INDIVIDUAL** (per-student from emails).

## Nushell Setup

- Activate the `nushell-expert` skill before any Nushell command.
- Load utilities: `use skills/review-evaluation/mod.nu *`

## Universal Workflow

Determine mode from user input. Ask the user for:
- `output_dir`: where to store results
- `input_dir`: directory with assignment instructions (e.g., enunciados)
- `spreadsheet_url`: Google Sheets URL (grupal only)

### Modes

| Mode | Trigger Keywords | Spreadsheet | Output Structure |
|------|-----------------|-------------|------------------|
| GRUPAL | grupal, grupo, grupos, team, equipo | Required | `grupo_XX/` per group |
| INDIVIDUAL | individual, alumno, estudiante, personal | Not needed | `nombre_alumno/` per student |

## VERSION GRUPAL

### 1. Spreadsheet → grupos.json
- Read spreadsheet via Google Sheets MCP (`getText` or `getRange`).
- Parse rows: infer groups from the sheet structure.
- Create `<output_dir>/grupos.json`:
  ```json
  [{"grupo": 1, "integrantes": ["Name One", "Name Two"], "analizado": false, "entregado": false}]
  ```

### 2. Email Download
- Search Gmail with label `work-evaluaciones`.
- For each email: extract sender name, match to group in `grupos.json`.
- Download attachments to `<output_dir>/grupo_XX/`.
- Set `entregado: true` in `grupos.json` for matched groups.
- After successful download, remove `work-evaluaciones` label from the email.

### 3. Decompress Archives
- For each group folder: detect archives (`.zip`, `.rar`, `.7z`, `.tar.gz`).
- Extract in-place using appropriate tool (`unzip`, `unrar`, `7z`, `tar`).
- Handle nested archives recursively.

### 4. Per-Group Evaluation Pipeline
For each group where `entregado == true` and `analizado == false`:

**(a) Problem Assignment:** Read the submitted report (PDF/MD). Determine which
LaTeX problem file (`TG_202601_{G1,G2,G3}.tex`) was assigned to this group.

**(b) Understand Expected Work:** Read the assigned `.tex` file thoroughly.
Identify: problem description, required deliverables, expected output format.

**(c) Analyze Submission:** Carefully read the report and all code files.
Note: approach, correctness, completeness, clarity, methodology.

**(d) Compile & Execute Code:**
- Auto-detect language from file extensions (`.py` → Python, `.R` → R, `.m` → MATLAB/Octave, `.ipynb` → Jupyter).
- Compile if needed, execute in a sandboxed subprocess.
- Capture stdout, stderr, exit code, timeout.
- Determine if code produces expected output per the problem requirements.

**(e) Write Report:** Create `<output_dir>/grupo_XX/reporte.md` in Spanish:
```markdown
# Reporte de Evaluación — Grupo XX

## Fortalezas
- ...

## Debilidades
- ...

## Nota Final: X.X

## Detección de IA en Texto
- Probabilidad: baja/media/alta
- Uso de IA: menormente/medianamente/altamente
- Snippets sospechosos: ...

## Detección de IA en Código
- Probabilidad: baja/media/alta
- Uso de IA: menormente/medianamente/altamente
- Observaciones: ...

## Preguntas para Presentación Oral
1. **Pregunta técnica 1?**
   - Respuesta esperada: ...
2. ...
```

**(f) Grade Suggestion:** After re-reading the report, code, and `reporte.md`,
suggest a single grade between 1.0 and 7.0. Justify with specific evidence.

**(g) AI Text Detection:**
- Convert PDF to text: `pdftotext <file>.pdf <output_dir>/grupo_XX/file.txt`
- Run: `ai analyze_ai_generated_text file.txt`
- Parse response for likelihood (baja/media/alta).
- Extract most probable AI-generated snippets.
- Include in reporte.md.

**(h) AI Code Detection:**
- Analyze code for AI patterns: uniform comments, over-explained variable names,
  consistent formatting, generic error handling, lack of personal style.
- Assess usage level: menormente/medianamente/altamente.
- Include in reporte.md.

**(i) Oral Exam Questions:**
Generate 3-4 technical questions that:
- Target specific parts of the submitted code/report.
- Require understanding of what the code actually does.
- Cannot be answered by someone who only used AI without understanding.
- Each question includes the expected correct answer.

**(j) State Update:** Set `analizado: true` in `grupos.json` for the group.
Save `grupos.json` after each group to support resumability.

## VERSION INDIVIDUAL

### 1. Email Download
- Search Gmail with label `work-evaluaciones`.
- For each email: extract sender name, create `<output_dir>/Nombre_Apellido/`.
- Download attachments to that directory.
- After successful download, remove `work-evaluaciones` label.

### 2. Decompress Archives
Same as GRUPAL step 3, but per student folder.

### 3. Per-Student Evaluation Pipeline
For each student folder:

**(a) Dataset Identification:** Read the submitted report. Cross-reference with
the evaluation instructions file to determine which dataset was used.

**(b) Understand Expected Work:** Read the evaluation instructions `.md` file.
Identify expected analyses, methods, and output format.

**(c)-(i) Same as GRUPAL steps (c)-(i), adapted for individual evaluation.**

## Code Execution Guidelines

- Always sandbox: use subprocess with timeout (default 60s).
- For Python: `python3 <file>.py`
- For R: `Rscript <file>.R`
- For MATLAB/Octave: `octave --no-gui <file>.m`
- For Jupyter: `jupyter nbconvert --to notebook --execute <file>.ipynb`
- Report: exit code, stdout (last 200 lines), stderr, timeout status.

## AI Detection Guidelines

### Text (pdf → text → analysis)
- Use `pdftotext -layout <pdf>` for best results.
- The `ai analyze_ai_generated_text` command outputs a structured analysis.
- Look for: uniform sentence structure, lack of personal voice, generic transitions,
  perfectly balanced paragraphs, absence of typos or informal language.

### Code (heuristic analysis)
Indicators of AI-generated code:
1. Perfect comments in non-native English with textbook phrasing.
2. Over-explained variable names (`the_list_of_filtered_results`).
3. Uniform indentation and spacing (no human inconsistency).
4. Generic error messages copied from documentation.
5. Missing edge-case handling that a human would naturally add.
6. Identical coding style across different students in the same group.

## Resumability

- GRUPAL: check `analizado` field in `grupos.json` to skip completed groups.
- INDIVIDUAL: check for existence of `reporte.md` in student folders.
- Save state after each evaluation to support interruption recovery.

## External Dependencies

- `pdftotext` (poppler-utils)
- `ai analyze_ai_generated_text` nushell command
- Google Workspace MCP server (Gmail + Sheets)
- `unzip`, `unrar`, `7z`, `tar` (archive tools)
- Python 3, R, Octave (runtimes — detect available ones)
