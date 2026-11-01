//
//  09-StiltonSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Stilton": three views under Marsh's segmented control. Money (account,
//  currency, categories, recurring), Reminders (notifications) and Privacy (App Lock, iCloud, Delete
//  All Data). About moves to an info button in the bar. Short screens, no scrolling at default sizes.
//

#if DEBUG
import SwiftUI

struct StiltonSettings: View {
    enum Panel: Hashable, CaseIterable {
        case money
        case reminders
        case privacy

        var title: LocalizedStringKey {
            switch self {
            case .money: "Money"
            case .reminders: "Reminders"
            case .privacy: "Privacy"
            }
        }
    }

    @Bindable var settings: STSettings

    @State private var panel: Panel
    @State private var showsAbout = false

    init(settings: STSettings, panel: Panel = .money) {
        self.settings = settings
        _panel = State(initialValue: panel)
    }

    var body: some View {
        STScreen(settings: settings) { actions in
            R6SegmentedControl(
                title: "Show",
                options: Panel.allCases.map { (value: $0, label: $0.title) },
                selection: $panel
            )

            switch panel {
            case .money:
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: actions.editAccount) {
                            STRow(.account, subtitle: Text(verbatim: settings.accountName)) {
                                STText.startingBalance(settings)
                                    .monospacedDigit()
                            }
                        }
                        .buttonStyle(.plain)
                        Divider()
                        STLink(route: .currency) {
                            STRow(.currency) { Text(verbatim: settings.currencyCode) }
                        }
                    }
                }
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        STLink(route: .categories) {
                            STRow(.categories) { STText.categories(settings) }
                        }
                        Divider()
                        STLink(route: .recurring) {
                            STRow(.recurring, subtitle: STText.nextRecurring(settings)) {
                                Text(settings.recurring.templates.count, format: .number)
                            }
                        }
                    }
                }
            case .reminders:
                R2Tile(padding: 18) {
                    STNotificationControls(settings: settings)
                }
            case .privacy:
                R2Tile(padding: 18) {
                    STAppLockControl(settings: settings)
                }
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        STSyncLabel(settings: settings)
                        Text(settings.sync.explanation)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                STDeleteButton(action: actions.deleteAll)
                    .padding(.top, 8)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("About", systemImage: "info") { showsAbout = true }
            }
        }
        .sheet(isPresented: $showsAbout) {
            NavigationStack {
                STAboutScreen()
                    .navigationDestination(for: STRoute.self) { _ in
                        STAcknowledgementsScreen()
                    }
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done", systemImage: "checkmark", role: .confirm) { showsAbout = false }
                        }
                    }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview("Stilton") {
    STHost { StiltonSettings(settings: $0) }
}

#Preview("Stilton · Reminders") {
    STHost { StiltonSettings(settings: $0, panel: .reminders) }
}

#Preview("Stilton · Privacy") {
    STHost(settings: .needsAttention) { StiltonSettings(settings: $0, panel: .privacy) }
}

#Preview("Stilton · Dark") {
    STHost { StiltonSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
