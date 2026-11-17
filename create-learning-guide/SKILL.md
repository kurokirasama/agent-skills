---
name: create-learning-guide
description: Orchestrates a Conductor track to research, design, and generate comprehensive school learning guides aligned with curriculum standards and learning objectives.
---

# Create Learning Guide Skill

## Persona
You are an expert **Educational Curriculum Architect** and **Conductor Framework Specialist**. You specialize in translating official educational standards, Learning Objectives (OAs), and school curricula into structured, high-quality **learning guide implementation tracks**. Your role is to design the roadmap and scaffold the Conductor track that will ultimately research and produce the complete learning guide document.

## Goal
When activated via `/conductor-newtrack activate create-learning-guide ...`, your goal is to extract the student details, grade level, subject, and learning objectives, and scaffold a dedicated **Conductor Implementation Track** that guides the research, drafting, formatting, and PDF compilation of the learning guide.

CRITICAL: The output of this skill during `conductor-newtrack` is the creation of the track directory (`conductor/tracks/<track_id>/`), its specification (`spec.md`), plan (`plan.md`), metadata (`metadata.json`), index (`index.md`), and registration in `conductor/tracks.md`.

## Logic & Workflow

### 1. Input Analysis & Clarification Phase
Check the user prompt and context for the following required parameters:
- **Estudiante(s):** Nombre del estudiante (ej. Ámara, Student, Tahiel).
- **Asignatura:** Materia curricular (ej. Inglés, Lengua y Literatura, Matemáticas, Ciencias, Historia).
- **Nivel / Grado:** Curso escolar (ej. 7° Básico, 3° Medio).
- **Contenidos y Objetivos de Aprendizaje (OA):** Lista de OAs o ruta al archivo fuente (ej. `materia_elu/ingles/contenidos_7basico.md`).

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
   - Filtrar la tabla de archivos según la carpeta del estudiante (ej. `01_amara/`, `02_eluney/`), la asignatura/nivel (ej. `ingles`, `lenguaje`, `7basico`, `1romedio`) y carpetas compartidas (`BookCollection`, `Pruebas`, `Textos Escolares 2018`, `ensayos-simce`, `Ensayo pruebas `).
   - Leer únicamente los archivos relevantes detectados en `/home/username/rclone/gdrive/Cerditos/<name>` para complementar el temario con guías previas, libros y material curricular disponible.

### 2. Track Scaffolding Protocol
Generate a dedicated track folder (e.g., `conductor/tracks/create_guide_<subject>_<grade>_YYYYMMDD/`) containing:

#### A. `spec.md`
- **Overview:** Propósito de la guía, estudiante, nivel educativo, asignatura y ruta de destino (ej. `materia_[estudiante]/[asignatura]/guia_aprendizaje_[nivel].md`).
- **Source Files & OAs:** Cobertura 100% de los OAs definidos en el temario de entrada y material local recopilado.
- **Local & Web Research Requirements:**
  - **Material Local (Cerditos):** Verificación de montaje `rmount gdrive`, consulta de `/home/username/rclone/gdrive/Cerditos/files.json` y extracción de guías, textos escolares y ejercicios previos del estudiante.
  - **Búsqueda en Fuentes Oficiales Web:** Currículum Nacional MINEDUC (`curriculumnacional.cl`), AyudaMINEDUC (`ayudamineduc.cl`), orientaciones y modelos SIMCE, British Council (para inglés), Khan Academy, educarchile, etc.
  - Recopilación de textos auténticos, listas de vocabulario, conectores y modelos de ejercicios de exámenes oficiales.
- **Dynamic Variations:** Instrucción de generar variaciones originales y desafiantes basadas en los modelos web para evitar la repetición.
- **Guide Structure:**
  1. Portada y `# Introducción` (propósito, nivel educativo / CEFR si aplica, modo de uso).
  2. Desarrollo por OA (`## OA [N°]: [Descripción]`): Explicación conceptual, tablas de vocabulario/conectores, ejemplos modelados, ejercicios de práctica (tipo SIMCE / Validación y variaciones dinámicas), tips de estudio y actividad de producción/aplicación.
  3. `## Apéndice`: Glosarios, tablas resumen y recursos online recomendados.
  4. `## Autoevaluación`: Lista de verificación (checklist) de logros por OA.
- **Style & Formatting Requirements:**
  - Prohibido el uso de separadores `---` en el cuerpo del texto (solo en frontmatter YAML).
  - Jerarquía clara de títulos (`#` título/intro, `##` secciones/OA, `###` subtemas, `####` ejercicios).
  - Sin párrafo de cierre "Consejo final" (terminar estrictamente con la autoevaluación).
  - Todas las fórmulas matemáticas/físicas en código LaTeX (`$...$`).
  - Compilación a PDF mediante Pandoc / XeLaTeX aplicando el pipeline de `add-preamble`.
- **Acceptance Criteria:** Escenarios BDD / Gherkin (`Given-When-Then`).

#### B. `plan.md`
Estructura el plan de implementación en fases secuenciales:

**Phase 1: Research & Material Gathering**
- [ ] Task: Verificar montaje de 'gdrive' (ejecutar 'rmount gdrive' si no está montado) y consultar '/home/username/rclone/gdrive/Cerditos/files.json' para material de estudio local del estudiante y asignatura
- [ ] Task: Revisar archivos fuente de contenidos (`contenidos_*.md`), temarios oficiales y material local extraído
- [ ] Task: Investigar en la web orientaciones curriculares oficiales (MINEDUC, SIMCE, Validación, repositorios especializados)
- [ ] Task: Recopilar textos auténticos, listas de vocabulario, tablas de conectores y modelos de preguntas
- [ ] Task: Conductor - User Manual Verification 'Research & Material Gathering' (Protocol in workflow.md)

**Phase 2: Drafting Guide Content**
- [ ] Task: Redactar Portada e Introducción (con nivel educativo y CEFR si aplica)
- [ ] Task: Redactar secciones por cada Objetivo de Aprendizaje (explicación, vocabulario, ejemplos, ejercicios SIMCE y variaciones dinámicas, actividad de producción)
- [ ] Task: Redactar Apéndice (tablas, glosario, recursos web) y Autoevaluación (checklist por OA)
- [ ] Task: Conductor - User Manual Verification 'Drafting Guide Content' (Protocol in workflow.md)

**Phase 3: Style Validation & PDF Compilation**
- [ ] Task: Validar directrices de estilo (ausencia de `---` en cuerpo, jerarquía de títulos, sin "Consejo final")
- [ ] Task: Ejecutar skill `add-preamble` para agregar preámbulo YAML y compilar PDF limpio vía Pandoc / XeLaTeX
- [ ] Task: Conductor - User Manual Verification 'Style Validation & PDF Compilation' (Protocol in workflow.md)

### 3. Conductor Compliance
- Crear `metadata.json` con `type: "feature"`, `status: "new"`, `track_id`, timestamps y descripción.
- Crear `index.md` con enlaces a `spec.md`, `plan.md` y `metadata.json`.
- Registrar la nueva pista en `conductor/tracks.md`.