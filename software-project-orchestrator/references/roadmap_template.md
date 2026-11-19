# Software Project `project-plan.md` Master Template (8-Stage Skill-Mapped Roadmap)

Customize placeholders (`<...>`) and swap archetype-specific skills from [archetype_matrix.md](./archetype_matrix.md) when writing `./project-plan.md`.

---

```markdown
# Software Project Plan: <Project Name>

## 1. Project Objectives & Product Vision
- **Core Product Goal:** <One-paragraph statement of the problem solved and target experience>
- **Functional & Non-Functional Objectives:**
  1. <Core user capability / MVP deliverable>
  2. <Performance, reliability, and security targets>
  3. <UX, accessibility, SEO, or CLI ergonomics targets>
- **Target Users & Personas:** <Who uses the app/site/tool and how>
- **Scope Boundaries:**
  - **In Scope (Release 1.0):** <Explicit MVP & v1 features>
  - **Out of Scope (Post-Launch Backlog):** <Deferred enhancements>
- **Success Metrics:** `>80%` test coverage, `>70%` mutation score on core logic, `0` critical/high security or a11y blockers, reproducible deploy & rollback.

---

## 2. High-Level Execution Roadmap

### Stage 1: Workspace & Conductor Initialization
- **Goal:** Initialize Spec-Driven Development (`conductor/`), Public/Private Git isolation rules, remote origin, and Obsidian project memory.
- **Skills:** `conductor-setup`, `git-remote-connect` (plus `longterm-memory-orchestrator`).
- **How to Invoke:**
  ```text
  # Initialize Conductor first (defines product.md, tech-stack.md, workflow.md, public/private repo protection)
  /conductor-setup
  ```
- **Deliverables:** `conductor/{index.md,product.md,product-guidelines.md,tech-stack.md,workflow.md,tracks.md}`, `.gitignore`, remote git origin.
- **Exit Gate:** `conductor/index.md` passes health check and initial commit is clean.

### Stage 2: Technical Discovery, Stack & Feasibility Research
- **Goal:** Evaluate libraries, APIs, hosting/VPS cost budgets, regional legal/tax/payment requirements, and technical risks before locking architecture.
- **Skills:** `context-expert`, `deep-retrieval-task` / `source-retrieval-task` (or `deep-research` with mandatory user cost approval if paid).
- **How to Invoke:**
  ```text
  Activate context-expert (and deep-retrieval-task for external API, <$5/mo server cost comparisons, or payment/tax compliance research) before finalizing tech-stack.md.
  ```
- **Deliverables:** Technical feasibility / server & legal research notes in `docs/`, confirmed dependency/API selections in `conductor/tech-stack.md`.
- **Exit Gate:** Stack, external APIs, hosting budget, and compliance feasibility verified with zero unexamined blockers.

### Stage 3: Architecture, Security Policy & UI/UX Design Specification
- **Goal:** Define system boundaries, DB/vector-store schemas, API contracts, 3-phase visual design tokens (`DESIGN.md` for UI/web projects: Author -> Enforce in environment -> Phased rollout plan), and `llm-security.md` policy when AI/LLM endpoints exist.
- **Skills:** `mermaid-diagram-creator`; for web/UI projects: `design-md-skill` + `frontend-design`; for AI/LLM apps: `security-analyst-specialist`.
- **How to Invoke:**
  ```text
  # For UI / Web Apps (Phase 1 Author DESIGN.md -> Phase 2 Enforce in GEMINI.md/product-guidelines/code_styleguides -> Phase 3 Phased Token Rollout):
  /conductor-newtrack activate design-md-skill
  /conductor-implement
  # If using AI/LLMs: scaffold conductor/code_styleguides/llm-security.md and enable per-task security review in conductor/workflow.md.
  # Supplement architecture, DB schema, and sequence diagrams with mermaid-diagram-creator.
  ```
- **Deliverables:** `DESIGN.md` (wired into `GEMINI.md`, `conductor/product-guidelines.md`, and `code_styleguides/`), architecture/ER/sequence diagrams, `conductor/code_styleguides/llm-security.md` (when LLM-enabled).
- **Exit Gate:** User approves system architecture, security baseline, and `DESIGN.md` visual tokens.

### Stage 4: Iterative Feature Implementation (Epic Consolidation + TDD Tracks)
- **Goal:** Consolidate large roadmaps (>6 phases) in **Stage 4.0** into **5–8 cohesive TDD Epics** in `conductor/tracks.md`, then implement features incrementally enforcing Red-Green-Refactor, `>80%` coverage, `>70%` mutation score, and phased token rollout (`Layout -> Components -> Sub-Pages`).
- **Skills:** `/conductor-newtrack` + `/conductor-implement` invoking stack experts (`programmer-expert`, `fastapi-templates`, `frontend-design`, `pandas-pro`, `nushell-expert`, `rust-best-practices`, `bash-defensive-patterns`, `matlab-expert`), `python-testing-patterns` / `test-engineer`, and `debug-specialist`.
- **How to Invoke:**
  ```text
  # Stage 4.0 (Large projects): consolidate docs/roadmap.md phases into 5-8 TDD Epics in conductor/tracks.md
  # Then per Epic / feature track:
  /conductor-newtrack <epic/feature track description>
  /conductor-implement
  ```
- **Deliverables:** Tested production source code, automated test suites (`unit` + `integration`), schema migration scripts (`scripts/migrations/`), updated `howto.md` per track.
- **Exit Gate:** All MVP tracks marked `[x]` with passing test/lint/mutation gates and verified UI token rollout.

### Stage 5: Capped Dependency, API & Scope Refresh
- **Goal:** Audit upstream dependency/API/runtime changes introduced during development and align release scope before pre-release hardening.
- **Skills:** `context-expert`, `deep-retrieval-task`, `nushell-update-evaluator` (when Nushell/plugin-based).
- **How to Invoke:**
  ```text
  Activate context-expert to audit dependency changelogs, API deprecations, and release scope alignment.
  ```
- **Deliverables:** Updated lockfiles/compatibility fixes and frozen v1.0 release scope.
- **Exit Gate:** Clean build and passing tests after dependency alignment.

### Stage 6: Multi-Session Pre-Release Audit & Polish Loop
- **Goal:** Conduct an independent, multi-perspective release readiness audit across fresh sessions with user approval before edits: code hygiene, Report-First `.gemini_security/` + LLM/RAG security audit, `>80%`/`>70%` test/mutation gate, `DESIGN.md` token-drift + Mobile + Dark Mode/Dark Reader + `accessibility` + `seo`, and `localhost`->prod HTTPS sweep + clean payload exclusions.
- **Skills:** `conductor-review` (**Pre-Release Multi-Session Audit Mode**), `security-analyst-specialist`, `security-programmer-specialist`, `python-testing-patterns`, `test-engineer`, `accessibility`, `seo` (for web/static apps).
- **How to Invoke:**
  ```text
  # Run EACH round in a FRESH session until 0 Critical/High issues remain:
  /conductor-review (Pre-Release Multi-Session Audit Mode)
  # Coordinates security-analyst-specialist (.gemini_security/ report-first + LLM checklist), security-programmer-specialist, test-engineer/python-testing-patterns, accessibility, and seo.
  # Present audit report and proposed fixes to user for approval BEFORE applying edits!
  ```
- **Deliverables:** Consolidated pre-release audit report (`REVIEW_REPORT.md` + `.gemini_security/audit_report_YYYYMMDD.md` with 0 Critical/High blockers), verified `DESIGN.md`/Dark/Mobile & `localhost`->prod/exclusion checks.
- **Exit Gate:** Fresh-session re-audit confirms 0 open Critical/High issues and explicit user release sign-off.

### Stage 7: Documentation & Release Packaging
- **Goal:** Produce thorough developer/user documentation, deployment runbooks, agent context parity (`GEMINI.md` / `AGENTS.md` / `CLAUDE.md`), and release changelog.
- **Skills:** `create-software-project-docs`, `init-gmn-md`, `get-diff-summarizer`.
- **How to Invoke:**
  ```text
  Activate create-software-project-docs and init-gmn-md; use get-diff-summarizer for release notes.
  ```
- **Deliverables:** Updated `README.md` (with optional app screenshots), API/CLI docs, `.env.example`, `GEMINI.md`/`AGENTS.md`/`CLAUDE.md`, `CHANGELOG.md`.
- **Exit Gate:** Clean documentation build and verified config/env parity.

### Stage 8: Deployment, Smoke Verification & Post-Launch Iteration
- **Goal:** Deploy to the chosen topology using clean, filtered production payloads, run HTTPS/health smoke checks, verify rollback procedures, and archive completed release tracks cleanly.
- **Selected Topology Pattern (choose matching target):**
  1. *Systemd + Cloudflare Tunnel (`cloudflared`):* `<app>.service` (`Restart=always`, dedicated port) + `setup-service.md`.
  2. *Docker / Podman Compose + Nginx HTTPS:* Reverse proxy + defensive `run`/`stop`/`clean` wrappers + static CLI/installer routes if applicable.
  3. *Filtered Nushell VPS/SFTP Sync:* `shell/deploy_prod.nu --dry-run` stripping `conductor/`, `docs/`, `DESIGN.md`, `GEMINI.md`, `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.gemini_security/`, `.env`, tests.
  4. *Package / Registry / Pages:* `clasp push` (GAS), `cargo` / OpenCode plugin sync, or static CDN deploy (+ optional launch announcement).
- **Skills:** `podman-operator`, `homelab-admin`, `linux-expert`, `bash-defensive-patterns`, `conductor-finish-track`, `git-sync`.
- **How to Invoke:**
  ```text
  Activate podman-operator / homelab-admin / linux-expert to execute filtered deploy (--dry-run first) and verify HTTPS/health smoke checks.
  Then run /conductor-finish-track to archive tracks, git-sync, and update long-term memory.
  ```
- **Deliverables:** Running production service/published package, verified health/smoke logs, rollback checklist, updated Obsidian memory.
- **Exit Gate:** Smoke checks pass in production and track lifecycle finalized.

---

## 3. Architecture, Implementation & Workflow Ideas
- **Module & Directory Layout:** <Clean separation of concerns, entrypoints, core domain logic, adapters, tests>
- **Schema Migration & Cross-Store Consistency:** <Idempotent `scripts/migrations/` with pre-migration backups; automated consistency checks between relational DBs and vector/secondary indexes (deletion/re-index parity)>
- **Auth, LLM Safety & Privacy Boundaries:** <Auth tokens/OAuth HTTPS redirects; XML prompt delimiters, PII masking, `DOMPurify`/`bleach` output sanitization, native safety filters; optional `nu-crypt`/GPG encrypted local storage for high-sensitivity personal/clinical apps>
- **Testing, CI & Mutation Pipeline:** <`pytest`/`httpx.AsyncClient`, `vitest`, `cargo test`, coverage threshold (`>80%`), mutation runner (`mutmut`/`stryker`/`cargo-mutants` `>70%`)>
- **Deployment & Rollback Topology:** <Systemd+`cloudflared`, Compose+Nginx/Quadlet, or filtered `deploy_prod.nu`; clean payload exclusions, healthchecks, backup & rollback plan>
- **Technical Risks & Mitigations:** <Rate limits, concurrency/locking, Dark Reader/mobile regressions, prompt-injection/LFI boundaries>
```
