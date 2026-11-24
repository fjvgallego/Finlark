# Coding style

How Swift is written in Finlark. How the code is organized (modules, imports, reads and writes, money, concurrency) is
in [architecture.md](../architecture.md), and this page doesn't repeat it.

## Design principles

SOLID was written for class-based object-oriented code. SwiftUI views are value types, and Swift prefers protocols and
composition to inheritance, so each principle is applied in Swift terms. Where following it literally would fight
SwiftUI or SwiftData, the exception is stated.

- **Single responsibility.** A type has one reason to change:
  - A screen shows data and forwards actions.
  - A draft holds editing state.
  - A use case performs one user action.
  - A Domain function computes one rule.
  - When parts of a view change for different reasons, they become separate views.
- **Open/closed.** Closed sets of cases, such as split modes, routes or debtor statuses, are enums.
  - A `switch` over one of our own enums has no `default:`, so adding a case makes the compiler list every place to
    update.
  - Protocols are for sets that really are open.
- **Liskov substitution.** A conformance keeps the contract of its protocol. A test double behaves like the real type,
  including the errors it throws. No class inheritance of our own; compose types instead.
- **Interface segregation.** Protocols are small and shaped by what the caller needs. A wrapper around a system
  framework exposes only the calls Finlark makes, not the whole framework.
- **Dependency inversion.** Depend on a protocol only at a real boundary: a system framework (notifications,
  LocalAuthentication), the clock, or anything that needs a test double.
  - No protocol has a single implementation and no test double.
  - Use cases are concrete types, tested on an in-memory store.
  - There are no repository protocols over SwiftData ([ADR-0002](../adr/0002-domain-logic-and-swiftdata.md)).
  - Fixed rules, such as Gregorian calendar arithmetic, are called directly, not passed in. Domain functions take the
    clock's reading and the time zone as parameters ([ADR-0013](../adr/0013-gregorian-days.md)). System frameworks
    sit behind a protocol at the system boundary.

## Functional style

Finlark is written in a functional style. Where SwiftUI or SwiftData need state, as with `@State`, drafts and models,
that state stays at the edges.

- **Pure functions.** Domain functions depend only on their inputs. Outside Domain, side effects stay at the edges, in
  use cases and Services. Computed properties never have side effects.
- **Immutability.** `let`, never a local `var`. Return a new value instead of changing a parameter. `inout` only when
  a measurement shows that copying costs too much, or when a Foundation API requires it, such as `NSDecimalRound`.
  Then a small private function holds the `inout` and the local `var`s it needs.
- **Transformations.** `map`, `filter`, `compactMap`, `allSatisfy` and `reduce` instead of loops, for example
  `shares.map(\.amount).reduce(.zero, +)`. Validate first, then transform, instead of a loop that exits early. A `for`
  loop only for side effects.
- **Expressions.** `switch` and `if` expressions instead of assigning a variable in each branch.
- **Clarity over cleverness.** No custom operators, point-free chains or currying. Unwrap optionals with `if let` or
  `guard let` rather than chained `map` and `flatMap`.

## Formatting

- [swift-format](https://github.com/swiftlang/swift-format), which ships with the Swift toolchain, enforces formatting
  with the [`.swift-format`](../../.swift-format) file at the repository root: 4 spaces, 120 columns, imports sorted.
- It also rejects force unwraps, `try!` and implicitly unwrapped optionals outside test files. Previews aren't exempt.
- `scripts/lint.sh` runs it over every Swift file in `Finlark/` and `Packages/`, skipping
  `Finlark/DesignExplorations/`, which is reference code written before these rules. CI runs the script and fails on
  any finding ([ADR-0011](../adr/0011-build-and-ci.md)).
- A `// swift-format-ignore` needs a comment saying why.

## Naming

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).
- Domain names use [glossary](../glossary.md) terms with exactly their meaning: `spending` and `balance` are never
  interchangeable, a `Repayment` is never income, and a `PendingItem` is never a transaction.
- No abbreviations except the common ones (`id`, `url`). Booleans read as assertions: `isArchived`, `hasRepayments`.
- Types end with their role where it helps: `…Screen` for screens, `…Draft` for drafts, `…Error` for errors. Use cases
  are verb phrases: `AddTransaction`, `RecordRepayment`, `ConfirmPendingItem`.

## Files

- One main type per file, named after it. Small private helpers can share the file.
- Protocol conformances go in extensions.
- Features is grouped by feature (`Features/History/`), and the other modules by concept.
- `// MARK: -` separates the sections of a long file.

## Access control

- `internal` by default, `private` for what a type doesn't share, and `public` only for what another module uses, or
  is meant to use as its ticket states.

## Swift

- Value types by default. Classes are `final`.
- `guard` for early exits.
- Make invalid values impossible to build. When a value is always valid if its input is, give it a non-failable
  initializer that takes that input, for example `Day(firstDayOf: period)`. Never an initializer that skips validation
  and trusts its caller.
- A type checks only what it guarantees: its stored format and its invariants. Limits on what the user may enter, such
  as the earliest date of a transaction, are enforced by the use case, and the screen limits what can be entered.
  Otherwise data that's already stored could stop being readable.
- Each use case throws its own error type, named in domain terms (`RecordRepaymentError.exceedsRemaining`). Screens
  turn errors into localized messages. No `fatalError` for anything a user or synced data can cause.
- `async`/`await` instead of completion handlers.

## SwiftUI

- A view's `body` fits on one screen. Parts are separate `View` structs, not computed properties or functions that
  return `some View`.
- State: `@State` for what a view owns, `@Query` for reads, `@Environment` for use cases and the router, `@Bindable`
  for drafts.
- System components first, then DesignSystem's. Colors, fonts, spacing and corner radii come from DesignSystem, never
  literals in Features.
- Fonts scale with Dynamic Type: text styles or DesignSystem fonts, never fixed sizes.
- Every screen and reusable component has `#Preview`s in light, dark, an accessibility text size, and Spanish.

## Localization

NFR-004:

- No user-facing text outside String Catalogs. Each module uses its own catalog through `Bundle.module`.
- Keys are the English text. Add a comment for translators when the context isn't obvious.
- Plurals use the catalog's plural variants, never `count == 1 ? … : …`.
- Amounts, dates and numbers are formatted with `FormatStyle` in the user's locale. Never build them by concatenating
  strings.

## Accessibility

NFR-003:

- Every interactive element has a label, including icon-only buttons.
- Status is never shown by color alone. It has text or a symbol too.
- Charts provide an accessibility summary and an audio graph.
- Animations respect Reduce Motion.
- A row that reads as one item combines its children for VoiceOver.

## Comments

- Code explains itself through names and types. Add a comment only when the code can't say it: why something
  unexpected is done, a workaround, or a rule from the docs that the code alone doesn't show. Never comment what the
  code already says.
- The same goes for documentation comments, public API included: none when the name and signature are enough.
- No commented-out code.
- Where the code implements a rule that isn't obvious, cite its ID: the requirement, or the ADR when no requirement
  states it. For example `// A-09: the pace part is hidden during the first 3 days of the month`.

## Logging

- `Logger` from `os`, with one subsystem per module. No `print` in committed code.
- `Logger` shows interpolated numbers publicly by default. Amounts, names, notes and categories are always marked
  `privacy: .private` (NFR-007).

## Tests

- Swift Testing, except UI tests ([ADR-0007](../adr/0007-testing-strategy.md)).
- Display names start with the ID of the document that states the behavior the test asserts. That's the requirement
  when it states it: `@Test("ACC-001: a €120 expense lowers a €1,000 balance to €880")`. Otherwise it's the ADR:
  `@Test("ADR-0005: stored minor units round-trip through Decimal")`. Never an `architecture.md` rule number, because
  those can be renumbered. Every rule there comes from an ADR.
- Test functions describe the behavior, without a `test` prefix, because `@Test` already marks them:
  `func expenseLowersBalance()`. XCUITest methods keep the `test` prefix, which XCTest needs to find them.
- One behavior per test. Repeated cases use `arguments:`.
- A test file is named after what it tests: `BalanceTests.swift`. No shared mutable state between tests.
