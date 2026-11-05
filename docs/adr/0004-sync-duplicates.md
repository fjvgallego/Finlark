# ADR-0004: Avoiding duplicates when iCloud syncs

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: A-12, C-3, ONB-004, ONB-005, REC-002, REC-005,
SYN-001

## Context

- CloudKit doesn't support unique constraints (C-3). When two installs each create a record that is meant to exist
  once, both copies sync and both stay.
- Two kinds of records are at risk (A-12): default data created at onboarding (the account and the default
  categories, ONB-004) and recurring occurrences (REC-002).
- ONB-005 says that when another setup's data arrives through iCloud, the user chooses which to keep. Nothing is
  merged.

## Options considered

1. **Store pending items and remove duplicates by key.** Every seeded or generated record gets a fixed key, and a
   cleanup step removes duplicates when synced data arrives. This covers everything, but pending items are stored, so
   they can be duplicated, and the cleanup step runs on them all the time.
2. **Calculate pending items instead of storing them.** Pending items come from the templates, minus the occurrences
   already confirmed or skipped. Only default data and the confirm and skip records need keys.
3. **Wait for iCloud before seeding, or keep a "defaults created" flag in iCloud key-value storage.** This doesn't
   work offline, still races, and the key-value store needs another entitlement.

## Decision

Option 2:

- **Pending items aren't stored.** Pending items are the occurrences of active templates, up to today, minus the
  occurrences that have a confirm or skip record. The recurrence date rules live in Domain
  ([ADR-0002](0002-domain-logic-and-swiftdata.md)).
- **Confirm and skip records have a key:** the template's stable ID plus the occurrence's calendar date, stored
  without a time zone so that every device works out the same key. Templates get a stable ID when they're created.
- **A cleanup step removes duplicate confirm and skip records.** It runs at launch and when synced data arrives. It
  keeps the same survivor on every device (the earliest record, ties broken by ID), so two devices never delete each
  other's copy.
- **Default data has a seed key** (for example `account.default` or `category.expense.groceries`), which doesn't
  depend on the app language. Two default accounts with the same seed key mean that two setups met through iCloud.
  That is the ONB-005 case: the app asks which data to keep, and never cleans up or merges silently.

## Consequences

- Duplicate pending items can't happen, because there's nothing stored to duplicate.
- Default categories created in different languages are still recognized as the same category.
- If two devices confirm the same occurrence while both are offline, the duplicate confirm record is cleaned up but
  both transactions stay, because deleting a transaction the user created would change data silently. This needs two
  iPhones on the same iCloud account and is accepted for v1.
- Pausing must record when the template was paused, so that resuming doesn't bring back occurrences from the pause
  (REC-005).
- "Make recurring" from an existing transaction (REC-001) records that transaction's occurrence as confirmed, so it
  doesn't come back as pending.
- REC-005 doesn't say whether editing a template changes occurrences that are already pending. With calculated pending
  items they would take the new values unless the edit is stored with the date it takes effect. This is an open
  question for the owner, to settle before recurring is implemented.
