# AGENTS.md

Finlark is a personal finance app for iPhone (iOS 26+), built with SwiftUI, SwiftData and CloudKit, with no backend.
Product documentation lives in [docs/](docs/README.md) and is the source of truth. If something contradicts it, ask.

## Hard rules

### Decision-making
- The owner makes the decisions. Agents may suggest, but must ask before deciding on:
  - **Architecture and data model**
  - **Dependencies:** packages, frameworks, capabilities, entitlements
  - **UI/UX** not already specified in the docs
  - **Scope:** adding, dropping or reinterpreting a requirement
- For these, present 2–3 options with trade-offs and a recommendation, then wait for an answer.
- Decide everything else yourself and list those choices in your summary.

### Way of working
- Work in vertical slices: one feature at a time, from data model to screen, with its tests. Don't design or build
  for a feature before its slice starts. Later releases get seams only where requirements/v1.md and architecture.md
  name them (for example NFR-011 and the period type). For the data model, see
  [ADR-0016](docs/adr/0016-data-model-per-slice.md).
- Raise only the decisions the current slice needs.

### Architecture
- Before writing or changing code, read [docs/architecture.md](docs/architecture.md) and follow its rules.
- A decision that is hard to reverse is recorded in an [ADR](docs/adr/README.md) approved by the owner. It's made when
  the slice that needs it is built. [ADR-0015](docs/adr/0015-adrs-for-hard-to-reverse-decisions.md) says which
  decisions those are.

### Coding style
- Write Swift following [docs/technical/coding-style.md](docs/technical/coding-style.md).

### Git
- Follow [docs/technical/git-workflow.md](docs/technical/git-workflow.md).
- Before handing a change to the owner, run the `ready` skill as
  [git-workflow.md](docs/technical/git-workflow.md#review-before-committing) describes.
- Never commit until the owner has reviewed the changes and asked for a commit.
- Push and open a pull request only when the owner asks, after they've reviewed its title and description. Never merge.

### Security
- This repository is **public**. Never commit secrets, API keys, certificates, provisioning profiles or personal data.
