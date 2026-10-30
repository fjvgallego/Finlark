//
//  OpalHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Opal": quick add stays in the bar above the tab bar, now with Expense and Income at
//  equal weight. Facet's bento is kept, but the plan spans the full width and lists what needs
//  attention, and spending is one bar split by category with a legend.
//

#if DEBUG
import SwiftUI

struct OpalHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }

    var body: some View {
        R3TabShell(model: model, quickAdd: .accessoryEqual) {
            R3HomeScroll(model: model) {
                Group {
                    R3SummaryTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                    R3PlanAttentionTile(snapshot: snapshot)
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            R2TileHeader(title: "Spending by category", symbol: "chart.bar.fill")
                            R3StackedSpending(spending: snapshot.r3TopSpending(limit: 4), code: snapshot.currencyCode)
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

#Preview("R3 Opal") {
    OpalHomeView()
}
#endif
