# ADR-0014: The currency table is append-only and leaves out fund codes

Status: **Accepted** (2026-11-19) · Ticket: FIN-18 · Requirements: ONB-001, SET-001, A-07, NFR-005, NFR-010, C-4

## Context

- [ADR-0005](0005-money-storage.md) stores every amount as an `Int64` count of minor units next to its ISO 4217 code,
  and Domain owns a table of each currency's minor-unit digits. A stored `1234` is €12.34 only because the table says
  EUR has 2 digits. The table is part of how stored data is read.
- The table is generated from SIX's ISO 4217 List One by `scripts/generate-currency-table.swift`. ISO amends the list a
  few times a year:
  - It withdraws currencies. The Croatian kuna (HRK) was replaced by the euro in 2023, and the old Sierra Leone leone
    (SLL) and the Zimbabwe dollar (ZWL) were replaced too. A withdrawn code disappears from List One.
  - It can change a currency's minor unit.
- If regenerating removed a code, records stored in it would no longer load. If it changed a code's digits, stored
  amounts in it would be read 10 or 100 times off. ADR-0005 expected a migration for a change of digits, but nothing
  made the person regenerating notice one.
- List One also has fund codes, such as CLF (a Chilean unit of account indexed to inflation) and USN (next-day US
  dollars). Nobody keeps an account in them. Finlark has no backend and no import, so a stored currency code is always
  one the user picked in onboarding (ONB-001) or in Settings (SET-001), and neither offers a fund code.
- [coding-style.md](../technical/coding-style.md) says a type checks only its stored format and invariants, and leaves
  limits on what the user may enter to the use case, so stored data can't stop being readable.

## Options considered

1. **The table is append-only.** New codes are added. Existing codes are never removed, and their digits never change.
   The generator reads the current table and enforces both. It's cheap, and a stored amount always reads the same.
2. **Every stored amount also stores its number of digits.** Each amount reads correctly on its own, whatever the
   table says. It changes the data model ([ADR-0012](0012-v1-data-model.md)) and adds a field to every amount, for a
   rare event.
3. **Each regeneration is reviewed as a schema migration (NFR-010).** It works only if whoever regenerates notices
   that a code was removed or changed.

## Decision

Option 1, and the table leaves out fund codes:

- The table holds every code that List One has given a minor unit since the table was first generated, except fund
  codes. Codes without a minor unit ("N.A."), such as XAU, are left out, as ADR-0005 implies.
- Leaving fund codes out of `Currency` isn't a limit on what the user may enter. It's the stored format: a fund code can
  never be stored, so no stored data can stop being readable, which is what the coding-style rule protects.
- A code is never removed from the table. A code in the table that List One no longer lists with a minor unit, or now
  flags as a fund, stays with its digits and is marked withdrawn. `Currency(code:)` still returns it, so records stored
  in it keep loading. Neither onboarding (ONB-001) nor Settings (SET-001, A-07) offers it. A user whose home currency
  is withdrawn keeps it.
- A code's digits never change. If List One changes them, the generator fails and the table keeps the old digits. Using
  the new digits needs a new ADR, with a migration of the amounts stored in that currency (NFR-010). That ADR's ticket
  also changes the generator to apply it.
- A withdrawn code that List One lists again with the same digits, and not as a fund, stops being withdrawn.
- The generator enforces all of this, using the current table as its input along with List One. The table is never
  edited by hand.

## Consequences

- Once a version of Finlark knows a currency, it and every later version read its amounts the same, whatever ISO later
  does to it. What an older version does with a code it doesn't know yet, synced from a newer one, is decided in
  FIN-19, where Persistence maps stored codes.
- ADR-0005 isn't rewritten ([ADR-0001](0001-record-architecture-decisions.md)). Its consequence "If ISO 4217 ever
  changes the minor unit of an existing currency, stored amounts in that currency need a migration" still holds, and
  the generator now makes sure nobody misses it.
- The table only grows. Withdrawals happen about once a year, so it stays small.
- Until the ADR for a changed minor unit is written, the generator fails on every run, so no other code can be added
  either. A change of digits can't be missed.
- Domain has no fund codes, so no currency has more than 3 digits today (KWD, BHD and others). A 4-digit currency
  could still be added by a future List One.
- Fund codes could only come back with a new ADR, for example if an import feature brought them in from bank data.
