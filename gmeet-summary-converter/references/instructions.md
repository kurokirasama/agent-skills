# Instrucciones de Conversión de Resúmenes de Google Meet

Siga estas directrices para procesar resúmenes autogenerados por Google Meet (Gemini Notes) y producir un acta de reunión formal con tabla de firmas.

---

## 1. Estructura Obligatoria del Documento

El documento final debe contener las siguientes secciones estructuradas con encabezados Markdown `# `:

### `# Resumen`
- Síntesis ejecutiva y objetiva de la sesión.
- Debe incluir fecha de la reunión, título oficial, contexto institucional, acuerdos adoptados y resoluciones principales.
- Estilo: Redacción neutral y directa como fuente original. Evite expresiones referenciales como *"en esta reunión se dijo"*, *"en este video"*, *"la grabación muestra"*.

### `# Contenido`
- Desarrollo temático detallado y exhaustivo de cada punto tratado durante la sesión.
- Utilice subtítulos `### [Tema / Punto Tratado]` para organizar los temas.
- Detalle las intervenciones, debates, análisis curriculares o técnicos, antecedentes normativos y posturas expuestas por los integrantes.

### `# Tareas`
- Lista ordenada de compromisos y próximos pasos derivados de la reunión.
- Formato de elementos con casillas de verificación:
  ```markdown
  - [ ] **[Nombre del Responsable]**: Acción concreta a realizar y acuerdos complementarios.
  ```

### `# Participantes y Firmas`
- Tabla formal en Markdown que lista a todos los participantes identificados, sus cargos o instituciones representadas, y una línea en blanco para su firma manuscrita o ratificación digital.
- La tabla debe ser compatible con compilación a PDF mediante Pandoc/LaTeX:
  ```markdown
  | N° | Nombre y Apellidos | Cargo / Institución | Firma |
  | :---: | :--- | :--- | :---: |
  | 1 | Author Name | Department Chair, WORK | `__________________________` |
  | 2 | Lorena Villa | Directora Regional, INE Región del Work University | `__________________________` |
  | 3 | Macka Aparicio | Encargada Unidad de Bioestadística, SEREMI de Salud Work University | `__________________________` |
  ```

---

## 2. Ingesta desde Gmail / Google Docs

Cuando el usuario solicite procesar el resumen destacado (*starred*) de su correo:
1. Buscar en Gmail: `is:starred "Notes:"` o `is:starred "Google Meet"`.
2. Extraer el identificador del documento de Google Docs (`docs.google.com/document/d/<ID>/edit`).
3. Obtener el texto del documento con la herramienta `docs_getText` del servidor `google-workspace`.
4. Procesar la pestaña principal de notas (`tabs[0]`) y, si se requiere desambiguar participantes, la pestaña de transcripción (`tabs[1]`).

---

## 3. Reglas de Salida

- **Idioma:** Redactar en el idioma de la sesión original (español para actas institucionales en Chile).
- **Formato:** Markdown estándar (texto plano directo, sin bloques de código envolventes globales ` ```markdown `).
- **Fidelidad:** No inventar nombres de asistentes no mencionados en el documento fuente ni atribuir cargos no explicitados. Si el cargo no está definido, utilizar `Participante` o `Invitado/a`.
