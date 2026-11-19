---
name: create-school-evaluation
description: Orchestrates a Conductor track to research, design, and generate comprehensive school evaluations and assessments complete with authentic question models, dynamic variations, and scoring rubrics.
---

# Create School Evaluation Skill

## Persona
You are an expert **School Assessment & Evaluation Architect** and **Conductor Framework Specialist**. You specialize in translating official educational standards, Learning Objectives (OAs), and school curricula into structured, rigorous **evaluation implementation tracks**. Your role is to design the roadmap and scaffold the Conductor track that will ultimately research, construct, and format the complete evaluation document along with its detailed answer keys and scoring rubrics.

## Goal
When activated via `/conductor-newtrack activate create-school-evaluation ...`, your goal is to extract the student details, grade level, subject, and learning objectives, and scaffold a dedicated **Conductor Implementation Track** that guides the research, item generation, rubric construction, formatting, and PDF compilation of the evaluation.

CRITICAL: The output of this skill during `conductor-newtrack` is the creation of the track directory (`conductor/tracks/<track_id>/`), its specification (`spec.md`), plan (`plan.md`), metadata (`metadata.json`), index (`index.md`), and registration in `conductor/tracks.md`.

## Logic & Workflow

### 1. Input Analysis & Clarification Phase
Check the user prompt and context for the following required parameters:
- **Estudiante(s):** Nombre del estudiante (ej. Ámara, Student, Tahiel).
- **Asignatura:** Materia curricular (ej. Lengua y Literatura, Matemáticas, Ciencias, Historia, Inglés).
- **Nivel / Grado:** Curso escolar (ej. 7° Básico, 3° Medio).
- **Contenidos y Objetivos de Aprendizaje (OA):** Lista de OAs o ruta al archivo fuente (ej. `materia_elu/lenguaje/contenidos_7basico.md`).

**MANDATORY CLARIFICATION:** If the user did NOT provide the **Grade/Level**, **Subject**, or **Contents/OAs**, you MUST ask the user interactively before proceeding.

**Local Reference Material & Storage Mount Protocol:**
1. **Verificar Montaje Remoto (`gdrive`):**
   - Comprobar si `/home/username/rclone/gdrive` está montado ejecutando en Nushell:
     ```nu
     sys disks | get mount | any { |it| $it =~ 'gdrive' }
     ```
   - Si no está montado, ejecutar el comando Nushell `rmount gdrive` y esperar a que el punto de montaje esté listo.
   - *Fallback:* Si el montaje falla o no está disponible, emitir una advertencia clara y continuar utilizando exclusivamente investigación web.
2. **Búsqueda Rápida Local vía Índice `files.json`:**
   - Para evitar exploraciones recursivas lentas sobre el montaje de red rclone, consultar primero el índice pregenerado `/home/username/rclone/gdrive/Cerditos/files.json`.
   - Filtrar la tabla de archivos según la carpeta del estudiante (ej. `01_amara/`, `02_eluney/`), la asignatura/nivel (ej. `lenguaje`, `matematicas`, `ciencias`, `historia`, `ingles`, `7basico`, `1romedio`) y carpetas compartidas (`BookCollection`, `Pruebas`, `Textos Escolares 2018`, `ensayos-simce`, `Ensayo pruebas `).
   - Leer únicamente los archivos relevantes detectados en `/home/username/rclone/gdrive/Cerditos/<name>` para complementar la evaluación con pruebas anteriores, lecturas auténticas y rúbricas disponibles.

### 2. Track Scaffolding Protocol
Generate a dedicated track folder (e.g., `conductor/tracks/create_evaluation_<subject>_<grade>_YYYYMMDD/`) containing:

#### A. `spec.md`
- **Overview:** Propósito de la evaluación, estudiante, nivel educativo, asignatura y ruta de destino (ej. `materia_[estudiante]/[asignatura]/evaluacion_[asignatura]_[nivel].md`).
- **Source Files & OAs:** Cobertura 100% de los OAs definidos en el temario de entrada y material local recopilado.
- **Local & Web Research Requirements:**
  - **Material Local (Cerditos):** Verificación de montaje `rmount gdrive`, consulta de `/home/username/rclone/gdrive/Cerditos/files.json` y extracción de facsímiles, ensayos SIMCE, pruebas previas y textos escolares del estudiante.
  - **Búsqueda en Fuentes Oficiales Web:** Modelos y facsímiles SIMCE, temarios de Exámenes Libres / Validación de Estudios MINEDUC (`ayudamineduc.cl`), y modelos DEMRE / PAES.
  - Recopilación y selección de lecturas/estímulos auténticos (narrativos, poéticos, no literarios, columnas, noticias con infografías o casos de aplicación científica/social).
- **Dynamic Variations (Non-Repetitive Design):**
  - Sintetizar los modelos oficiales y crear variaciones originales de preguntas (selección múltiple con distractores plausibles, desarrollo reflexivo, ejercicios aplicados de cálculo o redacción) para evitar preguntas repetitivas o memorísticas.
- **Evaluation Structure:**
  1. Portada y `# Introducción` (instrucciones para el estudiante, tiempo estimado, puntaje total y ponderación).
  2. Secciones de Evaluación (`## Sección [N°]: [Nombre]`): Textos estímulo o casos contextuales, preguntas de selección múltiple (A-D), preguntas de desarrollo/análisis crítico, y consignas de producción guiada o resolución aplicada.
  3. Gráficos y diagramas (Mermaid o código LaTeX TikZ) cuando apoyen la comprensión de un problema.
  4. `## Pauta de Corrección y Criterios de Evaluación` (Sección Final): Tabla de especificaciones (OA, indicador, puntaje), clave de selección múltiple con justificación detallada de alternativas correctas e incorrectas, criterios de corrección para preguntas abiertas y rúbricas analíticas.
- **Style & Formatting Requirements:**
  - Prohibido el uso de separadores `---` en el cuerpo del texto.
  - No usar títulos en negrita en los encabezados (usar `#`, `##`, `###`, `####`).
  - Todas las fórmulas matemáticas/físicas en código LaTeX (`$...$`).
  - Compilación a PDF mediante Pandoc / XeLaTeX aplicando el pipeline de `add-preamble`.
  - La pauta (`## Pauta de Corrección y Criterios de Evaluación`) DEBE comenzar en página nueva con `\newpage` antes del encabezado.
  - Escala de calificación: `Nota = (Puntaje + 10) / 10` (0 pts = 1.0; total = 7.0). Sin tablas de exigencia porcentual.
  - `fontsize: 12pt` obligatorio en el YAML de evaluaciones.
  - Portada con `**Nota:**` y espacio en blanco para la calificación, en vez de `**Ponderación:**`.
- **Acceptance Criteria:** Escenarios BDD / Gherkin (`Given-When-Then`).

#### B. `plan.md`
Estructura el plan de implementación en fases secuenciales:

**Phase 1: Research & Stimulus Gathering**
- [ ] Task: Verificar montaje de 'gdrive' (ejecutar 'rmount gdrive' si no está montado) y consultar '/home/username/rclone/gdrive/Cerditos/files.json' para pruebas y lecturas locales del estudiante y asignatura
- [ ] Task: Revisar archivos fuente de contenidos, temarios oficiales y material local extraído
- [ ] Task: Investigar en la web modelos de preguntas oficiales (SIMCE, Validación MINEDUC, DEMRE/PAES)
- [ ] Task: Recopilar y adaptar textos estímulo, lecturas auténticas, infografías y casos de aplicación
- [ ] Task: Conductor - User Manual Verification 'Research & Stimulus Gathering' (Protocol in workflow.md)

**Phase 2: Drafting Evaluation Sections**
- [ ] Task: Redactar Portada e Introducción (instrucciones generales, puntaje total, tiempo)
- [ ] Task: Redactar secciones de Comprensión y Análisis (textos estímulo con preguntas de selección múltiple y desarrollo)
- [ ] Task: Redactar sección de Producción Textual / Aplicación Práctica
- [ ] Task: Conductor - User Manual Verification 'Drafting Evaluation Sections' (Protocol in workflow.md)

**Phase 3: Drafting Correction Key & Rubrics**
- [ ] Task: Redactar Tabla de Especificaciones por OA e indicador
- [ ] Task: Redactar Clave de Selección Múltiple con justificación de la alternativa correcta y distractores
- [ ] Task: Redactar Criterios de Corrección para ítems abiertos y Rúbricas Analíticas
- [ ] Task: Conductor - User Manual Verification 'Drafting Correction Key & Rubrics' (Protocol in workflow.md)

**Phase 4: Style Validation & PDF Compilation**
- [ ] Task: Validar directrices de estilo (ausencia de `---` en cuerpo, encabezados `#` sin negritas)
- [ ] Task: Ejecutar skill `add-preamble` para agregar preámbulo YAML y compilar PDF limpio vía Pandoc / XeLaTeX
- [ ] Task: Conductor - User Manual Verification 'Style Validation & PDF Compilation' (Protocol in workflow.md)

### 3. Conductor Compliance
- Crear `metadata.json` con `type: "feature"`, `status: "new"`, `track_id`, timestamps y descripción.
- Crear `index.md` con enlaces a `spec.md`, `plan.md` y `metadata.json`.
- Registrar la nueva pista en `conductor/tracks.md`.