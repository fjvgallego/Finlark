# ADR-0010: Per-device settings

Status: **Accepted** (2026-11-03) · Ticket: FIN-10 · Requirements: NTF-002, NTF-004, SEC-001, SEC-003, SET-001,
ONB-003, A-14

## Context

- Settings (SET-001) mixes two kinds of values. Some are part of the user's data: the account's name and starting
  balance, the home currency, categories and recurring templates. Others only change how this app behaves: the
  notification toggles (NTF-004), the IOU reminder days (NTF-002) and App Lock (SEC-001).
- App Lock depends on the device. It can't be turned on without a device passcode (SEC-001, ONB-003).
- Notifications are local and scheduled by each device itself ([ADR-0003](0003-module-structure.md)).

## Options considered

1. **Per device.** These settings stay on the device and don't sync.
2. **Synced.** They're stored with the data in SwiftData and sync through CloudKit. Changing a toggle on one iPhone
   changes it everywhere, but App Lock can't follow, because another device may have no passcode.

## Decision

Option 1:

- The notification toggles, the IOU reminder days and App Lock are stored per device in `UserDefaults`, not in
  SwiftData, and don't sync.
- Everything else in Settings is user data and syncs: the account's name and starting balance, the home currency
  (stored with the account), categories and recurring templates.
- Services owns reading and writing the per-device settings, because notifications and App Lock use them. Features
  reads and changes them through Services.
- They stay in the app's own container, not the App Group ([ADR-0009](0009-store-location.md)), until an extension
  needs one of them.

## Consequences

- Settings never conflict between devices, and the schema has no settings records.
- On a new iPhone that isn't restored from a backup, these settings start from their defaults (notifications on, IOU
  reminder after 7 days, App Lock off), even when the data is restored from iCloud (ONB-005).
- With two devices, each one sends its own notifications according to its own settings.
- Delete All Data (SEC-003) also resets these settings, on the device where it runs. Other devices keep theirs.
