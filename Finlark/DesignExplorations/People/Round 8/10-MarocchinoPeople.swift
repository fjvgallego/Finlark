//
//  10-MarocchinoPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Marocchino": each share sits in its own soft inset inside the tile, no
//  dividers, and Settle All is the last of them: an "All open shares" row with the same check, set apart
//  by a light blue tint. One control to learn for one share or all of them.
//

#if DEBUG
import SwiftUI

struct MarocchinoPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if !person.openShares.isEmpty {
                R2Tile(padding: 14) {
                    VStack(alignment: .leading, spacing: 8) {
                        R2TileHeader(title: "Open shares", symbol: "clock.fill")
                            .padding(.horizontal, 4)
                            .padding(.bottom, 2)
                        ForEach(person.openShares) { share in
                            MarocchinoInset {
                                P5Row {
                                    VStack(alignment: .leading, spacing: 3) {
                                        P5ShareTitle(share: share, code: store.code)
                                        Text("\(share.remaining, format: .currency(code: store.code)) left")
                                            .font(.headline)
                                            .monospacedDigit()
                                            .padding(.top, 2)
                                    }
                                } controls: {
                                    GenmaichaCheck(title: Text("Mark \(share.ticket) as paid")) { actions.markPaid(share) }
                                }
                            }
                        }
                        if person.showsSettleAll {
                            MarocchinoInset(isHighlighted: true) {
                                P5Row {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("All open shares")
                                            .font(.headline)
                                        Text("\(person.owed, format: .currency(code: store.code)) in total")
                                            .font(.headline)
                                            .monospacedDigit()
                                            .padding(.top, 2)
                                    }
                                    .accessibilityHidden(true)
                                } controls: {
                                    GenmaichaCheck(title: Text("Settle all, \(person.owed.formatted(.currency(code: store.code)))"), action: actions.settleAll)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

/// A share's inset: a soft fill, or a light accent tint for the row that settles everything. The text
/// on it stays in the label color, so it keeps its contrast.
private struct MarocchinoInset<Content: View>: View {
    var isHighlighted = false
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isHighlighted ? AnyShapeStyle(Color.accentColor.opacity(0.14)) : AnyShapeStyle(.fill.quaternary))
            }
    }
}

#Preview("Marocchino") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { MarocchinoPerson(store: $0, id: $1) }
}

#Preview("Marocchino · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { MarocchinoPerson(store: $0, id: $1) }
}

#Preview("Marocchino · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { MarocchinoPerson(store: $0, id: $1) }
}

#Preview("Marocchino · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { MarocchinoPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
