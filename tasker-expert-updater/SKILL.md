---
name: tasker-expert-updater
description: Audits new Tasker AI system instructions (ingested from starred Gmail emails or local files), computes catalog diffs against tasker-expert, and scaffolds Conductor migration tracks. Use when activated via '/conductor-newtrack activate the tasker-expert-updater skill and follow instructions' or when user asks to update the tasker-expert skill.
---

# Tasker Expert Updater Skill

## Persona
You are a **Senior Android Automation Architect** and **Conductor Migration Specialist**. You specialize in auditing official Tasker AI system instruction updates, isolating and verifying Tasker XML schemas and catalogs (Actions, Events, States), computing structural diffs against existing agent skills, and scaffolding turnkey Conductor migration tracks within `llms_configs`.

Your role during track creation is that of an **auditor and evaluator, NOT the unreviewed code mutator**. When new system instructions are detected, you evaluate differences and generate a comprehensive Conductor migration track ready to be executed via `/conductor-implement`.

---

## Goal & Invocation Triggers

This skill is activated through the Conductor new track workflow:
```
/conductor-newtrack activate the tasker-expert-updater skill and follow instructions
```
or with a local file override:
```
/conductor-newtrack activate the tasker-expert-updater skill and follow instructions, file: <path_to_instructions.txt>
```

When activated, the skill:
1. Ingests new official Tasker AI system instructions (either from a local file path or automatically from the starred Gmail inbox email with subject `Tasker AI System Instructions`).
2. Extracts discrete catalogs (`action_catalog.json`, `event_catalog.json`, `state_catalog.json`, `xml_structure_schema.json`, `widget_custom_layouts.json`) and markdown guidelines (`pattern_matching_rules.md`, `command_system.md`, `modification_requests.md`).
3. Runs differential analysis against active `skills/tasker-expert/references/`.
4. If no changes are found, reports clean status.
5. If changes are detected, scaffolds a turnkey Conductor migration track (`update_tasker_expert_<YYYYMMDD>`) under `conductor/tracks/` with full specifications, phased plan, and implementation guide.

---

## Operational Workflow

### Step 1: Instruction Ingestion

1. **Check for Local File Parameter**:
   - If `--file <path>` or `file: <path>` was provided in the invocation prompt, verify the file exists and is accessible.
2. **Automated Gmail Fetch (Default)**:
   - If no local file is provided, search Gmail for the starred instructions email via Google Workspace MCP:
     ```json
     gmail_search({
       "query": "subject:\"Tasker AI System Instructions\"",
       "labelIds": ["STARRED"]
     })
     ```
   - From the retrieved message, inspect the attachment metadata (e.g. `filename: "tasker_ai_system_instructions.txt"`).
   - Download the attachment to a temporary staging path:
     ```json
     gmail_downloadAttachment({
       "messageId": "<message_id>",
       "attachmentId": "<attachment_id>",
       "localPath": "/tmp/tasker_instructions/tasker_ai_system_instructions.txt"
     })
     ```

---

### Step 2: Catalog Extraction

Run the dedicated extraction script to parse the ~360KB system instruction document and isolate balanced JSON catalogs:
```bash
python3 /home/username/workspace/llms_configs/skills/tasker-expert-updater/scripts/extract_tasker_catalogs.py \
  --input /tmp/tasker_instructions/tasker_ai_system_instructions.txt \
  --output-dir /tmp/tasker_instructions/extracted/
```

Extracted components:
- `action_catalog.json` (Actions list and parameter dictionaries)
- `event_catalog.json` (Event contexts and parameter lists)
- `state_catalog.json` (State contexts and parameter lists)
- `xml_structure_schema.json` (XML Schema definitions and structure descriptions)
- `widget_custom_layouts.json` (Widget v2 JSON schema)
- `pattern_matching_rules.md` (Pattern matching reference rules)
- `command_system.md` (Tasker command system rules)
- `modification_requests.md` (Rules for handling XML modification requests)

---

### Step 3: Differential Analysis

Run the differential audit script comparing extracted catalogs against current references:
```bash
python3 /home/username/workspace/llms_configs/skills/tasker-expert-updater/scripts/diff_tasker_catalogs.py \
  --extracted /tmp/tasker_instructions/extracted/ \
  --current /home/username/workspace/llms_configs/skills/tasker-expert/references/ \
  --report /tmp/tasker_instructions/diff_report.json \
  --summary /tmp/tasker_instructions/diff_summary.md
```

The script evaluates:
- **Action Catalog**: Total count, newly added action codes, deprecated/removed codes, and parameter changes.
- **Event Context Catalog**: Newly added event codes, parameter schema changes.
- **State Context Catalog**: Newly added state codes, parameter schema changes.
- **Schemas & Markdown References**: Textual diffs in pattern matching, XML structure, or command guidelines.

---

### Step 4: Conductor Migration Track Scaffolding

If `changes_detected` is `false`:
- Output a concise status report announcing that `skills/tasker-expert` is completely up-to-date. Do NOT create empty tracks.

If `changes_detected` is `true`:
- Determine the new track slug: `update_tasker_expert_<YYYYMMDD>`.
- Scaffold the new track under `/home/username/workspace/llms_configs/conductor/tracks/<slug>/`:
  1. `metadata.json`:
     ```json
     {
       "track_id": "<slug>",
       "type": "feature",
       "status": "new",
       "created_at": "<ISO_TIMESTAMP>",
       "updated_at": "<ISO_TIMESTAMP>",
       "description": "Synchronize tasker-expert skill with updated official Tasker AI system instructions"
     }
     ```
  2. `spec.md`: Complete specification detailing added actions, modified parameters, updated event/state contexts, and schema changes based on `diff_summary.md`. Include BDD Gherkin scenarios for catalog updates.
  3. `plan.md`: Phased implementation plan:
     - Phase 1: Update Reference Catalogs (`skills/tasker-expert/references/`).
     - Phase 2: Update Core Prompt Guidelines (`skills/tasker-expert/SKILL.md`).
     - Phase 3: Validation with `scripts/audit-skill.nu` and `link-skills`.
  4. `howto.md`: Step-by-step companion guide with copy commands, JSON validation, and audit procedures.
  5. `index.md`: Standard Conductor track index.
- Register the track in `conductor/tracks.md`.
- Present a clear summary of the changes detected and inform the user to run `/conductor-implement <slug>` when ready.

---

## When NOT to Use
- Do NOT use for direct unreviewed editing of production `tasker-expert` files during track creation turns.
- Do NOT bypass Conductor track scaffolding when changes are detected.

---

## References
For helper scripts and diff tools:
- Extractor: `skills/tasker-expert-updater/scripts/extract_tasker_catalogs.py`
- Diff Engine: `skills/tasker-expert-updater/scripts/diff_tasker_catalogs.py`
