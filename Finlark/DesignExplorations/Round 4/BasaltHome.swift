//
//  BasaltHome.swift
//  Finlark
//
//  FIN-9 Round 4 "Basalt": the balance gets its own tile, and "This month" compares income and
//  spending as two bars on the same scale. The spending bar is split by category, so the gap to income
//  and where the money went read at a glance. The plan lists what needs attention, and pending and
//  recent items are plain lists instead of sliders.
//

#if DEBUG
import SwiftUI
import Charts

struct BasaltHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                Group {
                    balanceTile
                    monthTile
                    R3PlanAttentionTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                }
                .padding(.horizontal)
                R4PendingList(model: model)
                R4RecentList(snapshot: snapshot)
            }
        }
    }

    private var balanceTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 4) {
                R2TileHeader(title: "Balance", symbol: "wallet.bifold.fill")
                Text(snapshot.balance, format: .currency(code: code))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var monthTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                R2TileHeader(title: "This month", symbol: "calendar") {
                    Text(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .accessibilityLabel(Text("Difference \(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))"))
                }
                BasaltComparisonChart(snapshot: snapshot)
                R4SpendingStrip(snapshot: snapshot)
            }
        }
    }
}

/// Income and spending on one scale. The spending bar is split by category (HOM-002).
private struct BasaltComparisonChart: View {
    let snapshot: ExplorationHomeSnapshot

    @ScaledMetric(relativeTo: .subheadline) private var rowHeight: CGFloat = 40

    private var code: String { snapshot.currencyCode }

    var body: some View {
        let top = snapshot.r3TopSpending(limit: 3)

        Chart {
            BarMark(x: .value("Amount", snapshot.monthIncome.plotValue), y: .value("Row", "income"))
                .foregroundStyle(Color.secondary.opacity(0.35))
                .cornerRadius(5)
            ForEach(top) { item in
                BarMark(x: .value("Amount", item.amount.plotValue), y: .value("Row", "spending"))
                    .foregroundStyle(item.category.color)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    if value.as(String.self) == "income" {
                        figure("Income", snapshot.monthIncome)
                    } else {
                        figure("Spending", snapshot.monthSpending)
                    }
                }
            }
        }
        .frame(height: rowHeight * 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Income \(snapshot.monthIncome, format: .currency(code: code)), spending \(snapshot.monthSpending, format: .currency(code: code))"))
    }

    private func figure(_ title: LocalizedStringKey, _ value: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.caption)
            Text(value, format: .currency(code: code))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
    }
}

#Preview("R4 Basalt") {
    BasaltHomeView()
}
#endif
