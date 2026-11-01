//
//  05-FetaSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Feta": a short menu. Seven rows, each a tile of its own with a line on how
//  it's set, and every one opens its screen: no switch or field on the first screen. Delete All Data
//  lives in iCloud and Data, next to where the data is.
//

#if DEBUG
import SwiftUI

struct FetaSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        STScreen(settings: settings) { _ in
            FetaRow(route: .account, item: .account, summary: STText.account(settings))
            FetaRow(route: .categories, item: .categories, summary: STText.categories(settings))
            FetaRow(route: .recurring, item: .recurring, summary: STText.nextRecurring(settings) ?? STText.recurring(settings))
            FetaRow(route: .notifications, item: .notifications, summary: notificationsSummary)
            FetaRow(route: .security, item: .appLock, summary: STText.appLock(settings))
            FetaRow(
                route: .sync,
                title: "iCloud and Data",
                symbol: STItem.sync.symbol,
                color: STItem.sync.color,
                summary: Text(settings.sync.title),
                needsAttention: settings.sync.needsAttention
            )
            FetaRow(route: .about, item: .about, summary: STText.version())
        }
    }

    private var notificationsSummary: Text {
        if settings.permission == .denied {
            return Text("Off in iOS Settings")
        }
        return switch (settings.notifiesRecurringDue, settings.notifiesIOU) {
        case (true, true): Text("Recurring due, IOU reminders")
        case (true, false): Text("Recurring due")
        case (false, true): Text("IOU reminders")
        case (false, false): Text("Off")
        }
    }
}

private struct FetaRow: View {
    let route: STRoute
    let title: LocalizedStringKey
    let symbol: String
    let color: Color
    let summary: Text
    var needsAttention = false

    init(route: STRoute, item: STItem, summary: Text) {
        self.init(route: route, title: item.title, symbol: item.symbol, color: item.color, summary: summary)
    }

    init(route: STRoute, title: LocalizedStringKey, symbol: String, color: Color, summary: Text, needsAttention: Bool = false) {
        self.route = route
        self.title = title
        self.symbol = symbol
        self.color = color
        self.summary = summary
        self.needsAttention = needsAttention
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationLink(value: route) {
            R2Tile(padding: 14) {
                HStack(spacing: 14) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        STIcon(symbol, color: color, size: 40)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.body.weight(.semibold))
                        HStack(spacing: 4) {
                            if needsAttention {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .accessibilityLabel(Text("Needs attention"))
                            }
                            summary
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if !dynamicTypeSize.isAccessibilitySize {
                        R2Chevron()
                    }
                }
            }
            .contentShape(.rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Feta") {
    STHost { FetaSettings(settings: $0) }
}

#Preview("Feta · Account") {
    STHost(path: [.account]) { FetaSettings(settings: $0) }
}

#Preview("Feta · iCloud and Data") {
    STHost(settings: .needsAttention, path: [.sync]) { FetaSettings(settings: $0) }
}

#Preview("Feta · Dark") {
    STHost { FetaSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
