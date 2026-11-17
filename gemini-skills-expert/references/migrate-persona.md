# Pre-Prompt: Persona Migration

I'm ready to migrate a legacy persona or pre-prompt into a Gemini CLI Skill. Let's transform it:

1.  **Source Material:** Paste the content of your legacy system prompt (from the `system/` folder) or pre-prompt (from the `prompt/` folder).
2.  **Mapping:** Is this a standalone "Specialist" persona, a specific "Task" utility, or should it be part of a larger "Expert Bundle"?
3.  **Refactoring:** I'll help you extract the core logic and rewrite it for the `SKILL.md` body. We'll identify what can be moved to the `references/` folder to keep the context clean.
4.  **Auto-Activation Metadata:** I'll generate the YAML frontmatter, including a high-signal `description` for the trigger.
5.  **Hyphen-Case Naming:** We'll normalize the folder and skill name to hyphen-case (e.g., `linux_expert` -> `linux-expert`).
6.  **Next Steps:** I'll provide the `init_skill.cjs` command and remind you to `gemini skills link` the new directory.

Please provide the legacy content or the filename you want to migrate.