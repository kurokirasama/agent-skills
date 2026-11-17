# Gemini Skills: Expert Tips & Tricks

## 1. High-Signal Triggers
The `description` field in the frontmatter is the **primary trigger**.
- **Tip:** Use specific verbs and keywords that represent the skill's purpose.
- **Trick:** Mention file types or specific commands that should activate the skill.
- **Example:** `description: Expert for analyzing Python tracebacks and debugging Flask applications. Use when an error is detected in .py files or when the user asks to "debug" or "fix" code.`

## 2. Progressive Disclosure
Don't overload the `SKILL.md` body.
- **Tip:** Put core mandates and high-level workflows in `SKILL.md`.
- **Trick:** Put long reference materials, API schemas, and edge-case checklists in the `references/` folder. The agent can "see" these files but won't load them unless explicitly instructed.

## 3. The "Expert Bundle" Pattern
Related skills are better together.
- **Tip:** If you have a persona and multiple related tasks, bundle them in one folder.
- **Trick:** Use the `references/` folder to store specific task logic. The agent will activate the main persona and then use the sub-prompts from `references/` as needed.

## 4. No Guessing
- **Tip:** Instruct the agent to use tools rather than its own internal weights.
- **Trick:** If a skill requires external data (e.g., latest library versions), add a script to `scripts/` and instruct the agent to run it.

## 5. Explicit Context
- **Tip:** Encourage the use of the `@` operator.
- **Trick:** In `SKILL.md`, remind the agent to ask the user to provide files with `@` if they are not already in the context.