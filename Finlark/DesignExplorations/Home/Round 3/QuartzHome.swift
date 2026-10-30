//
//  QuartzHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Quartz": two text buttons in the navigation bar, "Income" and a prominent
//  "Expense", so both are one tap away. The balance tile ends with one bar split by category and a
//  legend with amounts and shares. The plan tile lists the categories that need attention.
//

#if DEBUG
import SwiftUI

struct QuartzHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarPair) {
            R3HomeScroll(model: model) {
                Group {
                    R3SummaryTile(snapshot: snapshot) {
                        Divider()
                        Text("Where it went")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .accessibilityAddTraits(.isHeader)
                        R3StackedSpending(spending: snapshot.r3TopSpending(limit: 4), code: snapshot.currencyCode)
                    }
                    R3PlanAttentionTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                }
                .padding(.horizontal)
                R3PendingSection(model: model)
                R3RecentSection(snapshot: snapshot)
            }
        }
    }
}

#Preview("R3 Quartz") {
    QuartzHomeView()
}
#endif
