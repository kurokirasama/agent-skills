# Gemini Skill Compliance Checklist

Before packaging your skill, ensure it meets these quality standards:

## 1. Directory Structure
- [ ] Folder name is in **hyphen-case** (lowercase, digits, hyphens only).
- [ ] `SKILL.md` exists in the root of the folder.
- [ ] Resource folders (`scripts/`, `references/`, `assets/`) are used correctly.

## 2. YAML Frontmatter
- [ ] `name` field is unique and in hyphen-case.
- [ ] `description` field is a **single-line string**.
- [ ] `description` contains clear triggering keywords and context.

## 3. Instructional Body
- [ ] `SKILL.md` uses clear, authoritative markdown headings.
- [ ] Instructions prioritize **Progressive Disclosure**.
- [ ] No `TODO` placeholders or template text remains.
- [ ] Core mandates (e.g., "NEVER guess", "ALWAYS use tools") are prominent.

## 4. Technical Integrity
- [ ] All scripts in `scripts/` are executable and have proper error handling.
- [ ] References in `references/` are relevant and well-structured.
- [ ] The skill passes the `package_skill.cjs` validation script.

## 5. Security
- [ ] No API keys, secrets, or hardcoded credentials.
- [ ] No personal or sensitive information in the documentation or scripts.