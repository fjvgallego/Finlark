//
//  07-HalloumiSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Halloumi": searchable. A system list with a search field, like the Settings
//  app: typing "face", "reminder" or "euro" finds the setting by its name or what it's about, and
//  switches work right in the results. Each result names the section it's in.
//

#if DEBUG
import SwiftUI

struct HalloumiSettings: View {
    @Bindable var settings: STSettings

    @State private var query: String

    init(settings: STSettings, query: String = "") {
        self.settings = settings
        _query = State(initialValue: query)
    }

    var body: some View {
        STScreen(settings: settings, scrolls: false) { actions in
            let entries = HalloumiEntry.all(settings: settings, actions: actions)
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            List {
                if trimmed.isEmpty {
                    ForEach(HalloumiSection.allCases) { section in
                        Section(section.title) {
                            ForEach(entries.filter { $0.section == section }) { entry in
                                HalloumiRow(entry: entry, showsSection: false)
                            }
                        }
                    }
                } else {
                    let results = entries.filter { $0.matches(trimmed) }
                    if results.isEmpty {
                        ContentUnavailableView.search(text: trimmed)
                            .listRowBackground(Color.clear)
                    } else {
                        ForEach(results) { entry in
                            HalloumiRow(entry: entry, showsSection: true)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .searchable(text: $query, prompt: "Search settings")
        }
    }
}

private enum HalloumiSection: CaseIterable, Identifiable {
    case account
    case organize
    case notifications
    case privacy
    case about

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .account: "Account"
        case .organize: "Organize"
        case .notifications: "Notifications"
        case .privacy: "Privacy and Data"
        case .about: "About"
        }
    }
}

private struct HalloumiEntry: Identifiable {
    enum Kind {
        case link(STRoute, value: Text?)
        case action(destructive: Bool, value: Text?, run: () -> Void)
        case toggle(Binding<Bool>)
        case iouDays(STSettings)
    }

    let id: String
    let section: HalloumiSection
    let item: (title: LocalizedStringKey, symbol: String, color: Color)
    let subtitle: Text?
    /// The title and the words someone might search for, already localized.
    let searchText: [String]
    let kind: Kind

    func matches(_ query: String) -> Bool {
        searchText.contains { $0.localizedStandardContains(query) }
    }

    static func all(settings: STSettings, actions: STActions) -> [HalloumiEntry] {
        @Bindable var settings = settings
        func item(_ value: STItem) -> (LocalizedStringKey, String, Color) { (value.title, value.symbol, value.color) }

        return [
            HalloumiEntry(
                id: "account", section: .account, item: item(.account), subtitle: STText.startingBalance(settings),
                searchText: [String(localized: "Account"), String(localized: "Starting balance"), String(localized: "name, balance, money")],
                kind: .action(destructive: false, value: Text(verbatim: settings.accountName), run: actions.editAccount)
            ),
            HalloumiEntry(
                id: "currency", section: .account, item: item(.currency), subtitle: nil,
                searchText: [String(localized: "Home Currency"), settings.currencyName, settings.currencyCode, String(localized: "money, euro, dollar")],
                kind: .link(.currency, value: Text(verbatim: settings.currencyCode))
            ),
            HalloumiEntry(
                id: "categories", section: .organize, item: item(.categories), subtitle: nil,
                searchText: [String(localized: "Categories"), String(localized: "groceries, dining, labels, icons, archive")],
                kind: .link(.categories, value: Text(settings.activeCategoryCount, format: .number))
            ),
            HalloumiEntry(
                id: "recurring", section: .organize, item: item(.recurring), subtitle: nil,
                searchText: [String(localized: "Recurring"), String(localized: "rent, salary, subscriptions, repeat, templates")],
                kind: .link(.recurring, value: Text(settings.recurring.templates.count, format: .number))
            ),
            HalloumiEntry(
                id: "recurringDue", section: .notifications, item: ("Recurring due", "repeat", STItem.recurring.color),
                subtitle: Text("When a pending item is due"),
                searchText: [String(localized: "Recurring due"), String(localized: "notifications, alerts, pending, reminder")],
                kind: .toggle($settings.notifiesRecurringDue)
            ),
            HalloumiEntry(
                id: "iou", section: .notifications, item: ("IOU reminders", "person.2.fill", .teal),
                subtitle: Text("When a share is still unpaid"),
                searchText: [String(localized: "IOU reminders"), String(localized: "notifications, owed, friends, split, reminder")],
                kind: .toggle($settings.notifiesIOU)
            ),
            HalloumiEntry(
                id: "iouDays", section: .notifications, item: ("IOU reminder delay", "calendar", .teal), subtitle: nil,
                searchText: [String(localized: "IOU reminder delay"), String(localized: "days, notifications, reminder")],
                kind: .iouDays(settings)
            ),
            HalloumiEntry(
                id: "appLock", section: .privacy, item: ("App Lock", settings.biometry.symbol, STItem.appLock.color),
                subtitle: Text("Use \(Text(settings.biometry.title)) to open Finlark"),
                searchText: [String(localized: "App Lock"), String(localized: "Face ID, Touch ID, passcode, security, privacy")],
                kind: .toggle($settings.appLock)
            ),
            HalloumiEntry(
                id: "sync", section: .privacy, item: item(.sync), subtitle: nil,
                searchText: [String(localized: "iCloud"), String(localized: "sync, backup, devices")],
                kind: .link(.sync, value: Text(settings.sync.title))
            ),
            HalloumiEntry(
                id: "delete", section: .privacy, item: item(.delete), subtitle: nil,
                searchText: [String(localized: "Delete All Data"), String(localized: "erase, reset, start over")],
                kind: .action(destructive: true, value: nil, run: actions.deleteAll)
            ),
            HalloumiEntry(
                id: "about", section: .about, item: item(.about), subtitle: nil,
                searchText: [String(localized: "About"), String(localized: "version, privacy policy, acknowledgements")],
                kind: .link(.about, value: STText.version())
            ),
        ]
    }
}

private struct HalloumiRow: View {
    let entry: HalloumiEntry
    let showsSection: Bool

    var body: some View {
        let subtitle = showsSection ? Text(entry.section.title) : entry.subtitle
        switch entry.kind {
        case .link(let route, let value):
            NavigationLink(value: route) {
                STRow(title: entry.item.title, symbol: entry.item.symbol, color: entry.item.color, subtitle: subtitle, showsChevron: false) {
                    value
                }
            }
        case .action(let destructive, let value, let run):
            Button(action: run) {
                if destructive {
                    Label(entry.item.title, systemImage: "trash")
                        .foregroundStyle(.red)
                } else {
                    STRow(title: entry.item.title, symbol: entry.item.symbol, color: entry.item.color, subtitle: subtitle) {
                        value
                    }
                }
            }
            .tint(.primary)
        case .toggle(let isOn):
            STToggle(title: entry.item.title, symbol: entry.item.symbol, color: entry.item.color, subtitle: subtitle, isOn: isOn)
        case .iouDays(let settings):
            VStack(alignment: .leading, spacing: 2) {
                STIOUDaysStepper(settings: settings)
                    .disabled(!settings.notifiesIOU)
                if showsSection, let subtitle {
                    subtitle
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Halloumi") {
    STHost { HalloumiSettings(settings: $0) }
}

#Preview("Halloumi · Searching") {
    STHost { HalloumiSettings(settings: $0, query: "remind") }
}

#Preview("Halloumi · Dark") {
    STHost { HalloumiSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
