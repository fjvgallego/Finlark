//
//  05-DoppioPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Doppio": the open shares as a two-column grid of bento tiles, each with a
//  full-width Paid button. Settle All is a wide total tile under the grid. At accessibility sizes the
//  grid becomes one column.
//

#if DEBUG
import SwiftUI

struct DoppioPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if !person.openShares.isEmpty {
                let columns = dynamicTypeSize.isAccessibilitySize ? 1 : 2
                let rows = stride(from: 0, to: person.openShares.count, by: columns).map {
                    Array(person.openShares[$0..<min($0 + columns, person.openShares.count)])
                }

                VStack(spacing: r2TileSpacing) {
                    P8SectionTitle("Open shares")
                    Grid(horizontalSpacing: r2TileSpacing, verticalSpacing: r2TileSpacing) {
                        ForEach(rows, id: \.first?.id) { row in
                            GridRow {
                                ForEach(row) { share in
                                    DoppioTile(share: share, code: store.code) { actions.markPaid(share) }
                                }
                                if row.count < columns {
                                    Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                                }
                            }
                        }
                    }
                    if person.showsSettleAll {
                        DoppioTotalTile(person: person, code: store.code, action: actions.settleAll)
                    }
                }
            }
        }
    }
}

private struct DoppioTile: View {
    let share: PPShare
    let code: String
    let markPaid: () -> Void

    var body: some View {
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                ExplorationCategoryIcon(category: share.category)
                P5ShareTitle(share: share, code: code, showsPaid: false)
                Spacer(minLength: 0)
                VStack(alignment: .leading, spacing: 2) {
                    Text(share.remaining, format: .currency(code: code))
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                    Group {
                        if share.paid > 0 {
                            Text("\(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid")
                        } else {
                            Text("left")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .monospacedDigit()
                Button(action: markPaid) {
                    Label("Paid", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .accessibilityLabel(Text("Mark \(share.ticket) as paid"))
            }
        }
    }
}

/// The total open, with Settle All beside it, or under it at accessibility sizes.
private struct DoppioTotalTile: View {
    let person: PPPerson
    let code: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        R2Tile(padding: 16) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
                : AnyLayout(HStackLayout(spacing: 12))
            layout {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total open")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(person.owed, format: .currency(code: code))
                        .font(.title2.weight(.bold))
                        .fontDesign(.rounded)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: 8)
                }
                P8CompactSettleButton(person: person, code: code, controlSize: .large, action: action)
            }
        }
    }
}

#Preview("Doppio") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { DoppioPerson(store: $0, id: $1) }
}

#Preview("Doppio · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { DoppioPerson(store: $0, id: $1) }
}

#Preview("Doppio · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { DoppioPerson(store: $0, id: $1) }
}

#Preview("Doppio · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { DoppioPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
