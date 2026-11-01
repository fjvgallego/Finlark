//
//  10-MozzarellaSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Mozzarella": in plain words. Each setting is a sentence that says how
//  things are ("Your account started with €1,250.00", "Lock Finlark with Face ID"), with its switch or
//  button next to it. Friendlier than labels and values, and every line explains itself.
//

#if DEBUG
import SwiftUI

struct MozzarellaSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        STScreen(settings: settings) { actions in
            MozzarellaCard(item: .account) {
                Text("This is \(Text(verbatim: settings.accountName).bold()). It started with \(Text(settings.startingBalance, format: .currency(code: settings.currencyCode)).bold()).")
                Button("Edit Account", action: actions.editAccount)
                    .buttonStyle(.glass)
            }

            MozzarellaCard(item: .currency) {
                Text("Amounts are in \(Text(verbatim: settings.currencyName).bold()).")
                if settings.canChangeCurrency {
                    NavigationLink("Change Currency", value: STRoute.currency)
                        .buttonStyle(.glass)
                } else {
                    Text("It stays that way once there are transactions.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            MozzarellaCard(item: .categories) {
                Text("You sort transactions into \(Text("^[\(settings.activeCategoryCount) category](inflect: true)").bold()).")
                NavigationLink("Edit Categories", value: STRoute.categories)
                    .buttonStyle(.glass)
            }

            MozzarellaCard(item: .recurring) {
                let count = settings.recurring.templates.count
                if count == 0 {
                    Text("Nothing repeats on its own yet.")
                } else {
                    Text("\(Text("^[\(count) transaction](inflect: true)").bold()) repeat on their own.")
                }
                NavigationLink("See Recurring", value: STRoute.recurring)
                    .buttonStyle(.glass)
            }

            MozzarellaCard(item: .notifications) {
                STPermissionNote(settings: settings)
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Tell me when a recurring transaction is due.", isOn: $settings.notifiesRecurringDue)
                    Divider()
                    Toggle(isOn: $settings.notifiesIOU) {
                        Text("Remind me when a friend hasn't paid their share after \(Text("^[\(settings.iouReminderDays) day](inflect: true)").bold()).")
                    }
                    if settings.notifiesIOU {
                        Stepper("Change the days", value: $settings.iouReminderDays, in: STSettings.iouDayRange)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("IOU reminder delay"))
                            .accessibilityValue(STText.iouDays(settings))
                    }
                }
                .disabled(settings.permission == .denied)
            }

            MozzarellaCard(item: .appLock) {
                Toggle(isOn: $settings.appLock) {
                    Text("Lock Finlark with \(Text(settings.biometry.title)).")
                }
                STAppLockFootnote(settings: settings)
            }

            MozzarellaCard(symbol: settings.sync.symbol, color: settings.sync.color) {
                switch settings.sync {
                case .upToDate:
                    Text("Your data is \(Text("up to date").bold()) in iCloud, and on every iPhone signed in to it.")
                case .syncing:
                    Text("Your data is \(Text("syncing").bold()) with iCloud.")
                case .offline:
                    Text("Your data will sync with iCloud \(Text("when you're back online").bold()).")
                case .signedOut:
                    Text("Your data is \(Text("only on this iPhone").bold()). Sign in to iCloud in the Settings app to keep a copy.")
                }
            }

            MozzarellaCard(item: .about) {
                Text("Finlark keeps your money to yourself: no accounts, no analytics, no tracking.")
                STAboutRows()
                    .font(.subheadline)
            }

            MozzarellaCard(item: .delete) {
                Text("Start over by deleting everything, here and in iCloud.")
                Button("Delete All Data", role: .destructive, action: actions.deleteAll)
                    .buttonStyle(.glass)
                    .tint(.red)
            }
        }
    }
}

/// A sentence with its icon beside it and its control under it.
private struct MozzarellaCard<Content: View>: View {
    let symbol: String
    let color: Color
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(item: STItem, @ViewBuilder content: () -> Content) {
        self.init(symbol: item.symbol, color: item.color, content: content)
    }

    init(symbol: String, color: Color, @ViewBuilder content: () -> Content) {
        self.symbol = symbol
        self.color = color
        self.content = content()
    }

    var body: some View {
        R2Tile(padding: 18) {
            HStack(alignment: .top, spacing: 14) {
                if !dynamicTypeSize.isAccessibilitySize {
                    STIcon(symbol, color: color, size: 36)
                }
                VStack(alignment: .leading, spacing: 12) {
                    content
                }
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

#Preview("Mozzarella") {
    STHost { MozzarellaSettings(settings: $0) }
}

#Preview("Mozzarella · Fresh") {
    STHost(settings: .fresh) { MozzarellaSettings(settings: $0) }
}

#Preview("Mozzarella · Dark") {
    STHost { MozzarellaSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
