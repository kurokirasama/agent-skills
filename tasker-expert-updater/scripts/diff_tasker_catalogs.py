#!/usr/bin/env python3
"""
diff_tasker_catalogs.py - Computes structural diffs between extracted Tasker catalogs
and the current tasker-expert skill references.
"""

import argparse
import difflib
import json
import os


def load_json_safe(path):
    if not os.path.isfile(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, ValueError):
        # Fallback for JSONC or non-standard json
        with open(path, "r", encoding="utf-8") as f:
            return f.read()


def diff_action_catalog(current_data, extracted_data):
    if not current_data or not extracted_data:
        return {"status": "missing_data"}

    curr_actions = current_data.get("a", current_data) if isinstance(current_data, dict) else current_data
    extr_actions = extracted_data.get("a", extracted_data) if isinstance(extracted_data, dict) else extracted_data

    if not isinstance(curr_actions, list) or not isinstance(extr_actions, list):
        return {"status": "unsupported_format"}

    curr_map = {item.get("c"): item for item in curr_actions if isinstance(item, dict) and "c" in item}
    extr_map = {item.get("c"): item for item in extr_actions if isinstance(item, dict) and "c" in item}

    added = []
    removed = []
    modified = []

    for code, item in extr_map.items():
        if code not in curr_map:
            added.append({
                "code": code,
                "name": item.get("n", "Unknown"),
                "params_count": len(item.get("p", {}).get("p", []))
            })
        else:
            old_item = curr_map[code]
            # Compare parameters
            old_params = old_item.get("p", {}).get("p", [])
            new_params = item.get("p", {}).get("p", [])
            changes = []
            if old_item.get("n") != item.get("n"):
                changes.append(f"Name: '{old_item.get('n')}' -> '{item.get('n')}'")
            if len(old_params) != len(new_params):
                old_names = [p.get("m", f"arg{idx}") for idx, p in enumerate(old_params)]
                new_names = [p.get("m", f"arg{idx}") for idx, p in enumerate(new_params)]
                added_p = [n for n in new_names if n not in old_names]
                removed_p = [n for n in old_names if n not in new_names]
                ch_desc = f"Params count: {len(old_params)} -> {len(new_params)}"
                if added_p:
                    ch_desc += f" (added: {', '.join(added_p)})"
                if removed_p:
                    ch_desc += f" (removed: {', '.join(removed_p)})"
                changes.append(ch_desc)
            else:
                changed_p_names = []
                for idx, old_p in enumerate(old_params):
                    if old_p != new_params[idx]:
                        p_name = old_p.get("m", f"arg{idx}")
                        changed_p_names.append(p_name)
                if changed_p_names:
                    changes.append(f"Param details modified: {', '.join(changed_p_names)}")

            # Compare output variables
            old_ov = old_item.get("output_variable_list", [])
            new_ov = item.get("output_variable_list", [])
            if old_ov != new_ov:
                changes.append("Output variables modified")

            if changes:
                modified.append({
                    "code": code,
                    "name": item.get("n", old_item.get("n")),
                    "changes": changes
                })

    for code, item in curr_map.items():
        if code not in extr_map:
            removed.append({
                "code": code,
                "name": item.get("n", "Unknown")
            })

    return {
        "current_total": len(curr_map),
        "extracted_total": len(extr_map),
        "added": added,
        "removed": removed,
        "modified": modified,
        "changed": len(added) > 0 or len(removed) > 0 or len(modified) > 0
    }


def diff_event_or_state_catalog(current_data, extracted_data):
    if not current_data or not extracted_data:
        return {"status": "missing_data"}

    curr_list = current_data.get("c", current_data) if isinstance(current_data, dict) else current_data
    extr_list = extracted_data.get("c", extracted_data) if isinstance(extracted_data, dict) else extracted_data

    if not isinstance(curr_list, list) or not isinstance(extr_list, list):
        return {"status": "unsupported_format"}

    curr_map = {item.get("c"): item for item in curr_list if isinstance(item, dict) and "c" in item}
    extr_map = {item.get("c"): item for item in extr_list if isinstance(item, dict) and "c" in item}

    added = []
    removed = []
    modified = []

    for code, item in extr_map.items():
        if code not in curr_map:
            added.append({
                "code": code,
                "name": item.get("n", "Unknown"),
                "params_count": len(item.get("p", {}).get("p", []))
            })
        else:
            old_item = curr_map[code]
            changes = []
            if old_item.get("n") != item.get("n"):
                changes.append(f"Name changed: '{old_item.get('n')}' -> '{item.get('n')}'")
            old_params = old_item.get("p", {}).get("p", [])
            new_params = item.get("p", {}).get("p", [])
            if len(old_params) != len(new_params):
                changes.append(f"Parameter count changed: {len(old_params)} -> {len(new_params)}")
            elif old_params != new_params:
                changes.append("Parameters modified")
            if changes:
                modified.append({
                    "code": code,
                    "name": item.get("n", old_item.get("n")),
                    "changes": changes
                })

    for code, item in curr_map.items():
        if code not in extr_map:
            removed.append({
                "code": code,
                "name": item.get("n", "Unknown")
            })

    return {
        "current_total": len(curr_map),
        "extracted_total": len(extr_map),
        "added": added,
        "removed": removed,
        "modified": modified,
        "changed": len(added) > 0 or len(removed) > 0 or len(modified) > 0
    }


def diff_text_file(current_path, extracted_path):
    if not os.path.isfile(current_path) or not os.path.isfile(extracted_path):
        return {"changed": os.path.isfile(extracted_path) != os.path.isfile(current_path)}

    with open(current_path, "r", encoding="utf-8") as f:
        curr_text = f.read()
    with open(extracted_path, "r", encoding="utf-8") as f:
        extr_text = f.read()

    changed = (curr_text.strip() != extr_text.strip())
    diff_lines = []
    if changed:
        diff = difflib.unified_diff(
            curr_text.splitlines()[:50],
            extr_text.splitlines()[:50],
            fromfile="current",
            tofile="extracted",
            lineterm=""
        )
        diff_lines = list(diff)

    return {
        "changed": changed,
        "current_length": len(curr_text),
        "extracted_length": len(extr_text),
        "diff_preview": diff_lines[:20]
    }


def generate_diff_report(extracted_dir, current_refs_dir):
    report = {
        "actions": {},
        "events": {},
        "states": {},
        "xml_structure_schema": {},
        "pattern_matching_rules": {},
        "command_system": {},
        "modification_requests": {},
        "changes_detected": False
    }

    # Actions
    act_curr = load_json_safe(os.path.join(current_refs_dir, "action_catalog.json"))
    act_extr = load_json_safe(os.path.join(extracted_dir, "action_catalog.json"))
    report["actions"] = diff_action_catalog(act_curr, act_extr)
    if report["actions"].get("changed"):
        report["changes_detected"] = True

    # Events
    evt_curr = load_json_safe(os.path.join(current_refs_dir, "event_catalog.json"))
    evt_extr = load_json_safe(os.path.join(extracted_dir, "event_catalog.json"))
    report["events"] = diff_event_or_state_catalog(evt_curr, evt_extr)
    if report["events"].get("changed"):
        report["changes_detected"] = True

    # States
    st_curr = load_json_safe(os.path.join(current_refs_dir, "state_catalog.json"))
    st_extr = load_json_safe(os.path.join(extracted_dir, "state_catalog.json"))
    report["states"] = diff_event_or_state_catalog(st_curr, st_extr)
    if report["states"].get("changed"):
        report["changes_detected"] = True

    # Text / Schemas
    for fname in ["xml_structure_schema.json", "pattern_matching_rules.md", "command_system.md", "modification_requests.md"]:
        key = fname.split(".", maxsplit=1)[0]
        curr_p = os.path.join(current_refs_dir, fname)
        extr_p = os.path.join(extracted_dir, fname)
        res = diff_text_file(curr_p, extr_p)
        report[key] = res
        if res.get("changed"):
            report["changes_detected"] = True

    return report


def format_markdown_summary(report):
    md = ["# Tasker AI Instructions Differential Audit Report\n"]
    md.append(f"**Overall Changes Detected:** {'YES' if report.get('changes_detected') else 'NO'}\n")

    # Actions
    act = report.get("actions", {})
    md.append("## 1. Action Catalog")
    md.append(f"- Current actions: {act.get('current_total', 0)} | New actions: {act.get('extracted_total', 0)}")
    md.append(f"- **Added actions ({len(act.get('added', []))}):**")
    for a in act.get("added", []):
        md.append(f"  - Code `{a['code']}`: **{a['name']}** ({a['params_count']} params)")
    md.append(f"- **Modified actions ({len(act.get('modified', []))}):**")
    for m in act.get("modified", []):
        md.append(f"  - Code `{m['code']}`: **{m['name']}** -> {', '.join(m['changes'])}")
    md.append(f"- **Removed actions ({len(act.get('removed', []))}):**")
    for r in act.get("removed", []):
        md.append(f"  - Code `{r['code']}`: **{r['name']}**")
    md.append("")

    # Events
    evt = report.get("events", {})
    md.append("## 2. Event Context Catalog")
    md.append(f"- Current events: {evt.get('current_total', 0)} | New events: {evt.get('extracted_total', 0)}")
    md.append(f"- Added: {len(evt.get('added', []))} | Modified: {len(evt.get('modified', []))} | Removed: {len(evt.get('removed', []))}")
    for a in evt.get("added", []):
        md.append(f"  - Added Event `{a['code']}`: **{a['name']}**")
    for m in evt.get("modified", []):
        md.append(f"  - Modified Event `{m['code']}`: **{m['name']}** -> {', '.join(m.get('changes', []))}")
    md.append("")

    # States
    st = report.get("states", {})
    md.append("## 3. State Context Catalog")
    md.append(f"- Current states: {st.get('current_total', 0)} | New states: {st.get('extracted_total', 0)}")
    md.append(f"- Added: {len(st.get('added', []))} | Modified: {len(st.get('modified', []))} | Removed: {len(st.get('removed', []))}")
    for a in st.get("added", []):
        md.append(f"  - Added State `{a['code']}`: **{a['name']}**")
    for m in st.get("modified", []):
        md.append(f"  - Modified State `{m['code']}`: **{m['name']}** -> {', '.join(m.get('changes', []))}")
    md.append("")

    # XML & References
    md.append("## 4. Schemas & Reference Guides")
    for key in ["xml_structure_schema", "pattern_matching_rules", "command_system", "modification_requests"]:
        info = report.get(key, {})
        status = "MODIFIED" if info.get("changed") else "UNCHANGED"
        md.append(f"- **{key}**: {status}")

    return "\n".join(md)


def main():
    parser = argparse.ArgumentParser(description="Diff extracted Tasker catalogs against current skill references.")
    parser.add_argument("--extracted", "-e", required=True, help="Directory containing extracted catalogs")
    parser.add_argument("--current", "-c", required=True, help="Directory containing current skill references")
    parser.add_argument("--report", "-r", required=True, help="Output path for JSON diff report")
    parser.add_argument("--summary", "-s", help="Output path for Markdown summary")
    args = parser.parse_args()

    report = generate_diff_report(args.extracted, args.current)

    with open(args.report, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    summary_md = format_markdown_summary(report)
    if args.summary:
        with open(args.summary, "w", encoding="utf-8") as f:
            f.write(summary_md + "\n")

    print(f"Diff report saved to {args.report}")
    print(f"Changes detected: {report.get('changes_detected')}")
    print("\nSummary Preview:\n")
    print(summary_md[:800])


if __name__ == "__main__":
    main()
