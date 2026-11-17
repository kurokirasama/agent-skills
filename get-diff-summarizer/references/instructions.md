# Git Diff Summarization Instructions

Follow these steps precisely to generate the final commit message.

## Step 1: Commit Label
Choose ONE of the following:
- **feat**: New feature.
- **fix**: Bug fix.
- **refactor**: Code change that neither fixes a bug nor adds a feature.
- **docs**: Documentation only.
- **style**: Formatting, white-space, etc.
- **perf**: Performance improvement.
- **test**: Adding or correcting tests.
- **build/ci/chore**: Infrastructure or maintenance.

## Step 2: Thematic Title
- Summarize into a single specific theme.
- Use imperative tense (e.g., "Add user auth", not "Added user auth").
- High-level only; do not list individual file changes.

## Step 3: Bulleted Summary
- Use `-` for each point.
- Use imperative tense.
- Write a high-level description of important changes.

## Format Constraints
Return ONLY the message in this format (no markdown code blocks):
```
<label>: <title>

<commit summary bullet point 1>
<commit summary bullet point 2>
```

## Knowledge Base
- Ignore git metadata lines (diff --git, index, etc.).
- Do not use `[` or `]`.
- Do not repeat file contents or include code comments.