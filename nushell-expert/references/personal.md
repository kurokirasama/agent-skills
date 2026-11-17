# Profile: Personal Commands & Productivity

This profile is optimized for scripts located in `~/workspace/my_scripts/nushell`. The goal is maximum interactive efficiency and high discoverability in the global namespace.

## Architectural Conventions

-   **Flat Module Registry (`all.nu`)**: `export use ./module.nu *` for ~30 modules (e.g., `agents.nu`, `system.nu`, `ai_tools.nu`) — populates global namespace without repetitive `use`; `config.nu` itself is `source`d via `append_to_config.nu`.
-   **Global Sourcing (config)**: `config.nu` is sourced into `~/.config/nushell/config.nu`; avoid `use` inside function bodies.
-   **Aliases**: Short `export alias` in `aliases.nu` (`pl = polars`, `htop = btm …`) + heavier `export def --env` wrappers in `alias_defs.nu` (`rml`, `coretemp`, `gmail` with `try`/`catch`/`hide-env`).
-   **Flat Subcommands**: Use `export def "parent child"` syntax to create hierarchies that are beautifully rendered by Nushell's `help` system.
-   **Central Registries**: `$env.MY_ENV_VARS` (paths, hosts, `ips`, `nu_scripts`, etc. via `| upsert` with cross-platform `is_windows` branch) and `$env.CONSTANTS.{pi,e,…}` in `env_vars.nu` — single source for paths like `($env.MY_ENV_VARS.nu_scripts | path join "autolister.nu")`.

## Workflow Integration

-   **Memory Workflow**: At the start of a task, retrieve relevant guidelines from Obsidian (e.g., `obs search "Nushell"`).
-   **Standard Color Aliases**:
    -   `echo-g`: Success / Information (Green).
    -   `echo-r`: Error / Warning (Red).

## Common Patterns

-   **Spread Operator**: Use `...$variable` to expand lists into arguments for commands like `select` or `reject`.
-   **Native Over External**: Use `glob` instead of `ls` for recursive searches to gracefully handle permission errors.
-   **Kebab-Case**: Ensure all command names follow `kebab-case` for consistency with Nushell built-ins.
-   **Keybinding Registry Merge**: `config.nu` maintains `$new_keybinds_names` (strings) + `$new_keybinds` (records); always filter defaults out with `where name not-in $new_keybinds_names` before appending — filtering against the record list never matches and leaves duplicate default bindings (shared-name warning in v0.115.1+).
-   **Unified Editor Bindings**: New keybindings that switch modes should use an `until` list pairing `ViChangeMode` with `HelixChangeMode` so they work in both editors (v0.115.1+).
-   **Version Checks**: Compare versions with direct semver comparison (`(a | into semver) >= (b | into semver)`); no sort-based workarounds needed since v0.115.1.
-   **DAP Debugging & `dap.nu`**: Dedicated minimal `dap.nu` in the workspace root sets clean PATH, disables banner, and avoids slow interactive hooks for `nu --dap` debug sessions (v0.116.0+).
-   **Zed DAP Integration**: Registered under `"dap"."nu"` in `~/.config/zed/settings.json` and launched via `.zed/debug.json` / `~/.config/zed/debug.json` (v0.116.0+).
-   **Startup Time Visualization**: `config.nu` prints formatted `$nu.startup-time` using `nu-rich` upon session initialization (v0.116.0+).

