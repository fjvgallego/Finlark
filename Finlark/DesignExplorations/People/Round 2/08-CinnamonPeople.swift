//
//  08-CinnamonPeople.swift
//  Finlark
//
//  FIN-9 People, Round 2 "Cinnamon": color instead of glass. Iris's header becomes a solid block of the
//  accent color with white text, and so does the person's header, with white square actions on it.
//  Rows have round filled quick actions. Each open share shows its bar and a Pay button that opens the
//  repayment sheet, where All that's left and Part of it sit side by side (SPL-006, SPL-007).
//

#if DEBUG
import SwiftUI

struct CinnamonPeople: View {
    @Bindable var store: PPStore
    var surface: R2Surface = .solid

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    hero
                }
                if !store.owing.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            R2TileHeader(title: "Owe you", symbol: "arrow.down.circle.fill")
                            ForEach(store.owing) { person in
                                P2QuickRow(person: person, code: store.code) {
                                    PPReminderButton(store: store, person: person) {
                                        Label("Remind \(person.name)", systemImage: "bubble.left.and.text.bubble.right.fill")
                                    }
                                    .buttonStyle(P2IconButtonStyle(kind: .tinted))
                                    PPSettleAllButton(store: store, person: person) {
                                        Label("Settle all with \(person.name)", systemImage: "checkmark")
                                    }
                                    .buttonStyle(P2IconButtonStyle(kind: .filled))
                                }
                                if person.id != store.owing.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                P2SettledUpTile(store: store)
                P2ArchivedFootnote(store: store)
            }
            .padding()
        }
        .background { R2Backdrop() }
        .overlay {
            if store.people.isEmpty {
                P2EmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
        .environment(\.r2Surface, surface)
    }

    /// Iris's header on a block of the accent color.
    private var hero: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Owed to you")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(store.owedToYou, format: .currency(code: store.code))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                if store.owedToYou > 0 {
                    PPText.owing(store)
                        .foregroundStyle(.white.opacity(0.85))
                } else {
                    Text("Everyone's settled up.")
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
        }
        .foregroundStyle(.white)
        .padding(20)
        .background(Color.accentColor.gradient, in: .rect(cornerRadius: 24, style: .continuous))
    }
}

struct CinnamonPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .solid

    @State private var payment: P2Payment?
    @ScaledMetric private var avatarSize: CGFloat = 80

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    VStack(spacing: 14) {
                        VStack(spacing: 8) {
                            Text(verbatim: person.avatar.initial)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                                .frame(width: avatarSize, height: avatarSize)
                                .background(.white, in: .rect(cornerRadius: 26, style: .continuous))
                                .accessibilityHidden(true)
                            Text(verbatim: person.name)
                                .font(.title.weight(.bold))
                            PPText.owes(person, code: store.code)
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.85))
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        P2PersonActions(store: store, person: person, kind: .tinted, tint: .white)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.accentColor.gradient, in: .rect(cornerRadius: 28, style: .continuous))

                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    VStack(alignment: .leading, spacing: 10) {
                                        PPShareRow(share: share, code: store.code, showsBar: true)
                                        Button {
                                            payment = P2Payment(personID: person.id, shareID: share.id, mode: .full)
                                        } label: {
                                            Text("Pay \(share.remaining, format: .currency(code: store.code))")
                                                .monospacedDigit()
                                                .frame(maxWidth: .infinity)
                                        }
                                        .buttonStyle(P2ButtonStyle(kind: .filled, shape: .rounded))
                                        .accessibilityLabel(Text("Record a repayment for \(share.ticket)"))
                                    }
                                    if share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                    P2SettledTile(person: person, code: store.code)
                    P2NoSplitsNote(person: person)
                }
                .padding()
            }
            .background { R2Backdrop() }
            .ppPersonChrome(store: store, person: person)
            .sheet(item: $payment) { P2RepaymentSheet(store: store, payment: $0) }
            .environment(\.r2Surface, surface)
        }
    }
}

#Preview("Cinnamon") {
    PPHost { CinnamonPeople(store: $0) } person: { CinnamonPerson(store: $0, id: $1) }
}

#Preview("Cinnamon · Marta") {
    PPHost(opening: "marta") { CinnamonPeople(store: $0) } person: { CinnamonPerson(store: $0, id: $1) }
}

#Preview("Cinnamon · Glass") {
    PPHost(opening: "luis") {
        CinnamonPeople(store: $0, surface: .glass)
    } person: {
        CinnamonPerson(store: $0, id: $1, surface: .glass)
    }
}

#Preview("Cinnamon · Settled up") {
    PPHost(store: .settledUp) { CinnamonPeople(store: $0) } person: { CinnamonPerson(store: $0, id: $1) }
}
#endif
