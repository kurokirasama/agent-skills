#!/usr/bin/env python3
"""
scaffold_tasker_migration.py - Generates a turnkey Conductor migration track
when Tasker AI system instruction updates are detected.
"""

import argparse
from datetime import datetime
import json
import os


def scaffold_migration(report_path, extracted_dir, workspace_root, track_slug=None):
    with open(report_path, "r", encoding="utf-8") as f:
        report = json.load(f)

    if not report.get("changes_detected"):
        print("Clean status: No Tasker AI instruction changes detected. No track scaffolded.")
        return None

    today_str = datetime.now().strftime("%Y%m%d")
    slug = track_slug or f"update_tasker_expert_{today_str}"
    track_dir = os.path.join(workspace_root, "conductor", "tracks", slug)
    os.makedirs(track_dir, exist_ok=True)

    iso_now = datetime.now().astimezone().isoformat()

    # 1. metadata.json
    metadata = {
        "track_id": slug,
        "type": "feature",
        "status": "new",
        "created_at": iso_now,
        "updated_at": iso_now,
        "description": "Synchronize tasker-expert skill with updated official Tasker AI system instructions"
    }
    with open(os.path.join(track_dir, "metadata.json"), "w", encoding="utf-8") as f:
        json.dump(metadata, f, indent=2)

    # 2. spec.md
    act = report.get("actions", {})
    evt = report.get("events", {})
    st = report.get("states", {})

    spec_lines = [
        f"# Specification: Update Tasker Expert Skill (`{slug}`)\n",
        "## Overview",
        "Official Tasker AI system instructions have been updated with new actions, parameter changes, and schema adjustments. This track updates `skills/tasker-expert/` and its `references/` to ensure the skill maintains 100% fidelity to the latest Tasker specification.\n",
        "## Detected Catalog Changes",
        f"- **Action Catalog**: Total {act.get('extracted_total', 0)} actions (formerly {act.get('current_total', 0)})."
    ]
    if act.get("added"):
        spec_lines.append(f"  - **Added Actions ({len(act['added'])}):**")
        for a in act["added"]:
            spec_lines.append(f"    - Action `{a['code']}`: **{a['name']}** ({a['params_count']} parameters)")
    if act.get("modified"):
        spec_lines.append(f"  - **Modified Actions ({len(act['modified'])}):**")
        for m in act["modified"]:
            spec_lines.append(f"    - Action `{m['code']}`: **{m['name']}** ({', '.join(m['changes'])})")

    if evt.get("added"):
        spec_lines.append(f"- **Event Context Catalog**: {len(evt['added'])} added events.")
        for e in evt["added"]:
            spec_lines.append(f"  - Event `{e['code']}`: **{e['name']}**")

    if st.get("added"):
        spec_lines.append(f"- **State Context Catalog**: {len(st['added'])} added states.")
        for s in st["added"]:
            spec_lines.append(f"  - State `{s['code']}`: **{s['name']}**")
    if st.get("modified"):
        spec_lines.append(f"- **State Context Catalog**: {len(st['modified'])} modified states.")
        for m in st["modified"]:
            spec_lines.append(f"  - State `{m['code']}`: **{m['name']}** ({', '.join(m.get('changes', []))})")

    spec_lines.extend([
        "\n## Functional Requirements",
        "- **FR-1**: Copy updated JSON catalogs (`action_catalog.json`, `event_catalog.json`, `state_catalog.json`, `xml_structure_schema.json`, `widget_custom_layouts.json`) from extraction staging into `skills/tasker-expert/references/`.",
        "- **FR-2**: Synchronize markdown reference documents (`pattern_matching_rules.md`, `command_system.md`, `modification_requests.md`).",
        "- **FR-3**: Audit `skills/tasker-expert/SKILL.md` to ensure any prompt rule additions or dialog output variable updates are reflected.",
        "- **FR-4**: Validate skill integrity with `scripts/audit-skill.nu skills/tasker-expert` and verify `link-skills`.\n",
        "## BDD Acceptance Criteria",
        "```gherkin",
        "Scenario: Synchronize Tasker Expert Reference Catalogs",
        "  Given extracted Tasker catalogs from the latest official instructions",
        "  When catalogs are copied into skills/tasker-expert/references/",
        "  Then action_catalog.json contains all added and modified action codes",
        "  And event_catalog.json and state_catalog.json match the official catalog counts",
        "",
        "Scenario: Verify Tasker Expert Skill Quality",
        "  Given updated skill references and SKILL.md",
        "  When audit-skill.nu is executed on skills/tasker-expert",
        "  Then the validation passes with zero errors",
        "```"
    ])

    with open(os.path.join(track_dir, "spec.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(spec_lines) + "\n")

    # 3. plan.md
    plan_lines = [
        f"# Implementation Plan: Update Tasker Expert Skill (`{slug}`)\n",
        "## Phase 1: Reference Catalogs & Document Synchronization",
        "- [ ] Task 1.1: Copy Extracted JSON Catalogs into `skills/tasker-expert/references/`",
        "- [ ] Task 1.2: Synchronize Markdown Rules & XML Schemas",
        "- [ ] Task 1.3: Conductor - User Manual Verification 'Phase 1: Catalog Synchronization' (Protocol in workflow.md)\n",
        "## Phase 2: SKILL.md Prompts & Guidelines Update",
        "- [ ] Task 2.1: Audit and Update `skills/tasker-expert/SKILL.md` with new action semantics and output variables",
        "- [ ] Task 2.2: Conductor - User Manual Verification 'Phase 2: SKILL.md Prompts & Guidelines' (Protocol in workflow.md)\n",
        "## Phase 3: Verification & Registration",
        "- [ ] Task 3.1: Execute `scripts/audit-skill.nu skills/tasker-expert`",
        "- [ ] Task 3.2: Run `link-skills`",
        "- [ ] Task 3.3: Conductor - User Manual Verification 'Phase 3: Verification & Registration' (Protocol in workflow.md)"
    ]
    with open(os.path.join(track_dir, "plan.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(plan_lines) + "\n")

    # 4. howto.md
    howto_lines = [
        "> **Starting point, not a contract.** Adapt, improve, or replace this guide as you learn during implementation; update it whenever you diverge.\n",
        f"# Implementation Guide: Update Tasker Expert Skill (`{slug}`)\n",
        "## Step 1: Copy Staged Catalogs",
        "```bash",
        f"cp {extracted_dir}/*.json skills/tasker-expert/references/",
        f"cp {extracted_dir}/*.md skills/tasker-expert/references/",
        "```\n",
        "## Step 2: Audit and Link",
        "```nu",
        "nu scripts/audit-skill.nu skills/tasker-expert",
        "link-skills",
        "```"
    ]
    with open(os.path.join(track_dir, "howto.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(howto_lines) + "\n")

    # 5. index.md
    index_lines = [
        "# Track: Update Tasker Expert Skill\n",
        f"- **Track ID**: `{slug}`",
        "- **Type**: Feature",
        "- **Status**: New\n",
        "## Documents",
        "- [Specification](./spec.md)",
        "- [Implementation Plan](./plan.md)",
        "- [Implementation Guide](./howto.md)",
        "- [Metadata](./metadata.json)"
    ]
    with open(os.path.join(track_dir, "index.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(index_lines) + "\n")

    # 6. Register in conductor/tracks.md
    tracks_md_path = os.path.join(workspace_root, "conductor", "tracks.md")
    if os.path.isfile(tracks_md_path):
        with open(tracks_md_path, "r", encoding="utf-8") as f:
            content = f.read()
        entry = f"\n- [ ] **Track: Synchronize tasker-expert skill with updated official Tasker AI system instructions**\n  *Link: [./tracks/{slug}/](./tracks/{slug}/)*\n"
        if slug not in content:
            with open(tracks_md_path, "a", encoding="utf-8") as f:
                f.write(entry)

    print(f"Turnkey migration track scaffolded successfully under {track_dir}")
    return slug


def main():
    parser = argparse.ArgumentParser(description="Scaffold Conductor migration track from Tasker diff report.")
    parser.add_argument("--report", "-r", required=True, help="Path to diff_report.json")
    parser.add_argument("--extracted", "-e", required=True, help="Path to extracted catalogs directory")
    parser.add_argument("--workspace", "-w", default=".", help="Project workspace root")
    parser.add_argument("--slug", "-s", help="Custom track slug")
    args = parser.parse_args()

    scaffold_migration(args.report, args.extracted, args.workspace, args.slug)


if __name__ == "__main__":
    main()
