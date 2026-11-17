# Profile: Standalone Research Projects

This profile is tailored for complex Nushell applications (e.g., `ProjectA`, `ProjectB API`) found in `~/cloud/Research/`. The focus is on modularity, type safety, and rigorous quality gates.

## Architectural Consistency

-   **"Flat" Module Registry**:
    -   **No Internal `use`**: Do NOT use `use` statements inside `.nu` module files.
    -   **Global Registry**: Load all internal dependencies via a central `autouse.nu` file using `use module.nu *`.
    -   **Central Configuration**: Scripts and tests must `source nu_modules/autouse.nu` before execution.
-   **Robust Path Resolution**:
    -   Use `$env.NU_MODULES_DIR` (defined via `$env.FILE_PWD` in `autouse.nu`) to construct absolute paths to project resources (data, prompts).
    -   Ensures modules work correctly regardless of the current working directory.

## Quality Gates & Verification

-   **Type Safety**: All flags and parameters must have explicit Nushell type annotations (e.g., `--limit(-l): int`).
-   **Phase Checkpoints**: At the end of every phase, verify that every modified code file has a corresponding test.
-   **Auditable History**:
    -   Attach task summaries to commits using `git notes add -m "<summary>" <sha>`.
    -   Include automated test results and manual verification confirmations in phase checkpoint commits.

## Specialized API Patterns

-   **Dry-Run Mode**: All API connector functions should support a `--dry_run` flag that returns the constructed request for verification.
-   **Iterative JSON Decoding**: Use an iterative loop (up to 5 attempts) to `from json` output from LLMs to handle nested strings or Markdown delimiters.
-   **Standardized Reporting**: Automated generation of both JSON (structured) and CSV (human-readable) reports with timestamps.

## Formatting Standards

-   **Pipeline Continuity**: Leading `|` on continuation lines, aligned with `let`.
-   **Pass-Through Branches**: Use `Empty { }` for branches that should not transform data (e.g., `| if $cond { } else { transform }`).
-   **Explicit Filtering**: Use `where` for filtering instead of `each {if} | compact`.
-   **Type Signatures**: Include full type signatures: `[ ]: nothing -> table { ... }`.