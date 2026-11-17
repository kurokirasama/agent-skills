# How-To: Implement nu_plugin_plot Nushell Migration Track

This reference guides the implementation of a `nu_plugin_plot` Nushell migration track (`bump_nushell_<version_slug>_<YYYYMMDD>`). It is used by the `nushell-update-evaluator` skill (Step 6) to generate the concrete `<plugin_track_dir>/howto.md`.

## Prerequisites

- Rust 1.96.0+ installed (or the minimum required by the target Nushell version)
- Target Nushell version installed and available in PATH
- `nu_plugin_plot` builds and tests pass with its current dependency versions
- GitHub remote configured for `nu_plugin_plot` (`origin`)

### Baseline Check Before Changes

Before modifying `Cargo.toml` or `src/`, verify the existing baseline passes cleanly:

```bash
cd /home/username/workspace/Development/linux/nushell/nu_plugin_plot
cargo test
cargo build --release
```

## Phase 1: Cargo.toml Version Updates & Clean Build

### 1.1 Update Dependencies

Edit `Cargo.toml`, replacing `0.XXX.0` with the target Nushell version:

```toml
[dependencies]
nu-plugin = "0.XXX.0"
nu-protocol = { version = "0.XXX.0", features = ["plugin"] }
owo-colors = "3.5.0"
fnv = "1.0.7"
term_size = "0.3.2"

[dev-dependencies]
nu-plugin-test-support = "0.XXX.0"
nu-plugin-engine = { version = "0.XXX.0", features = ["local-socket"] }
```

Update the package version to match the target Nushell version:

```toml
version = "0.XXX.0"
```

### 1.2 Clean Build & Cargo.lock Update

Always start with a clean build to avoid stale-artifact errors, and verify that `Cargo.lock` resolves and updates to the target `0.XXX.0` crates:

```bash
cd /home/username/workspace/Development/linux/nushell/nu_plugin_plot
cargo clean
cargo build --release
git status --short Cargo.toml Cargo.lock
```

### 1.3 Check Warnings

```bash
cargo build 2>&1 | grep -i warning
```

## Phase 2: Breaking Fix Implementation

### 2.1 Follow Adaptation Tasks

For each breaking change recorded in the track's `spec.md`:
- Locate the affected file(s) in `src/`
- Apply the minimal fix described in the adaptation task
- Preserve backward compatibility where possible

### 2.2 Common Patterns

- **Trait signature changes**: Update `impl Plugin for ...` and `impl PluginCommand for ...`
- **Struct field changes**: Update `Value`, `Span`, `Type` construction/access
- **Macro changes**: Update `plugin_command!`, `register_plugin!` invocations
- **Feature flags**: Adjust `nu-protocol` features in `Cargo.toml`
- **Plugin protocol changes**: Review `nu-plugin` protocol version negotiation if plugins fail to register

### 2.3 Verify Compilation

```bash
cargo build --release
```

## Phase 3: Test Suite Updates & Verification

### 3.1 Update Tests

- Modify `tests/functional.rs` for API changes
- Update test expectations for changed behavior
- Add tests for any newly adopted functionality

### 3.2 Run Test Suite

```bash
cargo test
```

### 3.3 Check Coverage (if applicable)

```bash
cargo tarpaulin --out Html  # if installed
```

## Phase 4: Integration Testing with Nushell

### 4.1 Register Plugin

```bash
# From nu_plugin_plot project root
plugin add ./target/release/nu_plugin_plot
plugin use plot
```

### 4.2 Test Basic Functionality

```nu
# Line plots
let data = seq 0 0.1 10 | math sin
$data | plot

# Histograms
let data = seq 1 100 | math random
$data | hist

# XY plots
let x = seq 0 0.1 10
let y = $x | math sin
[$x $y] | xyplot
```

### 4.3 Test Edge Cases

```nu
# Empty data
[] | plot

# Single value
[5] | plot

# Negative values
[-5 -3 -1 1 3 5] | plot
```

### 4.4 Verify Plugin Protocol & Communication

```bash
nu -c 'plugin list | where name == "nu_plugin_plot"'
# Should show nu_plugin_plot registered and matching the target protocol version
```

## Phase 5: Documentation Updates

### 5.1 Update tech-stack.md

Update version references in `conductor/tech-stack.md`:
- `nu-plugin (v0.XXX.0)`
- `nu-protocol (v0.XXX.0)`
- `nu-plugin-engine (v0.XXX.0, local-socket feature)`
- Rust minimum version if changed

### 5.2 Update README (if needed)

Check installation instructions for version references.

## Phase 6: Remote Push & Cleanup

### 6.1 Commit Changes (including Cargo.lock)

```bash
cd /home/username/workspace/Development/linux/nushell/nu_plugin_plot
git add Cargo.toml Cargo.lock src/ tests/ conductor/tech-stack.md conductor/tracks.md
git commit -m "feat: Bump Nushell dependencies to 0.XXX.0"
```

### 6.2 Pull/Rebase & Push to Remote

```bash
git pull --rebase origin main
git push origin main
```

### 6.3 Cargo Clean

```bash
cargo clean
```

## Verification Commands

```bash
# Verify Cargo.toml versions
grep -A 10 "\[dependencies\]" Cargo.toml

# Verify build
cargo build --release 2>&1 | tail -5

# Verify tests
cargo test 2>&1 | tail -10

# Verify plugin protocol registration and execution in a fresh Nushell process
nu -c 'plugin add ./target/release/nu_plugin_plot; plugin use plot; [1 2 3] | plot'
nu -c 'plugin list | where name == "nu_plugin_plot"'

# Verify remote push
git log --oneline -1
git status
```

## Common Pitfalls

- **Run baseline `cargo test` first** — confirm the existing build passes before bumping dependencies
- **Don't forget `cargo clean`** before build — stale artifacts cause confusing errors
- **Commit `Cargo.lock`** alongside `Cargo.toml` so plugin crate resolution is reproducible
- **Always `git pull --rebase origin main`** before pushing to avoid non-fast-forward rejections
- **Version slug format**: `0.114.0` -> `01140` (major*10000 + minor*100 + patch)
- **Remote branch**: Push to `main` (current default branch)
- **Nushell binary**: Must be at the target version before integration testing
- **Feature flags**: `nu-protocol` requires `features = ["plugin"]` for plugins
- **Test support**: `nu-plugin-test-support` and `nu-plugin-engine` must match the version exactly
- **Local copies**: `textplots` and `drawille` in `src/color_plot/` are vendored — don't update unless necessary
- **Symlinked files**: `~/.agents/skills/` and `~/.gemini/antigravity-cli/skills/` are symlinked to `llms_configs/skills/` (while `~/.claude/skills/` uses copies synced via `link-skills`)
