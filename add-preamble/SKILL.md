---
name: add-preamble
description: Guides the agent through adding a YAML preamble to a Markdown file using the add-preamble nushell command, handling title/author/bullets/formulas, and compiling via Pandoc.
---

# Add Preamble Skill (`add-preamble`)

This skill automates the process of adding a properly formatted YAML preamble to a Markdown document and preparing it for Pandoc compilation. The agent follows a step-by-step workflow using the existing `add-preamble` Nushell command combined with manual editing via the agent's file editing tools.

## When to Use

Activate this skill when the user asks to:
- Add a preamble (title, author, date) to a Markdown file
- Prepare a document for Pandoc/LaTeX compilation
- Format a Markdown file with proper bullet spacing and math formulas
- Use the `work` for institutional documents
- Clean up formal document preamble fonts (remove custom fonts for official use)
- Remove spurious section separator lines (`---`) from document bodies

## Execution Strategy: Agent-First with Skill Fallback

Primary execution SHOULD attempt to spawn the dedicated `@add-preamble` subagent (`invoke_subagent` or platform subagent syntax) to isolate multi-pass document editing and Pandoc LaTeX compilation retries from the main conversation context.

### Subagent Spawning Protocol
1. Collect target file and preamble preferences (WORK template, title, author, Monocraft font removal).
2. Spawn `@add-preamble` passing parameters:
   - `invoke_subagent(TypeName: "add-preamble", Role: "Document Processing Specialist", Prompt: "Process document <file.md> with preamble options...")`

### Transparent Fallback Protocol
If spawning the subagent fails on any platform (e.g. `RESOURCE_EXHAUSTED` 429 quota, missing agent link, or platform tool restriction), fall back transparently to executing the 12-step skill workflow in the main thread described below.

## Operational Lifecycle

### Step 0: Activate Supporting Skills

Activate the `nushell-expert` skill if it has not already been activated during this session. This ensures the `add-preamble` Nushell command can be invoked via the `evaluate` tool.

### Step 1: Confirm Target File and Preamble Type

Interact with the user to confirm:

1. **Target file**: Which `.md` file or files needs a preamble?
2. **Preamble type:** For each selected file:
   - **Default**: Run `add-preamble file.md`
   - **WORK template**: Run `add-preamble file.md --work`

Use the `ask_user` tool (or equivalent) to present these choices before proceeding. If the `ask_user` tool is unavailable, ask the user directly by outputting the choices as plain text in the chat interface.

### Step 2: Execute Preamble Generation

Run the appropriate Nushell command based on the user's choice:

- **Default**: `add-preamble <file.md>`
- **WORK**: `add-preamble <file.md> --work`

Use the `evaluate` tool (or equivalent) to execute the command. Confirm that the command succeeded before proceeding.

### Step 3: Detect Formal Document

Analyze the document to determine if it is a formal or official document. Look for these indicators:

- **WORK institutional header elements**: `minipage` blocks with WORK logo references (`work.jpg`), `\hrule` lines after logos, faculty/department names (`FACULTAD DE CIENCIAS`, `DEPARTAMENTO DE ESTADÍSTICA`)
- **Academic structure**: Chapter/section numbering via `number_sections: true`, academic LaTeX packages (`algorithm2e`, `amsmath`, `dsfont`)
- **Formal metadata**: Default author set to an institutional name, formal title formatting

If the document is determined to be formal, proceed to Step 4. Otherwise, skip ahead to Step 5.

### Step 4: Handle Monocraft Font (Formal Documents Only)

If the document was determined to be formal in Step 3, check whether `\setmainfont{Monocraft Nerd Font}` is present in the preamble.

- **If the font line is found**, ask the user whether to remove it using `ask_user` (yes/no):
  > "This formal document uses the Monocraft Nerd Font in its preamble. Would you like to remove it and use the default system font?"
- **If confirmed**, use your file editing tools to delete the `\setmainfont{Monocraft Nerd Font}` line from the YAML frontmatter.
- **If the font line is not present**, skip silently.

Follow the same ask-then-act interaction pattern as Step 6 (Author handling). Do not prompt the user if the document is not formal.

### Step 5: Remove Section Separators (`---`)

Scan the document body for literal `---` lines that act as horizontal rule separators between sections.

- Detection: any `---` line that falls **outside** the YAML frontmatter block (i.e., after the second `---` that closes the preamble)
- These are horizontal rules that LLMs sometimes inject between sections
- **Automatically remove** all such `---` lines from the document body (no user confirmation needed)
- **CRITICAL**: Preserve the YAML frontmatter `---` delimiters — the first `---` that opens the preamble and the matching second `---` that closes it MUST remain intact

Use your file editing tools to delete only the extraneous `---` separator lines.

### Step 6: Handle Author Field

Remove the author from the preamble by default. Use your file editing tools (e.g., `edit_file`) to delete the `author:` line from the YAML frontmatter.

**If the user explicitly asks to keep the author, skip this step.**

To find the `author:` line, read the file's frontmatter (the YAML block between the first `---` and the second `---`).

### Step 7: Handle Title Field

Ask the user to choose one of three options using the `ask_user` or equivalent tool (if unavailable, present the options as plain text in the chat):

1. **Provide a custom title**: The user types a title, you insert it into the preamble
2. **Use the filename**: Extract the filename (without extension) and use it as the title
3. **Let the agent determine a title**: Read the file's content, analyze it, and choose a short, appropriate title

Once you have the title, use your file editing tools to set or update the `title:` field in the YAML frontmatter.

### Step 8: Fix Bullet Point Spacing

Read the file content using `read_file` and scan for bullet point lists:

- Lines starting with `- `, `* `, or `1. ` (ordered lists)
- For each list, ensure there is **exactly one empty line** before the first item of the list
- If a bullet list immediately follows a non-empty line without a blank separator, add a blank line before the first bullet item using your file editing tools

Do not modify content beyond adding the missing blank line separators.

### Step 9: Format Mathematical Formulas

Read the file content and detect any mathematical expressions, both those already in LaTeX and those written in plain text that need conversion to LaTeX:

**Convert plain-text formulas to LaTeX first:**

Identify mathematical expressions written in plain text (no LaTeX commands) and convert them to proper LaTeX syntax:
- `x^2 + y^2 = z^2` → `x^2 + y^2 = z^2` (already valid LaTeX, just needs wrapping)
- `a/b` → `\frac{a}{b}` for fractions or inline `a/b` if within text
- `sqrt(x)` → `\sqrt{x}`
- `alpha`, `beta`, `gamma`, `theta`, `mu`, `sigma`, etc. → `\alpha`, `\beta`, `\gamma`, `\theta`, `\mu`, `\sigma`
- `x_i` → `x_i` for subscripts, `x^i` for superscripts
- `sum_{i=1}^n`, `int_a^b`, `lim_{x->0}` → `\sum_{i=1}^{n}`, `\int_{a}^{b}`, `\lim_{x \to 0}`
- `->`, `=>` → `\to`, `\Rightarrow`
- And any other common plain-text math patterns.

Common plain-text patterns to convert:
| Plain text | LaTeX equivalent |
|------------|------------------|
| `a/b` (as standalone fraction) | `\frac{a}{b}` |
| `sqrt(...)` | `\sqrt{...}` |
| `alpha`, `beta`, ... (greek letters) | `\alpha`, `\beta`, ... |
| `x_i` | `x_i` (already valid) |
| `x^n` | `x^n` (already valid) |
| `a <= b`, `a >= b` | `a \le b`, `a \ge b` |
| `x != y` | `x \neq y` |
| `inf` | `\infty` |
| `...` between operators | `\dots` |

**Then wrap all formulas with proper delimiters:**

- **Inline formulas**: Expressions that appear inline with text. Wrap them with `$...$` (single dollar signs)
  - Example: `x^2 + y^2 = z^2` (already converted if needed) becomes `$x^2 + y^2 = z^2$`
- **Block/display formulas**: Standalone expressions on their own lines. Wrap them with `$$...$$` (double dollar signs)
  - Example: `\sum_{i=1}^{n} i = \frac{n(n+1)}{2}` becomes `$$\sum_{i=1}^{n} i = \frac{n(n+1)}{2}$$`

Use your file editing tools to make these modifications. Preserve existing `$...$` or `$$...$$` wrappers — only add wrappers to unformatted expressions.

**Detection hints**:
- Look for LaTeX commands like `\frac`, `\sum`, `\int`, `\alpha`, `\beta`, `\rightarrow`, etc.
- Look for standalone mathematical notation in plain text (superscripts like `x^2`, subscripts like `x_i`, operators like `/` for fractions)
- Look for Greek letter names written as words (`alpha`, `beta`, `theta`, `mu`, `sigma`)
- Look for function-like patterns (`sqrt(...)`, `sum_(...)`) 
- Look for expressions between text that look mathematical (numbers with operators, variables, etc.)

### Step 10: Compile via Pandoc

Activate the `pandoc-expert` skill and follow its guidance to compile the document via the provided Pandoc command.

1. Activate `pandoc-expert` (if not already active)
2. Let the user know you are about to compile
3. Run the Pandoc compilation command as instructed by the `pandoc-expert` skill

### Step 11: Handle Compilation Errors

If Pandoc compilation fails:

1. **Analyze the errors**: Read the error output carefully to identify the root cause
2. **Fix the source `.md` file**: Use your file editing tools to fix the issues in the source Markdown file (do not edit generated intermediate files)
3. **Retry compilation**: Re-run the Pandoc command
4. **Repeat up to 3 times**: If compilation still fails after 3 attempts, inform the user and ask for their help

Common Pandoc issues to check:
- Unclosed `$...$` or `$$...$$` math delimiters
- Malformed YAML frontmatter (invalid dates, missing required fields)
- Unescaped special characters in LaTeX
- Incorrect image paths or broken links

### Step 12: Report Result

- **On success**: Inform the user that the document was successfully compiled
- **On failure (after 3 retries)**: Show the error output and ask the user to help fix the remaining issues

## User Interaction Points

| Step | Interaction | Method |
|------|-------------|--------|
| 1 | Confirm target file and preamble type | `ask_user` (choice) |
| 4 | Ask whether to remove Monocraft font (formal docs) | `ask_user` (yes/no) |
| 6 | Ask if author should be kept | `ask_user` (yes/no) |
| 7 | Title selection (custom / filename / agent-determine) | `ask_user` (choice) |
| 10 | Inform about compilation start | Chat message |
| 12 | Report success or show errors | Chat message |
| 12 (fail) | Ask for help after 3 failed retries | `ask_user` |

## Content Processing Rules

- **Formal document font**: When a document is identified as formal and contains `\setmainfont{Monocraft Nerd Font}`, ask the user before removing it. Skip silently for non-formal documents or if the font is not present.
- **Section separators**: Remove literal `---` horizontal rule lines from the document body. Preserve the YAML frontmatter `---` delimiters (both opening and closing).
- **Bullet point spacing**: Exactly one empty line before the first item of a bullet list. Do not add extra blank lines between items within the same list.
- **Formula formatting**: Wrap detected LaTeX math correctly — inline with `$...$`, display with `$$...$$`. Do not double-wrap already formatted expressions.
- **Preserve existing formatting**: Do not modify content beyond the rules above (preamble, author, font, separators, bullet spacing, formula formatting).
- **File safety**: Always read the file before editing. Make targeted edits rather than rewriting the entire file.

## Error Handling

- **Nushell command failure**: If `add-preamble` fails, report the error to the user and stop.
- **Pandoc compilation failure**: Retry up to 3 times with fixes, then ask the user for help.
- **File not found**: If the target `.md` file does not exist, inform the user immediately.
- **Broken state prevention**: Do not leave the file in a modified state if subsequent steps fail. If a step fails after edits have been made, inform the user about which edits were applied and which were not.
