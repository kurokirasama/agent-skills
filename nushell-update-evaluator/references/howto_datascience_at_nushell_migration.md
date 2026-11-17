# How-To: Implement DataScienceAtNushell Nushell Migration Track

This reference guides the implementation of a `DataScienceAtNushell` Nushell migration track (`nushell_<version_slug>_upgrade_and_modernization_<YYYYMMDD>`). It is used by the `nushell-update-evaluator` skill (Step 7) to generate the concrete `<track_dir>/howto.md` in `/home/username/cloud/Documentos/Clases/WORK/DataScienceAtNushell/conductor/tracks/<track_id>/`.

## Prerequisites

- Target Nushell version installed and available in PATH (or verified via release artifacts)
- Docker daemon running with permissions to build and push container images
- `gh` CLI authenticated for GitHub Container Registry (`ghcr.io`) and GitHub Releases
- Pandoc and XeLaTeX installed on host (required by `Files/compile_books.nu`)
- Clean Git status on active branch `private` in `/home/username/cloud/Documentos/Clases/WORK/DataScienceAtNushell`

### Baseline Check Before Changes

```bash
cd /home/username/cloud/Documentos/Clases/WORK/DataScienceAtNushell
git status
git branch --show-current # Must be 'private'
nu tests/test_dsin_container.nu
```

---

## Phase 1: Environment & Container Toolchain Upgrade (TDD & Build)

### 1.1 Pre-Upgrade Assertion Check
Update `tests/test_dsin_container.nu` assertion to require the target Nushell version (e.g. `>= 0.XXX.0`) and run it to establish a failing test baseline (TDD):
```nu
nu tests/test_dsin_container.nu # Expected to fail before rebuild
```

### 1.2 Update Dockerfile and Container Automation
Edit `docker/Dockerfile`:
```dockerfile
ARG NUSHELL_VERSION="0.XXX.0"
```

Verify version detection via container automation helper:
```nu
nu update-dsin-nushell.nu --check
```

### 1.3 Build and Verify Container Locally
Build the updated `dsin:latest` container:
```nu
sudo docker build -t username/dsin:latest -t dsin:latest -f docker/Dockerfile docker
```
Or execute the automated builder without pushing:
```nu
nu update-dsin-nushell.nu -v 0.XXX.0
```

Verify container shell and plugin execution:
```nu
sudo docker run --rm username/dsin:latest -c "version | get version"
sudo docker run --rm username/dsin:latest -c "plugin list"
sudo docker run --rm username/dsin:latest -c "plugin use polars; [[x]; [10] [20]] | polars into-df | polars collect | polars into-nu"
```

Re-run container test suite:
```nu
nu tests/test_dsin_container.nu # Must achieve 100% PASS
```

---

## Phase 2: English Textbook Edition Modernization (`Files/DataScienceNushell.md`)

### 2.1 Candidate Snippet Verification
Write a scratch verification script to execute candidate syntax and command patterns inside the updated container or target binary. Validate parity between modern builtins and legacy patterns.

### 2.2 Chapter Overhauls in English Edition
Apply modern language primitives to `Files/DataScienceNushell.md`:
- Introduce new syntax/commands with conceptual explanations, ASCII tables, and realistic data science examples.
- Directly contrast against legacy workarounds.
- Validate table row streaming and pipeline transformations.

### 2.3 Container Execution Verification
Run candidate snippets inside `dsin:latest` to ensure 100% error-free execution.

---

## Phase 3: Spanish & WORK Editions Parity (`Files/DataScienceNushell.es.md` & `Files/DataScienceNushell_work.md`)

### 3.1 Establish Parity Checklist
Confirm that sections modified in the English edition are mirrored accurately in both Spanish editions.

### 3.2 Overhaul Spanish Edition (`Files/DataScienceNushell.es.md`)
Draft authentic Latin American Spanish technical prose preserving exact codeblocks, command options, and table diagrams.

### 3.3 Overhaul WORK Curriculum Edition (`Files/DataScienceNushell_work.md`)
Synchronize the WORK university edition with the Spanish content, preserving academic course alignment.

### 3.4 In-Container Verification
Run all Spanish and WORK codeblocks inside `dsin:latest` to confirm zero execution errors.

---

## Phase 4: Downstream Curriculum Audit & Behavior Change Sweep

### 4.1 Sweep Chapters 1–8
Audit remaining chapters for:
- Deprecated command calls or flag names.
- Behavioral changes (e.g. operator precedence, reserved keywords like `type`, closure syntax).
- Modernization opportunities where new commands improve readability or performance.

### 4.2 In-Container Curriculum Test Suite
Run markdown execution test suite:
```nu
nu tests/test_md_execution.nu
nu tests/test_curriculum_structure.nu
```

---

## Phase 5: Documentation, Tech Stack & Instruction Alignment

### 5.1 Repository Documentation
- Update `README.md` and `README.es.md` version badges and prerequisites to `0.XXX.0`.
- Update `conductor/tech-stack.md` with new Nushell version and container dependencies.

### 5.2 Agent Context Instructions
Audit and update AI instruction files:
- `GEMINI.md`
- `AGENTS.md`
- `CLAUDE.md`
Ensure they document the new Nushell version, new language features, and updated record/pipeline rules.

### 5.3 Task Synchronization
Update `todos.md` with completed upgrade items and new pedagogical roadmap items.

---

## Phase 6: Multi-Edition PDF Compilation & Full Test Verification

### 6.1 Syntax Highlighting Definition Refresh
Update syntax XML files with newly added Nushell keywords and builtins:
```nu
nu scripts/generate_nu_syntax.nu --from-docker
```
Inspect `Files/nu.xml` and `Files/nushell.xml` to verify new keywords (e.g. `type`, `record`, new commands) are highlighted.

### 6.2 Multi-Edition PDF Recompilation
Compile all three textbook editions via XeLaTeX:
```nu
nu Files/compile_books.nu -e all
```
Verify generated PDFs exist and have non-zero size:
- `Files/DataScienceNushell.pdf`
- `Files/DataScienceNushell.es.pdf`
- `Files/DataScienceNushell_work.pdf`

### 6.3 Full Regression Test Verification
```nu
nu tests/test_dsin_container.nu
nu tests/test_curriculum_structure.nu
nu tests/test_md_execution.nu
```

---

## Phase 7: Public Synchronization, Container Registry Push & GitHub Release

### 7.1 Container Registry Release (GHCR)
Login and push image tags to GitHub Container Registry:
```nu
nu update-dsin-nushell.nu -v 0.XXX.0 --push
```
Or manually:
```bash
gh auth token | sudo docker login ghcr.io -u username --password-stdin
sudo docker tag dsin:latest ghcr.io/username/dsin:latest
sudo docker tag dsin:latest ghcr.io/username/dsin:0.XXX.0
sudo docker push ghcr.io/username/dsin:latest
sudo docker push ghcr.io/username/dsin:0.XXX.0
```

### 7.2 Public Branch Synchronization & Sanitization
The repository operates with a local `private` development branch and a public `main` branch.

1. Ensure the working tree on `private` is clean:
   ```bash
   git status
   ```

2. Switch to `main` branch:
   ```bash
   git checkout main
   git pull --rebase origin main
   ```

3. Selectively checkout public deliverables from `private`:
   ```bash
   git checkout private -- \
     Files/DataScienceNushell.md \
     Files/DataScienceNushell.es.md \
     Files/DataScienceNushell.pdf \
     Files/DataScienceNushell.es.pdf \
     Files/nu.xml \
     Files/nushell.xml \
     README.md \
     README.es.md \
     docker/Dockerfile \
     docker/plugins/ \
     update-dsin-nushell.nu
   ```

4. Run mandatory public sanitization test suite:
   ```bash
   nu -c 'use tests/test_public_sanitization.nu run-sanitization-checks; run-sanitization-checks --branch main'
   ```
   **CRITICAL:** Must return 100% clean with zero leaked private files or internal track references.

5. Commit and push public changes:
   ```bash
   git commit -m "release: v0.XXX.0"
   git push origin main
   ```

### 7.3 Tagging and Formal GitHub Release
1. Create and push Git tag:
   ```bash
   git tag -a "v0.XXX.0" -m "Release v0.XXX.0"
   git push origin "v0.XXX.0"
   ```

2. Publish formal GitHub Release attaching compiled public PDFs:
   ```bash
   gh release create "v0.XXX.0" \
     Files/DataScienceNushell.pdf \
     Files/DataScienceNushell.es.pdf \
     --title "v0.XXX.0" \
     --notes "Nushell v0.XXX.0 toolchain upgrade, curriculum modernization, and container release."
   ```

3. Return to local `private` branch:
   ```bash
   git checkout private
   ```
