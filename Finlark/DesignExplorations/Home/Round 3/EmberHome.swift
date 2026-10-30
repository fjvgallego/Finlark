//
//  EmberHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Ember": quick add is a "+" in the navigation bar (tap for an expense, hold for
//  income). Below the balance, the plan gets its own full-width tile with labeled figures, and
//  spending is a bar chart that names each category and its amount.
//

#if DEBUG
import SwiftUI

struct EmberHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                Group {
                    R3SummaryTile(snapshot: snapshot)
                    R3PlanFiguresTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            R2TileHeader(title: "Spending by category", symbol: "chart.bar.fill")
                            R3LabeledBars(spending: snapshot.r3TopSpending(limit: 4), code: snapshot.currencyCode)
                        }
                    }
                }
                .padding(.horizontal)
                R3PendingSection(model: model)
                R3RecentSection(snapshot: snapshot)
            }
        }
    }
}

#Preview("R3 Ember") {
    EmberHomeView()
}
#endif
