# Roadmap

Versions are **indicative**. Priorities are revisited after each release, and each release gets its own requirements
file when it's planned in detail.

## Versioning rules

- **Major (x.0):** one big feature or platform capability.
- **Minor (x.y):** one small theme. New devices ship **one per minor release**, never several together.
- Every release keeps the data model CloudKit-compatible and ships with a schema migration if needed.

## Overview

| Version | Theme | Highlights |
|---|---|---|
| **1.0** | Core (iPhone) | Transactions, categories, single account, recurring (confirm-to-post), Monthly Plan + projection, bill splitting, notifications, app lock, iCloud sync. See [requirements/v1.md](requirements/v1.md). |
| 1.1 | Payee / merchant | Optional payee field with autocomplete that pre-fills the category. Per-merchant totals. |
| 1.2 | Data portability | CSV export and CSV import. |
| 1.3 | Plan alerts & month start | Plan threshold notifications. Custom month start day (e.g. payday). |
| 1.4 | Plan suggestions | History-based suggested planned amounts. |
| 1.5 | Split extras | Tip / service charge / discount in By item mode, distributed proportionally. |
| **2.0** | Apple Intelligence & System | App Intents (Siri, Shortcuts, Spotlight) + Foundation Models (natural-language entry, auto-categorization). |
| 2.1 | iPadOS | Adaptive iPad layout. |
| 2.2 | Widgets & controls | Home/Lock Screen widgets, Control Center control. |
| 2.3 | Receipt scanning | Scan a ticket into a By item split (Vision + Foundation Models). |
| 2.4 | AI insights | Monthly summaries and anomaly highlights. |
| **3.0** | Social | Groups/events, CloudKit sharing, debt simplification. |
| 3.1 | macOS | Native Mac app. |
| 3.2 | Multiple accounts | Multi-account UI and transfers. |
| 3.3 | watchOS | Quick add, complications. |
| 3.4 | Multi-currency | FX conversion between currencies. |

## Release details

### 1.1: Payee / merchant
- Optional payee on transactions (e.g. "Mercadona", "Repsol"), with autocomplete from previous entries.
- Choosing a known payee pre-fills its most recent category.
- Per-payee spending totals in History.
- *Why first:* small, makes entry faster, and the data later feeds AI categorization (2.0) and receipt scanning (2.3).

### 1.2: Data portability
- CSV export of all transactions (including split shares and repayments).
- CSV import with column mapping, date/decimal format detection and duplicate detection.
- *Use cases:* moving from another app or a bank export (and seeding history for plan suggestions in 1.4),
  spreadsheets and taxes, and user trust ("you can always take your data with you").

### 1.3: Plan alerts & month start
- Notifications when a category reaches a threshold of its plan (e.g. 80% and 100%).
- Custom month start day for the plan and all monthly stats.
- *Depends on:* period logic built behind a single abstraction in 1.0.

### 1.4: Plan suggestions
- Suggested planned amount per category based on recent months' spending (e.g. 3-month average), accepted with one tap.
- Shown only when there's enough history.
- *Depends on:* 1.0 Plan. Benefits from 1.2 import.

### 1.5: Split extras
- Tip, service charge and discount lines in By item mode, distributed in proportion to each participant's subtotal.

### 2.0: Apple Intelligence & System
- **App Intents:** "Log expense" / "Log income" intents, App Shortcuts (Siri, Action button, Spotlight), App Entities for
  categories and people, and Spotlight indexing.
- **Foundation Models (on-device):** natural-language entry ("23€ at Mercadona yesterday" → draft transaction) and
  category suggestions from note/payee.
- Every AI feature has a non-AI fallback for devices without Apple Intelligence.
- *Depends on:* 1.0 use-case layer (NFR-011). Benefits from 1.1 payee data.

### 2.1: iPadOS
- Adaptive layouts (sidebar, multi-column), keyboard shortcuts, pointer support.

### 2.2: Widgets & controls
- Widgets: month spending vs plan, owed to you, quick add.
- Control Center control and Lock Screen widget for quick add.
- *Depends on:* 2.0 App Intents.

### 2.3: Receipt scanning
- Capture a receipt photo and extract line items into a By item split (Vision text recognition + Foundation Models
  structuring). The user reviews before saving. The photo can be kept with the transaction.
- *Depends on:* 1.0 By item split, 1.5 extras, 2.0 Foundation Models integration.

### 2.4: AI insights
- On-device monthly summary ("You spent 18% less on Dining than usual") and unusual-spending highlights.
- *Depends on:* 2.0.

### 3.0: Social
- Groups/events (e.g. "Lisbon trip") with members and many expenses.
- CloudKit sharing so members using Finlark see the same group data.
- Debt simplification ("who pays whom").
- *Open question:* groups usually need "someone else paid", which v1 dropped for 1-to-1 splits. Scope to be decided
  when 3.0 is planned.

### 3.1: macOS
- Native Mac app (SwiftUI): windows, menu bar commands, keyboard-first entry.

### 3.2: Multiple accounts
- Create several accounts (Bank, Card, Savings…), per-account and total balances, transfers that don't count as
  spending, and a repayment destination account.
- *Depends on:* 1.0 multi-account data model (C-4).

### 3.3: watchOS
- Quick add (including voice/NL), today/month glance, complications.
- *Depends on:* 2.0 App Intents and natural-language entry.

### 3.4: Multi-currency
- Enter transactions in any currency, with conversion to the home currency using exchange rates (source and caching to be
  decided). Useful for travel and group trips.
- *Depends on:* 1.0 per-transaction currency codes (C-4). Pairs well with 3.0 groups.

## Ideas (unscheduled)

- FinanceKit integration (region-limited; requires an Apple entitlement).
- Live Activities for an open split ("2 of 3 friends paid").
- Apple Pay / Wallet hooks.

## Dropped

- Shares/percent split mode.
- "You owe them" splits (a friend paid and the user owes them).
- Standalone receipt photo attachments (photos only come with receipt scanning in 2.3).
- Location on transactions.
- Bank sync via aggregators (see [vision](vision.md#non-goals)).
