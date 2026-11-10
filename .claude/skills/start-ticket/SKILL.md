---
name: start-ticket
description: Start work on a Finlark Jira ticket (FIN-n). Reads the ticket, creates its branch from an up-to-date main, gathers the docs it touches and lists what needs the owner's decision. Use when the owner says to start, pick up or work on a ticket.
---

# Start a ticket

The ticket key comes from the owner (`FIN-n`). If it's missing, ask for it.

## 1. Read the ticket

- Read the issue with the Atlassian MCP: summary, description, status, parent, subtasks, links and comments. If you
  need the site's cloud ID, get it from the MCP's list of accessible sites.
- Read the parent epic too, for the context the ticket assumes.
- If the description is empty or vague, note it. Scope is the owner's to define, so don't fill the gap yourself.

## 2. Create the branch

Follow [git-workflow.md](../../../docs/technical/git-workflow.md#branches).

1. Check that the working tree is clean. If it isn't, stop and tell the owner what's uncommitted.
2. Update `main`: `git checkout main`, then `git pull --ff-only`.
3. Create `FIN-n-short-description` from `main`, with a few lowercase words from the summary.

If the branch already exists, switch to it instead and say so.

## 3. Gather context

- Read [architecture.md](../../../docs/architecture.md). It's required before writing or changing code.
- Find the requirement IDs the ticket touches in [requirements/v1.md](../../../docs/requirements/v1.md), and the
  terms it uses in the [glossary](../../../docs/glossary.md).
- Find the ADRs behind the areas involved in the [ADR index](../../../docs/adr/README.md).
- For screens, check the chosen design in `Finlark/DesignExplorations/`.
- Read [coding-style.md](../../../docs/technical/coding-style.md) if the ticket involves Swift.

## 4. Report to the owner

Write a short summary:

- **Ticket:** what it asks for, in your words.
- **Context:** requirement IDs, ADRs and docs that apply.
- **Open questions:** gaps or contradictions with the docs. The docs are the source of truth, so ask rather than
  pick.
- **Owner decisions:** anything in the AGENTS.md "Decision-making" list (architecture and data model, dependencies,
  UI/UX not in the docs, scope). For each, give 2–3 options with trade-offs and a recommendation.

Then offer to move the ticket to *In Progress* in Jira. Change its status only if the owner agrees.
