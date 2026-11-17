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
- `git log -p main..HEAD`, to check that no commit on the branch ever added a secret, even one removed later.
- The Jira ticket, the requirement IDs and the ADRs involved.
- The decisions made during the work, and who made each one: the owner or the agent. Note every time the owner went
  against the agent's recommendation.
- The `ready` skill's results, from the session and from the ticket's report in `.claude/reviews/FIN-n.md` if it
  exists. For each finding the report leaves *For the owner*, find what the owner decided in the session, and ask the
  owner if it isn't there. If neither the session nor the report shows that the review ran, ask the owner whether it
  ran, and why not, before writing "Didn't run".
- What was tested, and what wasn't.

If there are uncommitted changes, say so. They won't be in the pull request.

## 3. Draft it

- **Title:** `FIN-n: Summary`.
- **Description:** every section of the [template](../../../.github/pull_request_template.md), in order, each filled
  as its comment says. The comments are the one place that says what goes in each section.
  - Ask the owner before describing a security finding that is still open in more than general terms.
  - If a commit on the branch ever added a secret, stop before pushing and tell the owner, so the unpushed history can
    be rewritten and the secret rotated. Leave it out of the description.
  - End with the attribution line you were given.

## 4. Show it, then open it

Show the owner the title and description. When they ask:

1. Push the branch: `git push -u origin FIN-n-…`.
2. Open the pull request with `gh pr create --base main`, passing the description with a heredoc.
3. Share the pull request URL.

Never push to `main`, never force-push, and never rewrite history that has been pushed. Changes after a push are new
commits. Never merge: only the owner merges.
