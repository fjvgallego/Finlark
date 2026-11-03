# ADR-0003: Module structure

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: C-1, NFR-004, NFR-009, NFR-011

## Context

- [ADR-0002](0002-domain-logic-and-swiftdata.md) separates pure Domain rules, SwiftData persistence with use cases,
  and the UI. That separation only holds if something enforces it.
- The roadmap adds App Intents (v2.0), widgets and controls (v2.2), and later iPad, Mac and Watch. Extensions and other
  platforms need to share code with the app without pulling in all of it.
- Finlark is built by one owner, so the structure must not cost more wiring than it saves.

## Options considered

1. **One app target, folders by feature.** No setup. Nothing enforces the boundaries, and the code has to be split
   anyway when the first extension arrives.
2. **A local Swift package with one module per layer** (Domain, Persistence, DesignSystem, Features) and a thin app
   target. The compiler enforces which layer can import which. Domain builds and tests on its own.
3. **Layer modules plus one module per feature** (Home, History, Plan, People…). The strongest isolation and faster
   incremental builds, but much more package wiring, and screens in different features need extra interfaces to
   navigate to each other.

## Decision

Option 2. A local Swift package, `FinlarkKit`, in `Packages/FinlarkKit`, with these library modules:

| Module | Contains | Imports |
|---|---|---|
| `Domain` | Value types and pure rules: money, splits, repayments, projection, recurrence dates | Foundation |
| `Persistence` | `@Model` types, versioned schemas and migration plans, use cases | Domain, SwiftData |
| `DesignSystem` | Shared components, styles and design tokens with no knowledge of the domain | SwiftUI |
| `Features` | Screens and their state | Domain, Persistence, DesignSystem, SwiftUI |

The app target only holds the entry point, the `ModelContainer` setup, wiring, assets and entitlements. Its minimum
is iOS 26 (C-1).

Dependencies point one way: Features → Persistence → Domain, and Features → DesignSystem. Nothing depends on Features
except the app.

## Consequences

- A forbidden import (for example SwiftData in Domain, or Persistence in DesignSystem) fails the build instead of
  relying on review.
- Domain's tests don't depend on SwiftData or the UI (NFR-009). How tests run is decided in the testing ADR.
- Future extensions import only the modules they need, such as Domain and Persistence for App Intents.
- Each module with user-facing text or assets has its own String Catalog and resources and uses `Bundle.module`
  (NFR-004). Previews in package modules need their own sample data.
- `Features` can grow large. Splitting it per feature later needs a new ADR that supersedes this one.
- The Xcode project on `main` was created to try designs (FIN-9). The app target described here is set up when
  implementation starts.
