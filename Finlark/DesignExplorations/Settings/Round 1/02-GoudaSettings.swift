//
//  02-GoudaSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Gouda": Marsh's glass tiles. Each group of SET-001 is a tile with its
//  heading, and every control works inside it: toggles, the IOU delay, the iCloud status. Delete All
//  Data sits alone at the end, in red glass.
//

#if DEBUG
import SwiftUI

struct GoudaSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        STScreen(settings: settings) { actions in
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Account", symbol: STItem.account.symbol)
                    Button(action: actions.editAccount) {
                        STRow(.account, subtitle: STText.startingBalance(settings).monospacedDigit()) {
                            Text("Edit")
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Edits the name and starting balance."))
                    Divider()
                    STLink(route: .currency) {
                        STRow(.currency) {
                            Text(verbatim: settings.currencyCode)
                        }
                    }
                }
            }

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Organize", symbol: "tray.full.fill")
                    STLink(route: .categories) {
                        STRow(.categories) {
                            Text(settings.activeCategoryCount, format: .number)
                        }
                    }
                    Divider()
                    STLink(route: .recurring) {
                        STRow(.recurring) {
                            Text(settings.recurring.templates.count, format: .number)
                        }
                    }
                }
            }

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Notifications", symbol: STItem.notifications.symbol)
                    STNotificationControls(settings: settings)
                }
            }

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Privacy", symbol: "hand.raised.fill")
                    STAppLockControl(settings: settings)
                    Divider()
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

#Preview("Gouda") {
    STHost { GoudaSettings(settings: $0) }
}

#Preview("Gouda · Account") {
    STHost(opening: .accountEditor) { GoudaSettings(settings: $0) }
}

#Preview("Gouda · Dark") {
    STHost { GoudaSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
