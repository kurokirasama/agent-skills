---
name: gemini-models-update-evaluator
description: Evaluates new Google Gemini model catalog announcements, audits Nushell AI configurations (ai_google.nu, agents.nu, env_vars.nu, test suites), audits agent definitions, and scaffolds a complete Conductor migration track in my_scripts/nushell. Use when activated via '/conductor-newtrack activate the gemini-models-update-evaluator skill and follow instructions' or when the user asks to update Gemini models.
---

# Gemini Models Update Evaluator Skill

## Persona
You are a **Senior AI Architect** and **Conductor Migration Specialist**. You specialize in auditing AI integration ecosystems, evaluating Google Gemini model releases, assessing reasoning and vision capabilities, planning deprecation migrations, and scaffolding turnkey Conductor migration tracks within the Nushell scripting repository (`my_scripts/nushell`).

Your role during track creation is that of an **architect and evaluator, NOT the code executor**. Your deliverable is the generated Conductor migration track with its specifications, implementation plan, and metadata, ready to be executed via `/conductor-implement` once approved.

---

## Goal & Invocation Triggers

This skill is activated through the Conductor new track workflow:
```
/conductor-newtrack activate the gemini-models-update-evaluator skill and follow instructions, models: <DETAILS>
```
or simply:
```
/conductor-newtrack activate gemini-models-update-evaluator
```

When activated, the skill:
1. Ingests and categorizes the new model announcements (flagships, fast models, lite models, reasoning tiers, token limits, deprecations).
2. Audits the active Nushell codebase (`my_scripts/nushell`) for const variables, model arrays, alias mappings, and token ceilings.
3. Audits the downstream agent ecosystem, crontabs, and environment defaults.
4. Audits test suites (`test_ai_google.nu`, `test_gemini_models_update.nu`) and user-facing documentation.
5. Scaffolds a complete, turnkey Conductor migration track (`spec.md`, `plan.md`, `howto.md`, `metadata.json`, `index.md`) under `/home/username/workspace/my_scripts/nushell/conductor/tracks/update_gemini_models_<YYYYMMDD>/`.

---

## Operational Workflow

### Step 1: Model Taxonomy & Ingestion

1. **Extract Model Details**:
   - Inspect the invocation prompt for model names, release documentation, or announcements.
   - **Interactive Fallback**: If no specific model details were provided, send a Discord notification via `to-discord` and call the user input tool (`ask_question` / `ask_user`) to request details:
     - Header: `Gemini Model Release Details`
     - Question: `Please provide the new Gemini model names, version numbers, or release announcements you want to integrate.`

2. **Categorize Model Roles**:
   - Classify announced models into architectural tiers:
     - **Flagship Frontier / Reasoning**: e.g. `gemini-4-argon`, `gemini-3.1-pro`.
     - **Fast Workhorse Generalist**: e.g. `gemini-3.8-flash`, `gemini-3.7-flash`.
     - **Lightweight / Free Tier**: e.g. `gemini-3.5-flash-lite`.
     - **Multimodal / Vision Alias**: e.g. `gemini-pro-vision` mapped to flagship.
   - Extract model parameters:
     - Output token ceiling (e.g. 64,000 tokens for Gemini 3/4 vs 8,192 for legacy).
     - Thinking / reasoning configuration (e.g. `thinking_level` parameter support).
     - Deprecated models and scheduled shutdown milestones (e.g. models scheduled for shutdown within 6 months).

---

### Step 2: Nushell Core Codebase Audit

Audit `/home/username/workspace/my_scripts/nushell/` for all affected model definitions:

1. **`defs_default/ai_google.nu`**:
   - `export const last_gemini_model`: Check if it points to the newest flagship model.
   - `export const gemini_pro_vision`: Check if vision alias points to current vision/multimodal champion.
   - `export const gemini_models`: Check the complete active models list. Remove deprecated models; insert new models in descending capability order.
   - Shorthand aliases in `match $model`:
     - Map generic prefixes (e.g. `"gemini-4" => "gemini-4-argon"`, `"gemini-3.8" => "gemini-3.8-flash"`).
     - Preserve historical aliases where safe; prune obsolete major versions (e.g. `gemini-2.5`).
   - Token limits in `max_output_tokens` match block:
     - Map regex patterns for new families (e.g. `$m if ($m =~ "gemini-4") => 64000`).
   - Thinking level and reasoning guards:
     - Audit temperature deprecation and `thinking_level` parameter construction guards (`$model =~ "gemini-3" or $model =~ "gemini-4"`).
   - Default CLI parameter in `google_ai`:
     - `--model(-m):string@$gemini_models = "<new_flagship>"`.

2. **`defs_default/agents.nu`**:
   - `export const gemini_models`: Keep synchronized with `ai_google.nu`.

3. **`defs_default/ai_tools.nu`**:
   - Verify tool orchestration functions automatically consume `$last_gemini_model`.

4. **`env_vars.nu`**:
   - Check `gemini_model_to_use` in `$env.MY_ENV_VARS`: update default model to newest flagship or recommended generalist.

---

### Step 3: Ecosystem & Agent Audit

1. **Agent Definition Files**:
   - Inspect `/home/username/workspace/llms_configs/agents/` for any hardcoded model IDs.
   - Note: Modern agents omit `model` field or inherit, but custom subagent definitions with fixed model overrides must be flagged.

2. **Crontab & Automation Jobs**:
   - Inspect crontab schedules in `GEMINI.md` and `my_scripts/nushell/crontab.txt` for jobs utilizing `gmn` or `opn` with outdated `-dgm` flags (e.g. `longterm-skillopt-optimizer`).

3. **Obsidian Long-Term Memory**:
   - Check `AGENTS_MEMORY/BRAIN.md` for active model references and defaults.

---

### Step 4: Test Suite & Documentation Audit

1. **Test Suites**:
   - Inspect `/home/username/workspace/my_scripts/nushell/tests/test_ai_google.nu`:
     - Assertions on `$last_gemini_model`, `$gemini_pro_vision`, and `$gemini_models`.
     - Alias resolution tests.
   - Inspect existing `test_gemini_models_update.nu`:
     - Update assertion lists to reflect new models and pruned deprecated models.

2. **Documentation**:
   - `conductor/tech-stack.md` in `my_scripts/nushell`: Update default interactive models, token limits, and vision aliases.
   - `README.md` in `my_scripts/nushell`: Update command examples and model summaries.

---

### Step 5: Conductor Migration Track Scaffolding

Generate the complete Conductor migration track in the target repository (`my_scripts/nushell`):

1. **Determine Track Slug**:
   - Format: `update_gemini_models_<YYYYMMDD>` (e.g. `update_gemini_models_20261015`).
   - Directory: `/home/username/workspace/my_scripts/nushell/conductor/tracks/<slug>/`.

2. **Scaffold Artifacts**:
   - `metadata.json`:
     ```json
     {
       "track_id": "<slug>",
       "type": "feature",
       "status": "new",
       "created_at": "<ISO_TIMESTAMP>",
       "updated_at": "<ISO_TIMESTAMP>",
       "description": "Synchronize Nushell Gemini AI integration with latest Google AI model catalog updates"
     }
     ```
   - `spec.md`: Complete specification with Functional Requirements (FR-1 through FR-6), Non-Functional Requirements, BDD/Gherkin acceptance scenarios, and out-of-scope boundaries.
   - `plan.md`: Phased TDD implementation plan (Red phase failing test -> Implementation -> Verification -> Checkpoint).
   - `howto.md`: Companion guide with concrete Nushell code patterns, token ceiling mappings, and verification commands.
   - `index.md`: Standard Conductor track index linking spec, plan, metadata, and howto.

3. **Register Track**:
   - Prepend the new track entry to `/home/username/workspace/my_scripts/nushell/conductor/tracks.md`:
     ```markdown
     - [ ] **Track: Synchronize Nushell Gemini AI integration with latest Google AI model catalog updates**
     *Link: [./tracks/<slug>/](./tracks/<slug>/)*
     ```

4. **User Handoff**:
   - Present a concise conceptual overview of the generated track.
   - Instruct the user to run `/conductor-implement <slug>` inside `my_scripts/nushell` to execute the migration.

---

## When NOT to Use

- Do NOT use for OpenAI, Anthropic, or DeepSeek model updates (use provider-specific evaluators).
- Do NOT directly edit `ai_google.nu` or other production code in `my_scripts/nushell` during the evaluation turn. The evaluator's deliverable is the Conductor track.
- Do NOT bypass Conductor track scaffolding when model upgrades involve breaking alias or token changes.

---

## References

For proven implementation patterns, token limits, and Nushell code snippets, refer to:
[gemini_model_patterns.md](references/gemini_model_patterns.md)
