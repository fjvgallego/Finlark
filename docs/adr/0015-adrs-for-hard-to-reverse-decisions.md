# ADR-0015: ADRs record only decisions that are hard to reverse

Status: **Accepted** (2026-11-23) · Ticket: FIN-58 · Supersedes: [ADR-0001](0001-record-architecture-decisions.md)

## Context

- [ADR-0001](0001-record-architecture-decisions.md) gives every architecture, data model or dependency decision an
  ADR, and architecture.md needs an ADR for any change to it.
- In its first month that produced ADRs whose cost outweighed the risk they covered. One draft recorded that every
  module may import Foundation. Review findings about wording became questions for the owner, and some of them became
  ADRs.
- The decisions that do need a record are the ones that are expensive to undo: stored data and the CloudKit schema
  are permanent once v1.0 ships ([ADR-0002](0002-domain-logic-and-swiftdata.md)), and module boundaries and patterns
  that every screen follows touch code everywhere.
- Who decides doesn't change. Architecture, data model, dependency, UI/UX and scope decisions stay the owner's
  (AGENTS.md "Decision-making"). This ADR only changes which of them are recorded as ADRs.

## Options considered

1. **A reversibility test.** An ADR only when undoing the decision later would be expensive. Clarifications go into
   architecture.md with the owner's approval. Fewer ADRs, but someone has to judge each case.
2. **Keep an ADR for every decision, with a short format for small ones.** The least change, but it keeps the habit
   of writing an ADR for everything.
3. **A fixed list of categories** (data model, module boundaries, sync, dependencies). Easy to check, but a category
   doesn't measure the cost of undoing a decision.

## Decision

Option 1. This ADR replaces ADR-0001: everything ADR-0001 said that isn't changed here is restated below.

### When a decision gets an ADR

A decision gets an ADR when undoing it later would need any of these:

- A migration of stored data or a change to the CloudKit schema, including how a stored value is read.
- Moving code between modules, or changing what a module may import.
- Adding or removing a dependency, framework, capability or entitlement.
- Changing a pattern that code across modules follows, such as how screens read and write data, navigation or
  concurrency.

Everything else is recorded where it applies:

- **A clarification of architecture.md**, which states what the code and the ADRs already imply without changing
  what code may do, is edited into architecture.md directly. The owner approves it in the diff review, and the pull
  request lists it under Decisions.
- **A decision that applies to one place** goes in a code comment there, if the code doesn't explain it.
- **Every other decision** is listed in the pull request's Decisions section.

When it's unclear whether a decision passes the test, the agent asks the owner.

### How ADRs are written

- ADRs live in `docs/adr/`, one decision per file, named `NNNN-short-title.md`. Numbers have four digits, increase
  by one and are never reused once merged into `main`.
- An ADR has a status line and these sections: Context, Options considered, Decision, Consequences. It cites the
  requirement IDs it serves and the ticket that produced it.
- An ADR says only what a reader needs to check the decision. Context and Consequences list facts, not every case the
  decision touches. Detailed behavior belongs in the requirements, the code or its tests.
- Statuses: *Proposed*, *Accepted*, *Superseded by ADR-NNNN*, *Deprecated*.
- An ADR can be edited freely until it's merged into `main`. After that, an accepted ADR isn't rewritten when the
  decision changes. A new ADR supersedes it, and the old one only gets its status updated. Fixing typos and links is
  fine.
- A new ADR that changes only part of an ADR already merged into `main` refines it instead of superseding it. The old
  ADR keeps its status, its text and its row in the index, and its status line ends with `Refined by: ADR-NNNN`. The
  new ADR's status line ends with `Refines: ADR-NNNN`. Each ADR named is a link, and several are separated by commas.
- [README.md](README.md) lists every ADR with its status.
- [architecture.md](../architecture.md) describes the current architecture and links to the ADRs behind it. An ADR
  that changes the architecture updates that page in the same commit.

### Template

```markdown
# ADR-NNNN: Title

Status: **Proposed** (YYYY-MM-DD) · Ticket: FIN-n · Requirements: NFR-005, …

## Context
What forces the decision: requirements, constraints, risks.

## Options considered
Each option with its trade-offs.

## Decision
What we do, stated so it can be checked in code review.

## Consequences
What gets easier, what gets harder, and follow-ups.
```

## Consequences

- Fewer and shorter ADRs, kept for decisions where the reasons matter years later.
- Smaller decisions are still visible, in pull requests and code comments, but nothing collects them in one place.
- Whether a decision passes the test is a judgment. When the agent is unsure, it asks the owner.
- This ADR doesn't rewrite or reclassify ADR-0002 to ADR-0014.
- AGENTS.md, architecture.md, the `write-adr` and `check-architecture` skills and the `docs-keeper` agent now point
  to this ADR instead of requiring an ADR for every change.
