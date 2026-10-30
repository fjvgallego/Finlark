//
//  08-LilacPeople.swift
//  Finlark
//
//  FIN-9 People, Round 1 "Lilac": the nudge comes first. Every person who owes you has a Remind button
//  right on their row (PPL-002, NTF-003). A person shows the reminder as the message bubble their
//  friend will get, listing each open share and the total, with Share Reminder under it and Settle
//  all next to it (PPL-003, SPL-008). The open shares follow, then the settled ones.
//

#if DEBUG
import SwiftUI

struct LilacPeople: View {
    @Bindable var store: PPStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.active.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 4) {
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
                    }
                }
                if !store.owing.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(store.owing) { person in
                                row(person)
                                if person.id != store.owing.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                if !store.settled.isEmpty {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            R2TileHeader(title: "Settled up", symbol: "checkmark.circle.fill")
                            ForEach(store.settled) { person in
                                NavigationLink(value: PPRoute.person(person.id)) {
                                    HStack(spacing: 10) {
                                        PPPersonRow(person: person, code: store.code, avatarSize: 30)
                                        R2Chevron()
                                    }
                                    .contentShape(.rect)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                if !store.archived.isEmpty {
                    R2Tile(padding: 16) {
                        PPArchivedLink(store: store)
                    }
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .overlay {
            if store.people.isEmpty {
                PPEmptyState(store: store)
            }
        }
        .ppListChrome(store: store)
    }

    private func row(_ person: PPPerson) -> some View {
        HStack(spacing: 12) {
            NavigationLink(value: PPRoute.person(person.id)) {
                PPPersonRow(person: person, code: store.code)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            PPReminderButton(store: store, person: person) {
                Label("Remind \(person.name)", systemImage: "bubble.left.and.text.bubble.right.fill")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
        }
    }
}

struct LilacPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        if let person = store.person(id) {
            ScrollView {
                VStack(alignment: .leading, spacing: r2TileSpacing) {
                    R2Tile(padding: 18) {
                        HStack(spacing: 14) {
                            AEAvatar(person: person.avatar, size: 48)
                            PPText.owes(person, code: store.code)
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }

                    if person.owes {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Reminder", symbol: "bubble.left.and.text.bubble.right.fill")
                                Text(verbatim: store.reminder(for: person))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .foregroundStyle(.white)
                                    .background(Color.accentColor.gradient, in: LilacBubble())
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(.leading, 32)
                                    .accessibilityLabel(Text("Message: \(store.reminder(for: person))"))
                                PPReminderButton(store: store, person: person) {
                                    Label("Share Reminder", systemImage: "square.and.arrow.up")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.glassProminent)
                                .controlSize(.large)
                                PPSettleAllButton(store: store, person: person) {
                                    Label("Already paid? Settle All", systemImage: "checkmark.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.glass)
                                .controlSize(.large)
                            }
                        }
                    }

                    if !person.openShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 14) {
                                R2TileHeader(title: "Open shares", symbol: "clock.fill")
                                ForEach(person.openShares) { share in
                                    PPShareRow(share: share, code: store.code)
                                    if share.id != person.openShares.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    if !person.settledShares.isEmpty {
                        R2Tile(padding: 18) {
                            VStack(alignment: .leading, spacing: 12) {
                                R2TileHeader(title: "Settled", symbol: "checkmark.circle.fill")
                                ForEach(person.settledShares) { share in
                                    PPSettledRow(share: share, code: store.code)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background { R2Backdrop() }
            .ppPersonChrome(store: store, person: person)
        }
    }
}

/// A sent message's bubble: rounded, with a tighter bottom-trailing corner.
private struct LilacBubble: Shape {
    func path(in rect: CGRect) -> Path {
        UnevenRoundedRectangle(
            topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18,
            style: .continuous
        )
        .path(in: rect)
    }
}

#Preview("Lilac") {
    PPHost { LilacPeople(store: $0) } person: { LilacPerson(store: $0, id: $1) }
}

#Preview("Lilac · Marta") {
    PPHost(opening: "marta") { LilacPeople(store: $0) } person: { LilacPerson(store: $0, id: $1) }
}

#Preview("Lilac · Settled up") {
    PPHost(store: .settledUp) { LilacPeople(store: $0) } person: { LilacPerson(store: $0, id: $1) }
}
#endif
