# Glossary

Domain terms used across docs, code and tickets. Code identifiers should use the English term in the first column.

| Term | Definition |
|---|---|
| **Account** | A place where the user's money lives. v1 has exactly one, created at onboarding. It stores the home currency's code. |
| **Starting balance** | The amount in an account when the user starts using Finlark. |
| **Balance** | The money currently in the account: starting balance + income − expenses (full amount paid). From 2.0, plus repayments received. Not physical cash. |
| **Transaction** | A single money movement entered by the user: an *expense* or an *income*. Has amount, date, category and an optional note. The amount is in the home currency. |
| **Expense** | A transaction where the user paid money. Lowers the balance by the full amount paid. |
| **Income** | A transaction where the user received money that isn't a repayment (salary, refund, gift…). Raises the balance. |
| **Spending** | What the user consumed: the sum of expenses. From 2.0, only the user's share of a split expense counts. Used for stats, the Plan and projections. Never includes repayments. |
| **Category** | A label for transactions (Groceries, Dining, Salary…). Flat, typed as expense or income. Can be archived. |
| **Home currency** | The currency used for new transactions and all totals. Chosen at onboarding. Its ISO currency code is stored once, on the account ([ADR-0016](adr/0016-data-model-per-slice.md)). |
| **Fund code** | An ISO 4217 code for a unit of account rather than money anyone holds, such as CLF or USN. Not a currency in Finlark ([ADR-0014](adr/0014-append-only-currency-table.md)). |
| **Withdrawn currency** | A currency that was in Finlark's currency table and that ISO 4217 no longer lists. Amounts in it still load, but the user can't pick it ([ADR-0014](adr/0014-append-only-currency-table.md)). |
| **Recurring template** | A rule that describes a repeating transaction (amount, category, note, type, frequency, start/end date). |
| **Occurrence** | One date on which a recurring template falls, from its frequency and its start and end dates. See *Pending item*. |
| **Occurrence record** | Marks one occurrence as confirmed or skipped, keyed by the template's ID and the occurrence's date. |
| **Pending item** | An occurrence of a recurring template that is due and waiting for the user to confirm, edit or skip it. Doesn't affect balance or spending until confirmed. |
| **Monthly Plan** | The set of planned amounts per expense category, applied to each calendar month. Set by the user. In v1 one plan applies to every month (PLN-001). |
| **Planned amount** | The amount the user expects to spend in one category in a month (e.g. €100 Fuel). In v1 one plan applies to every month until it's changed or cleared. From 1.4, past months keep their amounts. |
| **Projection** | The estimated spending at month end for a category (or overall), based on the current pace plus pending recurring expenses still due this month. |
| **Plan status** | How a planned category, or the plan as a whole (HOM-003), is doing in the current month: *On track*, *At risk* or *Over*, as defined in PLN-002. |
| **Period** | The span of days that a monthly figure covers: spending, the Plan, projections and History's totals. In v1 a period is a Gregorian calendar month. From v1.3 it can start on a custom day of the month (roadmap 1.3). |
| **Day** | A date in the Gregorian calendar, with no time or time zone, the same on every device ([ADR-0013](adr/0013-gregorian-days.md)). Screens show it in the user's own calendar. |
| **Person** | From 2.0: a friend the user splits expenses with. A local record (name, optionally prefilled from Contacts). Friends don't need Finlark. |
| **Split** | From 2.0: an expense the user paid that is shared with one or more people. |
| **Split mode** | From 2.0: how a split is divided: *Equal*, *Exact amounts* or *By item*. |
| **Share** | From 2.0: the part of a split that belongs to one participant. The user's own share counts as spending. Each person's share is owed to the user. |
| **Split item** | From 2.0: a line of a ticket in *By item* mode (e.g. "Pizza €12"), assigned to one or more participants. |
| **Debtor** | From 2.0: a person who owes the user part of a split. Status per split: *Pending*, *Partially paid* or *Paid*. |
| **Repayment** | From 2.0: money a person gives back for their share. Raises the balance. Is **not** income and doesn't change spending. |
| **Settle all** | From 2.0: a person-level action that records repayments covering every open share that person has. |
| **IOU / Owed to you** | From 2.0: the outstanding (unpaid) part of people's shares. Shown separately from the balance. |
| **App Lock** | From 1.5: optional protection that asks for Face ID or Touch ID, with the device passcode as fallback, when Finlark opens or returns after a minute or more in the background. Set per device. |
