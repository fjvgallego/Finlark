# ADR-0002: Domain logic, SwiftData and screen state

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: C-3, NFR-005, NFR-008, NFR-009, NFR-010, NFR-011,
NFR-012

## Context

- Finlark's risk is in its money rules: Balance vs Spending, split shares and rounding (SPL-002, SPL-004), repayments
  (SPL-006…009), projection (PLN-003) and recurrence dates (REC-001). NFR-009 requires them to be covered by unit tests.
- SwiftData with CloudKit requires every property to be optional or defaulted and every relationship to be optional
  (C-3). Money math shouldn't have to deal with missing values.
- Core operations must be callable without the UI, so that App Intents and Foundation Models features (v2.0) can
  reuse them (NFR-011).
- Every user action must save atomically (NFR-012), and Home and Plan aggregates must stay fast with 10,000
  transactions (NFR-008).
- `@Query` only works inside a SwiftUI view. It keeps the view up to date as data changes, including changes that
  arrive through iCloud sync.
- Once the CloudKit schema is deployed to production, its record types and fields can't be renamed or deleted, but the
  schema must keep evolving with migrations (NFR-010).

## Options considered

### Where the rules live

1. **SwiftData models are the domain.** Views read with `@Query`, and the rules live in extensions on the `@Model`
   types. Least code and the most idiomatic SwiftData. But CloudKit's optional properties leak into the money math,
   every domain test needs a `ModelContainer`, and any view can change data without going through the rules.
2. **Separate domain with repositories.** Domain structs and repository protocols, with SwiftData hidden behind mapping
   code. Clean boundaries and tests, but it gives up `@Query`'s live updates, keeps two models in sync, and pays a
   mapping cost on large lists.
3. **Hybrid.** SwiftData models for storage and reading. Pure domain functions for the rules. Use cases for every write.

### How screens hold their state

1. **`@Query` in views, use cases from the Environment.** An `@Observable` draft only where a screen edits data before
   saving.
2. **A view model per screen.** It fetches with `FetchDescriptor` and refetches after saves and synced changes. One
   pattern everywhere, but it rebuilds the live updates `@Query` provides, and stale screens become a class of bug.
3. **`@Query` in views, feeding a view model per screen.** Live updates stay, but each screen's data comes from two
   places and has to be handed from the view to its model.

## Decision

The hybrid for the rules (option 3), and `@Query` with the Environment for screens (option 1):

- **Storage and reads:** SwiftData `@Model` types are the persisted model and the read model for the UI. Views read
  them with `@Query`. There are no view models for reading. Values that need rules, such as the balance, totals and
  plan statuses, are computed by Domain functions from the query results.
- **Rules:** balance, spending, split shares and rounding, repayment limits, projection and recurrence dates are pure
  functions and value types in the Domain module (see [ADR-0003](0003-module-structure.md)). Domain doesn't import
  SwiftData or SwiftUI. Its value types have no optionals that exist only because of CloudKit.
- **Writes:** every change to stored data goes through a use case (add transaction, create split, record repayment,
  confirm pending item…). A use case checks the Domain rules, changes the models and saves once per user action
  (NFR-012). Use cases don't depend on SwiftUI, so App Intents can call them (NFR-011).
- **Drafts:** a screen that edits several fields before saving (adding or editing a transaction and its split, a
  recurring template, the plan, onboarding…) keeps them in an `@Observable` draft. A draft holds plain values, not
  models. It checks the Domain rules as the user edits and passes the result to a use case to save.
- **Reaching use cases:** the app target creates the use cases from the `ModelContainer` and puts them in the SwiftUI
  Environment. Screens and drafts get them from there. There are no singletons.
- **CloudKit's optionality stays at the edge:** the persistence code decides what a missing stored value means when it
  turns a model into Domain values.
- Views never insert, change or delete models directly.
- **Schema changes:** the schema is a `VersionedSchema` with a migration plan from v1.0 onward (NFR-010). Once the
  CloudKit schema is in production, a new version only adds record types and fields. Nothing is renamed, deleted or
  changes type. A field that's no longer needed stays and is ignored. New fields are optional or defaulted (C-3).

## Consequences

- The rules can be tested exhaustively without a `ModelContainer` or a simulator. Drafts can be tested without a view
  or a store.
- Views keep SwiftData's live updates and need no mapping layer. A reading screen has no logic of its own to test,
  because its logic is Domain functions.
- v2.0 App Intents and widgets reuse the use cases instead of duplicating rules.
- There is some mapping code from models to Domain values. Aggregates over many transactions must be measured against
  NFR-008. A screen whose aggregate is too slow with `@Query` may need a fetch of only the properties it uses.
- SwiftData can't stop a view from changing a model. Where Swift allows it, model setters are visible only inside the
  Persistence module. Otherwise the rule is enforced in code review. Whether `@Model` properties accept a restricted
  setter wasn't verified when this ADR was written.
- Names and types in the schema are permanent once released, so the v1.0 schema needs a careful review before the
  CloudKit schema is deployed to production.
