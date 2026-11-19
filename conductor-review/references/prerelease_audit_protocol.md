# Multi-Session Pre-Release Audit Protocol

Use this protocol inside `conductor-review` when auditing a complete codebase, release milestone, or Stage 6 software deliverable (apps, webpages, APIs, CLIs, plugins) across fresh sessions until production readiness is signed off.

---

## 1. The 5 Pre-Release Audit Dimensions

### Dimension 1: Architecture, Spec & Code Hygiene (`conductor-review` Core)
- Verify modularity, zero duplicated logic across components, error handling (`try/catch`, typed errors, defensive exit paths), and alignment with `conductor/product.md`, `tech-stack.md`, `DESIGN.md` (if UI), and `code_styleguides/`.
- Flag dead code, commented-out blocks, hardcoded localhost/personal paths, and stray temporary files.

### Dimension 2: Security & Secrets Hardening
Coordinate with `security-analyst-specialist` and `security-programmer-specialist` (using `llm_and_web_security_checklist.md`):
- **Secrets & Env Hygiene:** Verify zero committed API keys, tokens, credentials, or `.env` files; check `.gitignore`, `.env.example`, and reject placeholder/default production session or cookie secrets.
- **Input Validation, LFI & Injection:** Audit SQL, shell, command, template/XSS, canonical path-containment checks against LFI/directory traversal, and strict allowlist SSRF checks on external/Drive fetchers.
- **Auth, CORS & Dependencies:** Verify server-side auth/RBAC middleware, CSRF/CORS restrictions, least-privilege roles, HTTPS-enforced OAuth redirects, and dependency vulnerabilities (`npm audit`, `cargo audit`, `pip-audit`).
- **AI / LLM & RAG Security Gate (When LLM Calls Exist):** Verify structured XML delimiters (`<user_input>`, `<retrieved_context>`), immutable system instructions, pre-prompt PII masking, input length caps, native provider safety filters, `DOMPurify`/`bleach` allowlist output sanitization, and generic client error IDs without stack-trace leakage.
- **Report-First `.gemini_security/` Audit Loop:** Verify historical `.gemini_security/` findings have not regressed, log all new vulnerabilities (`VULN-###` Severity + Source/Sink `file:line`) in `.gemini_security/audit_report_YYYYMMDD.md` **before** code changes, and obtain user approval before applying high-risk remediations.

### Dimension 3: Testing, Coverage & Mutation Quality Gate
Coordinate with `test-engineer`:
- Execute full unit, integration, and E2E/smoke test suites cleanly.
- Verify `>80%` code coverage on critical paths and `>70%` mutation score on core domain logic where mutation runners (`mutmut`, `stryker`, `cargo-mutants`) apply.
- Confirm linters, type checkers, and build pipelines exit `0` with zero skipped assertions.

### Dimension 4: Web / Frontend / UI Quality Gate (When Applicable)
For web apps, static sites, dashboards, or HTML UIs, coordinate with:
- **`accessibility`:** WCAG 2.2 AA compliance (semantic landmarks, contrast `>=4.5:1`, keyboard navigation, focus states, ARIA attributes, alt text).
- **`seo`:** Title/meta descriptions, Open Graph / Twitter cards, canonical URLs, JSON-LD structured data, `robots.txt`, `sitemap.xml`, and Core Web Vitals (CLS/LCP/INP).
- **`frontend-design` & `DESIGN.md` 3-Phase Parity:** Confirm `DESIGN.md` is enforced in `GEMINI.md`/`product-guidelines.md`/`code_styleguides/`, audit CSS/UI code for **token drift** (hardcoded colors, fonts, or spacing overriding semantic tokens), and verify **Mobile viewport responsiveness** plus **Dark Mode / Dark Reader contrast parity**.

### Dimension 5: Documentation, Domain Sweep & Deployment Payload Parity
- **Docs Parity:** Verify `README.md`, API docs, CLI `--help` flags, configuration keys, and deployment runbooks accurately match the shipped code.
- **`localhost` → Production Domain & HTTPS OAuth Sweep:** Audit frontend/backend configs, CLI defaults, OAuth redirect URIs, and docs to ensure zero development `localhost` / HTTP URLs leak into production configurations.
- **Production Payload Exclusion Gate:** Verify `.dockerignore`, deploy scripts (`deploy_prod.nu`, `rsync`, CI), and containers strip agent/dev artifacts (`conductor/`, `docs/`, `DESIGN.md`, `GEMINI.md`, `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.gemini_security/`, `todos.md`, `.env`, test suites), and validate `--dry-run` / rollback readiness.

---

## 2. Severity Rubric, User Approval Gate & Fresh-Session Loop

| Severity | Criteria | Release Gate |
| :--- | :--- | :--- |
| **CRITICAL** | Security hole, secret leak, data loss bug, failing test/build, WCAG blocker | **BLOCKS RELEASE** |
| **HIGH** | Broken edge case, missing auth/validation guard, major a11y/SEO defect, stale runbook | **BLOCKS RELEASE** |
| **MEDIUM** | Maintainability smell, minor UX/perf inefficiency, missing non-critical test | Resolve or explicitly defer |
| **LOW** | Stylistic nit, minor copy polish | Optional |

### Loop Execution Discipline
1. **Generate Consolidated Audit Report (`PRERELEASE_AUDIT_ROUND_<N>.md` or `REVIEW_REPORT.md`):** Tabulate all findings with file/line citations, severity, and concrete remediation patches.
2. **Mandatory User Approval Gate:** Send Discord alert (`to-discord $msg -p`) and present the findings + proposed edits to the user for **Approve / Defer / Reject** BEFORE modifying source files (especially for `HIGH`/`CRITICAL` or cross-cutting refactors).
3. **Apply & Verify Locally:** Implement approved fixes and re-run test/lint/build checks.
4. **Fresh-Session Delta Re-Audit (`Round N+1`):** Instruct starting a **fresh agent session** for the next audit pass so an unprimed reviewer inspects the updated codebase (`Round N Delta Summary`: Resolved Blockers, Remaining Findings, Regressions = None) until **0 `CRITICAL` / `HIGH` findings** remain and the user approves shipping.
