# ADR-0003: Module structure

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: C-1, C-2, NFR-004, NFR-009, NFR-011, NTF-001…004,
SEC-001, SEC-002, SYN-002

## Context

- [ADR-0002](0002-domain-logic-and-swiftdata.md) separates pure Domain rules, SwiftData persistence with use cases,
  and the UI. That separation only holds if something enforces it.
- Some features need system frameworks that are neither persistence nor UI (C-2): local notifications
  (UserNotifications, NTF-001…004), App Lock (LocalAuthentication, SEC-001) and the iCloud account status (CloudKit,
  SYN-002).
- Release 1.3 adds a custom month start day and depends on "period logic built behind a single abstraction in 1.0"
  ([roadmap](../roadmap.md#13-plan-alerts--month-start)).
- The roadmap adds App Intents (v2.0), widgets and controls (v2.2), and later iPad, Mac and Watch. Extensions and other
  platforms need to share code with the app without pulling in all of it.
- Finlark is built by one owner, so the structure must not cost more wiring than it saves.

## Options considered

1. **One app target, folders by feature.** No setup. Nothing enforces the boundaries, and the code has to be split
   anyway when the first extension arrives.
2. **A local Swift package with one module per layer** and a thin app target. The compiler enforces which layer can
   import which. Domain builds and tests on its own.
3. **Layer modules plus one module per feature** (Home, History, Plan, People…). The strongest isolation and faster
   incremental builds, but much more package wiring, and screens in different features need extra interfaces to
   navigate to each other.

For the system frameworks, three homes were considered: a separate Services module, the app target behind protocols
declared in Features, and Features itself. The app target would need extra protocols before data changes could update
notifications. Features would grow, and Persistence can't import it.

## Decision

Option 2, with a Services module for the system frameworks. A local Swift package, `FinlarkKit`, in
`Packages/FinlarkKit`, with these library modules:

| Module | Contains | Imports |
|---|---|---|
| `Domain` | Value types and pure rules: money, periods, splits, repayments, projection, recurrence dates, which notifications should exist | Foundation |
| `Persistence` | `@Model` types, versioned schemas and migration plans, use cases | Domain, SwiftData |
| `Services` | Notifications, App Lock, iCloud account status | Domain, Persistence, UserNotifications, LocalAuthentication, CloudKit |
| `DesignSystem` | Shared components, styles and design tokens with no knowledge of the domain | SwiftUI |
| `Features` | Screens, drafts and navigation | Domain, Persistence, Services, DesignSystem, SwiftUI |

The app target only holds the entry point, the `ModelContainer` setup, wiring, assets and entitlements. Its minimum
is iOS 26 (C-1).

Dependencies point one way: Features → Services → Persistence → Domain, Features → Persistence, and Features →
DesignSystem. Nothing depends on Features except the app.

- **Services** is the only module that imports UserNotifications, LocalAuthentication or CloudKit.
- **Notifications are reconciled, not scheduled one by one.** Domain works out which notifications should exist from
  the stored data. Services compares that with what is scheduled and adds or removes the difference. It runs at
  launch, when the app returns to the foreground, after each save and when synced data arrives. Use cases don't call
  Services.
- **Periods:** every monthly calculation (spending, plan, projection, History totals) goes through Domain's period
  type, so a custom month start (1.3) changes one place.

## Consequences

- A forbidden import (for example SwiftData in Domain, or Persistence in DesignSystem) fails the build instead of
  relying on review.
- Domain's tests don't depend on SwiftData or the UI (NFR-009). How tests run is decided in
  [ADR-0007](0007-testing-strategy.md).
- Future extensions import only the modules they need, such as Domain and Persistence for App Intents.
- Because notifications are worked out from the data, they stay correct when data changes on another device.
  iOS keeps a limited number of pending local notifications per app, so the reconciliation schedules the soonest
  ones first.
- Data written by another process (App Intents in v2.0, widgets in v2.2) updates notifications only when the app
  next reconciles, unless that process also runs Services.
- Notification taps reach navigation through the app target ([ADR-0008](0008-navigation.md)), because Services can't
  import Features.
- Each module with user-facing text or assets has its own String Catalog and resources and uses `Bundle.module`
  (NFR-004). Previews in package modules need their own sample data.
- `Features` can grow large. Splitting it per feature later needs a new ADR that supersedes this one.
- The Xcode project on `main` was created to try designs (FIN-9). The app target described here is set up when
  implementation starts.
