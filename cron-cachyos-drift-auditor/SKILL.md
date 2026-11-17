---
name: cron-cachyos-drift-auditor
description: Audits local CachyOS package drift against /home/username/workspace/Backups/linux/conductor/package_lists.json using pacman and aconfmgr, generating reviewable drafts in Obsidian AGENTS_MEMORY/_drafts_drifts with approval checkboxes and applying approved changes.
---

# cron-cachyos-drift-auditor

## Overview
`cron-cachyos-drift-auditor` is an autonomous system audit and drift reconciliation skill designed for Arch/CachyOS systems. It bridges the gap between active package installations on the host and the declarative package lists maintained in `/home/username/workspace/Backups/linux/conductor/package_lists.json`.

To ensure maximum safety and non-destructive operation, this skill enforces a **two-phase Draft & Approve lifecycle**:
1. **Audit & Propose**: When system drift is discovered, the skill never directly modifies production configuration files. Instead, it generates a dated Markdown draft in `/home/username/workspace/obsidian/vaults/AGENTS_MEMORY/_drafts_drifts/YYYY-MM-DD.md` containing individual `- [ ] Approved` and `- [ ] Not Approved` checkboxes for each proposed addition, removal, or cross-machine shared package move. A companion Habitica todo is dispatched under the tag `software-updates-(host)` to alert the user.
2. **Review & Apply**: On subsequent executions (or on-demand), the skill inspects pending review drafts. Any items checked `- [x] Approved` are merged into `/home/username/workspace/Backups/linux/conductor/package_lists.json` with strict alphabetical sorting and deduplication, preserving the `{ shared, hosts }` schema, and committed to `/home/username/workspace/Backups/linux`. Items marked `- [x] Not Approved` are saved into `rejected_drift.json` so they are never flagged again. Once all items in a draft are resolved, the draft is marked `implemented: true` and archived to `/home/username/workspace/obsidian/vaults/AGENTS_MEMORY/_drafts_drifts/processed_drafts/`.
3. **Cross-Machine Shared Analysis**: Analyzes declarative package listings across ALL recorded hosts in `package_lists.json.hosts`. Packages present in every host's list but absent from `shared` are proposed under Section 4: "Proposed Move to Shared Items". Approving a move appends it to `shared` and strips it from every host list, deduplicating the configuration across machines.

## Target Environment & Execution
- **Target Host**: Dynamically detected local Arch/CachyOS host via `sys host | get hostname`.
- **Execution Context**: Local execution directly on the CachyOS machine.

## Directory Structure
```
skills/cron-cachyos-drift-auditor/
├── SKILL.md                          # Skill definition and operational guide
├── mod.nu                            # Main entrypoint and orchestrator module
├── rejected_drift.json               # Registry of intentionally suppressed packages and configs
└── scripts/
    ├── audit.nu                      # Local package drift enumeration & cross-machine candidate analysis
    ├── draft_generator.nu            # Markdown draft formatter (including Section 4 Move to Shared) and Habitica dispatcher
    └── apply_approved.nu             # Schema-aware checkbox parser, package_lists updater, and draft archiver
```

## CLI Usage

### 1. Perform Dry-Run Audit
Inspect current system drift and preview the generated review draft without writing to disk or notifying Habitica:
```nu
use skills/cron-cachyos-drift-auditor/mod.nu *
audit-cachyos-drift --dry-run
```

### 2. Standard Autonomous Execution
Run the full lifecycle: process existing drafts, detect new drift, detect cross-machine shared candidates, generate draft, and dispatch Habitica todo:
```nu
use skills/cron-cachyos-drift-auditor/mod.nu *
audit-cachyos-drift
```

### 3. Commit Approved Changes to Git
Process approved items and commit the updated `package_lists.json` to the `/home/username/workspace/Backups/linux` Git repository:
```nu
use skills/cron-cachyos-drift-auditor/mod.nu *
audit-cachyos-drift --git-commit
```

### 4. Force Regenerate Today's Draft
Re-audit the system and overwrite an existing un-implemented draft for the current day:
```nu
use skills/cron-cachyos-drift-auditor/mod.nu *
audit-cachyos-drift --force
```

## Review Workflow for Users
1. Open the pending draft file in `/home/username/workspace/obsidian/vaults/AGENTS_MEMORY/_drafts_drifts/YYYY-MM-DD.md`.
2. For each package or file, check the appropriate decision box:
   - `- [x] Approved`: Applies the addition/removal/move to `/home/username/workspace/Backups/linux/conductor/package_lists.json` preserving the `{ shared, hosts }` structure.
   - `- [x] Not Approved`: Rejects the change and adds the package to `rejected_drift.json` to suppress it permanently.
3. On the next execution (or when running `audit-cachyos-drift`), the approvals will be automatically committed and the draft archived.
