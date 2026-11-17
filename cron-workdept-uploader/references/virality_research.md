# Virality & Optimization Research: YouTube Academic Video Publishing

This reference provides research-backed principles and heuristics for maximizing Click-Through Rate (CTR), search discoverability, audience retention, and visual appeal for the **Proyecto de Título** presentations on the **WORK DEPT** YouTube channel (`@workdept`).

---

## 1. The YouTube Recommendation Engine for Academic & Technical Content

YouTube's recommendation system focuses on **viewer satisfaction** and **viewer retention**, distributed across three discovery surfaces:
1. **Search (Evergreen Traffic)**: Academic, statistical, and engineering projects receive significant ongoing search traffic from students, researchers, and industry professionals looking for specific methodology implementations (e.g., survival analysis, deep learning, churn prediction).
2. **Suggested Videos**: YouTube pairs technical thesis videos alongside related machine learning, statistics, and university research videos when viewers finish watching related content.
3. **Browse Features (Home)**: High CTR and strong early retention trigger broader testing on home feeds of users interested in data science, Chilean universities, and applied statistics.

---

## 2. Title & Metadata Architecture

### A. Title Formulation
* **Format**: `<Clean Descriptive Topic> | Proyecto de Título SUBJECT WORK`
* **Rule**: The front portion (the topic) MUST contain the core problem or discovery without academic jargon bloat.
* **Why**: The first 50 characters are visible on mobile screens. Viewers click on the *problem being solved* (e.g., *“Descifrando el Futuro con Datos”*, *“Datos vs Leucemia Infantil”*, *“Predecir el Caos Económico”*), while the institutional suffix establishes authority and academic rigor.

### B. Description Optimization
* **Above-the-Fold (First 2 Lines)**:
  `Proyecto de Título de <Student Name> para la carrera de SUBJECT WORK, <Year>.`
  This immediately confirms identity, year, and degree credentials to search indexers and human viewers.
* **Hashtags**:
  YouTube displays up to 3 primary hashtags above the title or in the description.
  - **2 Topic/Domain Hashtags**: Extracted from the `aimsy` AI summary (e.g., `#CienciaDeDatos`, `#SaludPublica`, `#MachineLearning`).
  - **3 Institutional Hashtags**: `#SUBJECT #WORK #ProyectoDeTitulo`.

---

## 3. Tag Taxonomy & Strategic Role

While modern YouTube ranking relies heavily on natural language understanding (NLU) of audio transcripts, titles, and descriptions, tags remain important for search disambiguation and categorical indexing:

| Category | Purpose | Examples |
| :--- | :--- | :--- |
| **Broad (Domain)** | Categorizes the video into high-level knowledge graphs. | `ciencia de datos`, `estadística`, `ingeniería`, `machine learning`, `data science`, `análisis predictivo` |
| **Specific (Topic)** | Matches precise search queries derived from the `aimsy` summary. | `leucemia infantil`, `deserción universitaria`, `sismógrafo financiero`, `series de tiempo` |
| **Institutional (Always)** | Binds the video to the university brand and department archive. | `Work University`, `SUBJECT`, `proyecto de título`, `facultad de ciencias work`, `<year>` |
| **Orthographic Variants** | Captures common misspellings or unaccented searches. | `bio bio`, `Work University`, `estadistica`, `ingenieria` |

---

## 4. Thumbnail Frame Selection Heuristics

Custom thumbnails are the single largest factor in CTR. For automated thesis video publishing, frames are sampled and evaluated against specific visual criteria:

### A. Candidate Extraction Strategy
* Extract 3–5 candidate frames at evenly distributed timestamps using `ffmpeg` (e.g., at 15%, 35%, 55%, and 75% of the video duration).
* Skip the very beginning (0%–5%) to avoid black leader frames or introductory setup transitions.

### B. Selection Scoring Heuristics
1. **Human Element & Presenter Engagement**:
   - Prefer frames where the student presenter is visible with a calm, confident, or explanatory posture.
   - Avoid frames caught mid-blink, looking down at notes, or with severe motion blur.
2. **Visual Contrast & Slide Legibility**:
   - Prefer frames showing clean, high-contrast visual elements: statistical plots, regression lines, clustering charts, or title infographics.
   - Avoid frames overloaded with tiny code listings or wall-of-text slides that become unreadable when downscaled to mobile thumbnails.
3. **Color Contrast & Dynamic Range**:
   - Favor frames with vivid colors and strong lighting over dark or washed-out backgrounds.
   - High visual contrast pops against both YouTube's light and dark themes.

### C. Technical Constraints
* Format: PNG or JPEG.
* Recommended resolution: 1280x720 (minimum 640px width).
* Maximum file size: strictly under 2MB (enforced by the YouTube Data API).

---

## 5. Reachability Strategies for General Academic Videos

For non-thesis academic videos (talks, seminars, workshops, masterclasses, tutorials), discoverability strategies shift from credential archiving to broader search intent and curiosity:

### A. Content-Driven Hook Title Architecture
* **Rule**: Do NOT use raw filenames or generic labels (e.g. `charla_1.mp4`, `clase_2026.mp4`).
* **Structure**: `<Curiosity/Problem Hook> | WORK DEPT`
* **Length**: Keep hook between 30 and 55 characters (total title strictly under 70 characters for mobile truncation safety).
* **Hook Archetypes**:
  1. *How-To / Problem Solving*: e.g. `Cómo Predecir la Inflación con Redes Neuronales`
  2. *Curiosity / Discovery*: e.g. `El Secreto de las Series de Tiempo en Finanzas`
  3. *Domain / Masterclass*: e.g. `Machine Learning Explicado: De Cero a Experto`

### B. Adaptive Description & Hashtag Strategy
* **Lead Paragraph**: Contextualize the academic content, host department, and Work University.
* **Hashtags**: Include 2 topic hashtags derived from AI analysis plus `#WORKDEPT #WORK #SUBJECT` (omitting `#ProyectoDeTitulo`).

## 5. Shorts Format: Scale (Not Crop) + Background Music
* **Decision (2026-10-08, user-validated via side-by-side samples)**: render Shorts by scaling
  the highlight to fit 9:16 (1080x1920) with blurred-background padding (`fit` + `blur`),
  NOT center-cropping — cropping discards slide edges carrying the statistical content.
* **Audio**: mix a random lo-fi track from the music library at volume 0.1 under the original
  audio to raise retention without masking speech.
