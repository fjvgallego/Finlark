# ADR-0006: Concurrency

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: NFR-008, NFR-011, NFR-012

## Context

- SwiftData's main `ModelContext` and SwiftUI both work on the main actor. `@Model` objects aren't `Sendable`.
- Domain is pure value types and functions ([ADR-0002](0002-domain-logic-and-swiftdata.md)) and has no reason to be
  tied to an actor.
- v1 has little work that needs to run in the background. The heaviest is computing aggregates over 10,000
  transactions (NFR-008) and the duplicate cleanup step ([ADR-0004](0004-sync-duplicates.md)).
- The design project uses Swift 5 language mode with main-actor default isolation and Approachable Concurrency.

## Options considered

1. **Swift 6 language mode, with default isolation chosen per module.** Main actor for everything that touches
   SwiftData or SwiftUI. No default for Domain.
2. **Swift 6 language mode with no default isolation.** Every UI and persistence type is marked `@MainActor` by hand.
   More explicit, but it needs many annotations and works against SwiftData's main context.
3. **Swift 5 language mode with complete concurrency checking.** Data-race problems show up as warnings rather than
   errors.

## Decision

Option 1:

- Every module and the app target use the Swift 6 language mode, with the features that Xcode's Approachable
  Concurrency setting turns on.
- `Persistence`, `Services`, `DesignSystem`, `Features` and the app target default to `MainActor` isolation.
- `Domain` has no default isolation. Its types are `Sendable` and its functions are synchronous and pure.
- Use cases run on the main actor with the main `ModelContext`, which keeps one save per user action simple
  (NFR-012). App Intents (v2.0) call them the same way (NFR-011).
- Work moves off the main actor, for example to a `@ModelActor`, only when a measurement against NFR-008 shows that it
  must. Models never cross actors. Only `PersistentIdentifier`s and Domain values do.
- `@unchecked Sendable`, `nonisolated(unsafe)` and `@preconcurrency` are allowed only with a comment saying why they're
  safe.

## Consequences

- Data races are compile errors, not runtime bugs.
- Most code needs no concurrency annotations, because the main actor is the default where SwiftData and SwiftUI live.
- Domain can be called from any context, including future extensions and background work.
- If an aggregate turns out to be too slow on the main actor, moving it to the background needs an explicit actor
  and a copy of the data as Domain values.
- The package's manifest needs a Swift tools version that supports per-module default isolation.
