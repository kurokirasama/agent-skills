# Understanding Git Rebasing

Rebasing is a git command that reapplies commits on top of another base tip. It rewrites project history by creating brand new commits for each commit in the original branch.

## Resolving Rebase Conflicts
During a rebase, conflicts may occur. When Git pauses at a conflict:
1. Identify and resolve the conflicting code blocks.
2. Stage the resolved files:
   ```bash
   git add <resolved-file>
   ```
3. Continue the rebase:
   ```bash
   git rebase --continue
   ```
Do NOT commit the changes; Git handles that automatically once you continue.

## The Golden Rule of Rebasing
Never rebase branches that have been pushed to a public repository (public branches).
If you rewrite history that others have based their work on, you will cause significant synchronization issues for your team.
```
Public Branch (Do NOT Rebase):
A---B---C (main on origin)
     \
      D---E (feature - do NOT rebase if shared!)
```
