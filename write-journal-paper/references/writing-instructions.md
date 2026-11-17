# Journal Paper Writing Instructions (14-step procedure)

Source of truth for the paper-writing workflow. The track's `howto.md` is generated from this document plus the user's inputs.

## Procedure
1. Activate the `latex-expert` and `writing-expert` skills to guide compilation and writing.
2. Identify the top-1 candidate journal for publication from `bibliography/`. Research the journal: its guidelines and previous similar and dissimilar publications. Write the resulting writing plan/specification into the track `spec.md` or wherever appropriate in the track artifacts.
3. Follow an include strategy: `main.tex` only holds `\include` items for the different sections; each section in a separate file; `figures/` and `tables/` subfolders so the main folder stays uncluttered; one file per table, `\include`d from its section.
4. Write all section headers/files, empty for now. At this state the document MUST compile without errors.
5. Read `bibliography/` completely to understand the state of the art. Fill the `.bib` file with all necessary references.
6. Read the results source directory completely, especially the reports, to understand the results, available figures and tables.
7. Read `docs/` completely; useful material is likely stored there.
8. Copy all tables and figures to be used into `figures/` and `tables/`. When available, always prefer the PDF version of figures.
9. In the introduction or state of the art (where appropriate), state clearly the difference between the proposed method and the state of the art, and why the proposed approach remains relevant even when more recent or popular alternatives exist (specific contrasts come from the user's requirements).
10. Do NOT mention capabilities reserved for future papers. Apply every mention/avoid constraint provided by the user.
11. Give full detail of the results, with proper explanations and insights into what was found.
12. Orient the discussion section to the best possible approach for publication in the target journal. Include future-work ideas: adding penalties to the fitness function, expanding to other NN architectures, implementing new training algorithms.
13. In the acknowledgments, mention the funding received (details provided by the user).
14. After everything is written and compiles, spawn parallel `writing-expert` agents, one per non-empty tex file, to improve and humanize the wording.
15. Present the final result for the user to read and give feedback.

## Notes
- Steps map to track plan phases: (1-2) Setup & Journal Research; (3-4) LaTeX Scaffold; (8) Figures & Tables Ingestion; (5-7, 9-13) Content Writing; (14) Humanization; (15) Final Compilation & User Review.
- The generated track's `plan.md` MUST instruct reading `howto.md` first, as a starting point only.
