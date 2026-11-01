//
//  06-GruyereSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Gruyère": status first. The top tile checks what keeps the data safe and
//  the reminders coming: iCloud, notifications and App Lock, each with its state in words, and what
//  needs attention comes first, with a way to fix it. The rest of Settings follows in plain tiles.
//

#if DEBUG
import SwiftUI

struct GruyereSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        STScreen(settings: settings) { actions in
            GruyereChecks(settings: settings)

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Money", symbol: "banknote.fill")
                    Button(action: actions.editAccount) {
                        STRow(.account, subtitle: STText.startingBalance(settings).monospacedDigit()) {
                            Text(verbatim: settings.accountName)
                        }
                    }
                    .buttonStyle(.plain)
                    Divider()
                    STLink(route: .currency) {
                        STRow(.currency) { Text(verbatim: settings.currencyCode) }
                    }
                    Divider()
                    STLink(route: .categories) {
                        STRow(.categories) { Text(settings.activeCategoryCount, format: .number) }
                    }
                    Divider()
                    STLink(route: .recurring) {
                        STRow(.recurring) { Text(settings.recurring.templates.count, format: .number) }
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
                    STLink(route: .about) {
                        STRow(.about) { STText.version() }
                    }
                    Divider()
                    Button(role: .destructive, action: actions.deleteAll) {
                        STRow(.delete)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

/// iCloud, notifications and App Lock, attention first.
private struct GruyereChecks: View {
    @Bindable var settings: STSettings

    @Environment(\.openURL) private var openURL

    private enum Check: Identifiable {
        case sync
        case notifications
        case appLock

        var id: Self { self }
    }

    private func isFine(_ check: Check) -> Bool {
        switch check {
        case .sync: !settings.sync.needsAttention
        case .notifications: settings.permission != .denied
        case .appLock: settings.appLock
        }
    }

    var body: some View {
        let checks: [Check] = [.sync, .notifications, .appLock]
        let ordered = checks.filter { !isFine($0) } + checks.filter(isFine)
        let issues = checks.count(where: { !isFine($0) })

        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Image(systemName: issues == 0 ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(issues == 0 ? .green : .orange)
                        .accessibilityHidden(true)
                    Group {
                        if issues == 0 {
                            Text("All set")
                        } else {
                            Text("^[\(issues) thing](inflect: true) to look at")
                        }
                    }
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                }
                ForEach(ordered) { check in
                    if check != ordered.first {
                        Divider()
                    }
                    row(check)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ check: Check) -> some View {
        switch check {
        case .sync:
            GruyereCheckRow(
                symbol: settings.sync.symbol,
                color: settings.sync.color,
                title: "iCloud",
                state: Text(settings.sync.title),
                detail: settings.sync.needsAttention ? Text(settings.sync.explanation) : nil
            ) {
                NavigationLink("Details", value: STRoute.sync)
            }
        case .notifications:
            GruyereCheckRow(
                symbol: settings.permission == .denied ? "bell.slash.fill" : "bell.fill",
                color: settings.permission == .denied ? .orange : .red,
                title: "Notifications",
                state: STText.notifications(settings),
                detail: settings.permission == .denied ? Text("Recurring and IOU reminders can't reach you.") : nil
            ) {
                if settings.permission == .denied {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                            openURL(url)
                        }
                    }
                }
            }
        case .appLock:
            GruyereCheckRow(
                symbol: settings.appLock ? settings.biometry.symbol : "lock.open.fill",
                color: STItem.appLock.color,
                title: "App Lock",
                state: STText.appLock(settings),
                detail: settings.appLock ? nil : Text("Anyone with your iPhone unlocked can open Finlark.")
            ) {
                if settings.appLock {
                    NavigationLink("Details", value: STRoute.security)
                } else {
                    Button("Turn On") { settings.appLock = true }
                }
            }
        }
    }
}

private struct GruyereCheckRow<Action: View>: View {
    let symbol: String
    let color: Color
    let title: LocalizedStringKey
    let state: Text
    let detail: Text?
    @ViewBuilder let action: Action

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        layout {
            if !dynamicTypeSize.isAccessibilitySize {
                STIcon(symbol, color: color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                state
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let detail {
                    detail
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            action
                .buttonStyle(.glass)
                .controlSize(.small)
        }
    }
}

#Preview("Gruyère") {
    STHost { GruyereSettings(settings: $0) }
}

#Preview("Gruyère · Needs attention") {
    STHost(settings: .needsAttention) { GruyereSettings(settings: $0) }
}

#Preview("Gruyère · Dark") {
    STHost(settings: .needsAttention) { GruyereSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
