# Gemini Skill Migration Examples

## Example 1: Specialist (System Prompt)
**Original:** `system/linux_expert.md`
**New Structure:**
```text
skills/linux-expert/
└── SKILL.md
```
**Frontmatter:**
```yaml
---
name: linux-expert
description: Expert for Linux system administration, bash scripting, and Ubuntu/CentOS troubleshooting.
---
```

## Example 2: Task (Pre-Prompt)
**Original:** `prompt/fix_json.md`
**New Structure:**
```text
skills/json-fixer/
└── SKILL.md
```
**Frontmatter:**
```yaml
---
name: json-fixer
description: Specialized logic for repairing malformed JSON and ensuring schema compliance. Use when JSON parsing fails or when "fix json" is requested.
---
```

## Example 3: Expert Bundle (Complex Migration)
**Original:** `system/medical_assistant.md` + `prompt/analyze_symptoms.md` + `prompt/check_drug_interactions.md`
**New Structure:**
```text
skills/medical-assistant/
├── SKILL.md (The core persona)
└── references/
    ├── analyze-symptoms.md (Migration of analyze_symptoms.md)
    └── check-drug-interactions.md (Migration of check_drug_interactions.md)
```
**Frontmatter:**
```yaml
---
name: medical-assistant
description: Expert assistant for medical inquiries, symptom analysis, and drug interaction checks.
---
```