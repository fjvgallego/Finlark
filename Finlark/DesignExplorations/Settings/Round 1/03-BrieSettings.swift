//
//  03-BrieSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Brie": the account leads. A big tile at the top shows the account's name,
//  starting balance, home currency and iCloud status, with Edit. Under it, one tile lists everything
//  else, each row saying how it's set and opening its own screen.
//

#if DEBUG
import SwiftUI

struct BrieSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        STScreen(settings: settings) { actions in
            BrieAccountCard(settings: settings, edit: actions.editAccount)

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    STLink(route: .categories) {
                        STRow(.categories) { STText.categories(settings) }
                    }
                    Divider()
                    STLink(route: .recurring) {
                        STRow(.recurring) { STText.recurring(settings) }
                    }
                    Divider()
                    STLink(route: .notifications) {
                        STRow(.notifications) { STText.notifications(settings) }
                    }
                    Divider()
                    STLink(route: .security) {
                        STRow(.appLock) { STText.appLock(settings) }
                    }
                    Divider()
                    STLink(route: .sync) {
                        STRow(title: "iCloud and Data", symbol: STItem.sync.symbol, color: STItem.sync.color) {
                            Text(settings.sync.title)
                        }
                    }
                }
            }

            R2Tile(padding: 18) {
                STAboutRows()
            }
        }
    }
}

/// The account: who it is, where it started, its currency, and whether it's in iCloud.
private struct BrieAccountCard: View {
    let settings: STSettings
    let edit: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    STIcon(STItem.account.symbol, color: STItem.account.color, size: 52)
                    Spacer()
                    Button("Edit", action: edit)
                        .buttonStyle(.glass)
                        .accessibilityLabel(Text("Edit Account"))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: settings.accountName)
                        .font(.title2.weight(.bold))
                    Text("Starting balance \(settings.startingBalance, format: .currency(code: settings.currencyCode))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)

                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                    : AnyLayout(HStackLayout(spacing: 8))
                layout {
                    NavigationLink(value: STRoute.currency) {
                        Label {
                            Text(verbatim: settings.currencyCode)
                        } icon: {
                            Image(systemName: settings.canChangeCurrency ? "coloncurrencysign.circle" : "lock.fill")
                        }
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(Text("Home Currency"))
                    .accessibilityValue(STText.currency(settings))
                    NavigationLink(value: STRoute.sync) {
                        Label {
                            Text(settings.sync.title)
                        } icon: {
                            Image(systemName: settings.sync.symbol)
                                .foregroundStyle(settings.sync.color)
                        }
                    }
                    .buttonStyle(.glass)
                }
                .font(.subheadline.weight(.medium))
                .controlSize(.small)
            }
        }
    }
}

#Preview("Brie") {
    STHost { BrieSettings(settings: $0) }
}

#Preview("Brie · Fresh") {
    STHost(settings: .fresh) { BrieSettings(settings: $0) }
}

#Preview("Brie · Dark") {
    STHost { BrieSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
