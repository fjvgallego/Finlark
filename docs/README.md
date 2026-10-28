# Finlark docs

Product and engineering documentation for Finlark. Docs are written in English and live next to the code, so they
change in the same commits as the code they describe.

| Document | What it covers |
|---|---|
| [vision.md](vision.md) | What Finlark is, who it is for, guiding principles and non-goals |
| [glossary.md](glossary.md) | Domain terms used across docs, code and tickets |
| [requirements/v1.md](requirements/v1.md) | v1.0 scope: functional and non-functional requirements, out of scope, assumptions |
| [roadmap.md](roadmap.md) | Planned releases after v1.0 and their dependencies |

## Coming next

Created when their step starts, not before:

- `docs/design/`: main screens and flows.
- `docs/adr/`: Architecture Decision Records.
- `docs/technical/`: workflow, coding style, testing, and CI and security rules.

## Conventions

- **Requirement IDs** (`SPL-003`, `NFR-005`…) are stable. They are never renumbered or reused. A removed requirement
  is marked *Withdrawn* and keeps its ID.
- Jira tickets, tests and ADRs reference requirement IDs.
- A requirement lives in the file of the release that introduced it. If a later release changes it, it’s edited in place with a _Changed in vX.Y_ note, and the new release file lists it under “Changed requirements” by ID.
- Terms in the [glossary](glossary.md) are used with exactly that meaning everywhere, especially **Spending** vs
  **Balance**.
