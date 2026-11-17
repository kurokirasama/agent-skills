---
name: git-sanitize-cloud
description: Expert cognitive guide for sanitizing, repairing, and synchronizing local Git repositories inside cloud-synced folders (cloud, workspace) against remote origin without data loss.
---

# Git Cloud Repository Sanitizer (`git-sanitize-cloud`)

## Overview

When a Git repository resides inside a cloud-synchronized folder (such as cloud or workspace), asynchronous file replication engines interact unfavorably with Git's internal object store and stat cache. Cloud sync engines sync files out-of-order, restore stale deleted files, touch modification timestamps (`mtime`), and introduce conflict forks.

This skill provides an AI agent with structured diagnostic inspection tools (`mod.nu`) and a deterministic, 9-step remediation workflow to safely sanitize corrupted or desynchronized repositories against their remote origin (`origin/<branch>`) without silent data loss.

**Core Philosophy:** The Nushell helper module (`mod.nu`) never mutates the worktree, the index, or local branches. The sole exception is `refresh-remote-refs`, a non-destructive `git fetch` that updates only remote-tracking refs (`origin/*`); it is MANDATORY before trusting any ahead/behind comparison. All remediation steps are executed intentionally by the agent following this protocol.

---

## Cloud Desynchronization Root Causes

1. **Phantom Staged Deletions**: A cloud daemon downloads an upstream commit by writing new files and deleting old ones non-atomically. Git's index records files as staged for deletion (`D  path`), yet the files physically exist on the filesystem.
2. **Stat Cache (`mtime`) Desynchronization**: Cloud sync updates file contents or metadata, updating physical disk timestamps without updating the Git index stat cache. Git perceives every file as modified even when byte content is byte-for-byte identical.
3. **Stale Cloud Overwrites vs. Remote Commits**: An offline machine syncs older files after reconnecting, overwriting newer files committed upstream. The local file timestamp is older than the latest remote commit timestamp, and local diffs only revert upstream additions.
4. **Placeholder Stubs & Unhydrated Files**: Smart Sync or Selective Sync features create zero-byte placeholder stubs or virtual inodes for Git loose objects (`.git/objects/??/*`), triggering `fatal: loose object is corrupt` or `mmap failed` errors during `git fsck`.
5. **Stale `.git/*.lock` Files**: Cloud sync locks or aborts background operations, leaving orphaned lock files (`.git/index.lock`, `.git/HEAD.lock`, `.git/refs/...lock`) when no Git process is running.
6. **Stale Remote-Tracking Refs (Unfetched Remote)**: `origin/<branch>` is only as fresh as the last `git fetch`. On a long-lived or intermittently synced machine, the ref can lag behind the actual remote by many commits. Diagnostics then report `ahead 0 / behind 0` and a clean tree while the worktree is silently missing upstream files. **Never trust ahead/behind or conclude "remote is truth" until `refresh-remote-refs` has run.**

---

## 9-Step Agent Remediation Protocol

Before running any mutating Git command, the agent MUST run diagnostic gathering to understand the current state. **`gather-cloud-repo-status` fetches `origin` before computing divergence** (pass `--no-fetch` only when you have already fetched in this session):

```nu
use skills/git-sanitize-cloud/mod.nu *
let diag = gather-cloud-repo-status   # performs `git fetch origin --prune` first
```

Follow the sequential steps below based on the diagnostic findings:

### Step 1: Refresh Remote Refs & Pre-Flight Diagnostic Analysis
**MANDATORY FIRST ACTION — never skip.** A stale `origin/<branch>` ref will report `ahead 0 / behind 0` and an empty `git diff origin/<branch>` even when the worktree is missing dozens of upstream files.

1. Verify the refs are fresh (already done by `gather-cloud-repo-status`; run explicitly if you used `--no-fetch` or the fetch failed):
   ```nu
   refresh-remote-refs          # git fetch origin --prune; updates only remote-tracking refs
   ```
   Confirm `$diag.remote_sync.fetched` is true. If the fetch failed (offline, auth), STOP: every ahead/behind result is unreliable until it succeeds.
2. Compare `$diag.divergence.local_head` with `$diag.divergence.remote_head`. Equality means the local commit is current; inequality means you are genuinely ahead/behind.
3. Inspect `$diag.environment`, `$diag.artifacts`, `$diag.integrity`, and `$diag.divergence`.
   - If `$diag.environment.is_cloud` is false, this repository is not in cloud or workspace. Normal Git operations apply.
   - Ensure `$diag.artifacts.git_running` is false before touching locks or index state. If an active Git process is running, wait for it to complete.
4. If `$diag.divergence.behind` > 0, realign to the fetched `origin/<branch>` (Step 7) **before** reconciling stale files; missing upstream files are not "stale local edits", they are simply not fetched yet.

### Step 2: Safe Stale Lock Remediation
If `$diag.artifacts.stale_locks` is not empty:
1. Re-verify no active Git process is running (`ps | where { |p| $p.name =~ "(?i)^git" }`).
2. If confirmed orphaned, safely delete each lock file:
   ```nu
   for lock in $diag.artifacts.stale_locks {
       rm -v $lock
   }
   ```

### Step 3: Quarantining Git Dir & Worktree Conflict Copies
If `$diag.artifacts.git_dir_conflicts` or `worktree_conflicts` exist:
1. For conflicts inside `.git/` (e.g., `index (conflicted copy)`):
   - These are dangerous corruptions generated by cloud sync engines. Remove them immediately:
     ```nu
     for f in $diag.artifacts.git_dir_conflicts { rm -v $f }
     ```
2. For worktree conflict copies (e.g., `file (conflicted copy).txt`):
   - Do NOT delete silently. Inspect diff between the conflict copy and canonical file.
   - If identical or obsolete, remove. If unique user content exists, merge into canonical file before removing.

### Step 4: Index Reconciliation (Resolving Phantom Staged Deletes)
If `$diag.divergence.phantom_deletes` is not empty:
- Staged deletions exist in the index where files physically exist on disk.
- Realign the index with `HEAD` using a mixed reset:
  ```bash
  git reset HEAD
  ```
- This flushes the desynchronized index cache without altering files on disk.

### Step 5: Stat-Cache Refresh (Clearing False Mtime Diffs)
When files show as modified in `git status` but `git diff` produces empty content:
- Git's index stat cache is out of sync with disk `mtime` values.
- Refresh the index stat cache:
  ```bash
  git update-index --refresh
  ```
- Any clean files with updated mtimes will immediately disappear from `git status`.

### Step 6: Stale Cloud Overwrite Reconciliation
If `$diag.divergence.stale_local_files` contains files:
- The local file mtime is older than the latest commit date in `origin/<branch>`, and `git diff` indicates the local file is reverting recent remote changes.
- Verify with `git diff <file>`. If the local changes are purely regressions or deletions of upstream code caused by stale cloud sync:
  ```bash
  git checkout origin/<branch> -- <file>
  ```
- Repeat for verified stale files to restore upstream state.

### Step 7: Fast-Forward / Realignment for Pre-Synced Worktrees
If local worktree already contains all remote changes or is cleanly behind `origin/<branch>`:
- Re-verify freshness with `refresh-remote-refs` (idempotent; cheap after the Step 1 fetch).
- If the local branch has no uncommitted changes and only needs fast-forwarding:
  ```bash
  git merge --ff-only origin/<branch>
  ```
- If local `HEAD` diverged due to duplicated commits or rebase desync across machines, realign safely:
  ```bash
  git reset --mixed origin/<branch>
  ```

### Step 8: Isolating Genuine Local Changes
If `$diag.divergence.uncommitted_changes` contains genuine user edits:
1. Create a dedicated backup stash with a clear timestamped message:
   ```bash
   git stash push -m "cloud-sanitize-backup-(date now | format date '%Y%m%d%H%M%S')"
   ```
2. Synchronize branch with remote:
   ```bash
   git pull --rebase origin <branch>
   ```
3. Re-apply stashed changes:
   ```bash
   git stash pop
   ```
4. Resolve any genuine merge conflicts cleanly.

### Step 9: Post-Sanitization Verification & Reporting
Confirm the repository is in a clean, consistent state:
1. Run `refresh-remote-refs` once more, then `git status` and `git diff --stat origin/<branch>` to verify the worktree matches the **freshly fetched** remote (not a cached ref).
2. Run `inspect-git-integrity` to confirm `git fsck --full` passes with zero object corruption.
3. Spot-check a directory that changed upstream (e.g., `ls <path> | length`) to confirm file counts match `git ls-tree origin/<branch>:<path>`. A clean `git status` alone is not proof of completeness.
4. Report a clear summary of clean artifacts (stale locks removed, index refreshed, phantom deletes cleared, commits fast-forwarded, remote ref SHA before/after).

---

## Hard-Won Lessons (Pitfalls)

- **Never trust `ahead 0 / behind 0` without a fetch.** `origin/<branch>` is a local cache. Real incident: a repo diagnosed as "clean and identical to remote" after discarding local edits was actually 23 commits behind; the worktree was missing 8 reference files that existed upstream. The fix requires `git fetch origin --prune` *before* any divergence analysis, then `git merge --ff-only origin/<branch>`.
- **A clean `git status` proves consistency with `HEAD`, not with the remote.** If `HEAD` is stale, the tree is consistently stale.
- **Order matters when remote is truth:** fetch → compare `local_head` vs `remote_head` → fast-forward/realign → reconcile stale files/index. Reconciling index state before fetching can validate against the wrong baseline.
- **Keep a recovery patch before destructive remediation:** `git diff HEAD --binary o> /tmp/cloud-sanitize-backup-<timestamp>.patch`. Untracked files are not included; list them separately with `git status --porcelain`.
- **Gitlinks without `.gitmodules`** (`git submodule update` fails with "No url found") are usually manually vendored; verify each link's working-tree `HEAD` matches the recorded SHA instead of trying to initialize them.
