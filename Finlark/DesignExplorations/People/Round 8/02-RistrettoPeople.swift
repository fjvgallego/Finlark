//
//  02-RistrettoPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Ristretto": compact. Each share is one tight row, the ticket over its date,
//  the amount and a small check trailing. Settle All is a small capsule in the Open shares heading, and
//  the tile ends on the total.
//

#if DEBUG
import SwiftUI

struct RistrettoPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if !person.openShares.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        // At accessibility sizes Settle All moves under the heading, so the heading keeps its line.
                        R2TileHeader(title: "Open shares", symbol: "clock.fill") {
                            if person.showsSettleAll, !dynamicTypeSize.isAccessibilitySize {
                                P8CompactSettleButton(person: person, code: store.code, controlSize: .small, action: actions.settleAll)
                            }
                        }
                        if person.showsSettleAll, dynamicTypeSize.isAccessibilitySize {
                            P8CompactSettleButton(person: person, code: store.code, action: actions.settleAll)
                        }
                        ForEach(person.openShares) { share in
                            RistrettoRow(share: share, code: store.code) { actions.markPaid(share) }
                            Divider()
                        }
                        HStack {
                            Text("Total")
                            Spacer(minLength: 8)
                            Text(person.owed, format: .currency(code: store.code))
                                .monospacedDigit()
                        }
                        .font(.headline)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

private struct RistrettoRow: View {
    let share: PPShare
    let code: String
    let markPaid: () -> Void

    var body: some View {
        P5Row {
            P8InfoAndAmount {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: share.ticket)
                        .font(.body.weight(.semibold))
                    Group {
                        if share.paid > 0 {
                            Text("\(share.date, format: .dateTime.day().month()) · \(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid")
                        } else {
                            Text(share.date, format: .dateTime.weekday().day().month())
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .accessibilityValue(share.statusText(code: code))
            } amount: {
                Text(share.remaining, format: .currency(code: code))
                    .font(.headline)
                    .monospacedDigit()
            }
        } controls: {
            GenmaichaCheck(title: Text("Mark \(share.ticket) as paid"), action: markPaid)
                .controlSize(.small)
        }
    }
}

#Preview("Ristretto") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { RistrettoPerson(store: $0, id: $1) }
}

#Preview("Ristretto · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { RistrettoPerson(store: $0, id: $1) }
}

#Preview("Ristretto · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { RistrettoPerson(store: $0, id: $1) }
}

#Preview("Ristretto · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { RistrettoPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
