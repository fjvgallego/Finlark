# Architecture

How Finlark is built today. This page says **what** the architecture is; the [ADRs](adr/README.md) say **why**.
Sections link to the ADRs behind them.

A change to this page comes with an ADR in the same commit when
[ADR-0015](adr/0015-adrs-for-hard-to-reverse-decisions.md) says the decision needs one. A clarification is edited in
directly, with the owner's approval. Terms follow the [glossary](glossary.md).

## Constraints

- iPhone, iOS 26+ (C-1). SwiftUI, SwiftData, the CloudKit private database, Swift Charts, LocalAuthentication and
  UserNotifications (C-2). No backend, and no network use except CloudKit (C-5, NFR-006).
- No third-party SDKs that collect data (NFR-007). New dependencies need the owner's approval and an ADR.
- The data model stays CloudKit-compatible: no unique constraints, every property optional or defaulted, every
  relationship optional (C-3).

## Modules

All code except the app's entry point lives in a local Swift package, `Packages/FinlarkKit`
([ADR-0003](adr/0003-module-structure.md)).

The one exception is `Finlark/DesignExplorations/`: the FIN-9 designs, kept in the app target as reference code so
their previews keep working. Nothing in the app uses them, the rules on this page don't apply to them, and each one
is deleted when its screen is implemented in `Features`.

```mermaid
flowchart TD
    App[App target] --> Features
    Features --> Services
    Features --> Persistence
    Features --> DesignSystem
    Services --> Persistence
    Persistence --> Domain
    Services --> Domain
    Features --> Domain
```

| Module | Owns | May import |
|---|---|---|
| `Domain` | Value types and pure rules: money, periods, splits, repayments, projection, recurrence dates, which notifications should exist | Foundation |
| `Persistence` | `@Model` types, versioned schemas and migrations, use cases, the duplicate cleanup step | Domain, SwiftData |
| `Services` | Notifications, App Lock, iCloud account status, per-device settings | Domain, Persistence, UserNotifications, LocalAuthentication, CloudKit |
| `DesignSystem` | Components, styles and design tokens, with no knowledge of the domain | SwiftUI |
| `Features` | Screens, drafts, the router | Domain, Persistence, Services, DesignSystem, SwiftUI |
| App target | Entry point, `ModelContainer` setup, wiring into the Environment, assets, entitlements | Everything above |

## Data

### Model

The v1.0 schema is `SchemaV1` in Persistence ([ADR-0012](adr/0012-v1-data-model.md)):

```mermaid
erDiagram
    Account |o--o{ Transaction : holds
    Category |o--o{ Transaction : labels
    Transaction |o--o{ Share : "split into"
    Transaction |o--o{ SplitItem : "itemized as"
    SplitItem }o--o{ Share : "assigned to"
    Person |o--o{ Share : owes
    Share |o--o{ Repayment : "paid by"
    RecurringTemplate |o--o{ TemplateRevision : "valued by"
    RecurringTemplate |o--o{ OccurrenceRecord : "confirmed or skipped by"
    Category |o--o{ TemplateRevision : labels
    Category |o--o{ PlannedAmount : "planned by"
```

- The user's own share of a split is stored on the transaction. Share records exist only for people.
- A recurring template's values live in its template revisions, each from a given day on. A month's plan for a
  category is its latest planned amount from that month or before. Past months' values are never changed.
- A transaction that comes from a template, by confirming or by *Make recurring*, stores the template's ID and the
  occurrence date.
- Dates without a time are stored as `yyyymmdd` integers, months as `yyyymm`, and enumerations as `String` raw values.
  Days and months always use the Gregorian calendar, whatever calendar the user has chosen
  ([ADR-0013](adr/0013-gregorian-days.md)).
- Names, notes, amounts and what identifies a category (seed key, icon, color) are end-to-end encrypted in iCloud.
- Everything else the screens show (balance, spending, statuses, pending items, projections) is calculated.

### Reading

Views read models with `@Query`. There are no view models for reading. Values that need rules, such as the balance,
totals and plan statuses, come from Domain functions applied to the query results
([ADR-0002](adr/0002-domain-logic-and-swiftdata.md)).

### Writing

```
View → draft (if the screen edits) → use case → Domain rules → models changed → one save
```

- Every write goes through a use case in Persistence, which saves once per user action (NFR-012). Use cases don't
  depend on SwiftUI, so App Intents can call them (NFR-011).
- A screen that edits several fields keeps them in an `@Observable` draft holding plain values. The draft checks
  Domain rules while the user edits and passes the result to a use case.
- The app target creates the use cases and puts them in the SwiftUI Environment.

### Money

Amounts are stored as `Int64` counts of the currency's minor units, next to their ISO 4217 code. Domain works only in
`Decimal`, and Persistence converts between the two. Balance, spending and projections are calculated, never stored
([ADR-0005](adr/0005-money-storage.md), NFR-005).

Domain's table of minor-unit digits is generated and append-only: a code is never removed and its digits never change
([ADR-0014](adr/0014-append-only-currency-table.md)).

### Months

Every monthly calculation goes through Domain's period type, so a custom month start (roadmap 1.3) changes one place
([ADR-0003](adr/0003-module-structure.md)).

### Sync and the store

- The store lives in an App Group container and syncs to the CloudKit private database
  ([ADR-0009](adr/0009-store-location.md)).
- Pending items are calculated from recurring templates, not stored. Occurrence records (confirm and skip) are keyed by
  the template's ID and the occurrence date, and duplicates are cleaned up the same way on every device. Default data
  has a seed key, and two setups meeting through iCloud lead to the ONB-005 choice, never a silent merge
  ([ADR-0004](adr/0004-sync-duplicates.md), A-12).
- The schema is versioned from v1.0 (NFR-010). Once the CloudKit schema is in production, versions only add record
  types and fields ([ADR-0002](adr/0002-domain-logic-and-swiftdata.md)).

## System services

- **Notifications** are recalculated rather than scheduled one at a time. Domain works out which notifications should
  exist, and Services adds or removes the difference. This runs at launch, on return to the foreground, after each
  save and when synced data arrives ([ADR-0003](adr/0003-module-structure.md)).
- **App Lock** and the **iCloud account status** live in Services.
- **Settings** for notifications, IOU reminder days and App Lock are per device, in `UserDefaults`. Everything else in
  Settings is synced data ([ADR-0010](adr/0010-per-device-settings.md)). Each device also keeps there the shares it
  has sent an IOU reminder for and the day it was set up, so a reminder fires once per share on that device and a new
  device doesn't send reminders for old shares ([ADR-0012](adr/0012-v1-data-model.md)).

## Navigation

A tab bar with Home, History and Settings, with one navigation stack per tab. An `@Observable` router in the
Environment owns the selected tab, each tab's path and the presented sheet ([ADR-0008](adr/0008-navigation.md)).

- Every pushed screen is a `Route` case, and every modal is a `Sheet` case. Destinations are built in one place.
- The tab bar shows only on each tab's root screen.
- Notification taps, and later App Intents and Spotlight, open screens through the router's `open(_:)`. Services
  reports taps as plain values, and the app target turns them into routes.

## Concurrency

Swift 6 language mode everywhere. Every module except Domain defaults to `MainActor` isolation. Domain has no default
isolation, and its types are `Sendable`. Models never cross actors. Work moves off the main actor only when a
measurement shows that it must ([ADR-0006](adr/0006-concurrency.md)).

## Testing

| Layer | Covers |
|---|---|
| Domain unit tests | Every rule, including the requirements' own examples |
| Draft and router tests | Draft validation, which screen a route opens |
| Persistence integration tests | Use cases, the duplicate cleanup step, migrations, on an in-memory store |
| UI smoke tests | Onboarding, add an expense, split and repay, confirm a pending item |
| Manual, before each release | iCloud sync, App Lock, notifications, accessibility and appearance, and a run on iOS 26, because CI tests on iOS 27 |

Swift Testing for everything except UI tests, which use XCUITest ([ADR-0007](adr/0007-testing-strategy.md), NFR-009).

## Build and CI

- The shared `Finlark` scheme builds the app and runs every test target in `Finlark.xctestplan`:

  ```sh
  xcodebuild test -project Finlark.xcodeproj -scheme Finlark \
      -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest' CODE_SIGNING_ALLOWED=NO
  ```

- `scripts/lint.sh` runs swift-format over every Swift file in `Finlark/` and `Packages/`, except
  `Finlark/DesignExplorations/`.
- A new test target is added to `Finlark.xctestplan` in the same commit, or CI won't run it.
- GitHub Actions runs both on every pull request and on every push to `main`
  ([ADR-0011](adr/0011-build-and-ci.md), NFR-009).

## Where future releases plug in

| Release | Builds on |
|---|---|
| 1.3 Custom month start | Domain's period type |
| 2.0 App Intents | Use cases, and the router's `open(_:)` |
| 2.2 Widgets | The App Group store, Domain |
| 3.2 Multiple accounts | The multi-account data model (C-4) |
| 3.4 Multi-currency | The currency code stored with every amount (C-4) |

## Rules

Check these in every code review:

1. No module imports outside its row in [Modules](#modules).
2. Views never insert, change or delete models. Writes go through use cases.
3. Money is `Decimal` in Domain and `Int64` minor units in the store. Never `Double` or `Float`.
4. Domain never reads the clock or the time zone itself. They're passed in. Stored days and months, and Domain's `Day`
   and `Period`, always use the Gregorian calendar. Screens show dates in the user's calendar
   ([ADR-0013](adr/0013-gregorian-days.md)).
5. Monthly calculations go through Domain's period type.
6. After v1.0 ships, schema changes only add record types and fields.
7. Every pushed screen is a `Route` case, and screens don't hide the tab bar themselves.
8. Only Services imports UserNotifications, LocalAuthentication or CloudKit.
9. `@unchecked Sendable`, `nonisolated(unsafe)` and `@preconcurrency` come with a comment saying why they're safe.

## Not decided yet

- How the app picks up data written by extensions (v2.0, v2.2).
- How NFR-008 is measured (10,000 transactions).
