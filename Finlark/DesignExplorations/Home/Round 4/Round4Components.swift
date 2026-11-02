//
//  Round4Components.swift
//  Finlark
//
//  FIN-9 Round 4: pieces for the Ember variants. Ember's separate "Spending by category" tile is gone,
//  so HOM-002's chart shrinks into the month summary. The rest of Round 4 varies how each section
//  presents its information. Builds on the Round 2 and Round 3 components.
//

#if DEBUG
import SwiftUI
import Charts

/// Recent transactions (HOM-006) as a vertical list inside one tile, instead of cards.
struct R4RecentList: View {
    let snapshot: ExplorationHomeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: r2TileSpacing) {
            R3SectionHeader(title: "Recent") {
                R2Link(destination: .history) { Text("History") }
                    .font(.subheadline.weight(.semibold))
            }
            R2Tile(padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(snapshot.recentTransactions) { transaction in
                        ExplorationTransactionRow(transaction: transaction, currencyCode: snapshot.currencyCode)
                        if transaction.id != snapshot.recentTransactions.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
#endif
