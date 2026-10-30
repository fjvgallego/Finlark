//
//  PeopleRound4Components.swift
//  Finlark
//
//  FIN-9 People, Round 4: Anise, refined. The owner kept Anise's glass layout, its leading check and
//  the Undo toast, and asked for two fixes: Settle All lacked contrast (accent text on a faint accent
//  tint, worse in dark mode), and the open shares looked heavy. Each variant pairs a Settle All with
//  real contrast and a lighter share row. The list stays Round 3's `P3People`.
//

#if DEBUG
import SwiftUI

// MARK: - Settle All

/// Where Settle All sits and how it looks. Every style keeps text at AA contrast or better in both
/// appearances.
enum P4SettleStyle {
    /// White text on the accent, under the header.
    case filled
    /// Inverted: label color fill with background-colored text.
    case ink
    /// An accent outline with text in the label color.
    case outline
    /// A stronger accent tint with text in the label color and an accent icon.
    case strongTint
    /// A small filled pill in the Open shares heading.
    case inHeading
    /// A filled bar pinned above the tab bar.
    case pinned
}

/// An accent outline with label-colored text, so the words never depend on the accent's contrast.
struct P4OutlineButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontDesign(.rounded)
            .foregroundStyle(Color(uiColor: .label))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.accentColor, lineWidth: 2)
                    .padding(1)
            }
            .contentShape(.rect(cornerRadius: 16))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// A stronger accent tint than Round 3's, with label-colored text.
struct P4StrongTintButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontDesign(.rounded)
            .foregroundStyle(Color(uiColor: .label))
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .frame(minHeight: 52)
            .background(Color.accentColor.opacity(0.28), in: .rect(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// "Settle All · 55,00 €" in the chosen style.
private struct P4SettleAllButton: View {
    let person: PPPerson
    let code: String
    let style: P4SettleStyle
    let action: () -> Void

    var body: some View {
        switch style {
        case .filled, .pinned:
            button.buttonStyle(P2ButtonStyle(kind: .filled, shape: .rounded, isLarge: true))
        case .ink:
            button.buttonStyle(P2ButtonStyle(kind: .ink, shape: .rounded, isLarge: true))
        case .outline:
            button.buttonStyle(P4OutlineButtonStyle())
        case .strongTint:
            button.buttonStyle(P4StrongTintButtonStyle())
        case .inHeading:
            Button("Settle All", action: action)
                .buttonStyle(P2ButtonStyle(kind: .filled))
                .accessibilityLabel(Text("Settle all, \(person.owed.formatted(.currency(code: code)))"))
        }
    }

    private var button: some View {
        Button(action: action) {
            Label {
                Text("Settle All · \(person.owed, format: .currency(code: code))")
                    .monospacedDigit()
            } icon: {
                // An accent icon on the label-colored styles; on filled and ink it follows the text.
                if style == .outline || style == .strongTint {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Person screen

/// Anise's person screen with the Settle All style as a parameter (PPL-003, SPL-006…008). The variant
/// draws what sits next to the check; the check, touch-and-hold menu, sheet and Undo toast are shared.
struct P4PersonScreen<Content: View, Check: View>: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    let settleStyle: P4SettleStyle
    var surface: R2Surface = .glass
    /// Each share on its own inset card instead of rows with dividers.
    var usesShareCards = false
    @ViewBuilder let check: (PPShare, P3ShareActions) -> Check
    @ViewBuilder let content: (PPShare) -> Content

    @State private var payment: P2Payment?
    @State private var undo: P2Undo?

    var body: some View {
        if let person = store.person(id) {
            let showsSettle = person.openShares.count > 1

            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    P2PersonHeader(person: person, code: store.code)
                    if showsSettle, ![.inHeading, .pinned].contains(settleStyle) {
                        settleButton(person)
                    }
                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: usesShareCards ? 10 : 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill") {
                                    if showsSettle, settleStyle == .inHeading {
                                        settleButton(person)
                                    }
                                }
                                ForEach(person.openShares) { share in
                                    row(share, of: person)
                                    if !usesShareCards, share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                                Text("Check a share when it's paid back. Touch and hold to record part of it.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    P2SettledTile(person: person, code: store.code)
                    P2NoSplitsNote(person: person)
                }
                .padding()
            }
            .safeAreaInset(edge: .bottom) {
                if showsSettle, settleStyle == .pinned {
                    settleButton(person)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
            .background { R2Backdrop() }
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
            .sheet(item: $payment) { P2RepaymentSheet(store: store, payment: $0) }
            .p2UndoToast($undo, store: store)
            .environment(\.r2Surface, surface)
        }
    }

    private func settleButton(_ person: PPPerson) -> some View {
        P4SettleAllButton(person: person, code: store.code, style: settleStyle) {
            undo = store.settleAllWithUndo(person)
        }
    }

    @ViewBuilder
    private func row(_ share: PPShare, of person: PPPerson) -> some View {
        let actions = P3ShareActions(
            markPaid: { undo = store.markPaidWithUndo(share, of: person) },
            recordPart: { payment = P2Payment(personID: person.id, shareID: share.id, mode: .part) },
            pickDate: { payment = P2Payment(personID: person.id, shareID: share.id, mode: .full) }
        )

        P4CheckRow {
            check(share, actions)
        } content: {
            content(share)
                .accessibilityElement(children: .combine)
                // The words for Pending live here, since the rows no longer show them.
                .accessibilityValue(share.statusText(code: store.code))
        }
        .padding(usesShareCards ? 12 : 0)
        .background {
            if usesShareCards {
                RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.fill.quaternary)
            }
        }
        .contextMenu {
            Button("Record Part…", systemImage: "circle.lefthalf.filled", action: actions.recordPart)
            Button("Paid on Another Date…", systemImage: "calendar", action: actions.pickDate)
        }
        .accessibilityActions {
            Button("Record Part", action: actions.recordPart)
            Button("Paid on Another Date", action: actions.pickDate)
        }
    }
}

extension P4PersonScreen where Check == P3CheckButton {
    /// Anise's check: Saffron's round tinted button.
    init(
        store: PPStore,
        id: PPPerson.ID,
        settleStyle: P4SettleStyle,
        surface: R2Surface = .glass,
        usesShareCards: Bool = false,
        @ViewBuilder content: @escaping (PPShare) -> Content
    ) {
        self.init(store: store, id: id, settleStyle: settleStyle, surface: surface, usesShareCards: usesShareCards) { share, actions in
            P3CheckButton(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
        } content: { share in
            content(share)
        }
    }
}

/// Anise's layout: the check leads, the share follows. At accessibility sizes the check moves under it.
struct P4CheckRow<Check: View, Content: View>: View {
    @ViewBuilder let check: Check
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                content
                check
            }
        } else {
            HStack(alignment: .top, spacing: 12) {
                check
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Share pieces

/// The ticket and what's left on one line, or stacked at accessibility sizes.
struct P4TitleLine: View {
    let share: PPShare
    let code: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 8))
        layout {
            Text(verbatim: share.ticket)
                .font(.headline)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            Text(share.remaining, format: .currency(code: code))
                .font(.headline)
                .monospacedDigit()
        }
    }
}

/// "20,00 € of 30,00 € paid", only for a share that's partly paid.
struct P4PaidLine: View {
    let share: PPShare
    let code: String

    var body: some View {
        if share.paid > 0 {
            Text("\(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
#endif
