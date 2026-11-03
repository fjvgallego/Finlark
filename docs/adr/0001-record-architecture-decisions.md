# ADR-0001: Record architecture decisions

Status: **Accepted** (2026-11-03) · Ticket: FIN-10

## Context

The owner decides on architecture, the data model and dependencies (see [AGENTS.md](../../AGENTS.md)). Those decisions
need to outlive the conversation where they were made, so that the owner, contributors and agents can see what was
decided, why, and what was rejected. The docs are the source of truth and live next to the code.

## Decision

- Architecture decisions are recorded as ADRs in `docs/adr/`, one decision per file, named `NNNN-short-title.md`.
  Numbers have four digits, increase by one and are never reused.
- Every architecture, data model or dependency decision gets an ADR.
- An ADR has a status line and these sections: Context, Options considered, Decision, Consequences. It cites the
  requirement IDs it serves (`NFR-011`, `A-12`…) and the ticket that produced it.
- Statuses: *Proposed*, *Accepted*, *Superseded by ADR-NNNN*, *Deprecated*. An accepted ADR isn't rewritten when the
  decision changes. A new ADR supersedes it, and the old one only gets its status updated. Fixing typos and links is
  fine.
- [README.md](README.md) lists every ADR with its status.

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

- Decisions and their reasons are reviewable in the same pull requests as the code they shape.
- Changing a decision costs a new ADR, which keeps the history honest but adds a little writing.
