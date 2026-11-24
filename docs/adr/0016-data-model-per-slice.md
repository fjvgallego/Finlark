# ADR-0016: The data model grows slice by slice, with one currency on the account

Status: **Accepted** (2026-11-24) · Ticket: FIN-59 · Requirements: C-3, C-4, NFR-005, NFR-010, A-01, A-07 ·
Supersedes: [ADR-0012](0012-v1-data-model.md) · Refines: [ADR-0005](0005-money-storage.md)

## Context

- The owner chose to change how the project is run, to make it more efficient and less overwhelming (FIN-59). Until
  now, everything was designed up front: about 60 v1 requirements, 15 ADRs and the whole v1.0 data model
  ([ADR-0012](0012-v1-data-model.md)). That model included entities for features that hadn't been built and for
  releases years away. No feature was built yet.
- 1.0 is now smaller ([requirements/v1.md](../requirements/v1.md)). Bill splitting moves to 2.0, and plan history
  and App Lock move to 1.x releases ([roadmap](../roadmap.md)). Work goes in vertical slices: one feature at a time,
  from model to screen.
- C-4 is withdrawn. 1.0 has one account and one currency, and the data model no longer prepares for multiple accounts
  (roadmap 4.2) or currencies (4.4).
- Nothing is stored yet and the CloudKit schema isn't in production, so the schema can change freely until 1.0 ships
  ([ADR-0002](0002-domain-logic-and-swiftdata.md)). After that, versions only add record types and fields.

## Options considered

**The v1.0 data model**

1. **Keep ADR-0012 and remove what left 1.0** (splits, people, plan history, multi-account). Little rewriting, but
   1.0 keeps entities designed before their features existed, such as template revisions, and every slice inherits
   decisions made without it.
2. **Supersede ADR-0012. Each slice adds the entities it needs.** Only the rules for how values are stored, which are
   hard to change once stored, apply to every slice. Each entity is designed when its feature is built, but slices
   need care to stay consistent with each other.

**Where the currency code is stored**

1. **Next to every amount**, as ADR-0005 says. Ready for 4.4 with no new fields, but every amount in the schema carries
   a code that 1.0 never reads.
2. **Only on the account.** Every amount is in the account's currency. In 4.4, amounts get an optional `currencyCode`
   field, which CloudKit allows after release because it only adds fields. A missing code means the account's
   currency, which also covers records written by older app versions, so no stored data has to be rewritten.

## Decision

Option 2 in both cases.

- ADR-0012 is superseded. The v1.0 schema is still `SchemaV1`, a `VersionedSchema` in Persistence. Each slice adds or
  changes the entities its feature needs, and decides them then. The `FIN-19-schema-v1-models` branch, written from
  ADR-0012, is kept as a reference and isn't merged.
- These rules apply to every entity:
  - Every entity has `id: UUID`, set when it's created and never changed, and `createdAt: Date`.
  - Every relationship is optional and has an inverse. Delete rules are *Nullify* or *Cascade*, never *Deny*, and a rule
    that would need *Deny* is checked by the use case. Relationships are unordered. Where order matters, a
    `sortIndex: Int` stores it. (C-3, and Apple's CloudKit limits for Core Data.)
  - Enumerations are stored as their `String` raw value.
  - Days without a time are stored as `Int` in the form `yyyymmdd`, and months as `Int` in the form `yyyymm`
    ([ADR-0013](0013-gregorian-days.md)).
  - Amounts are `Int64` minor units ([ADR-0005](0005-money-storage.md)). Values that can be calculated, such as the
    balance, spending and projections, are never stored.
- This refines ADR-0005: the currency code is stored only on the account. No other amount stores a code.
- Whether any field is end-to-end encrypted in iCloud is open again. A field's encryption can't change once the
  CloudKit schema is in production, so the ticket that sets up CloudKit sync decides it, before 1.0 ships.

## Consequences

- Each slice brings up only its own data model decisions, when the feature is built.
- Slices can contradict each other. The rules above and the code review keep them consistent, and a slice that needs to
  change an earlier slice's entity can do so freely until 1.0 ships.
- Changing the home currency (A-07), allowed only while there are no transactions, changes the account's code and
  converts the amounts already stored in the old currency's minor units. The slice that adds it decides how.
- Multiple accounts (4.2) and multi-currency (4.4) each need a schema version that adds fields. The hard part of 4.4
  is exchange rates and totals across currencies, and storing codes today wouldn't help with that.
- Reading records whose parent hasn't synced yet, and values that a newer app version wrote, is decided in Persistence
  code by the slices involved, not here.
