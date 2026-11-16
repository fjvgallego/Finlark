# ADR-0012: The v1.0 data model

Status: **Accepted** (2026-11-16) · Ticket: FIN-15 · Requirements: C-3, C-4, NFR-005, NFR-008, NFR-009, NFR-010,
A-01, A-06, A-07, A-08, A-10, A-12, A-13, ONB-001, ONB-002, ONB-004, ONB-005, ACC-001, ACC-002, TRX-001…006,
CAT-001…003, REC-001…005, PLN-001…003, PPL-001…004, SPL-001…011, NTF-002, NTF-003, SEC-003, SET-001, SYN-003

## Context

- Every v1 feature reads or writes stored data, and architecture.md left the entities, their relationships and the
  v1.0 schema undecided.
- Names and types in the schema are permanent once the CloudKit schema is in production
  ([ADR-0002](0002-domain-logic-and-swiftdata.md)), so v1.0's schema has to be right before release.
- What's already decided:
  - CloudKit compatibility (C-3). Apple's CloudKit limits for Core Data, which SwiftData builds on, add three more:
    every relationship has an inverse, the *Deny* delete rule isn't supported, and relationships can't be ordered.
  - Several accounts and a currency code on every amount, though v1 shows one of each (C-4, A-01).
  - Amounts as `Int64` minor units next to their currency code, and balance, spending and projections never stored
    ([ADR-0005](0005-money-storage.md)).
  - Pending items calculated, not stored. Confirm and skip records keyed by the template's ID and the occurrence date.
    Seed keys on default data ([ADR-0004](0004-sync-duplicates.md)).
  - Per-device settings in `UserDefaults`, not in the schema. The home currency is stored with the account
    ([ADR-0010](0010-per-device-settings.md)).
- ADR-0004 left a question open: whether editing a recurring template changes occurrences that are already pending.
  REC-005 says edits apply to future occurrences only.

## Options considered

The owner chose between these during FIN-15.

**Editing a template while an occurrence is pending**

1. **The pending occurrence keeps the old values.** Each edit is stored with the date it takes effect. Matches REC-005,
   at the cost of keeping a short history per template.
2. **The pending occurrence takes the new values.** The template stores only its current values. Simplest, but REC-005
   would need to change.

**Keeping past months' plans (A-08)**

1. **A history of changes.** Each change is stored with the month it starts. A month's plan is the latest change at or
   before that month, so carrying over stores nothing.
2. **A copy per month.** The plan is copied into each new month. Every device makes its copy automatically, so two
   devices make two, which needs another duplicate cleanup.

**Where the user's own share is stored**

1. **On the transaction.** Share records exist only for people. Spending reads the transaction alone (NFR-008).
2. **As a share like the others.** Uniform split math, but spending has to read the shares, and each share needs a flag
   for the user, because a person's share can sync before its person does.

**How an item in a By item split records its assignees**

1. **A many-to-many relationship to shares,** plus a flag for the user. No extra record type.
2. **One assignment record per item and participant.** The most predictable with CloudKit, but a fourth record type in
   every split.

**How a transaction records that it came from a template (PLN-003)**

1. **On the transaction:** the template's ID and the occurrence date. Survives deleting the template (REC-005) and the
   duplicate cleanup of its confirm record (ADR-0004).
2. **Through the confirm record's link to the transaction.** Nothing is stored twice, but if the record goes, the
   transaction turns into variable spending and the projection changes.

**End-to-end encryption in iCloud.** A field's encryption can't change once the CloudKit schema is in production.

1. **Names and notes.** Apple can't read them, and amounts and dates stay ordinary fields.
2. **Names, notes and amounts.** Even the size of the user's spending is private.
3. **Nothing.** Apple-held keys protect everything, unless the user has turned on Advanced Data Protection.

Encrypted fields use keys in the user's iCloud Keychain, so resetting the Keychain makes them unrecoverable from
iCloud. CloudKit can't query them, which doesn't matter here, because SwiftData queries on the device.

## Decision

Option 1 in every case, except encryption, where it's option 2, extended to the fields that identify a category. The
v1.0 schema is `SchemaV1`, a `VersionedSchema` in Persistence, with these entities.

### Rules for every entity

- Every property has a default, or is optional where *missing* has a meaning stated below (C-3). No unique constraints.
- Every entity has `id: UUID` (set when created, never changed, and used to break ties) and `createdAt: Date`.
- Every relationship is optional and has an inverse. Delete rules are *Nullify* or *Cascade*, never *Deny*. A rule that
  needs *Deny* ("a person with open shares can't be deleted") is checked by the use case.
- A record whose parent hasn't synced yet (a transaction without its account or category, a share, item or repayment
  without its transaction or share, a revision or occurrence record without its template) is left out of every
  calculation and list until the parent arrives, and so are the records under it. Accounts and categories aren't
  deleted in v1, so a transaction's parents always arrive. A share without a person still counts toward what's owed,
  and shows without a name.
- Enumerations are stored as their `String` raw value. A value Persistence doesn't recognize, written by a newer version
  of the app, maps to a safe fallback documented where Persistence maps the value to Domain, and never crashes the app.
- Calendar dates without a time (a transaction's date, an occurrence) are stored as `Int` in the form `yyyymmdd`, with
  no time zone, so every device reads the same day. Months are `Int` in the form `yyyymm`. Persistence converts them to
  Domain's day and period types.
- Amounts follow ADR-0005: `…Minor: Int64` next to `currencyCode: String`.
- These properties are marked `.allowsCloudEncryption`, so CloudKit stores them end-to-end encrypted: every `name`,
  `note` and `…Minor` property, and `seedKey`, `symbolName` and `colorName`, which would otherwise show what a category
  is. Dates, kinds, currency codes, IDs, how many records there are and how they link stay readable to Apple.
- Relationships are unordered. Where order matters, a `sortIndex: Int` stores it.

### Entities

**Account** (ONB-001, ONB-002, ACC-001, ACC-002, C-4)
- `name: String`, `startingBalanceMinor: Int64`, `currencyCode: String`. In v1 the account's currency is the home
  currency (A-07, ADR-0010).
- `seedKey: String?`: `account.default` for the account created at onboarding (ADR-0004).
- `transactions` → Transaction, *Nullify*.

**Category** (CAT-001…003, ONB-004)
- `name: String`, `kind: String` (`expense` or `income`), `symbolName: String` (an SF Symbol), `colorName: String`
  (a DesignSystem color token), `isArchived: Bool`.
- `seedKey: String?`: for example `category.expense.groceries`. A default category stores its name in the app
  language at onboarding.
- `transactions`, `templateRevisions` and `plannedAmounts`, all *Nullify*. Categories aren't deleted in v1 (A-13).

**Transaction** (TRX-001…006, SPL-001, PLN-003)
- `kind: String` (`expense` or `income`), `amountMinor: Int64` (the full amount paid), `currencyCode: String`,
  `day: Int`, `note: String`.
- `splitMode: String?`: `equal`, `exactAmounts` or `byItem`. `nil` means the transaction isn't split.
- `userShareMinor: Int64`: the user's share when split. Spending is `amountMinor` for an expense that isn't split, and
  `userShareMinor` for one that is.
- `recurringTemplateID: UUID?` and `recurringOccurrenceDay: Int?`: set when the transaction comes from confirming a
  pending item, or when it's the one *Make recurring* started from (REC-001), which then no longer counts as variable
  spending. When confirming, `recurringOccurrenceDay` is the occurrence's date, which differs from the transaction's
  `day` if the user changed the date before confirming (REC-003). For *Make recurring* it's the transaction's `day`. If
  *Make recurring* starts the template on a day that makes the transaction's day not an occurrence, neither is set, and
  the transaction stays variable spending. Kept when the template is deleted.
- Deleting a transaction that came from a template keeps its occurrence record, so the occurrence doesn't come back as
  pending.
- `account` → Account, `category` → Category. `shares` → Share and `splitItems` → SplitItem, both *Cascade* (SPL-011).
- For a split, `userShareMinor` plus the shares' amounts equals `amountMinor`, and in By item mode the items add up to
  `amountMinor`. The use case checks this on every save. While sync is still delivering a split's records they may not
  add up for a moment: Domain uses the stored values as they are, and the rest of the split's records settle it.

**Share** (SPL-001…011): what one person owes on a split. The user's share isn't a Share record.
- `amountMinor: Int64`, `currencyCode: String`.
- `sortIndex: Int`: the order the people were added to the split. The lowest is the "first assignee" who gets a shared
  item's remainder when the user isn't assigned to it (SPL-004), and the split detail and the reminder message list
  people in this order (SPL-005, NTF-003). Editing the split keeps it.
- `transaction` → Transaction, `person` → Person.
- `repayments` → Repayment, *Cascade* (A-06).
- `splitItems` ↔ SplitItem, many-to-many, *Nullify*.

**SplitItem** (SPL-004, SPL-010)
- `name: String`, `amountMinor: Int64`, `currencyCode: String`, `sortIndex: Int`.
- `includesUser: Bool`. An item with no shares and `includesUser` false counts as the user's (SPL-004).
- `transaction` → Transaction. `shares` ↔ Share.
- The shares' amounts are calculated from the items when the split is saved, and stored on the shares, so that
  reading what's owed doesn't redo the By item math.

**Repayment** (SPL-006…009)
- `amountMinor: Int64`, `currencyCode: String`, `day: Int`.
- `share` → Share. A repayment goes to the account of its split's transaction.

**Person** (PPL-001…004)
- `name: String`, `isArchived: Bool`.
- `shares` → Share, *Nullify*.

**RecurringTemplate** (REC-001…005): only the template's identity. Its values are in its revisions.
- `revisions` → TemplateRevision, *Cascade*. `occurrenceRecords` → OccurrenceRecord, *Cascade*.

**TemplateRevision** (REC-001, REC-005, CAT-003): the template's values from a given day on.
- `effectiveDay: Int`, `kind: String`, `amountMinor: Int64`, `currencyCode: String`, `note: String`,
  `frequency: String` (`weekly`, `monthly` or `yearly`), `startDay: Int`, `endDay: Int?`, `isPaused: Bool`.
- `template` → RecurringTemplate, `category` → Category.
- Creating a template adds its first revision, with `effectiveDay` equal to `startDay`, so a template that starts in
  the past brings its missed occurrences (REC-002).
- Editing or pausing adds a revision that takes effect the next day, so an occurrence that's already pending, or falls
  today, keeps the values it had. Resuming adds one that takes effect the same day, so an occurrence that falls on the
  day of resuming appears.
- Editing changes the latest revision in place instead of adding one when no occurrence on or after its
  `effectiveDay` has an occurrence record, and the revision was created today or hasn't taken effect yet. This fixes a
  mistake made while creating a template, and lets a template that hasn't started move its start into the past and
  bring its missed occurrences, as creating it would (REC-002). The revision keeps its `id` and `createdAt`. If it's the
  template's first revision, its `effectiveDay` follows the new `startDay`.
- On any day, the template follows the most recently created revision (the latest `createdAt`, then the highest `id`)
  among those whose `effectiveDay` is on or before that day. A newer revision therefore always wins over an older one
  from its own `effectiveDay` on, even when the older one takes effect later (a template that starts in the future, or
  pausing and resuming on the same day).
- A paused revision has no occurrences, so resuming doesn't bring back the days in between (ADR-0004). Occurrences from
  before a pause stay pending.
- Archiving a category used by a template (CAT-003) adds a revision with the replacement category. Like an edit, it
  takes effect the next day, so an occurrence already pending keeps the archived category.
- A template's name, where one is shown (SET-001), is its `note`, or its category's name when the note is empty.
- Revisions aren't cleaned up like duplicates. Two devices editing at once each add one, and the rule above picks
  between them. Two devices changing the same revision in place resolve last-writer-wins (SYN-003).

**OccurrenceRecord** (REC-003, REC-004): marks one occurrence as confirmed or skipped.
- `templateID: UUID`, `occurrenceDay: Int`, `outcome: String` (`confirmed` or `skipped`).
- `template` → RecurringTemplate.
- The key is `templateID` plus `occurrenceDay`, and the duplicate cleanup follows ADR-0004. `templateID` is stored as
  well as the relationship, because the record can sync before its template.
- *Make recurring* adds a `confirmed` record with `occurrenceDay` equal to the transaction's `day`, when that day is an
  occurrence (ADR-0004).

**PlannedAmount** (PLN-001, A-08): a category's planned amount from a given month on.
- `fromMonth: Int`, `amountMinor: Int64?`, `currencyCode: String`. `nil` means the plan for the category was cleared.
- `category` → Category.
- A month's plan for a category is the PlannedAmount with the latest `fromMonth` at or before that month.
- If the category has a PlannedAmount whose `fromMonth` is the current month, a change updates the one that wins (the
  latest `createdAt`, then the highest `id`). Otherwise it adds one with `fromMonth` set to the current month, so past
  months never change.
- Archiving a category (CAT-003) clears its plan from the current month on, the same way as the user clearing it.
  Past months keep their amounts, and unarchiving doesn't bring the plan back.
- Planned amounts aren't cleaned up like duplicates. If two devices each add one for the same month, the same rule
  picks the winner.

Changing the home currency, which A-07 allows only while there are no transactions, also changes the currency code of
the account's starting balance, every template revision and every planned amount. Each amount keeps its value and is
rewritten in the new currency's minor units, because currencies have different numbers of decimals: €12.34 (`1234`)
becomes $12.34 (`1234`), and €10.00 (`1000`) becomes ¥10 (`10`). When the new currency has fewer decimals, the value is
rounded to the nearest minor unit, halves away from zero, so €10.55 becomes ¥11.

### Stored and calculated

| Calculated by Domain, never stored | Comes from |
|---|---|
| Balance | The account's starting balance, transactions and repayments (ACC-001) |
| Spending, month totals | Transactions: the amount, or the user's share |
| Share status, paid so far, what's owed | Shares and their repayments |
| Pending items, next occurrence | Template revisions minus occurrence records |
| A month's plan, plan status, projection | Planned amounts, transactions, pending and upcoming occurrences |
| Variable spending (PLN-003) | Transactions without `recurringTemplateID` |
| Transactions per category (CAT-001) | Transactions |
| Which IOU reminders exist (NTF-002) | Shares not fully paid, each from its split date plus the per-device reminder days, minus the shares whose reminder date is before this device's reminder start date and the shares this device has recorded as reminded |

Each device keeps two values in `UserDefaults` so that an IOU reminder fires once per share on it (A-10):

- **The reminder start date:** the day the device finished onboarding or restoring from iCloud (ONB-005). A share
  whose reminder date is before it never fires on that device, so a new iPhone doesn't send a reminder for every old
  unpaid share at once.
- **The reminded shares:** when the notifications are recalculated, the device records the IDs of the shares whose
  reminder date has passed, so changing the reminder days or a split's date never repeats a reminder. An ID is removed
  only when its share is deleted, so undoing a payoff (SPL-008, SPL-009) doesn't send the reminder again.

These are device state rather than settings, kept next to the per-device settings of ADR-0010 as an exception to that
ADR's list.

## Consequences

- Every requirement's stored data has a place, and adding a field later stays possible (NFR-010).
- Multiple accounts (roadmap 3.2) need no new record type. A repayment's destination account and transfers will be
  added as new fields then. Multi-currency (3.4) finds a currency code on every amount.
- Template revisions make occurrence dates harder to work out, because they come from several revisions. Domain owns
  that logic, and it needs thorough tests (NFR-009).
- A template's earlier values stay stored, on the device and in iCloud, until the template is deleted.
- Delete All Data (SEC-003) deletes every entity type in `SchemaV1`, type by type rather than by following
  relationships, so records whose parent never arrived go too. It also removes every scheduled and delivered
  notification, because they show names, amounts and notes, and clears the reminder start date and the reminded
  shares. How the app's
  CloudKit data is removed and the per-device settings are reset (ADR-0010) is decided in the SEC-003 ticket.
- `Transaction` has the same name as SwiftUI's `Transaction`. Code that imports both writes `Persistence.Transaction`.
  The name follows the glossary and is permanent in the CloudKit schema.
- A default category keeps the name it got at onboarding if the app language changes later.
- If the user resets their iCloud Keychain, the encrypted fields can't be restored from iCloud.
- With two devices, each one can send its own IOU reminder for the same share.
- How SwiftData syncs the many-to-many link between shares and items, and encrypted fields, through CloudKit is
  supported by community examples rather than Apple documentation, and so is what happens to the store on a device
  after an iCloud Keychain reset. The ticket that writes `SchemaV1` tests all three on a CloudKit development container
  before the schema goes to production.
- Indexes for NFR-008 (for example on `Transaction.day`) are decided when that measurement is done.
