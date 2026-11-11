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
                    HMSettingsScreen()
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

// MARK: - Buttons

/// A custom button look: a filled, tinted, outlined or ink (inverted) shape, slightly pressed in on tap.
struct PPButtonStyle: ButtonStyle {
    enum Kind {
        case filled
        case tinted
        case outline
        case ink
    }

    enum Shape {
        case capsule
        case rounded
    }

    var kind: Kind
    var tint: Color = .accentColor
    var shape: Shape = .capsule
    var isLarge = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isLarge ? .headline : .subheadline.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(PPInk.foreground(kind, tint: tint))
            .padding(.horizontal, isLarge ? 20 : 14)
            .padding(.vertical, isLarge ? 14 : 8)
            .frame(minHeight: isLarge ? 52 : 36)
            .background { PPInk.background(kind, tint: tint, in: outline) }
            .contentShape(outline)
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
    }

    private var outline: AnyShape {
        switch shape {
        case .capsule: AnyShape(Capsule())
        case .rounded: AnyShape(RoundedRectangle(cornerRadius: isLarge ? 16 : 12, style: .continuous))
        }
    }
}

/// Colors for the custom buttons. White text sits only on the accent or another dark tint, so it
/// keeps AA contrast; ink buttons invert with the appearance.
enum PPInk {
    static func foreground(_ kind: PPButtonStyle.Kind, tint: Color) -> AnyShapeStyle {
        switch kind {
        case .filled: AnyShapeStyle(Color.white)
        case .tinted, .outline: AnyShapeStyle(tint)
        case .ink: AnyShapeStyle(Color(uiColor: .systemBackground))
        }
    }

    @ViewBuilder
    static func background(_ kind: PPButtonStyle.Kind, tint: Color, in shape: AnyShape) -> some View {
        switch kind {
        case .filled: shape.fill(tint.gradient)
        case .tinted: shape.fill(tint.opacity(0.14))
        case .outline: shape.stroke(tint.opacity(0.7), lineWidth: 1.5).padding(0.75)
        // A concrete label color, since glass tiles turn `.primary` into a vibrant gray.
        case .ink: shape.fill(Color(uiColor: .label))
        }
    }
}

// MARK: - List pieces

/// The list's header: Owed to you, who and how many shares, and their faces.
struct PPOwedHeader: View {
    let store: PPStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HMTile(padding: 20) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Owed to you")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(store.owedToYou, format: .currency(code: store.code))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    if store.owedToYou > 0 {
                        PPText.owing(store)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Everyone's settled up.")
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                Spacer(minLength: 8)
                if !dynamicTypeSize.isAccessibilitySize {
                    PPAvatarStack(people: store.owing)
                }
            }
        }
    }
}

/// The Settled up tile: everyone who owes nothing, each opening their person screen.
struct PPSettledUpTile: View {
    let store: PPStore

    var body: some View {
        if !store.settled.isEmpty {
            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HMTileHeader(title: "Settled up", symbol: "checkmark.circle.fill")
                    ForEach(store.settled) { person in
                        PPPersonLink(person: person, code: store.code)
                        if person.id != store.settled.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

/// A person row that opens the person, with a chevron.
struct PPPersonLink: View {
    let person: PPPerson
    let code: String
    var avatarSize: CGFloat = 36
    /// Off when quick-action buttons follow the row and need the room.
    var showsChevron = true

    var body: some View {
        NavigationLink(value: PPRoute.person(person.id)) {
            HStack(spacing: 10) {
                PPPersonRow(person: person, code: code, avatarSize: avatarSize)
                if showsChevron {
                    HMChevron()
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// A person row with quick actions trailing it, or under it at accessibility sizes so the name keeps
/// the full width.
struct PPQuickRow<Actions: View>: View {
    let person: PPPerson
    let code: String
    @ViewBuilder let actions: Actions

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                PPPersonLink(person: person, code: code)
                HStack(spacing: 8) { actions }
            }
        } else {
            HStack(spacing: 8) {
                PPPersonLink(person: person, code: code, showsChevron: false)
                actions
            }
        }
    }
}

/// Archived people stay reachable (PPL-004) through a quiet line at the end of the list instead of a
/// section of their own. Nothing when there are none.
struct PPArchivedFootnote: View {
    let store: PPStore

    var body: some View {
        if !store.archived.isEmpty {
            NavigationLink(value: PPRoute.archived) {
                HStack(spacing: 4) {
                    Image(systemName: "archivebox")
                    Text("^[\(store.archived.count) archived person](inflect: true)")
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Person pieces

/// The person's header: the avatar centered, the name and what they owe.
struct PPPersonHeader: View {
    let person: PPPerson
    let code: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 8) {
            // The avatar scales with text, so it starts smaller at accessibility sizes.
            AEAvatar(person: person.avatar, size: dynamicTypeSize.isAccessibilitySize ? 52 : 88)
            Text(verbatim: person.name)
                .font(.title.weight(.bold))
            PPText.owes(person, code: code)
                .font(.title3)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

/// The person's settled shares in a tile.
struct PPSettledTile: View {
    let person: PPPerson
    let code: String

    var body: some View {
        if !person.settledShares.isEmpty {
            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HMTileHeader(title: "Settled", symbol: "checkmark.circle.fill")
                    ForEach(person.settledShares) { share in
                        PPSettledRow(share: share, code: code)
                    }
                }
            }
        }
    }
}

/// Shown for a person who hasn't been part of a split yet.
struct PPNoSplitsNote: View {
    let person: PPPerson

    var body: some View {
        if person.shares.isEmpty {
            Text("\(person.name) shows up here once you split an expense with them.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }
}

// MARK: - Paying one share (SPL-006, SPL-007)

/// Which share's repayment sheet is open, and whether it starts on the full amount or on part of it.
struct PPPayment: Identifiable {
    enum Mode: Hashable {
        case full
        case part
    }

    let personID: PPPerson.ID
    let shareID: PPShare.ID
    var mode: Mode = .full

    var id: PPShare.ID { shareID }
}

/// Records a repayment for one share: all that's left, or part of it, dated today unless changed
/// (SPL-006, SPL-007). The amount can't go over what's left (A-04).
struct PPRepaymentSheet: View {
    let store: PPStore
    let payment: PPPayment
    var kind: PPButtonStyle.Kind = .filled
    /// The system's blue Liquid Glass for Record instead of the custom look.
    var usesSystemGlass = false

    @State private var mode: PPPayment.Mode
    @State private var amountText = ""
    @State private var date = Date.now
    @Environment(\.dismiss) private var dismiss

    init(store: PPStore, payment: PPPayment, kind: PPButtonStyle.Kind = .filled, usesSystemGlass: Bool = false) {
        self.store = store
        self.payment = payment
        self.kind = kind
        self.usesSystemGlass = usesSystemGlass
        _mode = State(initialValue: payment.mode)
    }

    private var share: PPShare? { store.share(payment.shareID, of: payment.personID) }
    private var maximum: Decimal { share?.remaining ?? 0 }
    private var amount: Decimal {
        mode == .full ? maximum : (AEMoney.parse(amountText) ?? 0)
    }
    private var isTooMuch: Bool { amount > maximum }
    private var canSave: Bool { amount > 0 && !isTooMuch }

    var body: some View {
        NavigationStack {
            Form {
                if let share {
                    Section {
                        HStack(spacing: 12) {
                            ExplorationCategoryIcon(category: share.category)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: share.ticket)
                                    .font(.headline)
                                // Not a Label: in a Form its icon would line up with the row icons.
                                HStack(spacing: 6) {
                                    Image(systemName: share.status.symbol)
                                        .foregroundStyle(share.status.tint)
                                    share.statusText(code: store.code)
                                }
                                .font(.subheadline)
                            }
                        }
                        .accessibilityElement(children: .combine)
                        LabeledContent("Share") {
                            Text(share.share, format: .currency(code: store.code))
                        }
                        LabeledContent("Left") {
                            Text(share.remaining, format: .currency(code: store.code))
                        }
                    }
                    .monospacedDigit()
                }

                Section {
                    Picker("Repayment", selection: $mode) {
                        Text("All that's left").tag(PPPayment.Mode.full)
                        Text("Part of it").tag(PPPayment.Mode.part)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    LabeledContent("Amount") {
                        if mode == .full {
                            Text(maximum, format: .currency(code: store.code))
                                .monospacedDigit()
                        } else {
                            PPAmountField(text: $amountText, code: store.code)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } footer: {
                    if isTooMuch {
                        Label {
                            Text("That's more than the \(maximum, format: .currency(code: store.code)) left on this share.")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("Raises your balance. A repayment isn't income and doesn't change your spending.")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Group {
                    if usesSystemGlass {
                        recordButton
                            .buttonStyle(.glassProminent)
                            .controlSize(.large)
                    } else {
                        recordButton
                            .buttonStyle(PPButtonStyle(kind: kind, shape: .rounded, isLarge: true))
                    }
                }
                .disabled(!canSave)
                .padding()
            }
            .navigationTitle("Record Repayment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .environment(\.explorationIconStyle, .soft)
    }

    private var recordButton: some View {
        Button {
            store.record(amount, on: payment.shareID, of: payment.personID, on: date)
            dismiss()
        } label: {
            Text("Record \(amount, format: .currency(code: store.code))")
                .monospacedDigit()
                .frame(maxWidth: .infinity)
        }
    }
}

/// An amount typed as text and parsed to `Decimal` (NFR-005).
struct PPAmountField: View {
    @Binding var text: String
    let code: String

    var body: some View {
        let affix = AEMoney.affix(for: code)

        HStack(spacing: 2) {
            if affix.isLeading { Text(verbatim: affix.symbol).foregroundStyle(.secondary) }
            TextField("Amount", text: $text, prompt: Text(verbatim: "0"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .fixedSize()
            if !affix.isLeading { Text(verbatim: affix.symbol).foregroundStyle(.secondary) }
        }
        .monospacedDigit()
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.fill.tertiary, in: .rect(cornerRadius: 10, style: .continuous))
        .onChange(of: text) { _, newValue in
            let clean = AEMoney.sanitize(newValue, fractionDigits: AEMoney.fractionDigits(for: code))
            if clean != newValue { text = clean }
        }
    }
}

// MARK: - Undo

/// What was just recorded with one tap, so it can be undone.
struct PPUndo: Equatable {
    let message: String
    let personID: PPPerson.ID
    let repaymentIDs: [PPRepayment.ID]
}

extension PPStore {
    /// Marks a share paid today and returns what Undo needs.
    func markPaidWithUndo(_ share: PPShare, of person: PPPerson) -> PPUndo? {
        guard let repayment = markPaid(share.id, of: person.id) else { return nil }
        let amount = share.remaining.formatted(.currency(code: code))
        return PPUndo(
            message: String(localized: "\(share.ticket) marked as paid, \(amount)"),
            personID: person.id,
            repaymentIDs: [repayment.id]
        )
    }
}

/// A toast at the bottom with Undo, for actions that happen in one tap. It goes away after a few
/// seconds, and VoiceOver announces it.
struct PPUndoToast: ViewModifier {
    @Binding var undo: PPUndo?
    let store: PPStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let undo {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                        Text(verbatim: undo.message)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        Spacer(minLength: 8)
                        Button("Undo") {
                            for id in undo.repaymentIDs { store.undo(id, of: undo.personID) }
                            self.undo = nil
                        }
                        .buttonStyle(PPButtonStyle(kind: .tinted))
                    }
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: .capsule)
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                    .task(id: undo) {
                        AccessibilityNotification.Announcement(undo.message).post()
                        try? await Task.sleep(for: .seconds(5))
                        if !Task.isCancelled { self.undo = nil }
                    }
                }
            }
            .animation(reduceMotion ? nil : .snappy, value: undo)
    }
}

extension View {
    func ppUndoToast(_ undo: Binding<PPUndo?>, store: PPStore) -> some View {
        modifier(PPUndoToast(undo: undo, store: store))
    }
}

// MARK: - Reminder sheet (NTF-003)

/// The reminder as the bubble the friend will get, with a custom Share button. For places where the
/// share sheet can't open straight away, like a swipe action.
struct PPReminderSheet: View {
    let store: PPStore
    let person: PPPerson
    var kind: PPButtonStyle.Kind = .filled

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(verbatim: store.reminder(for: person))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.accentColor.gradient, in: PPBubble())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 40)
                    .accessibilityLabel(Text("Message: \(store.reminder(for: person))"))
                PPReminderButton(store: store, person: person) {
                    Label("Share Reminder", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PPButtonStyle(kind: kind, shape: .rounded, isLarge: true))
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(Text("Remind \(person.name)"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", role: .cancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// A sent message's bubble: rounded, with a tighter bottom-trailing corner.
/// `nonisolated` because SwiftUI can ask a `Shape` for its path off the main actor.
nonisolated struct PPBubble: Shape {
    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18,
            style: .continuous
        )
        .path(in: rect)
    }
}

#Preview("Repayment sheet") {
    let store = PPStore.sample
    let luis = store.person("luis")!
    return PPRepaymentSheet(store: store, payment: PPPayment(personID: luis.id, shareID: luis.openShares[1].id, mode: .part))
}

#Preview("Reminder sheet") {
    let store = PPStore.sample
    return PPReminderSheet(store: store, person: store.person("marta")!)
}

// MARK: - Actions

extension PPStore {
    /// Settle all for a person today (SPL-008) and returns what Undo needs.
    func settleAllWithUndo(_ person: PPPerson) -> PPUndo? {
        let total = person.owed.formatted(.currency(code: code))
        let repayments = settleAll(person.id)
        guard !repayments.isEmpty else { return nil }
        return PPUndo(
            message: String(localized: "Settled \(total) with \(person.name)"),
            personID: person.id,
            repaymentIDs: repayments.map(\.id)
        )
    }
}

// MARK: - Share text

/// The ticket and the date, with the status words for VoiceOver, since rows no longer print "Pending".
struct PPShareTitle: View {
    let share: PPShare
    let code: String
    var showsPaid = true

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(verbatim: share.ticket)
                .font(.headline)
            Text(share.date, format: .dateTime.weekday().day().month())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if showsPaid, share.paid > 0 {
                Text("\(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(share.statusText(code: code))
    }
}

// MARK: - Actions

/// What a variant's open shares and Settle All can do. Both record today's date and show Undo.
struct PPActions {
    let markPaid: (PPShare) -> Void
    let settleAll: () -> Void
}

extension PPPerson {
    /// Settle All only shows for two or more open shares: with one, paying that share is the same.
    var showsSettleAll: Bool { openShares.count > 1 }

    /// Open shares, oldest first, for variants that read as a timeline.
    var openSharesOldestFirst: [PPShare] { openShares.sorted { $0.date < $1.date } }
}

// MARK: - Person screen

/// The person screen with the middle drawn by its caller: the open shares and Settle All,
/// and optionally a bar pinned above the tab bar. The header, settled shares, reminder and Undo toast
/// are shared (PPL-003, NTF-003).
struct PPPersonScaffold<Content: View, Pinned: View>: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    /// Off when the variant draws the header itself.
    var showsHeader = true
    @ViewBuilder let content: (PPPerson, PPActions) -> Content
    @ViewBuilder let pinned: (PPPerson, PPActions) -> Pinned

    @State private var undo: PPUndo?

    var body: some View {
        if let person = store.person(id) {
            let actions = PPActions(
                markPaid: { share in undo = store.markPaidWithUndo(share, of: person) },
                settleAll: { undo = store.settleAllWithUndo(person) }
            )

            ScrollView {
                VStack(spacing: hmTileSpacing) {
                    if showsHeader {
                        PPPersonHeader(person: person, code: store.code)
                    }
                    content(person, actions)
                    PPSettledTile(person: person, code: store.code)
                    PPNoSplitsNote(person: person)
                }
                .padding()
            }
            // The toast sits inside the pinned bar's inset, so it shows above the bar, not over it.
            .ppUndoToast($undo, store: store)
            .safeAreaInset(edge: .bottom) {
                pinned(person, actions)
            }
            .background { HMBackdrop() }
            .ppPersonChrome(store: store, person: person)
            .toolbar {
                if person.owes {
                    ToolbarItem(placement: .topBarTrailing) {
                        PPReminderButton(store: store, person: person) {
                            Label("Share Reminder", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }
}

extension PPPersonScaffold where Pinned == EmptyView {
    init(
        store: PPStore,
        id: PPPerson.ID,
        showsHeader: Bool = true,
        @ViewBuilder content: @escaping (PPPerson, PPActions) -> Content
    ) {
        self.init(store: store, id: id, showsHeader: showsHeader, content: content) { _, _ in EmptyView() }
    }
}

// MARK: - Settle All

/// Genmaicha's full-width Settle All with the total.
struct PPSettleAllTotalButton: View {
    let person: PPPerson
    let code: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: action) {
            Label {
                // At accessibility sizes the total gets its own line instead of wrapping at the dot.
                if dynamicTypeSize.isAccessibilitySize {
                    VStack {
                        Text("Settle All")
                        Text(person.owed, format: .currency(code: code))
                    }
                    .monospacedDigit()
                } else {
                    Text("Settle All · \(person.owed, format: .currency(code: code))")
                        .monospacedDigit()
                }
            } icon: {
                Image(systemName: "checkmark.circle.fill")
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        .controlSize(.large)
    }
}

// MARK: - Share pieces

/// What's left on a share, large, with "left" under it.
struct PPRemaining: View {
    let share: PPShare
    let code: String
    var font: Font = .headline

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        // Trailing beside the share, leading once it moves under it at accessibility sizes.
        VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 0) {
            Text(share.remaining, format: .currency(code: code))
                .font(font)
                .monospacedDigit()
            Text("left")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// Info leading and an amount trailing, or the amount under the info at accessibility sizes.
struct PPInfoAndAmount<Info: View, Amount: View>: View {
    @ViewBuilder let info: Info
    @ViewBuilder let amount: Amount

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                info
                amount
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                info
                    .frame(maxWidth: .infinity, alignment: .leading)
                amount
            }
        }
    }
}

/// The category icon, left out at accessibility sizes so the text keeps the width.
struct PPCategoryIcon: View {
    let category: ExplorationCategory

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            ExplorationCategoryIcon(category: category)
        }
    }
}

// MARK: - Options

/// Where Settle All goes.
enum PPSettlePlacement {
    /// Under the name and what they owe.
    case underHeader
    /// Above the tab bar, always in reach.
    case pinned
}

/// How Settle All looks.
enum PPSettleLook {
    /// A full-width bar with the total.
    case fullWidth
    /// A centered pill, since the header already says the total.
    case pill
    /// A glass bar with the total and share count leading and the button trailing. For `.pinned`.
    case summaryBar
}

/// How the two buttons under a share relate.
enum PPButtonPair {
    /// Add Repayment in plain glass, Mark as Paid in blue glass: the full repayment leads.
    case secondaryAndPrimary
    /// Both in blue glass, as equals.
    case bothPrimary
}

// MARK: - Person screen

/// The person screen shared by every person, set up by the options (PPL-003, SPL-006…008).
struct PPPersonScreen: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var settlePlacement: PPSettlePlacement = .underHeader
    var settleLook: PPSettleLook = .fullWidth
    var buttonPair: PPButtonPair = .secondaryAndPrimary
    /// A bar under a partly paid share's text, showing how much came back.
    var showsProgress = false

    @State private var payment: PPPayment?
    @State private var undo: PPUndo?

    var body: some View {
        if let person = store.person(id) {
            let settleAll = { undo = store.settleAllWithUndo(person) }

            ScrollView {
                VStack(spacing: hmTileSpacing) {
                    PPPersonHeader(person: person, code: store.code)
                    if person.showsSettleAll, settlePlacement == .underHeader {
                        settle(person, action: settleAll)
                    }
                    if !person.openShares.isEmpty {
                        HMTile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                HMTileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    PPShareRow(
                                        share: share,
                                        code: store.code,
                                        buttonPair: buttonPair,
                                        showsProgress: showsProgress,
                                        addRepayment: { payment = PPPayment(personID: person.id, shareID: share.id, mode: .part) },
                                        markPaid: { undo = store.markPaidWithUndo(share, of: person) }
                                    )
                                    if share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    PPSettledTile(person: person, code: store.code)
                    PPNoSplitsNote(person: person)
                }
                .padding()
            }
            // Inside the pinned bar's inset, so the toast shows above the bar, not over it.
            .ppUndoToast($undo, store: store)
            .safeAreaInset(edge: .bottom) {
                if person.showsSettleAll, settlePlacement == .pinned {
                    settle(person, action: settleAll)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .background { HMBackdrop() }
            .ppPersonChrome(store: store, person: person)
            .toolbar {
                if person.owes {
                    ToolbarItem(placement: .topBarTrailing) {
                        PPReminderButton(store: store, person: person) {
                            Label("Share Reminder", systemImage: "square.and.arrow.up")
                        }
                    }
                }
            }
            .sheet(item: $payment) { PPRepaymentSheet(store: store, payment: $0, usesSystemGlass: true) }
        }
    }

    @ViewBuilder
    private func settle(_ person: PPPerson, action: @escaping () -> Void) -> some View {
        switch settleLook {
        case .fullWidth:
            PPSettleAllTotalButton(person: person, code: store.code, action: action)
        case .pill:
            Button(action: action) {
                Label("Settle All", systemImage: "checkmark.circle.fill")
                    .padding(.horizontal, 8)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityLabel(Text("Settle all, \(person.owed.formatted(.currency(code: store.code)))"))
        case .summaryBar:
            PPSummaryBar(person: person, code: store.code, action: action)
        }
    }
}

// MARK: - Share row

/// A share's row with what's left trailing, and the two buttons under it, side by side, or stacked
/// at accessibility sizes.
struct PPShareRow: View {
    let share: PPShare
    let code: String
    let buttonPair: PPButtonPair
    var showsProgress = false
    let addRepayment: () -> Void
    let markPaid: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                PPCategoryIcon(category: share.category)
                VStack(alignment: .leading, spacing: 8) {
                    PPInfoAndAmount {
                        PPShareTitle(share: share, code: code)
                    } amount: {
                        PPRemaining(share: share, code: code)
                    }
                    if showsProgress, share.paid > 0 {
                        PPProgressBar(share: share, color: .accentColor)
                    }
                }
            }

            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 8))
                : AnyLayout(HStackLayout(spacing: 10))
            layout {
                Group {
                    switch buttonPair {
                    case .secondaryAndPrimary:
                        addButton.buttonStyle(.glass)
                    case .bothPrimary:
                        addButton.buttonStyle(.glassProminent)
                    }
                }
                Button(action: markPaid) {
                    Label("Mark as Paid", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .accessibilityLabel(Text("Mark \(share.ticket) as paid"))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.85)
        }
    }

    private var addButton: some View {
        Button(action: addRepayment) {
            Label("Add Repayment", systemImage: "plus")
                .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(Text("Add repayment for \(share.ticket)"))
    }
}

// MARK: - Settle All bar

/// A pinned glass bar: what's open on the leading side, Settle All trailing, or under it at
/// accessibility sizes.
struct PPSummaryBar: View {
    let person: PPPerson
    let code: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 0) {
                Text(person.owed, format: .currency(code: code))
                    .font(.headline)
                    .monospacedDigit()
                Text("^[\(person.openShares.count) open share](inflect: true)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            Button(action: action) {
                Label("Settle All", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityLabel(Text("Settle all, \(person.owed.formatted(.currency(code: code)))"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}
#endif
