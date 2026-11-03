# ADR-0005: How amounts are stored

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: NFR-005, NFR-008, C-3, C-4, A-01

## Context

- NFR-005: amounts are computed as `Decimal`, never floating point. Rounding to the currency's minor unit happens only
  at split-share boundaries and for display.
- C-4: every record that holds money stores its own ISO 4217 currency code.
- How SwiftData stores a `Decimal` property when it syncs through CloudKit, and whether predicates and sorting compare
  such properties by value, couldn't be verified when this ADR was written.

## Options considered

1. **SwiftData `Decimal` properties.** The simplest option, but its CloudKit storage and its behavior in predicates and
   sorting are unverified.
2. **Integers in the currency's minor unit, plus the currency code.** €12.34 is stored as `1234` with `EUR`. Exact,
   stored natively by CloudKit, and predicates and sorting compare values correctly. Converting needs each currency's
   number of minor-unit digits.
3. **`Decimal` stored as text.** Exact at any precision, but the store can't filter or sort by amount, and every read
   parses text (NFR-008).

## Decision

Option 2:

- Every stored amount is an `Int64` count of the currency's minor units, next to the currency code it belongs to.
  That applies to transactions, shares, split items, repayments, planned amounts, recurring templates and the
  starting balance. Negative values are allowed where the requirements allow them (ONB-002).
- Domain works only with a money value type built on `Decimal`. Converting between stored integers and `Decimal`
  happens in Persistence, at the edge ([ADR-0002](0002-domain-logic-and-swiftdata.md)).
- Domain owns a table of minor-unit digits taken from ISO 4217. It doesn't rely on locale or formatter data, which
  doesn't always match ISO 4217's minor units.
- Saving an amount with more decimal places than its currency allows is a programming error, and the use case
  rejects it. Amount fields only accept the currency's number of decimal places.
- Values that are calculated (balance, spending, projection) aren't stored. They're computed in `Decimal` and rounded
  only for display.

## Consequences

- Stored amounts are exact, and they compare and sort correctly in fetches.
- `Decimal` never meets CloudKit, so the unverified behavior doesn't matter.
- The minor-unit table has to be maintained. If ISO 4217 ever changes the minor unit of an existing currency, stored
  amounts in that currency need a migration (NFR-010).
- Every model property that holds money is paired with a currency code, which is a little more schema to write.
