//
//  CinderHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Cinder": an "Add" button in the navigation bar that always asks Expense or Income.
//  The plan and the spending chart become one tile: a bullet bar per planned category (spent,
//  projected and planned) with its figures and status written above it, plus the unplanned total.
//

#if DEBUG
import SwiftUI

struct CinderHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarChoice) {
            R3HomeScroll(model: model) {
                Group {
                    R3SummaryTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                    planTile
                }
                .padding(.horizontal)
                R3PendingSection(model: model)
                R3RecentSection(snapshot: snapshot)
            }
        }
    }

    @ViewBuilder
    private var planTile: some View {
        if let plan = snapshot.plan {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 16) {
                    R2TileHeader(title: "Plan by category", symbol: "chart.bar.doc.horizontal.fill") {
                        R2Link(destination: .plan) { Text("Open") }
                            .font(.subheadline.weight(.semibold))
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(plan.totalSpent, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code))")
                                .font(.title3.weight(.semibold))
                            Spacer(minLength: 8)
                            ExplorationStatusLabel(status: plan.status)
                                .font(.subheadline.weight(.semibold))
                        }
                        HStack {
                            Text("Projected \(plan.totalProjected, format: .currency(code: code))")
                            Spacer(minLength: 8)
                            Text("\(snapshot.r3DaysLeft) days to go")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    .monospacedDigit()
                    .accessibilityElement(children: .combine)

                    ForEach(plan.categories) { category in
                        R3PlanBulletRow(plan: category, code: code)
                    }
                    if plan.unplannedSpent > 0 {
                        Divider()
                        HStack {
                            Label("Unplanned", systemImage: "questionmark.circle")
                            Spacer(minLength: 8)
                            Text(plan.unplannedSpent, format: .currency(code: code))
                                .monospacedDigit()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        } else {
            R3PlanFiguresTile(snapshot: snapshot)
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    R2TileHeader(title: "Spending by category", symbol: "chart.bar.fill")
                    R3LabeledBars(spending: snapshot.r3TopSpending(limit: 4), code: code)
                }
            }
        }
    }
}

#Preview("R3 Cinder") {
    CinderHomeView()
}
#endif
