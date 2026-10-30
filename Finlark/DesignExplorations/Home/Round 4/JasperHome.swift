//
//  JasperHome.swift
//  Finlark
//
//  FIN-9 Round 4 "Jasper": an inset-list feel. Section titles sit above the tiles, and inside them
//  each value is its own labeled row with dividers, like Settings. Quick to scan top to bottom, and
//  every number has a name next to it.
//

#if DEBUG
import SwiftUI

struct JasperHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Balance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(snapshot.balance, format: .currency(code: code))
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                }
                .padding(.horizontal)

                R3SectionHeader(title: "\(Text(Date.now, format: .dateTime.month(.wide)))")
                JasperRows {
                    JasperRow("Income") { Text(snapshot.monthIncome, format: .currency(code: code)) }
                    JasperRow("Spending") { Text(snapshot.monthSpending, format: .currency(code: code)) }
                    JasperRow("Difference") {
                        Text(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))
                            .fontWeight(.semibold)
                    }
                    R4SpendingStrip(snapshot: snapshot)
                        .padding(.vertical, 4)
                }

                R3SectionHeader(title: "Monthly Plan") {
                    R2Link(destination: .plan) { Text("Open") }
                        .font(.subheadline.weight(.semibold))
                }
                planRows

                if snapshot.owedToYou > 0 {
                    R3SectionHeader(title: "People")
                    R2Link(destination: .people) {
                        JasperRows {
                            JasperRow("Owed to you") {
                                HStack(spacing: 8) {
                                    Text(snapshot.owedToYou, format: .currency(code: code))
                                    R2Chevron()
                                }
                            }
                            JasperRow("People who owe you") { Text(snapshot.owedPeopleCount, format: .number) }
                        }
                    }
                    .buttonStyle(.plain)
                }

                R4PendingList(model: model)
                R4RecentList(snapshot: snapshot)
            }
        }
    }

    @ViewBuilder
    private var planRows: some View {
        if let plan = snapshot.plan {
            JasperRows {
                JasperRow("Status") { ExplorationStatusLabel(status: plan.status).fontWeight(.semibold) }
                ExplorationPlanBar(
                    spent: plan.totalSpent,
                    projected: plan.totalProjected,
                    planned: plan.totalPlanned,
                    tint: plan.status.tint
                )
                .padding(.vertical, 6)
                JasperRow("Spent") { Text(plan.totalSpent, format: .currency(code: code)) }
                JasperRow("Projected") { Text(plan.totalProjected, format: .currency(code: code)) }
                JasperRow("Planned") { Text(plan.totalPlanned, format: .currency(code: code)) }
                JasperRow(plan.totalSpent > plan.totalPlanned ? "Over" : "Left") {
                    Text(abs(plan.totalRemaining), format: .currency(code: code))
                }
                JasperRow("Days to go") { Text(snapshot.r3DaysLeft, format: .number) }
            }
        } else {
            R2Link(destination: .plan) {
                JasperRows {
                    JasperRow("Monthly Plan") {
                        HStack(spacing: 8) {
                            Text("Set up")
                            R2Chevron()
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

/// A tile of rows separated by dividers.
private struct JasperRows<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Group(subviews: content) { rows in
                    ForEach(rows) { row in
                        row
                            .padding(.vertical, 10)
                        if row.id != rows.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

private struct JasperRow<Value: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let value: Value

    init(_ title: LocalizedStringKey, @ViewBuilder value: () -> Value) {
        self.title = title
        self.value = value()
    }

    var body: some View {
        LabeledContent {
            value
                .foregroundStyle(.primary)
                .monospacedDigit()
        } label: {
            Text(title)
        }
    }
}

#Preview("R4 Jasper") {
    JasperHomeView()
}
#endif
