---
name: ready
description: Check that a Finlark change is ready for the owner's review by running the review agents (code-reviewer, docs-keeper, security-auditor) in parallel and merging their findings. Use before handing a change to the owner, or when the owner asks if a change is ready.
---

# Ready for review

## 1. Pick what to review

The owner's target if they gave one. Otherwise the current branch against `main`, including uncommitted changes:
`git diff --stat main...HEAD` and `git status --short`. If there are no changes, say so and stop.

## 2. Choose the agents

| Agent | Runs when the change touches |
|---|---|
| `code-reviewer` | Any `.swift` file outside `Finlark/DesignExplorations/` |
| `docs-keeper` | `docs/`, `AGENTS.md`, `.claude/` skills and agents, `.github/`, or Swift behavior that a requirement, ADR or `architecture.md` describes |
| `security-auditor` | Always. The repository is public, so a secret can land in any file. |

## 3. Run them

Start the chosen agents in parallel, in one message. Give each one:

- The target (branch and base, or paths), and whether uncommitted changes are included.
- The ticket key and one or two sentences on what the change is meant to do.

## 4. Merge the reports

- Combine the findings into one list, most serious first. Drop duplicates, keeping the clearer wording, and note which
  agent found each one.
- Fix the findings that are unambiguous breaks of a written rule in code you wrote, then say what you fixed. If a fix
  is more than a few lines, ask first.
- List everything else for the owner: judgment calls, questions, and anything involving architecture, the data model,
  dependencies, UI/UX or scope.
- Say which agents ran, which were skipped and why.

## 5. Point to the bug review

These agents check Finlark's rules, not correctness. For changes with logic in them, suggest the owner run the
built-in `/code-review`. Don't run it yourself, because it starts several reviewers of its own.
