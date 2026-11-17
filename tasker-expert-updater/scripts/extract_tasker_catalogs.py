#!/usr/bin/env python3
"""
extract_tasker_catalogs.py - Extracts discrete JSON catalogs and markdown references
from Tasker AI System Instructions.
"""

import argparse
import json
import os
import re
import sys


def extract_balanced_json(text, start_idx):
    """
    Extracts a balanced JSON object ({...}) or array ([...]) starting at start_idx.
    """
    ch = text[start_idx]
    if ch not in ('{', '['):
        return None
    stack = [ch]
    in_string = False
    escape = False
    for i in range(start_idx + 1, len(text)):
        c = text[i]
        if escape:
            escape = False
            continue
        if c == '\\':
            escape = True
            continue
        if c == '"':
            in_string = not in_string
            continue
        if not in_string:
            if c in ('{', '['):
                stack.append(c)
            elif c in ('}', ']'):
                opener = stack.pop()
                if (opener == '{' and c != '}') or (opener == '[' and c != ']'):
                    return None
                if len(stack) == 0:
                    raw = text[start_idx:i+1]
                    try:
                        return json.loads(raw)
                    except (json.JSONDecodeError, ValueError):
                        return raw
    return None


def find_and_extract_catalog(text, header_pattern, key_indicators):
    """
    Finds header and extracts the balanced JSON matching one of the key_indicators.
    """
    pos = 0
    m = re.search(header_pattern, text, re.IGNORECASE)
    if m:
        pos = m.end()
    else:
        return None

    # Search for first indicator after header
    best_idx = -1
    for ind in key_indicators:
        idx = text.find(ind, pos)
        if idx != -1 and (best_idx == -1 or idx < best_idx):
            best_idx = idx

    if best_idx != -1:
        # If indicator is inside a JSON, start at indicator
        return extract_balanced_json(text, best_idx)
    return None


def extract_catalogs(instruction_text, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    results = {}

    # 1. Event Context Catalog
    event_data = find_and_extract_catalog(
        instruction_text,
        r'Event Context Catalog Data:',
        ['{"c":', '[{"c":', '[{"code":']
    )
    if event_data:
        results['event_catalog'] = event_data
        with open(os.path.join(output_dir, 'event_catalog.json'), 'w', encoding='utf-8') as f:
            if isinstance(event_data, (dict, list)):
                json.dump(event_data, f, indent=2, ensure_ascii=False)
            else:
                f.write(str(event_data))

    # 2. State Context Catalog
    state_data = find_and_extract_catalog(
        instruction_text,
        r'State Context Catalog Data:',
        ['{"c":', '[{"c":', '[{"code":']
    )
    if state_data:
        results['state_catalog'] = state_data
        with open(os.path.join(output_dir, 'state_catalog.json'), 'w', encoding='utf-8') as f:
            if isinstance(state_data, (dict, list)):
                json.dump(state_data, f, indent=2, ensure_ascii=False)
            else:
                f.write(str(state_data))

    # 3. Action Catalog
    action_data = find_and_extract_catalog(
        instruction_text,
        r'Action Catalog Data:',
        ['{"a":', '[{"a":', '[{"code":']
    )
    if action_data:
        results['action_catalog'] = action_data
        with open(os.path.join(output_dir, 'action_catalog.json'), 'w', encoding='utf-8') as f:
            if isinstance(action_data, (dict, list)):
                json.dump(action_data, f, indent=2, ensure_ascii=False)
            else:
                f.write(str(action_data))

    # 4. XML Structure Schema Definition (Item 4 up to Item 17 or schema JSON)
    xml_match = re.search(r'(\d+\.\s+\*\*Tasker XML Schema Definition:\*\*|4\.\s+XML Structure Schema:)', instruction_text)
    if xml_match:
        start_idx = xml_match.start()
        next_match = re.search(r'(\d+\.\s+\*\*Tasker Pattern Matching Rules:\*\*)', instruction_text[start_idx:])
        end_idx = start_idx + next_match.start() if next_match else len(instruction_text)
        xml_content = instruction_text[start_idx:end_idx].strip()
        results['xml_structure_schema'] = xml_content
        with open(os.path.join(output_dir, 'xml_structure_schema.json'), 'w', encoding='utf-8') as f:
            f.write(xml_content + '\n')
    else:
        # Fallback for simple test samples
        xml_fallback = find_and_extract_catalog(instruction_text, r'XML Structure Schema:', ['{', '['])
        if xml_fallback:
            results['xml_structure_schema'] = xml_fallback
            with open(os.path.join(output_dir, 'xml_structure_schema.json'), 'w', encoding='utf-8') as f:
                if isinstance(xml_fallback, (dict, list)):
                    json.dump(xml_fallback, f, indent=2, ensure_ascii=False)
                else:
                    f.write(str(xml_fallback))

    # 5. Widget Custom Layout Schema (optional)
    widget_match = re.search(r'Widget v2 Custom Layout JSON Schema:', instruction_text, re.IGNORECASE)
    if widget_match:
        w_start = widget_match.end()
        # Find backtick or brace
        brace_idx = instruction_text.find('{', w_start)
        if brace_idx != -1:
            w_data = extract_balanced_json(instruction_text, brace_idx)
            if w_data:
                results['widget_custom_layouts'] = w_data
                with open(os.path.join(output_dir, 'widget_custom_layouts.json'), 'w', encoding='utf-8') as f:
                    if isinstance(w_data, (dict, list)):
                        json.dump(w_data, f, indent=2, ensure_ascii=False)
                    else:
                        f.write(str(w_data))

    # 6. Pattern Matching Rules (Item 17)
    pm_match = re.search(r'(\d+\.\s+\*\*Tasker Pattern Matching Rules:\*\*)', instruction_text)
    if pm_match:
        start_idx = pm_match.start()
        next_match = re.search(r'(\d+\.\s+\*\*Tasker Command System)', instruction_text[start_idx:])
        end_idx = start_idx + next_match.start() if next_match else len(instruction_text)
        pm_content = instruction_text[start_idx:end_idx].strip()
        with open(os.path.join(output_dir, 'pattern_matching_rules.md'), 'w', encoding='utf-8') as f:
            f.write(pm_content + '\n')
        results['pattern_matching_rules'] = True

    # 7. Command System (Item 18)
    cs_match = re.search(r'(\d+\.\s+\*\*Tasker Command System)', instruction_text)
    if cs_match:
        start_idx = cs_match.start()
        next_match = re.search(r'(\d+\.\s+\*\*Handling Modification Requests|\*\*Your Role & Process:\*\*|\*\*End of System Instructions\*\*)', instruction_text[start_idx:])
        end_idx = start_idx + next_match.start() if next_match else len(instruction_text)
        cs_content = instruction_text[start_idx:end_idx].strip()
        with open(os.path.join(output_dir, 'command_system.md'), 'w', encoding='utf-8') as f:
            f.write(cs_content + '\n')
        results['command_system'] = True

    # 8. Handling Modification Requests (Item 19)
    mod_match = re.search(r'(\d+\.\s+\*\*Handling Modification Requests[^*]*\*\*)', instruction_text)
    if mod_match:
        start_idx = mod_match.start()
        next_match = re.search(r'(\*\*Privacy Constraint:\*\*|\*\*Your Role & Process:\*\*|\*\*End of System Instructions\*\*)', instruction_text[start_idx:])
        end_idx = start_idx + next_match.start() if next_match else len(instruction_text)
        mod_content = instruction_text[start_idx:end_idx].strip()
        with open(os.path.join(output_dir, 'modification_requests.md'), 'w', encoding='utf-8') as f:
            f.write(mod_content + '\n')
        results['modification_requests'] = True

    return results


def main():
    parser = argparse.ArgumentParser(description="Extract JSON catalogs and reference docs from Tasker system instructions.")
    parser.add_argument("--input", "-i", required=True, help="Path to raw Tasker system instructions text file")
    parser.add_argument("--output-dir", "-o", required=True, help="Directory to save extracted catalogs and references")
    args = parser.parse_args()

    if not os.path.isfile(args.input):
        print(f"Error: input file {args.input} does not exist", file=sys.stderr)
        sys.exit(1)

    with open(args.input, "r", encoding="utf-8") as f:
        text = f.read()

    results = extract_catalogs(text, args.output_dir)
    print(f"Extracted {len(results)} components to {args.output_dir}:")
    for k in results:
        print(f"  - {k}")


if __name__ == "__main__":
    main()

