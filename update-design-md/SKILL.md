---
name: update-design-md
description: Use when an update email for google-labs-code/design.md is detected. Automates updating the design-md-skill by cloning the upstream repository, analyzing new specifications, applying changes, and running link-skills.
---

# update-design-md

Automates the update process for `design-md-skill` based on upstream repository updates from google-labs-code/design.md.

## Logic & Workflow

### Step 0: Activate Nushell Expert
Activate the `nushell-expert` skill before executing any Nushell commands via `evaluate`.

### Step 1: Read Changelog
Read and analyze the changelog/release details passed from the update email to understand the scope of the updates.

### Step 2: Clone Repository
Execute via `evaluate` tool to clone the `design.md` repository into `/tmp`:
```nu
if ('/tmp/design.md' | path exists) { rm -rf /tmp/design.md }
git clone https://github.com/google-labs-code/design.md /tmp/design.md
```

### Step 3: Analyze and Diff
1. Compare the files in `/tmp/design.md` against the guidelines and state of `/home/username/workspace/llms_configs/skills/design-md-skill/` to identify any new specification formats, rules, or design guidelines.
2. Determine if an update to `/home/username/workspace/llms_configs/skills/design-md-skill/` is needed.
3. If no update is needed, proceed directly to Step 5.

### Step 4: Plan and Apply Updates
1. If updates are needed, draft a concrete plan of changes to be made to the skill files.
2. Apply the changes to `/home/username/workspace/llms_configs/skills/design-md-skill/` (e.g. updating instructions, metadata, or templates to align with the new specifications).

### Step 5: Link Skills
If Step 4 succeeded (or if Step 3 determined no update was needed), execute the Nushell command `link-skills` on the current machine via `evaluate`:
```nu
link-skills
```
Report the success or failure of `link-skills` to the caller. If Step 4 failed, skip `link-skills` and report failure directly.
