# Pre-Prompt: New Skill Creation

I'm ready to build a new Gemini CLI skill. Help me walk through the standard creation lifecycle:

1.  **Objective & Naming:** What is the primary task or domain for this skill? Suggest a unique, hyphen-case name (e.g., `git-diff-summarizer`).
2.  **Auto-Activation Strategy:** Help me draft a single-line `description` for the YAML frontmatter that accurately triggers the skill in the right context.
3.  **Instructional Design:** Help me draft the `SKILL.md` body using "Progressive Disclosure." Keep the core instructions lean and identify what should be moved to the `references/` folder.
4.  **Resource Identification:** Based on my requirements, suggest any necessary `scripts/` (for logic) or `assets/` (for templates).
5.  **Initialization:** Provide the `init_skill.cjs` command to scaffold the directory.
6.  **Validation Check:** Remind me to run `package_skill.cjs` once implementation is complete to verify YAML and placeholders.

Let's start with Step 1: What are we building today?