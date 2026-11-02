//
//  PeopleComponents.swift
//  Finlark
//
//  FIN-9 People: pieces shared by the People explorations (PPL-001…004, SPL-008, NTF-003). People isn't
//  a tab: Home's owed bar links to it (HOM-004), so the host is Marsh's tab bar with People pushed on
//  Home, and a person pushed on People. Marsh's look throughout: the tinted backdrop, glass tiles, soft
//  icons and avatars, system glass buttons.
//

#if DEBUG
import SwiftUI

// MARK: - Host

enum PPRoute: Hashable {
    case people
    case person(PPPerson.ID)
    case archived
}

/// Marsh's tab bar with People pushed on Home, as the link in Home's owed bar does. `opening` also
/// pushes that person, as tapping their row would.
struct PPHost<List: View, Person: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    @State private var store: PPStore
    @State private var selection: AppTab = .home
    @State private var path: [PPRoute]
    private let list: (PPStore) -> List
    private let person: (PPStore, PPPerson.ID) -> Person

    init(
        store: PPStore = .sample,
        opening personID: PPPerson.ID? = nil,
        @ViewBuilder list: @escaping (PPStore) -> List,
        @ViewBuilder person: @escaping (PPStore, PPPerson.ID) -> Person
    ) {
        _store = State(initialValue: store)
        _path = State(initialValue: [.people] + (personID.map { [.person($0)] } ?? []))
        self.list = list
        self.person = person
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack(path: $path) {
                    ContentUnavailableView {
                        Label("Home", systemImage: "house")
                    } description: {
                        Text("Marsh isn't part of the People exploration.")
                    } actions: {
                        NavigationLink("Open People", value: PPRoute.people)
                            .buttonStyle(.glass)
                    }
                    .navigationTitle("Home")
                    .navigationDestination(for: PPRoute.self) { route in
                        switch route {
                        case .people: list(store)
                        case .person(let id): person(store, id)
                        case .archived: PPArchivedScreen(store: store)
                        }
                    }
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                ContentUnavailableView {
                    Label("History", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Lyra isn't part of the People exploration.")
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    R2SettingsScreen()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(\.explorationIconStyle, .soft)
    }
}

// MARK: - Bars

/// "People", inline, with an add button (PPL-001).
struct PPListChrome: ViewModifier {
    let store: PPStore

    @State private var isAdding = false

    func body(content: Content) -> some View {
        content
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Person", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) {
                PPAddSheet(store: store)
            }
    }
}

/// The person's name, inline, and Edit for renaming or archiving them (PPL-004).
struct PPPersonChrome: ViewModifier {
    let store: PPStore
    let person: PPPerson

    @State private var isEditing = false

    func body(content: Content) -> some View {
        content
            .navigationTitle(Text(verbatim: person.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { isEditing = true }
                }
            }
            .sheet(isPresented: $isEditing) {
                PPPersonEditor(store: store, person: person)
            }
    }
}

extension View {
    func ppListChrome(store: PPStore) -> some View {
        modifier(PPListChrome(store: store))
    }

    func ppPersonChrome(store: PPStore, person: PPPerson) -> some View {
        modifier(PPPersonChrome(store: store, person: person))
    }
}

// MARK: - Add and edit (PPL-001, PPL-004)

/// A name, required, and the system contact picker to prefill it (PPL-001). The picker hands back only
/// the contact the user picks, so Finlark never asks for access to Contacts. Here a button stands in
/// for it.
struct PPAddSheet: View {
    let store: PPStore

    @State private var name = ""
    @FocusState private var isFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit(add)
                } footer: {
                    Text("Friends you split with don't need Finlark.")
                }
                Section {
                    Button("Choose from Contacts", systemImage: "person.crop.circle") {
                        // Stands in for CNContactPickerViewController.
                        name = "Carmen"
                    }
                } footer: {
                    Text("Only the name of the contact you pick is used. Finlark doesn't ask for access to your contacts.")
                }
            }
            .navigationTitle("New Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", systemImage: "checkmark", role: .confirm, action: add)
                        .disabled(!PPStore.isValidName(name))
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium, .large])
    }

    private func add() {
        guard store.add(named: name) != nil else { return }
        dismiss()
    }
}

/// Rename, archive or unarchive (PPL-004). Someone who still owes can't be archived, and the footer
/// says why instead of hiding the button.
struct PPPersonEditor: View {
    let store: PPStore
    let person: PPPerson

    @State private var name = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                }
                Section {
                    if person.isArchived {
                        Button("Unarchive", systemImage: "tray.and.arrow.up") {
                            store.setArchived(false, person.id)
                            dismiss()
                        }
                    } else {
                        Button("Archive", systemImage: "archivebox", role: .destructive) {
                            store.setArchived(true, person.id)
                            dismiss()
                        }
                        .disabled(!person.canArchive)
                    }
                } footer: {
                    if person.isArchived {
                        Text("Unarchived people show up again when you split an expense.")
                    } else if person.canArchive {
                        Text("Archived people are hidden when you split an expense. Their history is kept.")
                    } else {
                        Text("\(person.name) still owes you \(person.owed, format: .currency(code: store.code)). Settle up before archiving.")
                    }
                }
            }
            .navigationTitle("Edit Person")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        store.rename(person.id, to: name)
                        dismiss()
                    }
                    .disabled(!PPStore.isValidName(name))
                }
            }
            .onAppear { name = person.name }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Actions (SPL-008, NTF-003)

/// Settle all, after a confirmation, since repayments recorded by mistake are annoying to undo.
struct PPSettleAllButton<Label: View>: View {
    let store: PPStore
    let person: PPPerson
    @ViewBuilder let label: Label

    @State private var isConfirming = false

    var body: some View {
        Button {
            isConfirming = true
        } label: {
            label
        }
        .alert(Text("Settle all with \(person.name)?"), isPresented: $isConfirming) {
            Button("Cancel", role: .cancel) {}
            Button("Settle All") { store.settleAll(person.id) }
        } message: {
            PPSettleMessage(person: person, code: store.code)
        }
    }
}

extension PPSettleAllButton where Label == SwiftUI.Label<Text, Image> {
    /// "Settle all · €55.00".
    init(store: PPStore, person: PPPerson) {
        self.init(store: store, person: person) {
            SwiftUI.Label {
                Text("Settle All · \(person.owed, format: .currency(code: store.code))")
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
        }
    }
}

/// "This records €55.00 in repayments for 2 shares, dated today."
struct PPSettleMessage: View {
    let person: PPPerson
    let code: String

    var body: some View {
        if person.openShares.count == 1 {
            Text("This records a repayment of \(person.owed, format: .currency(code: code)), dated today.")
        } else {
            Text("This records \(person.owed, format: .currency(code: code)) in repayments for \(person.openShares.count) shares, dated today.")
        }
    }
}

/// The share sheet with a message listing the open shares and the total (NTF-003).
struct PPReminderButton<Label: View>: View {
    let store: PPStore
    let person: PPPerson
    @ViewBuilder let label: Label

    var body: some View {
        ShareLink(
            item: store.reminder(for: person),
            preview: SharePreview(Text("Reminder for \(person.name)"))
        ) {
            label
        }
    }
}

extension PPReminderButton where Label == SwiftUI.Label<Text, Image> {
    init(store: PPStore, person: PPPerson) {
        self.init(store: store, person: person) {
            SwiftUI.Label("Share Reminder", systemImage: "bubble.left.and.text.bubble.right")
        }
    }
}

// MARK: - Text

enum PPText {
    /// "2 open shares", "Settled up" or "No splits yet".
    static func summary(_ person: PPPerson) -> Text {
        if person.owes {
            Text("^[\(person.openShares.count) open share](inflect: true)")
        } else if person.shares.isEmpty {
            Text("No splits yet")
        } else {
            Text("Settled up")
        }
    }

    /// "Owes you €55.00" or "Settled up".
    static func owes(_ person: PPPerson, code: String) -> Text {
        if person.owes {
            Text("Owes you \(person.owed, format: .currency(code: code))")
        } else if person.shares.isEmpty {
            Text("No splits yet")
        } else {
            Text("Settled up")
        }
    }

    /// "3 people · 5 open shares".
    static func owing(_ store: PPStore) -> Text {
        Text("^[\(store.owing.count) person](inflect: true) · ^[\(store.openShareCount) open share](inflect: true)")
    }

    /// "today", "yesterday" or "on 14 Oct", to go inside a sentence.
    static func day(_ date: Date) -> Text {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return Text("today")
        } else if calendar.isDateInYesterday(date) {
            return Text("yesterday")
        } else if calendar.isDate(date, equalTo: .now, toGranularity: .year) {
            return Text("on \(date, format: .dateTime.day().month())")
        } else {
            return Text("on \(date, format: .dateTime.day().month().year())")
        }
    }

    /// "12 days open", "Since yesterday" or "Since today".
    static func age(_ share: PPShare) -> Text {
        switch share.age {
        case 0: Text("Since today")
        case 1: Text("Since yesterday")
        default: Text("^[\(share.age) day](inflect: true) open")
        }
    }
}

// MARK: - Rows

/// Avatar, name and what's open, with what they owe trailing (PPL-002). At accessibility sizes the
/// avatar goes and the amount moves under the name, so the name keeps the full width.
struct PPPersonRow: View {
    let person: PPPerson
    let code: String
    var avatarSize: CGFloat = 36

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    identity
                    amount
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 12) {
                    AEAvatar(person: person.avatar, size: avatarSize)
                    identity
                    Spacer(minLength: 8)
                    amount
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: person.name)
                .font(.headline)
            PPText.summary(person)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var amount: some View {
        if person.owes {
            Text(person.owed, format: .currency(code: code))
                .font(.headline)
                .monospacedDigit()
        }
    }
}

/// A settled share: ticket, when it was paid back, and the share.
struct PPSettledRow: View {
    let share: PPShare
    let code: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: share.ticket)
                if let date = share.settledOn {
                    Text("Paid back \(PPText.day(date))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(share.share, format: .currency(code: code))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

/// How much of a share is paid back. Decorative: the status says it in words.
struct PPProgressBar: View {
    let share: PPShare
    let color: Color

    @ScaledMetric private var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(color)
                    .frame(width: max(proxy.size.width * share.progress, share.paid > 0 ? height : 0))
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A few overlapping avatars, for a group at a glance. Decorative.
struct PPAvatarStack: View {
    let people: [PPPerson]
    var size: CGFloat = 30

    var body: some View {
        HStack(spacing: -size * 0.3) {
            ForEach(people.prefix(4)) { person in
                AEAvatar(person: person.avatar, size: size)
                    .background(.background, in: .rect(cornerRadius: size * 0.36, style: .continuous))
                    .padding(2)
                    .background(.background, in: .rect(cornerRadius: size * 0.4, style: .continuous))
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Empty and archived

/// People hidden from pickers, with their history kept (PPL-004).
struct PPArchivedScreen: View {
    let store: PPStore

    var body: some View {
        List {
            Section {
                ForEach(store.archived) { person in
                    NavigationLink(value: PPRoute.person(person.id)) {
                        PPPersonRow(person: person, code: store.code)
                    }
                }
            } footer: {
                Text("Archived people are hidden when you split an expense. Open one to unarchive them.")
            }
        }
        .overlay {
            if store.archived.isEmpty {
                ContentUnavailableView("No Archived People", systemImage: "archivebox")
            }
        }
        .navigationTitle("Archived")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("New person") {
    PPAddSheet(store: .sample)
}

#Preview("Edit person") {
    PPPersonEditor(store: .sample, person: PPStore.sample.people[0])
}
#endif
