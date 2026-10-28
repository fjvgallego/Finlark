# Glossary

Domain terms used across docs, code and tickets. Code identifiers should use the English term in the first column.

| Term | Definition |
|---|---|
| **Account** | A place where the user's money lives. The data model supports many accounts. v1 has exactly one, created at onboarding. |
| **Starting balance** | The amount in an account when the user starts using Finlark. |
| **Balance** | The money currently in the account: starting balance + income − expenses (full amount paid) + repayments received. Not physical cash. |
| **Transaction** | A single money movement entered by the user: an *expense* or an *income*. Has amount, currency, date, category and an optional note. |
| **Expense** | A transaction where the user paid money. Lowers the balance by the full amount paid. |
| **Income** | A transaction where the user received money that isn't a repayment (salary, refund, gift…). Raises the balance. |
| **Spending** | What the user consumed: the sum of expenses, counting only the user's share of split expenses. Used for stats, the Plan and projections. Never includes repayments. |
| **Category** | A label for transactions (Groceries, Dining, Salary…). Flat, typed as expense or income. Can be archived. |
| **Home currency** | The currency used for new transactions and all totals. Chosen at onboarding. Every transaction also stores its own ISO currency code. |
| **Recurring template** | A rule that describes a repeating transaction (amount, category, note, type, frequency, start/end date). |
| **Pending item** | An occurrence of a recurring template that is due and waiting for the user to confirm, edit or skip it. Doesn't affect balance or spending until confirmed. |
| **Monthly Plan** | The set of planned amounts per expense category for a calendar month. Set by the user. |
| **Planned amount** | The amount the user expects to spend in one category in a month (e.g. €100 Fuel). |
| **Projection** | The estimated spending at month end for a category (or overall), based on the current pace plus pending recurring expenses still due this month. |
| **Person** | A friend the user splits expenses with. A local record (name, optionally prefilled from Contacts). Friends don't need Finlark. |
| **Split** | An expense the user paid that is shared with one or more people. |
| **Split mode** | How a split is divided: *Equal*, *Exact amounts* or *By item*. |
| **Share** | The part of a split that belongs to one participant. The user's own share counts as spending. Each person's share is owed to the user. |
| **Split item** | A line of a ticket in *By item* mode (e.g. "Pizza €12"), assigned to one or more participants. |
| **Debtor** | A person who owes the user part of a split. Status per split: *Pending*, *Partially paid* or *Paid*. |
| **Repayment** | Money a person gives back for their share. Raises the balance. Is **not** income and doesn't change spending. |
| **Settle all** | A person-level action that records repayments covering every open share that person has. |
| **IOU / Owed to you** | The outstanding (unpaid) part of people's shares. Shown separately from the balance. |
