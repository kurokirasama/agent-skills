# Rubric Schemas and Evaluation Tables

## Standard Rubric CSV Columns
For both written and practical evaluations, the criterion-level breakdown is saved to `rubrica_<eval>.csv` with the following canonical columns:

| Column | Type | Description |
|---|---|---|
| `bloque` | string | High-level module (e.g., Limpieza, Exploración, Modelación, Presentación) |
| `criterio` | string | Specific criterion name |
| `puntaje_max` | number | Maximum assignable points for this criterion |
| `puntaje` | number | Points awarded based on student deliverables |
| `nivel` | string | Achievement level (Insuficiente, Básico, Destacado, Excelente) |
| `evidencia` | string | Concrete citation (script filename, line numbers, command, or report section) |

## Chilean Grade Conversion Standard
For evaluations based on total points:
- **Default Scale (Max 60 points)**:
  $$\text{Nota} = \frac{\text{Puntaje} + 10}{10}$$
  - $0\text{ pts} \to 1.0$
  - $30\text{ pts} \to 4.0$ (60% approval threshold)
  - $50\text{ pts} \to 6.0$
  - $60\text{ pts} \to 7.0$

- **Arbitrary Scale**:
  $$\text{Nota} = \left(\frac{\text{Puntaje}}{\text{Puntaje Máximo}} \times 6.0\right) + 1.0$$
  Bounded between $1.0$ and $7.0$, rounded to one decimal place.
