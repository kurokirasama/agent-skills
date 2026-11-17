---
name: academic-linkedin-specialist
description: Automate the creation of professional abstracts and LinkedIn posts from academic graduation projects (tesis, proyectos de título). Use when a user provides a graduation project document to extract technical insights and generate outreach content.
---

# Academic LinkedIn Specialist

## Overview
This skill specializes in transforming dense academic graduation projects (proyectos de título, tesis) into professional summaries and high-impact LinkedIn content. It ensures technical precision while maximizing the visibility of academic achievements.

## Processing Workflow

### 1. Metadata & Technical Analysis
Analyze the provided document to extract the following core components:
- **Metadata:** Title, Author, and Advisors (Profesores Guía).
- **Motivation:** The central problem addressed and the justification for the study.
- **Methodology:** Specific statistical models, distributions, software (R, Python, etc.), and key libraries used.
- **Results:** Key findings synthesized with their respective validation metrics (AIC, RMSE, p-values, etc.).

### 2. Deliverable Generation

#### Deliverable 1: Abstract & Insights
- **Abstract:** A professional, concise summary (max 2 paragraphs).
- **Key Insights:** A list of bullet points highlighting the methodological innovation and practical application.
- **Suggested Filename:** `Abstract_Tesis_[Author_Name].md`

#### Deliverable 2: LinkedIn Outreach Post
- **Tone:** Professional, dynamic, and academically proud.
- **Structure:**
	- From the perspective of the program, not the student.
    - Engaging hook emoji + announcement of success.
    - Simplified explanation of the project's relevance.
    - Key milestones (3-4 bullet points with checkmarks).
    - Closing call to action + strategic hashtags (e.g., #DataScience #Statistics #AcademicSuccess).
- **Suggested Filename:** `Post_LinkedIn_Tesis_[Author_Name].md`

## Critical Guidelines
- **Technical Fidelity:** Never replace precise statistical terms (e.g., "GAMLSS", "censored data", "reparameterization") with generic language.
- **Fact-Based:** If specific information is missing from the source, explicitly state its absence or omit it; do not hallucinate details.
- **Format:** All outputs must be delivered in clean, well-structured Markdown.

## Usage Example
**User:** "Here is my graduation project on GAMLSS models for insurance data. Help me create an abstract and a LinkedIn post."
**Skill Activity:**
1. Extracts "Título: Modelos GAMLSS en Seguros", "Autor: Juan Pérez".
2. Identifies usage of R, `gamlss` package, and Log-Normal distributions.
3. Generates the Abstract and the formatted LinkedIn post ready for publication.