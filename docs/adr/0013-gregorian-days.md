# ADR-0013: Stored days are Gregorian, and Domain takes a time zone instead of a calendar

Status: **Accepted** (2026-11-18) · Ticket: FIN-18 · Requirements: NFR-004, NFR-009

## Context

- [ADR-0012](0012-v1-data-model.md) stores calendar dates as `yyyymmdd` and months as `yyyymm`, with no time zone, so
  every device reads the same day. The numbers in those forms are a year, a month and a day, and they only identify a
  date when every device reads them in the same calendar.
- Architecture rule 4 said Domain never reads "the clock, the calendar or the time zone" itself.
  [ADR-0007](0007-testing-strategy.md) says Domain functions take "the current date, calendar and time zone as inputs".
- An iPhone can use a calendar other than the Gregorian one, such as the Buddhist or the Japanese calendar. On the
  Buddhist calendar, 2026 is 2569.
- The clock and the time zone change what a function returns, so tests have to control them. The rules of the
  Gregorian calendar don't change: February 2024 has 29 days on every device.

## Options considered

1. **Use the user's calendar.** A user on the Buddhist calendar would store 2569 for 2026, and a device on the
   Gregorian calendar would read that as a date 543 years later.
2. **Pass in a `Calendar`, and require it to be Gregorian.** Matches rule 4's wording. But every caller would pass the
   same fixed calendar, and passing any other one would make the function fail.
3. **Domain always uses the Gregorian calendar, and only the time zone is passed in.** Converting a `Date` to a day
   still depends on the time zone, which the caller provides. Domain takes no parameter for something that never
   varies.

## Decision

Option 3:

- Stored days and months, and Domain's `Day` and `Period`, always use the Gregorian calendar, whatever calendar the
  user has chosen.
- Domain doesn't take a `Calendar` as a parameter and never reads `Calendar.current`. Where it needs a Foundation
  calendar, it creates `Calendar(identifier: .gregorian)` itself. Such a calendar starts with the device's time zone,
  so Domain only calls its APIs that take a time zone explicitly, such as `dateComponents(in:from:)`, or sets the
  calendar's `timeZone` to the one passed in before using it.
- Domain never reads the clock or the time zone. Turning a `Date` into a `Day` takes the time zone as a parameter. A
  Domain function that needs today takes it as a `Day`, or as a `Date` together with a time zone.
- Outside Domain, the caller passes the device's current time zone, read when the value is needed and never kept, so
  a user who travels gets the day where they are.
- Valid years are 1583 to 9999, for both days and months. Foundation's Gregorian calendar uses the Julian calendar
  before 15 October 1582, where it would disagree with Domain's own calendar rules, so 1583 is the first whole year
  both agree on. Above 9999, a year doesn't fit `yyyymmdd`.
- A stored value that isn't a valid day or month, such as `20260230` or a year before 1583, doesn't become a `Day` or a
  `Period`. Persistence decides what happens to the record that holds it, as ADR-0012 does for enumeration values it
  doesn't recognize: a fallback documented where Persistence maps the value, never a crash
  ([ADR-0012](0012-v1-data-model.md)).
- Screens show dates in the user's own calendar and locale, with `FormatStyle` (NFR-004). Only storage and Domain are
  fixed to the Gregorian calendar.

## Consequences

- A day means the same date on every device, whatever calendar each one uses.
- Domain's date functions take one parameter fewer, and their tests stay deterministic, because the clock and the time
  zone are still inputs (NFR-009).
- Architecture rule 4 now reads "the clock or the time zone", and says that days and months always use the Gregorian
  calendar.
- ADR-0007 isn't rewritten ([ADR-0001](0001-record-architecture-decisions.md)). Its line "Domain functions take the
  current date, calendar and time zone as inputs" now means the current date and the time zone. Domain uses the
  Gregorian calendar itself.
- A day before 1583 can't be a `Day`, so Finlark never writes one. One that arrives from elsewhere is handled as
  described above. No real transaction has such a date. Limits on the dates a user may enter, such as the earliest
  date of a transaction, belong in the screens and use cases, not in `Day`.
- Showing a stored day with `FormatStyle`, and scheduling a notification at 09:00 on a due date (NTF-001), need a
  `Date` built from a `Day` in a given time zone. Domain doesn't provide that conversion yet. The first ticket that
  needs it adds it to Domain.
