# Vision

## Pitch

**Finlark is a personal finance tracker for iPhone (later iPad, Mac and Apple Watch) that knows the difference
between what you spend and what leaves your account.**

Pay a €120 dinner for four friends and most trackers record €120 of "Dining". Finlark records your €30 share as
spending, keeps track of the €90 your friends owe you, and adds each repayment back to your balance as it arrives.
A Monthly Plan sets how much you expect to spend per category, and a projection tells you early whether you're on
track.

Over time Finlark grows into an Apple-native showcase: App Intents, on-device intelligence with Foundation Models,
and one experience across all of your Apple devices.

## Who it is for

- Individuals who want a clear, private view of their monthly spending without connecting a bank.
- People who often pay for the group (dinners, tickets, trips) and lose track of who still owes them money.
- Apple users who expect an app that feels native and works across their devices.

## Principles

1. **Spending ≠ Balance.** Spending is what you consumed. Balance is the money in your account. Splits and
   repayments affect them differently, and the app never mixes the two.
2. **Private by design.** Data lives on the device and in the user's own iCloud (CloudKit private database). There's no
   backend, no third-party analytics and no tracking. App Privacy target: *Data Not Collected*.
3. **Apple-native first.** System frameworks (SwiftUI, SwiftData, CloudKit, Swift Charts, App Intents, Foundation
   Models) over third-party dependencies. Follow the current iOS design language.
4. **Manual first, assisted later.** v1 makes manual entry fast and pleasant. Intelligence (v2) speeds it up and
   always has a non-AI fallback.
5. **The user decides.** Plans are set by the user. The app suggests and projects but never silently changes data
   (recurring items are confirmed, not auto-posted).
6. **Small, focused releases.** Each minor release has one theme, and big features get a major version (see
   [roadmap](roadmap.md)).

## What makes it different

- **Bill splitting with honest accounting.** Equal, exact or by item. Per-ticket repayment status plus *Settle all*.
- **Monthly Plan + projection.** Per-category estimates and a pace projection ("at this pace you'll spend ~€230 on
  Leisure, plan €200").
- **Confirm-to-post recurring items.** Rent, subscriptions and salary appear as pending when due, so nothing gets entered
  wrong silently.
- **Later:** Siri/Shortcuts and Spotlight via App Intents, natural-language entry and receipt scanning with on-device
  Foundation Models, widgets, iPad, Mac and Watch.

## Non-goals

- Bank connections or open-banking aggregators (no backend, no regulatory scope).
- Investments, crypto, net-worth or loan tracking.
- Ads, tracking or selling data.
- Monetization in v1. It may be revisited later.
- A full Splitwise replacement in v1. Friends don't need the app, and v1 only tracks money owed **to** you.
- Explicitly dropped features: shares/percent split mode, "you owe them" splits (a friend paid), standalone receipt
  photo attachments, location on transactions.

## v1 success criteria

- Approved and published on the App Store (iPhone, iOS 26+), in English and Spanish.
- Every requirement in [requirements/v1.md](requirements/v1.md) meets its acceptance criteria.
- Domain logic (balance, splits, repayments, projection, recurrence) is covered by automated tests that run in CI on
  every push.
- Data syncs to iCloud and restores correctly on a new iPhone.
