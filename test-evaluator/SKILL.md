---
name: test-evaluator
description: Automates the evaluation of student programming tests across any language and course. Organizes submissions, compiles/runs solutions, calculates integer grades (1-7), and sends personalized, seamlessly integrated feedback via Gmail.
---

# Universal Test Evaluator

This skill orchestrates the end-to-end workflow for grading student programming tests, designed to be agnostic to the specific course and programming language.

## Core Workflow

### 0. Reference Solution Generation
- **Problem Analysis**: Read and analyze the test problem(s) description provided by the user.
- **Master Implementation**: Generate a `solucion_maestra` (with appropriate extension like `.c`, `.py`, `.r`) that solves the problem perfectly.
- **Constraints Check**: Ensure the solution only uses concepts and libraries explicitly allowed/seen in the course material provided (e.g., checking against a `CEI.md` file).
- **Verification**: Compile and execute the master solution to ensure it works correctly before starting the student evaluations.

### 1. Retrieval and Organization
- **Email Search**: Search Gmail for messages with a user-specified label (default: "work-evaluaciones").
- **Directory Structure**: For each unique student, create a folder named "Apellido_Nombre" in the target workspace.
- **Metadata**: Inside each folder, create an "evaluacion.md" containing:
    - Student's Full Name
    - Gmail Message/Thread ID (for replying)
    - Placeholders for "Nota" and "Feedback".
- **Source Extraction**: Download attachments or extract code from the email body.
    - **Agnostic Conversion**: Convert non-source files (e.g., "DOCX", "PDF") to the target language source extension using appropriate extraction tools.

### 2. Automated Evaluation
- **Reference Solution**: Analyze the provided master solution file for the current test.
- **Verification Loop**: Attempt to compile (if applicable) or execute each submission.
    - **Rule**: If a program does NOT compile or has a critical runtime error upon start, the maximum grade is **4**.
- **Logic Validation**: Run tests or manual checks and compare student output/code against the reference solution and requirements.
- **Grading**: Assign an **integer** grade from 1 to 7. Decimal grades are prohibited.
- **Documentation**: Update "evaluacion.md" with the grade and qualitative feedback bullets.

### 3. Reporting & Feedback
- **Consolidation**: Generate a CSV report with columns: "apellido, nombre, <test_name>".
- **Email Dispatch**: Reply to the student's email thread using the following protocol:
    - **Drafting**: Use the provided template as a base.
    - **Rewrite Protocol (MANDATORY)**: Do NOT perform a simple copy-paste of feedback bullets. Integrate the feedback into a natural, cohesive, and professional body.
    - **Quality Gate**: If the grade is 7, omit negative feedback entirely.
    - **Tone**: Professional, encouraging, and clear.

## Email Feedback Integration: Bad vs. Good

### Example 1: Perfect Score (Nota 7)

**❌ BAD (Fragmented/Redundant):**
"Hola Kevin, te informo que has obtenido un 7 en el test 1 del curso. Lo que hiciste bien fue Excelente trabajo. El programa está bien estructurado... Lo que falto o estuvo incorrecto fue Nada, implementación impecable. Saludos."

**✅ GOOD (Seamless/Fluid):**
"¡Excelente trabajo, Kevin! Te informo que has obtenido un 7 en el test 1. Tu solución está impecablemente estructurada; el cálculo del promedio es preciso y el filtrado en el segundo arreglo funciona a la perfección. Demostraste un dominio total de los conceptos evaluados y la salida de datos es sumamente clara e intuitiva. ¡Sigue así!"

### Example 2: Partial Score (Nota 6)

**❌ BAD (Template-forced):**
"Hola Matías, te informo que has obtenido un 6 en el test 1 del curso. Lo que hiciste bien fue Lograste implementar la lógica de suma... Lo que falto o estuvo incorrecto fue Ten cuidado con los índices... Saludos."

**✅ GOOD (Integrated/Professional):**
"Hola Matías, te informo que tu nota en el test 1 es un 6. En general, lograste implementar correctamente la lógica de suma, promedio y filtrado solicitada, y tu programa compila y corre sin problemas. Sin embargo, debes tener especial cuidado con los índices de los arreglos en C, ya que al comenzar en 0, tu código intentaba acceder a la posición 12, lo cual podría causar errores graves de memoria. Además, recuerda inicializar siempre los arreglos de resultados según lo pide el enunciado."

## Quality Gates
- [ ] Was the master solution generated and verified against problem constraints?
- [ ] Are grades integers only (1-7)?
- [ ] Did non-working code get a 4?
- [ ] Is the email feedback blended naturally (conversational tone)?
- [ ] Was a Discord notification sent upon completion?