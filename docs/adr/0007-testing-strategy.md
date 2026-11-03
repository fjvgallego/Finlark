# ADR-0007: Testing strategy

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: NFR-008, NFR-009, NFR-010, NFR-012, A-12

## Context

- NFR-009: domain logic (balance, spending, split math, repayments, projection, recurrence dates) is covered by
  automated tests written with Swift Testing, and tests run in CI on every push.
- [ADR-0002](0002-domain-logic-and-swiftdata.md) and [ADR-0003](0003-module-structure.md) put those rules in a Domain
  module that is testable on its own, and every write in use cases.
- Some behavior can't be automated reliably: iCloud sync between devices, Face ID, and notifications that fire on a
  real date.

## Options considered

1. **Unit and integration tests only.** Domain unit tests plus use-case tests on an in-memory SwiftData store. The UI
   is checked by hand.
2. **Option 1 plus a few UI smoke tests.** Four to six critical flows also run as UI tests in CI.
3. **Option 2 plus snapshot tests.** Covers dark mode and Dynamic Type automatically, but needs a third-party library
   and tends to break when iOS changes.

## Decision

Option 2, in three layers:

| Layer | What it covers | How |
|---|---|---|
| Domain unit tests | Every rule: balance, spending, split shares and rounding, repayment limits, projection, recurrence dates, minor-unit conversion | Swift Testing, parameterized where cases repeat |
| Persistence integration tests | Use cases (rules enforced, one save per action), the duplicate cleanup step, schema migrations, money round trips | Swift Testing on an in-memory `ModelContainer` with the real schema, no CloudKit |
| UI smoke tests | Onboarding, add an expense, split and record a repayment, confirm a pending item | XCUITest, with the app launched on an in-memory store and fixed data |

- Domain functions take the current date, calendar and time zone as inputs. Domain never reads the clock itself, so
  projection and recurrence tests are deterministic.
- Test names cite the requirement they check, and the requirements' own examples become test cases (for example
  `SPL-002: €100 among 3 gives friends €33.33 and the user €33.34`).
- Edge cases are tested explicitly: rounding remainders (A-03), monthly dates on the 29th–31st (REC-001), the first
  3 days of a month (A-09), leap years, and time zone changes.
- Each package module with logic has its own test target. Features gets tests when its screen state has logic worth
  testing.
- Everything automated runs in CI on every push (NFR-009).
- iCloud sync (SYN-001…003, ONB-005, A-12), App Lock with Face ID, notifications, and VoiceOver, Dynamic Type and dark
  mode reviews are checked by hand before each release.

## Consequences

- The riskiest code, the money rules, gets the fastest and most thorough tests.
- UI smoke tests catch wiring mistakes that unit tests miss, at the cost of slower CI runs and some flakiness to
  manage.
- The app needs launch arguments or a test configuration to start with an in-memory store and fixed data. They must
  not ship enabled in release builds.
- Accessibility and appearance stay a manual review. Snapshot tests can be reconsidered in a new ADR.
- UI tests use XCUITest because, as far as was known when this ADR was written, Swift Testing doesn't support UI
  automation. This should be checked again when the test targets are set up.
- How NFR-008 is measured (10,000 transactions) and which commands run the tests are decided with the CI setup.
