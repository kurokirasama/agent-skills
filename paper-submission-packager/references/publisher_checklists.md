# Publisher Submission Formatting Checklists

Verify the target journal's official Author Guidelines first; use these battle-tested checklists to catch common portal build failures before upload.

---

## 1. Springer Nature / Aries Editorial Manager (`sn-jnl.cls`)
*(Distilled from `springer_submission_compliance_20261014`)*
- [ ] **Archive Modular Tree:** Snapshot `main.tex`, `sections/`, `figures/`, `tables/` into `original/`.
- [ ] **Zero-Subdirectory Flat Bundle (Strict EM Rule):** Aries Editorial Manager fails on nested folders (`figures/`, `sections/`, `tables/`). Place ALL submission files (`main.tex`, `sn-jnl.cls`, `sn-mathphys-num.bst` or `sn-mathphys.bst`, `.bbl`, `.bib`, all figures) flat at the root of `springer_submission/`.
- [ ] **Inlined Self-Contained `main.tex`:** Replace `\include{...}` / `\input{...}` calls with inlined section and table code to avoid EM partial-compile ordering bugs.
- [ ] **Normalized Figure Paths:** Set `\graphicspath{{./}}` (or omit prefix) so `\includegraphics{fig_name.pdf}` resolves directly in the flat folder. Remove unused figures from the bundle.
- [ ] **Pre-Compiled Bibliography:** Include generated `main.bbl` alongside `.bib` (some EM setups do not run `bibtex` automatically).
- [ ] **Companion Items:** Title page with author affiliations/ORCID, Funding/Acknowledgments, Competing Interests, Ethics/Data/Code Availability declarations, Cover Letter.

---

## 2. Elsevier Editorial Manager (`elsarticle.cls`)
- [ ] **Document Class & Options:** Verify single-column review (`review` / `preprint`, `3p` / `5p`) vs final layout as requested by the journal (`elsarticle-num` vs `elsarticle-harv` / `cas-dc`).
- [ ] **Highlights File:** Separate `highlights.tex`/`.docx` or inline block: **3 to 5 bullet points**, each strictly **<= 85 characters** including spaces.
- [ ] **Graphical Abstract:** Confirm whether mandatory or optional (`graphical_abstract.png`/`.pdf`, high DPI, readable at thumbnail size).
- [ ] **CRediT Authorship Statement:** Explicit per-author role taxonomy (`Conceptualization`, `Methodology`, `Software`, `Writing - Original Draft`, etc.).
- [ ] **Subscription (`$0` APC) vs Gold OA Selection:** Verify non-OA / subscription pathway matches the project budget unless APC funding is approved.
- [ ] **Cascade Compatibility:** Most Elsevier journals accept `elsarticle` manuscripts with minimal or zero structural reformatting during Editorial Manager transfer/cascade.

---

## 3. IEEE Journals & Transactions (`IEEEtran.cls`)
- [ ] **Mode & Bibliography:** Use `\documentclass[journal]{IEEEtran}` (or `peerreview` if requested) with `IEEEtran.bst`.
- [ ] **Flat or Clean ZIP:** Ensure figures compile cleanly with `pdflatex` (`\DeclareGraphicsExtensions{.pdf,.png,.eps}`); avoid EPS-only incompatibilities under `pdflatex`.
- [ ] **Page Limits & Overlength Fees:** Verify page count against IEEE Transactions / Letters / Access limits.
- [ ] **Author Biographies & Photos:** Prepare short bios and cropped headshot photos if required for final/review upload.
- [ ] **IEEE PDF eXpress Check:** Ensure all fonts are embedded (no Type 3 bitmap fonts in plots) and no PDF hyperlinks/bookmarks violate IEEE PDF eXpress rules.

---

## 4. ML Conferences & ACM (`iclr`, `cvpr`, `neurips`, `acmart`)
- [ ] **Double-Blind Anonymization Audit:** Strip author names, institutions, grant numbers, personal GitHub links, self-identifying cluster names, and PDF author metadata (`\hypersetup{pdfauthor={}}`).
- [ ] **Strict Main-Text Page Cap:** Verify page count up to the start of `References` (e.g., 8 pages CVPR, 9 pages NeurIPS, 10 pages ICLR) matches official `.sty`; move overflow derivations/tables to `Appendix` after `References`.
- [ ] **Mandatory Reproducibility Checklist:** Include required ethics, broader impact, and reproducibility statement sections cleanly.
