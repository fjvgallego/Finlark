//
//  PeopleRound2Components.swift
//  Finlark
//
//  FIN-9 People, Round 2: pieces the Round 2 variants share. From Round 1 the owner kept Iris's Owed to
//  you header and Settled up tile, quick Remind and Settle actions on the list, and Dahlia's person
//  screen, with every share payable on its own so Settle all is never the only way (SPL-006, SPL-007).
//  Buttons have their own look instead of the system's, and tiles come with or without Liquid Glass
//  through `\.r2Surface`.
//

#if DEBUG
import SwiftUI

// MARK: - Buttons

/// A custom button look: a filled, tinted, outlined or ink (inverted) shape, slightly pressed in on tap.
struct P2ButtonStyle: ButtonStyle {
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
            .foregroundStyle(P2Ink.foreground(kind, tint: tint))
            .padding(.horizontal, isLarge ? 20 : 14)
            .padding(.vertical, isLarge ? 14 : 8)
            .frame(minHeight: isLarge ? 52 : 36)
            .background { P2Ink.background(kind, tint: tint, in: outline) }
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
enum P2Ink {
    static func foreground(_ kind: P2ButtonStyle.Kind, tint: Color) -> AnyShapeStyle {
        switch kind {
        case .filled: AnyShapeStyle(Color.white)
        case .tinted, .outline: AnyShapeStyle(tint)
        case .ink: AnyShapeStyle(Color(uiColor: .systemBackground))
        }
    }

    @ViewBuilder
    static func background(_ kind: P2ButtonStyle.Kind, tint: Color, in shape: AnyShape) -> some View {
        switch kind {
        case .filled: shape.fill(tint.gradient)
        case .tinted: shape.fill(tint.opacity(0.14))
        case .outline: shape.stroke(tint.opacity(0.7), lineWidth: 1.5).padding(0.75)
        // A concrete label color, since glass tiles turn `.primary` into a vibrant gray.
        case .ink: shape.fill(Color(uiColor: .label))
        }
    }
}

// MARK: - List pieces (from Iris)

/// Iris's header: Owed to you, who and how many shares, and their faces.
struct P2OwedHeader: View {
    let store: PPStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        R2Tile(padding: 20) {
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

/// Iris's Settled up tile: everyone who owes nothing, each opening their person screen.
struct P2SettledUpTile: View {
    let store: PPStore

    var body: some View {
        if !store.settled.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Settled up", symbol: "checkmark.circle.fill")
                    ForEach(store.settled) { person in
                        P2PersonLink(person: person, code: store.code)
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
struct P2PersonLink: View {
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
                    R2Chevron()
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// A person row with quick actions trailing it, or under it at accessibility sizes so the name keeps
/// the full width.
struct P2QuickRow<Actions: View>: View {
    let person: PPPerson
    let code: String
    @ViewBuilder let actions: Actions

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                P2PersonLink(person: person, code: code)
                HStack(spacing: 8) { actions }
            }
        } else {
            HStack(spacing: 8) {
                P2PersonLink(person: person, code: code, showsChevron: false)
                actions
            }
        }
    }
}

/// Archived people stay reachable (PPL-004) through a quiet line at the end of the list instead of a
/// section of their own. Nothing when there are none.
struct P2ArchivedFootnote: View {
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

// MARK: - Person pieces (from Dahlia)

/// Dahlia's header: the avatar centered, the name and what they owe.
struct P2PersonHeader: View {
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
struct P2SettledTile: View {
    let person: PPPerson
    let code: String

    var body: some View {
        if !person.settledShares.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Settled", symbol: "checkmark.circle.fill")
                    ForEach(person.settledShares) { share in
                        PPSettledRow(share: share, code: code)
                    }
                }
            }
        }
    }
}

/// Shown for a person who hasn't been part of a split yet.
struct P2NoSplitsNote: View {
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
struct P2Payment: Identifiable {
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
struct P2RepaymentSheet: View {
    let store: PPStore
    let payment: P2Payment
    var kind: P2ButtonStyle.Kind = .filled
    /// The system's blue Liquid Glass for Record instead of the custom look, from People Round 9.
    var usesSystemGlass = false

    @State private var mode: P2Payment.Mode
    @State private var amountText = ""
    @State private var date = Date.now
    @Environment(\.dismiss) private var dismiss

    init(store: PPStore, payment: P2Payment, kind: P2ButtonStyle.Kind = .filled, usesSystemGlass: Bool = false) {
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
                        Text("All that's left").tag(P2Payment.Mode.full)
                        Text("Part of it").tag(P2Payment.Mode.part)
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
                            P2AmountField(text: $amountText, code: store.code)
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
                            .buttonStyle(P2ButtonStyle(kind: kind, shape: .rounded, isLarge: true))
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
struct P2AmountField: View {
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
struct P2Undo: Equatable {
    let message: String
    let personID: PPPerson.ID
    let repaymentIDs: [PPRepayment.ID]
}

extension PPStore {
    /// Marks a share paid today and returns what Undo needs.
    func markPaidWithUndo(_ share: PPShare, of person: PPPerson) -> P2Undo? {
        guard let repayment = markPaid(share.id, of: person.id) else { return nil }
        let amount = share.remaining.formatted(.currency(code: code))
        return P2Undo(
            message: String(localized: "\(share.ticket) marked as paid, \(amount)"),
            personID: person.id,
            repaymentIDs: [repayment.id]
        )
    }
}

/// A toast at the bottom with Undo, for actions that happen in one tap. It goes away after a few
/// seconds, and VoiceOver announces it.
struct P2UndoToast: ViewModifier {
    @Binding var undo: P2Undo?
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
                        .buttonStyle(P2ButtonStyle(kind: .tinted))
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
    func p2UndoToast(_ undo: Binding<P2Undo?>, store: PPStore) -> some View {
        modifier(P2UndoToast(undo: undo, store: store))
    }
}

// MARK: - Reminder sheet (NTF-003)

/// The reminder as the bubble the friend will get, with a custom Share button. For places where the
/// share sheet can't open straight away, like a swipe action.
struct P2ReminderSheet: View {
    let store: PPStore
    let person: PPPerson
    var kind: P2ButtonStyle.Kind = .filled

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(verbatim: store.reminder(for: person))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .foregroundStyle(.white)
                    .background(Color.accentColor.gradient, in: P2Bubble())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.leading, 40)
                    .accessibilityLabel(Text("Message: \(store.reminder(for: person))"))
                PPReminderButton(store: store, person: person) {
                    Label("Share Reminder", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(P2ButtonStyle(kind: kind, shape: .rounded, isLarge: true))
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
struct P2Bubble: Shape {
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
    return P2RepaymentSheet(store: store, payment: P2Payment(personID: luis.id, shareID: luis.openShares[1].id, mode: .part))
}

#Preview("Reminder sheet") {
    let store = PPStore.sample
    return P2ReminderSheet(store: store, person: store.person("marta")!)
}
#endif
