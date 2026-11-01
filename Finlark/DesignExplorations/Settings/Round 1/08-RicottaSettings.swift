//
//  08-RicottaSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Ricotta": edited in place. The account's name and starting balance are
//  fields right on the screen, saved as they change; the IOU delay is a slider with common choices;
//  App Lock is Off or the unlock method. Only Categories, Recurring and the home currency open
//  another screen.
//

#if DEBUG
import SwiftUI

struct RicottaSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        STScreen(settings: settings) { actions in
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Account", symbol: STItem.account.symbol)
                    STAccountFields(
                        name: $settings.accountName,
                        startingBalance: $settings.startingBalance,
                        code: settings.currencyCode
                    )
                    Divider()
                    STLink(route: .currency) {
                        STRow(.currency, subtitle: settings.canChangeCurrency ? nil : Text("Fixed once there are transactions")) {
                            Text(verbatim: settings.currencyCode)
                        }
                    }
                }
            }
            STStartingBalanceFootnote()

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    STLink(route: .categories) {
                        STRow(.categories) { STText.categories(settings) }
                    }
                    Divider()
                    STLink(route: .recurring) {
                        STRow(.recurring) { STText.recurring(settings) }
                    }
                }
            }

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Notifications", symbol: STItem.notifications.symbol)
                    STPermissionNote(settings: settings)
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Recurring due", isOn: $settings.notifiesRecurringDue)
                        Divider()
                        Toggle("IOU reminders", isOn: $settings.notifiesIOU)
                        if settings.notifiesIOU {
                            RicottaDaysPicker(settings: settings)
                        }
                    }
                    .disabled(settings.permission == .denied)
                }
            }

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "App Lock", symbol: settings.biometry.symbol)
                    RicottaLockPicker(settings: settings)
                    STAppLockFootnote(settings: settings)
                }
            }

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "iCloud", symbol: STItem.sync.symbol)
                    STSyncLabel(settings: settings)
                    Text(settings.sync.explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "About", symbol: STItem.about.symbol)
                    STAboutRows()
                }
            }

            STDeleteButton(action: actions.deleteAll)
                .padding(.top, 8)
        }
    }
}

/// Common delays as chips, and a slider for any day from 1 to 60 (NTF-002).
private struct RicottaDaysPicker: View {
    @Bindable var settings: STSettings

    private let presets = [3, 7, 14, 30]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Remind me when a share is still unpaid ^[\(settings.iouReminderDays) day](inflect: true) after the split")
                .font(.subheadline)
                .monospacedDigit()
            Slider(
                value: Binding(
                    get: { Double(settings.iouReminderDays) },
                    set: { settings.iouReminderDays = Int($0.rounded()) }
                ),
                in: Double(STSettings.iouDayRange.lowerBound)...Double(STSettings.iouDayRange.upperBound),
                step: 1
            ) {
                Text("IOU reminder delay")
            } minimumValueLabel: {
                Text(STSettings.iouDayRange.lowerBound, format: .number)
            } maximumValueLabel: {
                Text(STSettings.iouDayRange.upperBound, format: .number)
            }
            .accessibilityValue(STText.iouDays(settings))
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { days in
                    let isSelected = settings.iouReminderDays == days
                    Button {
                        settings.iouReminderDays = days
                    } label: {
                        Text("^[\(days) day](inflect: true)")
                            .font(.footnote.weight(.semibold))
                            .monospacedDigit()
                    }
                    .buttonStyle(.glass)
                    .tint(isSelected ? Color.accentColor : nil)
                    .controlSize(.small)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

/// Off or the unlock method, as two choices instead of a switch.
private struct RicottaLockPicker: View {
    @Bindable var settings: STSettings

    var body: some View {
        Picker("App Lock", selection: $settings.appLock) {
            Text("Off").tag(false)
            Text(settings.biometry.title).tag(true)
        }
        .pickerStyle(.segmented)
    }
}

#Preview("Ricotta") {
    STHost { RicottaSettings(settings: $0) }
}

#Preview("Ricotta · Fresh") {
    STHost(settings: .fresh) { RicottaSettings(settings: $0) }
}

#Preview("Ricotta · Dark") {
    STHost { RicottaSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
