//
//  SettingsRound2Components.swift
//  Finlark
//
//  FIN-9 Settings, Round 2: Gouda, the owner's lean, with two touches from Comté to try on its rows.
//  Categories can show the most used category icons under its title, and Recurring can show the next
//  item due. Everything else is Gouda as it was: a glass tile per group, controls inside them, Delete All
//  Data alone at the end.
//

#if DEBUG
import SwiftUI

/// Gouda's layout, with each of Comté's touches on or off.
struct ST2Gouda: View {
    @Bindable var settings: STSettings
    var showsCategoryIcons = false
    var showsNextRecurring = false

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
                        if showsCategoryIcons {
                            ST2CategoriesRow(settings: settings)
                        } else {
                            STRow(.categories) {
                                Text(settings.activeCategoryCount, format: .number)
                            }
                        }
                    }
                    Divider()
                    STLink(route: .recurring) {
                        STRow(.recurring, subtitle: showsNextRecurring ? STText.nextRecurring(settings) : nil) {
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

/// Categories with the four most used ones under the title, as Comté's tile shows them. At
/// accessibility sizes the icons step aside and "17 categories" goes under the title instead.
struct ST2CategoriesRow: View {
    let settings: STSettings

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            if !dynamicTypeSize.isAccessibilitySize {
                STIcon(STItem.categories.symbol, color: STItem.categories.color)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(STItem.categories.title)
                if dynamicTypeSize.isAccessibilitySize {
                    STText.categories(settings)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 4) {
                        ForEach(settings.leadingCategories.prefix(4)) { category in
                            CTBadge(symbol: category.symbol, color: category.color, size: 22)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !dynamicTypeSize.isAccessibilitySize {
                Text(settings.activeCategoryCount, format: .number)
                    .foregroundStyle(.secondary)
            }
            R2Chevron()
        }
        .padding(.vertical, 2)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
#endif
