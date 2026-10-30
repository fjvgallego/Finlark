//
//  GarnetHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Garnet": keeps Round 2's quick add ("Add expense" first, with an Income shortcut,
//  in the bar above the tab bar) so only the information changes. The donut becomes labeled bars
//  inside the balance tile, and the plan shows a bullet bar for the three categories closest to
//  their limit.
//

#if DEBUG
import SwiftUI

struct GarnetHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        R3TabShell(model: model, quickAdd: .accessoryExpenseFirst) {
            R3HomeScroll(model: model) {
                Group {
                    R3SummaryTile(snapshot: snapshot) {
                        Divider()
                        R3LabeledBars(spending: snapshot.r3TopSpending(limit: 4), code: code)
                    }
                    planTile
                    R3OwedRow(snapshot: snapshot)
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
            R2Link(destination: .plan) {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 16) {
                        R2TileHeader(title: "Monthly Plan", symbol: "chart.bar.doc.horizontal.fill") { R2Chevron() }
                        HStack(alignment: .firstTextBaseline) {
                            ExplorationStatusLabel(status: plan.status)
                                .font(.title3.weight(.semibold))
                            Spacer(minLength: 8)
                            R3RemainingText(planned: plan.totalPlanned, spent: plan.totalSpent, code: code)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                        ForEach(closestToLimit(plan)) { category in
                            R3PlanBulletRow(plan: category, code: code)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        } else {
            R3PlanFiguresTile(snapshot: snapshot)
        }
    }

    /// The three categories with the highest projection relative to their plan.
    private func closestToLimit(_ plan: ExplorationPlanSummary) -> [ExplorationCategoryPlan] {
        let ranked = plan.categories.sorted { lhs, rhs in
            lhs.projected * rhs.planned > rhs.projected * lhs.planned
        }
        return Array(ranked.prefix(3))
    }
}

#Preview("R3 Garnet") {
    GarnetHomeView()
}
#endif
