//
//  03-LungoPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Lungo": the open shares as a timeline, oldest first, each saying how long
//  it's been open. Settle All floats above the tab bar while there's more than one share, so it's
//  always in reach however long the list gets.
//

#if DEBUG
import SwiftUI

struct LungoPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if !person.openShares.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Open shares", symbol: "clock.fill")
                        VStack(alignment: .leading, spacing: 0) {
                            let shares = person.openSharesOldestFirst
                            ForEach(shares) { share in
                                LungoRow(share: share, code: store.code, isLast: share.id == shares.last?.id) {
                                    actions.markPaid(share)
                                }
                            }
                        }
                    }
                }
            }
        } pinned: { person, actions in
            if person.showsSettleAll {
                P8SettleAllButton(person: person, code: store.code, action: actions.settleAll)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
    }
}

private struct LungoRow: View {
    let share: PPShare
    let code: String
    let isLast: Bool
    let markPaid: () -> Void

    @ScaledMetric private var dot: CGFloat = 10

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // The timeline: a dot per share and a line down to the next one.
            VStack(spacing: 4) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: dot, height: dot)
                    .padding(.top, 5)
                if !isLast {
                    Capsule()
                        .fill(.quaternary)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)

            P5Row {
                VStack(alignment: .leading, spacing: 3) {
                    PPText.age(share)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    P5ShareTitle(share: share, code: code)
                    Text("\(share.remaining, format: .currency(code: code)) left")
                        .font(.headline)
                        .monospacedDigit()
                        .padding(.top, 2)
                }
            } controls: {
                GenmaichaCheck(title: Text("Mark \(share.ticket) as paid"), action: markPaid)
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}

#Preview("Lungo") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { LungoPerson(store: $0, id: $1) }
}

#Preview("Lungo · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { LungoPerson(store: $0, id: $1) }
}

#Preview("Lungo · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { LungoPerson(store: $0, id: $1) }
}

#Preview("Lungo · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { LungoPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
