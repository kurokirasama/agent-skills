# Release Verification Protocol

This reference defines the verification rules for folding a Nushell release into codebase migration tracks and the `nushell-expert` skill. Release announcements summarize PR titles and can omit flag constraints, type-checking nuances, or silent behavioral changes.

---

## 1. Source Hierarchy

When release notes, source code, and runtime behavior disagree, resolve conflicts using this strict priority order:

1. **Target Binary Behavior (Highest Authority)**: What a fresh `nu` process at the target version actually parses and outputs.
2. **Source Code at the Release Tag**: Crate definitions, command signatures (`Signature::build`), and parser tests in the Nushell repository at tag `<version>`.
3. **Release-Note Prose (Lowest Authority)**: Blog posts and changelog summaries. Treat release notes as leads to verify, never as self-proving facts.

---

## 2. Fresh-Process Verification Rule

Never rely on a long-lived Nushell MCP session (`evaluate`) to verify version-sensitive behavior or new syntax:

- A persistent MCP server keeps the binary and environment from when it was spawned and can lag behind `PATH` after an upgrade.
- Interactive user configurations (`config.nu`, `env.nu`) can shadow builtins (for example, `use std/assert *` shadowing `length`) or alter default settings.

Always verify version claims in a fresh subprocess:

```bash
# Check the installed binary version on PATH
nu -n -c 'version | select version commit_hash'

# Run a snippet in a clean, config-free process
nu -n -c '[1 2 3 4 5] | take while --include 1 {|x| $x < 3 }'

# Check parser diagnostics on a temporary file
nu --ide-check 10 /tmp/verify_release_snippet.nu
```

When a command depends on a plugin (`polars`, `plot`), load the plugin explicitly in the fresh process or inspect its registered signature before documenting it.

---

## 3. Claim Labels

Every release-note claim recorded in a migration `spec.md` or added to `nushell-expert` must either be executed on the target binary or carry an explicit verification label:

| Label | Meaning | When to Use |
|---|---|---|
| *(unlabeled)* | Executed on the target binary in a fresh process | Post-upgrade planning or verified on the matching `nu --version` |
| `(source-checked)` | Confirmed in Nushell source or PR diff at the release tag, but not executed locally | Pre-upgrade planning when source/PR is inspected, or platform-specific behavior |
| `(release notes only)` | Taken from release-note prose without binary or source confirmation | Pre-upgrade planning before the target binary is installed |
| `(not run: <reason>)` | Cannot be executed in the current environment | Interactive TUI/TTY flows, Windows-only paths on Linux, or missing optional dependencies |

### Labeling Examples

```markdown
- `lines --skip-empty` drops empty lines on strings and byte streams.
- `kill --signal 0 <pid>` replaces the removed `kill -0` shorthand (source-checked).
- `tui run` supports mouse scroll events in nested split panes (release notes only).
- `@interactive` completers claim the terminal on the line-editor thread (not run: requires interactive TTY tab trigger).
```

> **Rule:** When planning happens **pre-upgrade** (`nu --version` is older than the target release), every claim that depends on the new binary MUST carry `(source-checked)`, `(release notes only)`, or `(not run: <reason>)`, and the generated track MUST include a Phase 1 post-upgrade task to run and clear those labels.

---

## 4. Before / After Binary Comparison

Silent behavior changes (altered defaults, renamed clashing columns, stricter YAML/CSV parsing, glob dotfile matching) are the highest-risk items in a Nushell upgrade because `nu --ide-check` does not flag them.

When both the previous binary and the target binary are available (or before upgrading the binary in place):

1. Capture baseline outputs on the old binary for every changed default or silent behavior change listed in the release notes.
2. Run the identical pipeline on the new binary in a fresh `nu -n -c` process.
3. Record the exact input and the before/after output diff in the track's `spec.md` and `nushell-expert/references/migration.md`.

```nu
# Example: verifying flatten column-collision renaming (0.116)
let sample = [{a: 1, b: {a: 2}}]
$sample | flatten
# Pre-0.116 vs 0.116+: {a: 1, b_a: 2}
```

If only the old binary is installed at planning time, record the old binary's output as the baseline and schedule the new-binary comparison in Phase 1 of the generated migration track.

---

## 5. Patch-Release Policy

Nushell patch releases (`0.X.1`, `0.X.2`) frequently ship behavioral fixes, completion changes, and parser adjustments that affect daily scripts and `nu_plugin_plot` protocol alignment (e.g., `0.115.1` changed `deprecation_info` from `null` to `[]`, fixed semver boolean comparisons, and added `HelixChangeMode`).

1. **Patch Releases Trigger the Evaluator**: A patch release alone is sufficient reason to run `nushell-update-evaluator`.
2. **No Skipped Patches**: When evaluating target version `0.X.Y`, check the last folded version in `skills/nushell-expert/references/migration.md` and `SKILL.md`.
3. **Cumulative Ingestion**: Fetch and read **every** intermediate minor and patch release note between the last folded version and the target version (for example, if moving from `0.116.1` to `0.117.1`, ingest `0.116.2` if any, `0.117.0`, and `0.117.1`).
4. **Version-Gated Attribution**: When a behavior or fix landed in a specific patch (such as `0.115.1` or `0.116.2`), label the exact patch version `(v0.115.1)` rather than attributing it generically to `0.115` or `0.116`.
