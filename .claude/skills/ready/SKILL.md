---
name: ready
description: Check that a Finlark change is ready for the owner's review by running the review agents (code-reviewer, docs-keeper, security-auditor) in parallel, merging their findings and saving the report for the ticket. Use before handing a change to the owner, or when the owner asks if a change is ready.
---

# Ready for review

## 1. Pick what to review

The owner's target if they gave one. Otherwise the current branch against `main`, including uncommitted changes:
`git diff --stat main...HEAD` and `git status --short`. If there are no changes, say so and stop.

## 2. Choose the agents

| Agent | Runs when the change touches |
|---|---|
| `code-reviewer` | Any `.swift` file outside `Finlark/DesignExplorations/` (`Package.swift` included), `Finlark.xctestplan`, `project.pbxproj`, or any file in `.github/workflows/` |
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
- Apply docs-keeper's *Wording* findings with the replacement text it gives, and report them as fixed. The owner sees
  them in the diff and the report.
- List everything else for the owner: judgment calls, questions, and anything involving architecture, the data model,
  dependencies, UI/UX or scope.
- Say which agents ran, which were skipped and why.

## 5. Save the report

Add the merged report to `.claude/reviews/FIN-n.md`, with the ticket key from the reviewed branch's name (`FIN-n-…`,
see [git-workflow.md](../../../docs/technical/git-workflow.md#branches)), or from the current branch when the target is
paths or uncommitted changes. Git ignores this folder. Create the file if it doesn't exist. Otherwise add to its end,
so earlier runs are kept. Each run is one entry:

```markdown
## 2026-11-16 14:30 · FIN-16-pr-decisions-and-review against main, uncommitted changes included

Ran: docs-keeper, security-auditor. Skipped: code-reviewer (no Swift or build files).

- [docs-keeper] `docs/technical/git-workflow.md:40`: the finding. **Fixed:** what changed.
- [security-auditor] `.gitignore:29`: the finding. **For the owner:** the question.
```

- If nothing was found, the entry says so.
- The report never contains secret values, personal data or real financial data. For those, give the file, the line
  and the kind of data.
- If that branch doesn't start with `FIN-n-`, don't save the report, and say so.

## 6. Point to the bug review

These agents check Finlark's rules, not correctness. For changes with logic in them, suggest the owner run the
built-in `/code-review`. Don't run it yourself, because it starts several reviewers of its own.
