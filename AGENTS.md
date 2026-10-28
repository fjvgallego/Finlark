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

### Security
- This repository is **public**. Never commit secrets, API keys, certificates, provisioning profiles or personal data.
