# Design

The design chosen for each v1 screen in FIN-9. This page says **what** was chosen. The screens themselves are SwiftUI
code in `Finlark/DesignExplorations/`, with previews, until each one is implemented in `Features` and its
exploration is deleted ([architecture.md](../architecture.md#modules)). Every variant, including the ones not chosen,
is kept on the `archive/FIN-9-design-explorations` branch, which is never merged
([git-workflow.md](../technical/git-workflow.md#branches)).

Items marked *To confirm* are drafts waiting for the owner.

## Look

- **Marsh's look** everywhere except onboarding and the lock screen: a tinted backdrop, glass tiles, soft icons and
  avatars (tinted rounded squares instead of the system look), and the system's Liquid Glass for buttons and controls
  (NFR-002).
- **The brand:** a full-bleed indigo gradient with the Finlark mark and wordmark in white, the same in light and dark.
  Onboarding, the lock screen and the app icon share it.
- **Font family:** a custom family is planned. *To confirm:* which one. Until then, system text styles.

## Navigation

A tab bar with Home, History and Settings, with screens pushed from them and sheets for adding
([architecture.md](../architecture.md#navigation), [ADR-0008](../adr/0008-navigation.md)):

| Screen | Opens from |
|---|---|
| Plan | Pushed from Home's plan card (HOM-003) |
| People, then a person | Pushed from Home's Owed to you bar (HOM-004) and from Settings (SET-001) |
| Transaction detail | Pushed from Home and History |
| Categories, Recurring | Pushed from Settings (SET-001) |
| Add | A sheet from quick add on Home and History (HOM-007, TRX-001) |

## Screens

| Screen | Chosen | Requirements | Key decisions | Status |
|---|---|---|---|---|
| Home | **Marsh** | HOM-001…007 | A segmented control (Month \| Categories) switches the view. The month view has a scrubbable category bar. | Chosen |
| Add & edit | **Dunlin** | TRX-001…003, SPL-001…004, SPL-010 | The four most used categories stay on top, and the rest sit in a thin bar that expands in place. A category picked from the bar moves into the first slot. The split has people chips, the mode and the By item table. The date has no time. | Chosen |
| Transaction detail | **Birch** | TRX-004, TRX-006, SPL-005…009, SPL-011 | One line per friend with a ring that fills as they pay. Tapping a friend opens a sheet with their repayments (swipe to edit or delete), *Mark as paid* (SPL-006) and *Record part* (SPL-007). Edit turns the tiles into Dunlin's fields in place. | Chosen |
| History | **Lyra** | TRX-005 | Every month in one scroll. Each month's glass bar pins to the top with its difference, income and spending. The title's menu narrows to one month. Chips filter by type and category. | Chosen |
| Plan | **Tramontana** | PLN-001…003 | A line chart of spending day by day up to today, a dashed line to the projection at month end, and a rule at the planned total. The categories follow. The title's menu picks a past month. | Chosen |
| People | **Genmaicha** | PPL-001, PPL-002, PPL-004, SPL-008 | A check on each row that owes settles everything that person owes, with Undo in a toast. | Chosen |
| Person | **Financier** | PPL-003, SPL-008, NTF-003 | *Settle all* pinned in a glass bar that also shows what's open and across how many shares. *Share reminder* stays. | Chosen |
| Recurring | **Moderato** | REC-001…005, NTF-001 | Pending items first, as a paged slider of cards, or a caught-up tile. Then what goes out and comes in each month, then every template soonest first, with paused ones apart. | Chosen |
| Categories | **Velvet** | CAT-001…003 | A three-column grid of glass tiles with a big icon, the name and how many transactions use it. Archived categories follow in gray, with Unarchive on long press. One type at a time. | Chosen |
| Settings | **Leyden** | SET-001, ACC-002, SEC-003 | Gouda's layout: a glass tile per group with the controls inside it, and Delete All Data alone at the end in red glass. Leyden adds the next occurrence under Recurring ("Veggie box · In 3 days"). | Chosen |
| App Lock | **Clove** | SEC-001, SEC-002, A-14 | The brand gradient as the lock screen and the app-switcher cover. Face ID is asked as soon as the app opens. On an iPhone without a passcode the app opens without asking, and App Lock is disabled. | Chosen |
| Onboarding | **Yawl** | ONB-001…005 | Every step on the brand gradient, in white with glass controls, sliding in place under step dots. The currency list opens in a sheet. The starting balance can be left empty. When iCloud data arrives after *Continue as New User*, the user chooses between it and this setup (ONB-005). | Chosen |

## Default categories

Appendix A of the [requirements](../requirements/v1.md#appendix-a-default-categories) leaves icons and colors to UI
design. These are the explorations' proposals. *To confirm.*

| Category | SF Symbol | Color |
|---|---|---|
| Groceries | `cart.fill` | green |
| Dining | `fork.knife` | orange |
| Transport | `tram.fill` | blue |
| Fuel | `fuelpump.fill` | brown |
| Housing | `house.fill` | indigo |
| Bills & Utilities | `bolt.fill` | teal |
| Health | `heart.fill` | pink |
| Shopping | `bag.fill` | mint |
| Leisure | `theatermasks.fill` | purple |
| Subscriptions | `tv.fill` | red |
| Travel | `airplane` | cyan |
| Other | `square.grid.2x2.fill` | gray |
| Salary | `banknote.fill` | mint |
| Refunds | `arrow.uturn.backward` | blue |
| Gifts | `gift.fill` | pink |
| Other income | `plus.square.fill` | gray |
