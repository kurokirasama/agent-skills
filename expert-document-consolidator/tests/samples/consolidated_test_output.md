# Comprehensive Git Rebasing Guide

## Table of Contents
1. [Introduction to Git Rebasing](#introduction-to-git-rebasing)
2. [Basic Rebasing Command](#basic-rebasing-command)
3. [Advanced Rebasing Workflows](#advanced-rebasing-workflows)
   - [Interactive Rebasing](#interactive-rebasing)
   - [Resolving Rebase Conflicts](#resolving-rebase-conflicts)
4. [The Golden Rule of Rebasing](#the-golden-rule-of-rebasing)

## Introduction to Git Rebasing
Git rebasing is the process of moving or combining a sequence of commits to a new base commit tip. By reapplying commits on top of this new base, Git rewrites the project history by creating brand new commits for each commit in the original branch. This technique is highly effective for maintaining a clean, linear, and easily readable project history.

## Basic Rebasing Command
To rebase your current branch onto another branch (such as `main`), use the following command:
```bash
git rebase main
```

## Advanced Rebasing Workflows

### Interactive Rebasing
Interactive rebasing allows you to alter individual commits in your branch's history. This is particularly useful for cleaning up your commits before merging them into a main branch by squashing, editing, or rewording them.

For example, to interactively rebase the last three commits on your current branch, execute:
```bash
git rebase -i HEAD~3
```
This command opens an editor listing the target commits, along with options to manipulate them, such as `pick`, `squash`, and `reword`.

### Resolving Rebase Conflicts
During the rebasing process, Git may encounter conflicts between your changes and the base branch, causing it to pause. When this occurs, follow these steps to resolve the conflict:

1. **Identify and resolve** the conflicting code blocks in your files.
2. **Stage the resolved files** using:
   ```bash
   git add <resolved-file>
   ```
3. **Continue the rebasing process** with:
   ```bash
   git rebase --continue
   ```

> [!IMPORTANT]
> Do NOT use `git commit` to commit the resolutions; Git handles the commit creation automatically once you run the continue command.

## The Golden Rule of Rebasing
The golden rule of Git rebasing is: **Never rebase branches that have been pushed to a public repository (public branches).**

If you rewrite history that other developers have already pulled and based their work on, you will cause significant synchronization issues for your team.

```text
Public Branch (Do NOT Rebase):
A---B---C (main on origin)
     \
      D---E (feature - do NOT rebase if shared!)
```
