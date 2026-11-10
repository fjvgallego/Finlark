---
name: commit
description: Commit reviewed changes on a Finlark ticket branch, following the repo's git workflow. Use only when the owner has asked for a commit.
---

# Commit

The rules are in [git-workflow.md](../../../docs/technical/git-workflow.md). Read it first. This skill is the
checklist for applying them.

## 1. Check that the owner asked

Agents never commit on their own. Go ahead only if the owner asked for a commit in this conversation, after reviewing
the changes. If they didn't, stop and hand the change over as
[git-workflow.md](../../../docs/technical/git-workflow.md#review-before-committing) describes.

## 2. Check the branch and the tree

- You're on a `FIN-n-…` branch, never `main`. If you're on `main`, stop. Suggest the ticket's branch,
  or for work without a ticket, a new ticket and a branch named after it.
- Run `git status` and `git diff --staged`. If something is already staged that isn't part of this change, ask before
  going on.

## 3. Stage by path

- Stage the files of one logical change by path. Never use `git add -A` or `git add .`.
- Docs that describe the change go in the same commit.
- Check the staged files for secrets, API keys, certificates, provisioning profiles and personal data. The repository
  is public. If you find any, stop and tell the owner.

## 4. Write the message

```
FIN-n: Imperative summary of up to 72 characters

What changed and why, wrapped at 72 characters. Cite requirement
IDs (SPL-003, NFR-005) and ADRs (ADR-0005) where they apply.

<attribution trailer you were given>
```

## 5. Show it, then commit

Show the owner the message and the list of staged files. Commit once they approve, passing the message with a
heredoc so the formatting survives. Then run `git status` to confirm the commit worked.

Don't push. Pushing is part of [open-pr](../open-pr/SKILL.md), and only happens when the owner asks.
