# ADR-0009: Store location

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: SYN-001, NFR-010, NFR-012

## Context

- Widgets and controls (v2.2) show month spending, plan status and what is owed, so they need the app's data. App
  Intents (v2.0) may also run outside the app's process.
- An extension can only read the app's files through a shared App Group container.
- Moving a CloudKit-synced store to another location after release means copying the store on every device without
  losing or duplicating data.

## Options considered

1. **An App Group container from v1.0.** The store never moves. The App Groups entitlement is added now, before
   anything else uses it.
2. **The app's default location.** No new entitlement now. The store has to move in v2.2, with a migration that risks
   users' data.

## Decision

Option 1:

- From v1.0, the SwiftData store lives in an App Group container, configured on the `ModelConfiguration`, and syncs to
  the CloudKit private database from there (SYN-001).
- The App Groups capability is added with the app target. The group identifier is based on the bundle identifier
  (`group.com.fjvgallego.Finlark`).
- Only the store goes in the shared container. Other files stay in the app's own container until a feature needs to
  share them.

## Consequences

- Widgets and extensions open the same store without a migration.
- v1.0 ships an entitlement that nothing but the store uses until v2.2.
- Once an extension writes data, more than one process writes the store. How the app picks up those changes is decided
  with v2.0 or v2.2.
