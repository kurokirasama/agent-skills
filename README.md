# Agent Skills

A curated collection of specialized AI agent skills (`SKILL.md` definitions, helper scripts, templates, and references) designed for **Gemini CLI**, **Antigravity CLI**, **Claude Code**, and **OpenCode**.

> **Disclaimer — Nushell Scripts**
>
> Several skills in this repository include or invoke **Nushell** (`.nu`) scripts and modules. To run those skills, you will need **Nushell** installed from the official repository:
> **[https://github.com/nushell/nushell](https://github.com/nushell/nushell)**

## Structure

Each top-level directory corresponds to a self-contained skill containing:
- `SKILL.md` — YAML frontmatter (`name`, `description`) and operational instructions.
- Optional `scripts/`, `references/`, `assets/`, `tests/`, or `mod.nu` Nushell modules.

## Third-Party Attributions

This repository also bundles skills from the following upstream repositories (with nested `.git` metadata stripped for unified distribution):
- **[google-deepmind/science-skills](https://github.com/google-deepmind/science-skills)** (`science-skills/`) — Scientific and bioinformatics database/literature skills.
- **[google-gemini/gemini-skills](https://github.com/google-gemini/gemini-skills)** (`gemini-api-skills/`) — Gemini API and SDK development skills.
