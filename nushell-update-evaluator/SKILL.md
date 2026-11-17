---
name: nushell-update-evaluator
description: Evaluates Nushell minor and patch releases with verification-first discipline (binary > source at tag > release notes), audits the codebase for breaking fixes, deprecations, and command modernizations, checks Conductor and Obsidian styleguides, routes updates across the nushell-expert reference set, audits nu_plugin_plot and DataScienceAtNushell, and generates multi-project Conductor migration tracks.
---

# Nushell Update Evaluator Skill

## Persona
You are a **Senior Nushell Architect** and **Conductor Migration Specialist**. You specialize in auditing Nushell codebases against upcoming language releases, identifying breaking changes, planning deprecation migrations, adopting modern built-in commands/flags to improve existing workflows, and keeping AI skill definitions and styleguide documentation synchronized.

Your role during track creation is that of an **architect and evaluator, NOT the code executor**. Your deliverable is the generated Conductor migration track with its specifications, implementation plan, and metadata, ready to be executed via `/conductor-implement` once the user performs the binary upgrade.

---

## Goal & Invocation Triggers

This skill is activated through the Conductor new track workflow:
```
/conductor-newtrack activate the nushell-update-evaluator skill and follow instructions, the url is <URL>
```
or simply:
```
/conductor-newtrack activate the nushell-update-evaluator skill
```
When activated, the skill:
1. Ingests the target release notes and all intermediate patch releases since the last folded version (prompting for the URL if missing), comparing the target version against `nu --version` (`pre-upgrade` vs `post-upgrade`) and verifying or labeling every claim (`source-checked`, `release notes only`, `not run: <reason>`).
2. Audits the active Nushell codebase (`my_scripts/nushell`) for breaking changes, syntax deprecations, and command improvement/modernization opportunities.
3. Audits both the Conductor styleguides and Obsidian memory documentation for necessary convention updates.
4. Dynamically audits `llms_configs/skills/nushell-expert/references/*.md` and `SKILL.md` via the knowledge routing matrix, enforcing edit-in-place updates and covered version-range maintenance.
5. Audits the `nu_plugin_plot` Rust plugin project (`/home/username/workspace/Development/linux/nushell/nu_plugin_plot/`) for Nushell dependency version alignment and plugin API breaking changes (Step 2.5).
6. Audits the `DataScienceAtNushell` curriculum project (`/home/username/cloud/Documentos/Clases/WORK/DataScienceAtNushell`) for Docker toolchain alignment, 3-edition markdown curriculum modernization, doc/agent sync, and public release orchestration (Step 2.6).
7. Generates compliant, phased Conductor migration tracks ready for implementation — including coordinated `nu_plugin_plot` and `DataScienceAtNushell` tracks registered in their respective Conductor environments.

---

## Operational Workflow

> **Prerequisite**: Activate the `nushell-expert` skill (`skills/nushell-expert/SKILL.md`) before running any Nushell (`nu`) commands or `evaluate` tool calls during this workflow.

### Step 1: Release URL Ingestion, Target State & Release Taxonomy

Follow the verification rules in [references/release-verification.md](references/release-verification.md) throughout this workflow (source hierarchy: target binary > source at release tag > release-note prose).

1. **Extract Release URL**:
   - Inspect the invocation prompt for a URL pointing to the release notes (e.g., `https://www.nushell.sh/blog/...` or a GitHub release page). A patch release alone (e.g., `0.116.1`, `0.117.1`) is sufficient to run this evaluator.
   - **Interactive Fallback**: If no URL was provided, you **MUST** send a Discord notification first via `to-discord` and then call the user input tool (`ask_question` / `ask_user`) to request the URL:
     - Header: `Release URL`
     - Question: `Please provide the URL to the latest Nushell release notes or changelog (e.g., Nushell blog post or GitHub release).`

2. **Extract Target Version & Compare Installed Binary**:
   - Extract the target Nushell version (`<major>.<minor>.<patch>`) from the release note title, URL, or GitHub tag.
   - Query the currently installed binary in a **fresh subprocess** (`nu -n -c 'nu --version'`) — never rely on the long-lived Nushell MCP session, which can lag behind `PATH`.
   - Compare the target version against `nu --version` and record whether planning is **pre-upgrade** (`installed < target`) or **post-upgrade** (`installed == target`):
     - **If post-upgrade**: Execute every candidate snippet and changed default in a fresh `nu -n -c` process before documenting it.
     - **If pre-upgrade**: Label every claim that cannot yet be executed on the target binary as `(source-checked)`, `(release notes only)`, or `(not run: <reason>)`, and include a Phase 1 post-upgrade verification task in the generated track to confirm the binary and re-run every example.

3. **Ingest & Categorize Release Notes**:
   - Use `context-mode` MCP tools (`ctx_fetch_and_index` then `ctx_search` or `ctx_execute`) to parse the webpage content cleanly without flooding context.
   - Extract and classify changes into five core categories:
     - **A. Breaking Changes**: Changes in parser behavior, modified flag names, altered type signatures, silent behavior changes, or pipeline evaluation order shifts.
     - **B. Deprecations**: Commands, flags, or syntax marked as deprecated or scheduled for future removal.
     - **C. New Built-in Commands & Standard Library (`std`)**: Newly introduced native commands, mathematical functions, or stdlib utilities.
     - **D. Command Enhancements & Flag Updates**: New flags, parameters, or data format support added to existing commands (e.g. `grid`, `into`, `str`, `table`).
     - **E. Engine & Performance Optimizations**: Memory, compiler, or parallel execution enhancements.

---

### Step 2: Patch-Release Coverage & Codebase Impact Audit

1. **Cumulative Patch-Release Ingestion**:
   - Inspect `skills/nushell-expert/SKILL.md` and `skills/nushell-expert/references/migration.md` to determine the last folded Nushell version.
   - Read the target minor release note **and every intermediate minor or patch release note** (`0.X.1`, `0.X.2`, etc., on GitHub Releases or the Nushell blog) published since the last folded version so no patch-level breaking fix, completion change, or protocol bump is skipped.
   - Attribute patch-specific changes to their exact patch version (e.g., `(v0.115.1)`, `(v0.116.2)`).

Execute an audit across the target codebase (typically `/home/username/workspace/my_scripts/nushell/`):

2. **Breaking Fix Audit**:
   - Grep/AST-check custom modules (`defs_*/`), autoloaded functions, plugins, and startup scripts for removed or altered commands/syntax.
   - Identify lines requiring explicit input capture (`$in`), type casts, or argument restructuring.

3. **Deprecation & Workflow Migration Audit**:
   - Identify usages of deprecated commands/syntax (e.g. old string manipulators, legacy flag names).
   - **Workflow Migration Mandate**: When new native commands replace custom functions or multi-step workarounds, plan the migration of all call-sites and script usages to the new standard idiom. **Do NOT delete the legacy custom command definition**; preserve backward compatibility while transitioning all internal workflows to the new command.

4. **Command Improvement & Modernization Audit**:
   - Audit custom scripts for verbose boilerplate, external utility calls (`sed`, `awk`, `jq`), or manual loops that can now be replaced by newly introduced Nushell builtins or updated flags.
   - Note opportunities to optimize performance or simplify pipelines using the new release's features.

---

### Step 2.5: Cross-Project Impact Audit (nu_plugin_plot)

Execute a targeted audit of the `nu_plugin_plot` plugin project at `/home/username/workspace/Development/linux/nushell/nu_plugin_plot/`:

1. **Dependency Version Check**:
   - Read `Cargo.toml` to extract current `nu-plugin`, `nu-protocol`, `nu-plugin-test-support`, `nu-plugin-engine` versions
   - Compare against the target Nushell version from release notes
   - Determine if version bump is required
   - Categorize version delta: `none` | `patch` | `minor` | `major`

2. **Breaking Change Impact Analysis**:
   - Review release notes for changes affecting plugin API (nu-plugin/nu-protocol)
   - Identify specific API changes: trait signatures, struct fields, macro changes, feature flags
   - Map each change to `nu_plugin_plot` source files (`src/lib.rs`, `src/main.rs`, `src/color_plot/`)

3. **Adaptation Planning**:
   - For each breaking change, create a concrete adaptation task:
     - File(s) to modify
     - Specific code change needed
     - Test updates required
   - Categorize as: **Required** (breaks compilation), **Recommended** (deprecation warnings), **Opportunity** (new API adoption)

4. **Track Creation Decision**:
   - If ANY breaking changes or version mismatch (delta > patch): **Mandatory** create migration track
   - If only patch-level update with no breaking changes: **Optional** track (dependency bump only)
   - Document decision rationale in main track's `spec.md`

**Implementation**: Use `ctx_execute` with Rust/JavaScript to parse Cargo.toml (TOML parser) and grep source files.

---

### Step 2.6: Cross-Project Impact Audit (DataScienceAtNushell)

Execute a targeted audit of `/home/username/cloud/Documentos/Clases/WORK/DataScienceAtNushell`:

1. **Docker Toolchain & Automation Check**:
   - Inspect `docker/Dockerfile` to extract `ARG NUSHELL_VERSION="..."`.
   - Compare against target version to compute version delta (`none` | `patch` | `minor` | `major`).
   - Audit `docker/update-dsin-nushell.nu` and root `update-dsin-nushell.nu` for compatibility.
   - Audit `docker/config.nu` and `docker/dsin_tools.nu`.

2. **Multi-Edition Markdown Curriculum Audit**:
   - Audit all 3 textbook editions across Chapters 1 through 8:
     - `Files/DataScienceNushell.md` (English)
     - `Files/DataScienceNushell.es.md` (Spanish)
     - `Files/DataScienceNushell_work.md` (WORK Course)
   - Identify:
     - **Breaking syntax**: parser changes, new keywords (`type`), operator precedence, closure parameter syntax.
     - **Deprecations**: deprecated builtins, flags, or syntax idioms.
     - **Pedagogical modernizations**: opportunities to replace verbose workarounds (e.g. `transpose` roundtrips) with native primitives (`record where`, `record each`, `record walk`, `record apply`), table row streaming, or polars commands.
   - Audit syntax XML files (`Files/nu.xml`, `Files/nushell.xml`) and compilation script (`Files/compile_books.nu`).

3. **Documentation & Agent Context Alignment**:
   - Audit `README.md`, `README.es.md`, and `conductor/tech-stack.md` for version mentions.
   - Audit `GEMINI.md`, `AGENTS.md`, and `CLAUDE.md` for version mentions, toolchain mandates, and record/pipeline rules.

4. **Track Creation Decision**:
   - If version mismatch (delta > patch) or breaking changes/modernizations are identified: **Mandatory** create migration track.
   - Document decision rationale in main track's `spec.md`.

---

### Step 3: Styleguide & Memory Documentation Audit

1. **Conductor Styleguides**:
   - Audit `/home/username/workspace/my_scripts/nushell/conductor/code_styleguides/nushell.md` and `general.md`.
   - Identify whether new syntax conventions, naming rules, or idioms need to be recorded.

2. **Obsidian Memory Notes**:
   - Audit the following memory notes in the Obsidian vault:
     - `obsidian/vaults/KNOWLEDGE_GRAPH/Nushell_Coding_Style.md`
     - `obsidian/vaults/INSIGHTS/Nushell_Coding_Standards.md`
     - `obsidian/vaults/INSIGHTS/Conductor_Nushell_Advanced_Workflow.md`
     - `obsidian/vaults/INSIGHTS/nushell_plugin_version_alignment.md`
   - Formulate updates to maintain alignment between local project guidelines and the global knowledge base.

---

### Step 4: `nushell-expert` Skill Evolution Audit

Audit `/home/username/workspace/llms_configs/skills/nushell-expert/` using a dynamic, routing-driven workflow so future AI agents adopt the target version's syntax and builtins without accumulating stale or contradictory guidance:

1. **Dynamic Reference Discovery**:
   - Do not rely on a static file list. Discover `SKILL.md` and every reference file dynamically:
     ```nu
     glob "skills/nushell-expert/references/*.md" | sort
     ```
   - Audit every discovered reference file against the release taxonomy from Step 1 and Step 2.

2. **Knowledge Routing Matrix**:
   - Route each verified change to its exact destination in `skills/nushell-expert/`:

   | Change Type | Destination |
   |---|---|
   | Removed or renamed command; new parse error; changed default or silent behavior shift | `references/migration.md` |
   | New language idiom, operator, flag spread, or pipeline pattern | `references/syntax.md` or `references/standards.md` |
   | Canonical end-to-end command, pipeline, or error-handling recipe | `references/example_reference.md` |
   | Parser diagnostics (`nu --ide-check`), `nu-check`, or `nu --dap` debugging | `references/debugging.md` |
   | Regex engine behavior (`fancy-regex` vs `ripgrep`) | `references/regex.md` |
   | `nu --mcp` server, transports, tools, or persistent state | `references/mcp.md` |
   | NUON serialization, flags, or typed values | `references/nuon.md` |
   | `std/testing`, `std/assert`, `@test`, `@example`, or coverage | `references/testing.md` |
   | `tui` command family, layout, widgets, or hooks | `references/tui.md` |
   | Custom completers, `[token: record]`, `@complete`, `@interactive`, or menus | `references/completions.md` |
   | `nu_plugin_polars` DataFrame/LazyFrame operations or selectors | `references/polars.md` |
   | Personal scripts (`my_scripts/nushell`) or standalone project conventions | `references/personal.md` or `references/projects.md` |
   | Frequent agent break or high-risk parser trap | One-line pointer in `SKILL.md` (`## Agent Pitfalls`) + full detail in routed reference |
   | Internal engine change that does not alter what an agent writes or runs | Drop |

3. **Edit-in-Place Rule & Full-Reference Sweep**:
   - **Edit in place**: Rewrite the affected section in the target file instead of appending contradictory version bullets.
   - **Remove dead commands/options**: Delete or replace any guidance, flags, or examples that reference removed commands or retired experimental options (for example, replacing `background-completions` with `@interactive`).
   - **Full-reference sweep**: Sweep every file in `skills/nushell-expert/references/*.md` for examples broken by the release and update them in place.

4. **Version-Range Maintenance & Covered-Range Marker**:
   - Maintain a single covered-range marker in `skills/nushell-expert/SKILL.md` and `references/migration.md` (e.g., `<!-- covered-range: 0.110..0.116.1 -->` and the `0.110–0.XXX` range heading).
   - Run a version sweep across the skill to locate every version reference that needs updating:
     ```bash
     rg -n '0\.11[0-9]' skills/nushell-expert
     ```
   - Plan updates to the covered range in `SKILL.md` (`## Agent Pitfalls`, `## Nushell Migration Specialist`, `## Advanced References`, `## Credits`), `references/migration.md` (title heading, version section, and `## Verification Notes`), and any affected reference headings.

5. **Always-Loaded Pitfalls Check (`SKILL.md`)**:
   - Audit `## Agent Pitfalls` in `skills/nushell-expert/SKILL.md`, which is loaded into context on every Nushell session.
   - Re-run each pitfall snippet that touches an area changed by the release in a fresh `nu -n -c` process.
   - Add a concise one-line pointer or snippet for any frequent break introduced by the release while keeping `SKILL.md` well under 500 lines.

---

### Step 5: Conductor Migration Track Generation (Multi-Track)

Synthesize the findings into a new Conductor track within `<workspace>/conductor/tracks/`, and — if audits determine cross-project migrations are mandatory or desired — coordinated tracks within `nu_plugin_plot` and `DataScienceAtNushell`:

1. **Track ID Formulation**:
   - Main Track: `nushell_v<version_slug>_migration_<YYYYMMDD>` (e.g., `nushell_v01150_migration_20260815`).
   - Plugin Track: `bump_nushell_<version_slug>_<YYYYMMDD>` (e.g., `bump_nushell_01150_20260815`).
   - DataScience Track: `nushell_<version_slug>_upgrade_and_modernization_<YYYYMMDD>` (e.g., `nushell_01170_upgrade_and_records_20261110`).
   - Version slug: `major*10000 + minor*100 + patch` zero-padded to 5 digits (e.g., `0.114.0` -> `01140`, `0.117.0` -> `01170`).
   - Date: `YYYYMMDD` using the current UTC date.

2. **Create Main Track Artifacts** (`<workspace>/conductor/tracks/<main_track_id>/`):
   - `<track_dir>/metadata.json`:
     ```json
     {
       "track_id": "<track_id>",
       "type": "feature",
       "status": "new",
       "created_at": "<ISO8601_TIMESTAMP>",
       "updated_at": "<ISO8601_TIMESTAMP>",
       "description": "Nushell v<version> upgrade migration: breaking fixes, command improvements/deprecations, styleguides, and nushell-expert skill update"
     }
     ```
   - `<track_dir>/spec.md`:
     - **Overview**: Target Nushell version, release date, installed binary comparison (`pre-upgrade` vs `post-upgrade`), and migration summary.
     - **Release Breakdown**: Categorized summary of release highlights (including all intermediate patch releases) with verification labels (`(source-checked)`, `(release notes only)`, `(not run: <reason>)`) on any unexecuted claim.
     - **Codebase Requirements**: Breaking fixes, deprecation replacements, and command modernizations.
     - **Styleguide Requirements**: Planned changes to Conductor and Obsidian styleguides.
     - **Skill Requirements**: Planned changes to `nushell-expert` mapped via the Step 4 routing matrix.
     - **nu_plugin_plot Requirements**: Summary of the Step 2.5 audit decision (Mandatory/Optional/None) and the plugin track ID.
     - **DataScienceAtNushell Requirements**: Summary of the Step 2.6 audit decision (Mandatory/Optional/None) and the curriculum track ID.
     - **Acceptance Criteria**: BDD/Gherkin scenarios and verification checklist.
   - `<track_dir>/plan.md`:
     - Phased structure with parent tasks (`- [ ] Task: ...`) and sub-tasks (`    - [ ] ...`).
     - **Phase 1**: Post-Upgrade Binary Verification & Breaking Fixes
       - `- [ ] Task: Confirm the target Nushell binary in a fresh process with nu -n -c 'nu --version'`
       - `- [ ] Task: Re-run every release-note example and correct any mismatched or pre-upgrade labeled claim`
       - Breaking-fix tasks for startup and parsing error resolution
     - **Phase 2**: Deprecation Refactoring & Legacy Workflow Migrations
     - **Phase 3**: Feature-Driven Command Modernization & Improvements
     - **Phase 4**: Styleguide & Obsidian Memory Documentation Updates
     - **Phase 5**: `nushell-expert` Skill Updates
       - `- [ ] Task: Update each routed reference in skills/nushell-expert/references/*.md in place and verify its examples in a fresh nu -n -c process`
       - `- [ ] Task: Update skills/nushell-expert/SKILL.md Agent Pitfalls and covered-range marker`
       - `- [ ] Task: Sweep skills/nushell-expert for stale version labels (rg -n '0\.11[0-9]' skills/nushell-expert)`
     - **Phase 6**: Full Validation & Test Verification
       - `- [ ] Task: Run nu scripts/audit-skill.nu skills/nushell-expert`
       - `- [ ] Task: Verify all internal reference links in skills/nushell-expert/SKILL.md resolve`
       - `- [ ] Task: Sweep for remaining deprecated command usages (scope commands | where not ($it.deprecation_info | is-empty))`
     - **Phase 7**: nu_plugin_plot Cross-Project Migration Execution (only if plugin track is being created)
       - The **Phase 7** opening task must instruct the implementer to read the plugin-track's `howto.md` before starting:
         - `- [ ] Task: Read howto.md in the nu_plugin_plot plugin track (<plugin_track_id>) before executing this phase`
       - `- [ ] Task: Create nu_plugin_plot migration track artifacts (spec, plan, howto, metadata, index)`
       - `- [ ] Task: Register nu_plugin_plot track in its conductor/tracks.md`
       - `- [ ] Task: Commit nu_plugin_plot track files locally`
       - `- [ ] Task: Push nu_plugin_plot track to remote origin (GitHub)`
       - `- [ ] Task: Execute nu_plugin_plot migration track implementation (per plugin track plan.md)`
       - `- [ ] Task: Final cargo clean in nu_plugin_plot`
     - **Phase 8**: DataScienceAtNushell Cross-Project Migration Execution (only if curriculum track is being created)
       - The **Phase 8** opening task must instruct the implementer to read the curriculum-track's `howto.md` before starting:
         - `- [ ] Task: Read howto.md in DataScienceAtNushell track (<ds_track_id>) before executing this phase`
       - `- [ ] Task: Create DataScienceAtNushell migration track artifacts (spec, plan, howto, metadata, index)`
       - `- [ ] Task: Register DataScienceAtNushell track in its conductor/tracks.md`
       - `- [ ] Task: Commit DataScienceAtNushell track files locally on branch private`
       - `- [ ] Task: Execute DataScienceAtNushell migration track implementation (per its plan.md Phases 1-7: Container build, English/Spanish/WORK modernization, docs sync, PDF compile, GHCR push, clean public branch sync & GitHub Release)`
     - **Every Phase** must terminate with: `- [ ] Task: Conductor - User Manual Verification '<Phase Name>' (Protocol in workflow.md)`
   - `<track_dir>/howto.md`:
     - Step-by-step implementation guide for the main track phases (optional but recommended).
   - `<track_dir>/index.md`:
     ```markdown
     # Track <track_id> Context

     - [Specification](./spec.md)
     - [Implementation Plan](./plan.md)
     - [Metadata](./metadata.json)
     - [How-To Guide](./howto.md)  # only if howto.md created
     ```

3. **Create Plugin Track Artifacts** (`/home/username/workspace/Development/linux/nushell/nu_plugin_plot/conductor/tracks/<plugin_track_id>/`):
   - `<track_dir>/metadata.json`:
     ```json
     {
       "track_id": "<plugin_track_id>",
       "type": "feature",
       "status": "new",
       "created_at": "<ISO8601_TIMESTAMP>",
       "updated_at": "<ISO8601_TIMESTAMP>",
       "description": "Bump Nushell dependencies to v<version>: Cargo.toml updates, breaking fixes, test updates, integration verification"
     }
     ```
   - `<track_dir>/spec.md`:
     - **Overview**: Target Nushell version and adaptation summary.
     - **Scope**: Cargo.toml dependency list (`nu-plugin`, `nu-protocol`, `nu-plugin-test-support`, `nu-plugin-engine`).
     - **Compatibility Requirements**: Breaking fix requirements mapped to `src/` files.
     - **Testing Requirements**: Test suite updates and integration verification.
     - **Acceptance Criteria**: Verification checklist.
     - **Out of Scope**: Vendored `textplots`/`drawille` updates, new features.
   - `<track_dir>/plan.md`:
     - Phased per `nu_plugin_plot/conductor/workflow.md` (TDD).
     - **Phase 1**: Cargo.toml version updates & clean build
     - **Phase 2**: Breaking fix implementation (source code adaptations)
     - **Phase 3**: Test suite updates & verification
     - **Phase 4**: Integration testing with Nushell binary
     - **Phase 5**: tech-stack.md & documentation updates
     - **Every Phase** must terminate with: `- [ ] Task: Conductor - User Manual Verification '<Phase Name>' (Protocol in workflow.md)`
     - The plan MUST instruct the implementer to read the track's `howto.md` before starting.
   - `<track_dir>/howto.md`:
     - Step-by-step guide generated from `references/howto_nu_plugin_plot_migration.md` (see Step 6), adapted to the concrete version delta and identified breaking changes.
   - `<track_dir>/index.md`:
     ```markdown
     # Track <plugin_track_id> Context

     - [Specification](./spec.md)
     - [Implementation Plan](./plan.md)
     - [Metadata](./metadata.json)
     - [How-To Guide](./howto.md)
     ```

4. **Create DataScienceAtNushell Track Artifacts** (`/home/username/cloud/Documentos/Clases/WORK/DataScienceAtNushell/conductor/tracks/<ds_track_id>/`):
   - `<track_dir>/metadata.json`:
     ```json
     {
       "track_id": "<ds_track_id>",
       "type": "feature",
       "status": "new",
       "created_at": "<ISO8601_TIMESTAMP>",
       "updated_at": "<ISO8601_TIMESTAMP>",
       "description": "Nushell v<version> upgrade: container toolchain, 3-edition markdown modernization, documentation sync, PDF compilation, GHCR push, and clean public release"
     }
     ```
   - `<track_dir>/spec.md`:
     - **Overview**: Target Nushell version and curriculum adaptation summary.
     - **Functional Requirements**: Docker upgrade (`ARG NUSHELL_VERSION`), automated build audit (`update-dsin-nushell.nu`), English/Spanish/WORK markdown modernization, XML syntax highlighting (`Files/*.xml`), documentation & agent instructions sync (`GEMINI.md`, `AGENTS.md`, `CLAUDE.md`, `README*.md`), XeLaTeX PDF compilation (`compile_books.nu`), container registry release (GHCR), and clean public release (`main` branch sync via `test_public_sanitization.nu`, Git tagging `v<version>`, and GitHub Release with PDFs attached).
     - **Acceptance Criteria**: Verification checklist and BDD scenarios.
   - `<track_dir>/plan.md`:
     - Phased 7-Phase structure per `references/howto_datascience_at_nushell_migration.md`.
     - **Phase 1**: Environment & Container Toolchain Upgrade (TDD & Build)
     - **Phase 2**: Chapter Modernization in English Edition (`Files/DataScienceNushell.md`)
     - **Phase 3**: Chapter Modernization in Spanish & WORK Editions (`Files/DataScienceNushell.es.md` & `Files/DataScienceNushell_work.md`)
     - **Phase 4**: Downstream Curriculum Audit & Behavior Change Sweep
     - **Phase 5**: Documentation, Tech Stack & Instruction Alignment
     - **Phase 6**: Multi-Edition PDF Compilation & Full Test Verification
     - **Phase 7**: Public Synchronization, Container Registry Push & GitHub Release
     - **Every Phase** must terminate with: `- [ ] Task: Conductor - User Manual Verification '<Phase Name>' (Protocol in workflow.md)`
   - `<track_dir>/howto.md`:
     - Step-by-step guide generated from `references/howto_datascience_at_nushell_migration.md` (see Step 7), adapted to the concrete version delta and identified curriculum changes.
   - `<track_dir>/index.md`:
     ```markdown
     # Track <ds_track_id> Context

     - [Specification](./spec.md)
     - [Implementation Plan](./plan.md)
     - [Metadata](./metadata.json)
     - [How-To Guide](./howto.md)
     ```

5. **Register Tracks**:
   - Main Track: Append to `llms_configs/conductor/tracks.md`:
     ```markdown

     ---

     - [ ] **Track: Nushell v<version> upgrade migration: breaking fixes, command improvements/deprecations, styleguides, and nushell-expert skill update**
     *Link: [./tracks/<main_track_id>/](./tracks/<main_track_id>/)*
     ```
   - Plugin Track: Append to `nu_plugin_plot/conductor/tracks.md`:
     ```markdown

     ---

     - [ ] **Track: Bump Nushell dependencies to v<version>**
     *Link: [./tracks/<plugin_track_id>/](./tracks/<plugin_track_id>/)*
     ```
   - DataScience Track: Append to `DataScienceAtNushell/conductor/tracks.md`:
     ```markdown

     ---

     - [ ] **Track: Nushell v<version> toolchain upgrade, curriculum modernization, and container release**
     *Link: [./tracks/<ds_track_id>/](./tracks/<ds_track_id>/)*
     ```

6. **Commit Track Files**:
   - Main Repo: Stage `<workspace>/conductor/tracks/<main_track_id>/` and `conductor/tracks.md`.
     - Commit with message: `chore: initialize track '<main_track_id>'` (never use `(conductor)` or other AI-identifying labels).
   - Plugin Repo: Stage `nu_plugin_plot/conductor/tracks/<plugin_track_id>/` and `conductor/tracks.md`.
     - Commit with message: `chore: initialize track '<plugin_track_id>'` (never use `(conductor)` or other AI-identifying labels).
   - DataScience Repo: Stage `DataScienceAtNushell/conductor/tracks/<ds_track_id>/` and `conductor/tracks.md`.
     - Commit on `private`: `chore: initialize track '<ds_track_id>'` (never use `(conductor)` or other AI-identifying labels).

7. **Push Plugin Track to Remote**:
   - In the `nu_plugin_plot` repo, pull/rebase and push the track commit to the remote origin:
     ```bash
     git pull --rebase origin main
     git push origin main
     ```

8. **Announce Completion**:
   - Inform the user that the migration track(s) are ready, summarize the high-level impact (number of breaking changes, deprecations, and modernization candidates identified; the `nu_plugin_plot` and `DataScienceAtNushell` impact decisions), and instruct them to run `/conductor-implement` once they are ready to apply the migration.

---

### Step 6: Plugin Track How-To Generation

Generate the plugin track's `howto.md` by adapting the reference file `references/howto_nu_plugin_plot_migration.md` to the concrete version delta and the identified breaking changes from Step 2.5:

1. Read `references/howto_nu_plugin_plot_migration.md`.
2. Replace the placeholder Nushell version (`0.XXX.0`) with the target version from the release notes.
3. Inject the concrete adaptation tasks from the Step 2.5 audit into the "Breaking Fix Implementation" section.
4. Keep the integration testing, documentation update, remote push, and `cargo clean` sections unchanged.
5. Write the adapted content to `<plugin_track_dir>/howto.md`.

---

### Step 7: DataScienceAtNushell Track How-To Generation

Generate `<ds_track_dir>/howto.md` by adapting `references/howto_datascience_at_nushell_migration.md` to the concrete version delta and curriculum changes from Step 2.6:

1. Read `references/howto_datascience_at_nushell_migration.md`.
2. Replace `0.XXX.0` with the target Nushell version from the release notes.
3. Inject concrete codeblock examples and affected chapters from the Step 2.6 audit into Phase 2 (English), Phase 3 (Spanish/WORK), and Phase 4 (Downstream sweep).
4. Preserve container toolchain commands, PDF compilation instructions, and dual-branch sanitization / GitHub Release sequences intact.
5. Write the adapted content to `<ds_track_dir>/howto.md`.

**Note**: The `references/` directory lives at `skills/nushell-update-evaluator/references/` (symlinked to `~/.agents/skills/nushell-update-evaluator/references/`).
