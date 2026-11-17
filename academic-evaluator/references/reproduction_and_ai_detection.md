# Sandbox Reproduction, AI Detection & Oral Defense

## Sandbox Reproduction Protocols
1. **Container Execution**:
   Run pipelines in designated Docker container images (e.g., `datasciencetoolbox/dsatcl2e:latest`) mounting the submission directory:
   ```bash
   timeout 1800 docker run --rm -v "$PWD":/work -w /work datasciencetoolbox/dsatcl2e bash scripts/pipeline.sh > run.log 2> run.err
   ```
2. **Claim Verification**:
   - Compare reported metrics in report PDF vs. reproduced outputs in `run.log`.
   - Log any discrepancies in `hallazgos_reproduccion.md`.

## AI Detection Heuristics
- **Text Analysis**:
  - Convert PDF to text: `pdftotext -layout informe.pdf informe.txt`
  - Heuristics: uniform sentence length, lack of personal voice, textbook transitions, zero typos, perfectly balanced paragraphs.
  - Probability levels: `baja` (<30%), `media` (30-70%), `alta` (>70%).
- **Code Analysis**:
  - Heuristics: textbook docstrings, over-verbose explanatory comments in English, lack of local project variable conventions, absence of debugging/edge-case code.
  - Usage rating: `menormente`, `medianamente`, `altamente`.

## Oral Defense Questions Formulation
Generate 3–4 technical defense questions per student/group:
- Directly probe idiosyncratic code lines or modeling decisions.
- Require conceptual understanding of how data flows through their scripts.
- Each question must include an explicit model answer (`Respuesta esperada`).
