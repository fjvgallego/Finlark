---
name: open-pr
description: Draft and open a pull request for a Finlark ticket branch, using the repo's PR template. Use when the owner asks for a pull request or its description.
---

# Open a pull request

The rules are in [git-workflow.md](../../../docs/technical/git-workflow.md#pull-requests-and-merging). Read it first.

## 1. Check that the owner asked

Go ahead only if the owner asked for a pull request in this conversation. Drafting the title and description is fine
any time. Pushing and opening the pull request happen only when the owner asks.

## 2. Gather what the pull request covers

- `git log main..HEAD` and `git diff main...HEAD` for everything on the branch, not just the last commit.
- The Jira ticket, the requirement IDs and the ADRs involved.
- The decisions made during the work, and who made each one: the owner or the agent.
- What was tested, and what wasn't.

If there are uncommitted changes, say so. They won't be in the pull request.

## 3. Draft it

- **Title:** `FIN-n: Summary`.
- **Description:** the six sections of the [template](../../../.github/pull_request_template.md), in order: Summary,
  Ticket, Changes, Decisions, Testing, Follow-ups.
  - Every section stays. An empty one says "None".
  - Plain language, for someone who didn't follow the ticket. Changes are grouped by area, not listed by file.
  - End with the attribution line you were given.

## 4. Show it, then open it

Show the owner the title and description. When they ask:

1. Push the branch: `git push -u origin FIN-n-…`.
2. Open the pull request with `gh pr create --base main`, passing the description with a heredoc.
3. Share the pull request URL.

Never push to `main`, never force-push, and never rewrite history that has been pushed. Changes after a push are new
commits. Never merge: only the owner merges.
