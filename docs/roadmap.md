# Roadmap

Versions are **indicative**. Priorities are revisited after each release, and each release gets its own requirements
file when it's planned in detail. Later releases don't shape earlier ones: what a release needs from the data model
is added in its own schema version ([ADR-0016](adr/0016-data-model-per-slice.md)).

On 2026-11-24 (FIN-59) bill splitting became 2.0 and every later major moved up by one. Documents written before
then, including ADR-0002 to ADR-0014, use the old numbers: their 2.x is now 3.x and their 3.x is now 4.x.

## Versioning rules

- **Major (x.0):** one big feature or platform capability.
- **Minor (x.y):** one small theme. New devices ship **one per minor release**, never several together.
- Every release keeps the data model CloudKit-compatible and ships with a schema migration if needed.

## Overview

| Version | Theme | Highlights |
|---|---|---|
| **1.0** | Core (iPhone) | Transactions, categories, single account, recurring (confirm-to-post) with due notifications, Monthly Plan + projection, iCloud sync. See [requirements/v1.md](requirements/v1.md). |
| 1.1 | Payee / merchant | Optional payee field with autocomplete that pre-fills the category. Per-merchant totals. |
| 1.2 | Data portability | CSV export and CSV import. |
| 1.3 | Plan alerts & month start | Plan threshold notifications. Custom month start day (e.g. payday). |
| 1.4 | Plan history & suggestions | Browse past months' plan vs actual. History-based suggested planned amounts. |
| 1.5 | App Lock | Face ID / passcode lock and a private app-switcher snapshot. |
| **2.0** | Bill splitting | Splits of expenses the user paid (Equal, Exact amounts, By item), people, repayments, *Settle all*, IOU reminders. |
| 2.1 | Split extras | Tip / service charge / discount in By item mode, distributed proportionally. |
| **3.0** | Apple Intelligence & System | App Intents (Siri, Shortcuts, Spotlight) + Foundation Models (natural-language entry, auto-categorization). |
| 3.1 | iPadOS | Adaptive iPad layout. |
| 3.2 | Widgets & controls | Home/Lock Screen widgets, Control Center control. |
| 3.3 | Receipt scanning | Scan a ticket into a By item split (Vision + Foundation Models). |
| 3.4 | AI insights | Monthly summaries and anomaly highlights. |
| **4.0** | Social | Groups/events, CloudKit sharing, debt simplification. |
| 4.1 | macOS | Native Mac app. |
| 4.2 | Multiple accounts | Multi-account UI and transfers. |
| 4.3 | watchOS | Quick add, complications. |
| 4.4 | Multi-currency | FX conversion between currencies. |

## Release details

### 1.1: Payee / merchant
- Optional payee on transactions (e.g. "Mercadona", "Repsol"), with autocomplete from previous entries.
- Choosing a known payee pre-fills its most recent category.
- Per-payee spending totals in History.
- *Why first:* small, makes entry faster, and the data later feeds AI categorization (3.0) and receipt scanning (3.3).

### 1.2: Data portability
- CSV export of all transactions.
- CSV import with column mapping, date/decimal format detection and duplicate detection.
- *Use cases:* moving from another app or a bank export (and seeding history for plan suggestions in 1.4),
  spreadsheets and taxes, and user trust ("you can always take your data with you").
- From 2.0, the export also includes split shares and repayments.

### 1.3: Plan alerts & month start
- Notifications when a category reaches a threshold of its plan (e.g. 80% and 100%).
- Custom month start day for the plan and all monthly stats.
- *Depends on:* period logic built behind a single abstraction in 1.0.

### 1.4: Plan history & suggestions
- Plan changes apply from the current month on, and past months keep the amounts they had. Previous months can be
  browsed, read-only, as plan vs actual. In 1.0 there is a single current plan.
- Suggested planned amount per category based on recent months' spending (e.g. 3-month average), accepted with one tap.
- Suggestions are shown only when there's enough history.
- *Depends on:* 1.0 Plan. Benefits from 1.2 import.

### 1.5: App Lock
- Optional lock with Face ID / Touch ID and the device passcode as fallback, on launch and after a minute or more in
  the background, offered during onboarding and in Settings. Set per device.
- The app-switcher snapshot is obscured while App Lock is on.
- *Scope:* the withdrawn v1 requirements ONB-003, SEC-001, SEC-002 and A-14 are the starting point. Their full text
  is in [requirements/v1.md as of commit 7af4385](https://github.com/fjvgallego/Finlark/blob/7af4385/docs/requirements/v1.md).

### 2.0: Bill splitting
- *Spending ≠ Balance:* an expense the user paid can be split with friends. The user's share counts as spending, the
  rest is owed to the user, and repayments raise the balance without changing spending.
- People, split modes (Equal, Exact amounts, By item), per-share repayment tracking with partial repayments,
  *Settle all*, *Owed to you* on Home, IOU reminders and a share reminder message.
- *Scope:* the withdrawn v1 requirements PPL-001…004, SPL-001…011, HOM-004, NTF-002, NTF-003 and assumptions A-03…A-06
  and A-10 are the starting point. Their full text is in
  [requirements/v1.md as of commit 7af4385](https://github.com/fjvgallego/Finlark/blob/7af4385/docs/requirements/v1.md).
  The FIN-9 split screens in `Finlark/DesignExplorations/` are its chosen designs.
- *Depends on:* a schema version that adds people, shares and repayments, and the user's share on transactions.

### 2.1: Split extras
- Tip, service charge and discount lines in By item mode, distributed in proportion to each participant's subtotal.

### 3.0: Apple Intelligence & System
- **App Intents:** "Log expense" / "Log income" intents, App Shortcuts (Siri, Action button, Spotlight), App Entities for
  categories and people, and Spotlight indexing.
- **Foundation Models (on-device):** natural-language entry ("23€ at Mercadona yesterday" → draft transaction) and
  category suggestions from note/payee.
- Every AI feature has a non-AI fallback for devices without Apple Intelligence.
- *Depends on:* 1.0 use-case layer (NFR-011). Benefits from 1.1 payee data.

### 3.1: iPadOS
- Adaptive layouts (sidebar, multi-column), keyboard shortcuts, pointer support.

### 3.2: Widgets & controls
- Widgets: month spending vs plan, owed to you, quick add.
- Control Center control and Lock Screen widget for quick add.
- *Depends on:* 3.0 App Intents.

### 3.3: Receipt scanning
- Capture a receipt photo and extract line items into a By item split (Vision text recognition + Foundation Models
  structuring). The user reviews before saving. The photo can be kept with the transaction.
- *Depends on:* 2.0 By item split, 2.1 extras, 3.0 Foundation Models integration.

### 3.4: AI insights
- On-device monthly summary ("You spent 18% less on Dining than usual") and unusual-spending highlights.
- *Depends on:* 3.0.

### 4.0: Social
- Groups/events (e.g. "Lisbon trip") with members and many expenses.
- CloudKit sharing so members using Finlark see the same group data.
- Debt simplification ("who pays whom").
- *Open question:* groups usually need "someone else paid", which 2.0 drops for 1-to-1 splits. Scope to be decided
  when 4.0 is planned.

### 4.1: macOS
- Native Mac app (SwiftUI): windows, menu bar commands, keyboard-first entry.

### 4.2: Multiple accounts
- Create several accounts (Bank, Card, Savings…), per-account and total balances, transfers that don't count as
  spending, and a repayment destination account.
- *Depends on:* a schema version that adds transfers and a repayment's destination account
  ([ADR-0016](adr/0016-data-model-per-slice.md)).

### 4.3: watchOS
- Quick add (including voice/NL), today/month glance, complications.
- *Depends on:* 3.0 App Intents and natural-language entry.

### 4.4: Multi-currency
- Enter transactions in any currency, with conversion to the home currency using exchange rates (source and caching to be
  decided). Useful for travel and group trips.
- *Depends on:* a schema version that adds an optional currency code to amounts, where a missing code means the
  account's currency ([ADR-0016](adr/0016-data-model-per-slice.md)). Pairs well with 4.0 groups.

## Ideas (unscheduled)

- FinanceKit integration (region-limited; requires an Apple entitlement).
- Live Activities for an open split ("2 of 3 friends paid").
- Apple Pay / Wallet hooks.
- Custom app passcode: a passcode for App Lock that belongs to Finlark, so the lock also works on iPhones without a
  device passcode. Builds on App Lock (1.5).

## Dropped

- Shares/percent split mode.
- "You owe them" splits (a friend paid and the user owes them).
- Standalone receipt photo attachments (photos only come with receipt scanning in 3.3).
- Location on transactions.
- Bank sync via aggregators (see [vision](vision.md#non-goals)).
