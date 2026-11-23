---
name: write-adr
description: Write an Architecture Decision Record for Finlark in docs/adr/. Use when a decision is hard to reverse as ADR-0015 defines it, or when the owner asks for an ADR.
---

# Write an ADR

How ADRs work is in [ADR-0015](../../../docs/adr/0015-adrs-for-hard-to-reverse-decisions.md). Read it first,
including its template.
If the vendored `domain-modeling` skill is loaded too, ADR-0015 and this skill win everywhere they differ: which
decisions get an ADR, the template, the numbering and the index.

## 1. Check that it needs an ADR

A decision gets an ADR only when undoing it later would be expensive, as
[ADR-0015](../../../docs/adr/0015-adrs-for-hard-to-reverse-decisions.md) lists. A clarification of architecture.md, a
decision that applies to one place, and every other decision are recorded where ADR-0015 says, without an ADR. If
it's unclear whether a decision passes the test, ask the owner.

Architecture, data model and dependency decisions are the owner's, with or without an ADR (AGENTS.md
"Decision-making"):

- If the owner hasn't decided yet, write the ADR to present the choice: options with trade-offs and a recommendation,
  status *Proposed*.
- Don't mark it *Accepted* until the owner approves it.

## 2. Number and name it

- Take the next number in the [ADR index](../../../docs/adr/README.md): four digits, one above the highest. Numbers are
  never reused once merged into `main`.
- File name: `docs/adr/NNNN-short-title.md`, lowercase and hyphenated.

## 3. Write it

Follow the template in ADR-0015 and the shape of the existing ADRs (for example
[ADR-0007](../../../docs/adr/0007-testing-strategy.md)):

- Status line: `Status: **Proposed** (YYYY-MM-DD) · Ticket: FIN-n · Requirements: …`, with today's date.
- **Context:** the requirement IDs and constraints that force the decision.
- **Options considered:** numbered, each with its trade-offs.
- **Decision:** stated so it can be checked in code review.
- Say only what a reader needs to check the decision. Detailed behavior belongs in the requirements, the code or its
  tests.
- **Consequences:** what gets easier, what gets harder, and follow-ups.
- Use [glossary](../../../docs/glossary.md) terms with exactly their meaning, and link related ADRs.

## 4. Update the docs it affects

All in the same commit as the ADR:

- Add a row to the [ADR index](../../../docs/adr/README.md) with its status.
- If it changes the architecture, update [architecture.md](../../../docs/architecture.md) and link the ADR from the
  section it changes.
- An ADR can be edited freely until it's merged into `main`. If it supersedes an ADR already merged, don't rewrite the
  old one. Only change its status to *Superseded by ADR-NNNN*, in the file and in the index. Fixing typos and links in
  it is fine.
- If it changes only part of an ADR already merged, it refines it: end the new ADR's status line with
  `Refines: ADR-NNNN` and the old one's with `Refined by: ADR-NNNN`, one link per ADR, separated by commas. The old ADR
  keeps its status, its text and its row in the index.
