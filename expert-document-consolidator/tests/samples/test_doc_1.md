# Git Rebase Guide

Git rebasing is the process of moving or combining a sequence of commits to a new base commit. It is useful for maintaining a clean, linear project history.

## How to Rebase
To rebase your current branch onto another branch (e.g., `main`), use the following command:
```bash
git rebase main
```

## Interactive Rebase
Interactive rebasing allows you to alter individual commits in the history. You can use it to squash, edit, or reword commits.
For example, to interactively rebase the last 3 commits:
```bash
git rebase -i HEAD~3
```
This will open an editor showing a list of commits with commands like `pick`, `squash`, and `reword`.
