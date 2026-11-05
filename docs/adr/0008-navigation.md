# ADR-0008: Navigation

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: HOM-003, HOM-004, NTF-001, NTF-002, SEC-001,
NFR-011

## Context

- The chosen designs (FIN-9) use a tab bar with Home, History and Settings, a navigation stack per tab, and sheets for
  adding and editing.
- Some screens are pushed from more than one place. Transaction detail opens from Home and History, Plan and People
  from Home (HOM-003, HOM-004), and Categories and Recurring from Settings.
- Some screens open from outside the app's own navigation. A recurring-due notification opens the confirm screen
  (NTF-001), an IOU reminder opens the person detail (NTF-002), and v2.0 adds App Intents and Spotlight.
- The owner decided that the tab bar shows only on each tab's root screen and hides on every pushed screen.

## Options considered

1. **A central router.** A route type, and one object that owns the selected tab, each tab's path and the presented
   sheet. Anything that opens a screen, inside or outside the app, goes through it.
2. **Navigation local to each screen.** Each screen pushes with `NavigationLink` and owns its sheets. Simpler at first,
   but opening a screen from a notification or an App Intent needs its own handling every time.

## Decision

Option 1:

- A `Route` enum lists every screen that can be pushed, and a `Sheet` enum lists every modal. A route refers to a
  record by the stable ID stored on the model, not by `PersistentIdentifier`, so it can be stored in a notification or
  built by an App Intent.
- An `@Observable` `Router` in the Environment owns the selected tab, one path per tab and the presented sheet.
  Screens navigate with `NavigationLink(value:)` or by calling the router.
- Destinations are built in one place. That place also hides the tab bar on every pushed screen, so no screen does
  it on its own.
- `open(_:)` is the single way in from outside the app. It dismisses any sheet, selects the tab the route belongs to
  and replaces that tab's path. While App Lock is showing (SEC-001), the route waits until the user unlocks.
- Services reports notification taps as plain values (the kind and the record's ID). The app target turns them into
  routes, because Services can't import Features ([ADR-0003](0003-module-structure.md)).

## Consequences

- Notification taps, App Intents and Spotlight (v2.0) share one way into the app, and which screen a route opens can
  be tested without UI.
- Every pushed screen needs a `Route` case, and the place that builds destinations grows with the app.
- A route can point to a record that was deleted in the meantime, for example through sync. It then falls back to the
  tab's root screen.
- Records that can be opened from outside the app need a stable ID on the model.
- The Home design puts quick add in the tab view's bottom accessory. Whether it hides with the tab bar on pushed
  screens wasn't verified, and is checked when navigation is built.
