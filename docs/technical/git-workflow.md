# Git workflow

How work moves from a ticket to `main`. Finlark uses one short-lived branch per ticket, merged into `main` through a
pull request.

## Branches

- Every ticket gets its own branch from an up-to-date `main`, named `FIN-n-short-description` (for example
  `FIN-10-architecture-adrs`). For a request without a ticket, suggest creating one under the story or epic it belongs
  to, and name the branch after it once the owner agrees.
- Nobody commits to `main` directly. It only receives squash merges from pull requests.
- Branches that are never meant to be merged, such as design explorations, are kept as archives.

## Commits

- The message starts with the ticket key and an imperative summary of up to 72 characters:
  `FIN-10: Add the coding style guide`.
- The body says what changed and why, wrapped at 72 characters, and cites requirement IDs and ADRs where they apply.
- Commits written by an agent end with the attribution trailer the agent is given.
- One logical change per commit. Docs change in the same commit as the code they describe.
- Stage files by path, never with `git add -A` or `git add .`. Check what is already staged before committing.
- Never commit secrets, API keys, certificates, provisioning profiles or personal data. The repository is public.

## Review before committing

Agents don't commit on their own:

1. When the work is done, the agent leaves it uncommitted, runs the [`ready`](../../.claude/skills/ready/SKILL.md)
   skill and summarizes the changes, the decisions it made and the review results.
2. The owner reviews the diff.
3. The agent commits only when the owner asks, using a message the owner has seen.

The `ready` skill is skipped only when the owner says so. An agent whose tool can't run the skill, or the agents it
starts, says in its summary that the review didn't run.

## Pull requests and merging

- A pull request's title is the ticket key and a summary: `FIN-10: Architecture ADRs and engineering guides`.
- Its description follows the [template](../../.github/pull_request_template.md): Summary, Ticket, Changes, Decisions,
  Testing and Follow-ups.
  - Every section stays. An empty one says "None", so the reader knows it was considered.
  - It's written in plain language for someone who didn't follow the ticket.
  - A description written by an agent ends with the attribution line the agent is given.

When a branch is ready:

1. The agent shows the owner the pull request's title and description.
2. The owner reviews them.
3. When the owner asks, the agent pushes the branch and opens the pull request with `gh pr create`.

Agents push only when the owner asks. They never push to `main`, never force-push, and never rewrite history that has
been pushed: changes after a push are new commits.

Only the owner merges. Pull requests are squash merged, so `main` has one commit per ticket. The squash message keeps
the ticket key and lists the branch's commits.
