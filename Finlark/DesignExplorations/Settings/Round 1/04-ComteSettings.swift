//
//  04-ComteSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Comté": bento. Settings as tiles in two columns, like Marsh's Home. Each
//  tile shows its state at a glance: the most used categories as icons, the next recurring item, which
//  notifications are on, a big App Lock switch, the iCloud status. A tap opens its screen; App Lock
//  switches right on the tile.
//

#if DEBUG
import SwiftUI

struct ComteSettings: View {
    @Bindable var settings: STSettings

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: r2TileSpacing), count: count)
    }

    var body: some View {
        STScreen(settings: settings) { actions in
            Button(action: actions.editAccount) {
                R2Tile(padding: 18) {
                    STRow(.account, subtitle: STText.startingBalance(settings).monospacedDigit()) {
                        Text("Edit")
                    }
                }
                .contentShape(.rect(cornerRadius: 24))
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: columns, spacing: r2TileSpacing) {
                ComteTile(route: .categories, item: .categories) {
                    HStack(spacing: -6) {
                        ForEach(settings.leadingCategories.prefix(4)) { category in
                            CTBadge(symbol: category.symbol, color: category.color, size: 28)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .strokeBorder(.background, lineWidth: 2)
                                }
                        }
                    }
                    STText.categories(settings)
                }
                ComteTile(route: .recurring, item: .recurring) {
                    Text(settings.recurring.templates.count, format: .number)
                        .font(.title.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    if let next = STText.nextRecurring(settings) {
                        next.lineLimit(2)
                    }
                }
                ComteTile(route: .notifications, item: .notifications) {
                    if settings.notifiesRecurringDue {
                        Label("Recurring due", systemImage: "checkmark")
                    } else {
                        Label("No recurring alerts", systemImage: "minus")
                    }
                    Label {
                        settings.notifiesIOU ? STText.iouDays(settings) : Text("No IOU reminders")
                    } icon: {
                        Image(systemName: settings.notifiesIOU ? "checkmark" : "minus")
                    }
                    if settings.permission == .denied {
                        Label("Off in iOS Settings", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
                ComteLockTile(settings: settings)
                ComteTile(route: .sync, item: .sync) {
                    STSyncLabel(settings: settings, showsLastSynced: false)
                        .foregroundStyle(.primary)
                }
                ComteTile(route: .currency, item: .currency) {
                    Text(verbatim: settings.currencyCode)
                        .font(.title.weight(.bold))
                        .foregroundStyle(.primary)
                    Text(verbatim: settings.currencyName)
                }
            }

            R2Tile(padding: 18) {
                STAboutRows()
            }

            STDeleteButton(action: actions.deleteAll)
                .padding(.top, 8)
        }
    }
}

/// A square-ish tile with its icon and title on top and its state below, opening its screen.
private struct ComteTile<Content: View>: View {
    let route: STRoute
    let item: STItem
    @ViewBuilder let content: Content

    var body: some View {
        NavigationLink(value: route) {
            R2Tile(padding: 14) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        STIcon(item.symbol, color: item.color)
                        Spacer()
                        R2Chevron()
                    }
                    Text(item.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    VStack(alignment: .leading, spacing: 4) {
                        content
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
            }
            .contentShape(.rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// App Lock switches on the tile itself, with the unlock method as its icon.
private struct ComteLockTile: View {
    @Bindable var settings: STSettings

    var body: some View {
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    STIcon(settings.biometry.symbol, color: STItem.appLock.color)
                    Spacer()
                    Toggle("App Lock", isOn: $settings.appLock)
                        .labelsHidden()
                }
                Text("App Lock")
                    .font(.subheadline.weight(.semibold))
                Group {
                    if settings.appLock {
                        Text("Asks for \(Text(settings.biometry.title))")
                    } else {
                        Text("Anyone with your iPhone can open it")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Comté") {
    STHost { ComteSettings(settings: $0) }
}

#Preview("Comté · Needs attention") {
    STHost(settings: .needsAttention) { ComteSettings(settings: $0) }
}

#Preview("Comté · Dark") {
    STHost { ComteSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
