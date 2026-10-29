//
//  06-PaceHome.swift
//  Finlark
//
//  FIN-9 exploration 06 "Pace": plan-centric. The hero is cumulative spending against the plan line,
//  with a "today" rule and a dashed projection to month end (PLN-003). The balance comes second.
//

#if DEBUG
import SwiftUI
import Charts

struct PaceHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var paceChartHeight: CGFloat = 220
    @ScaledMetric(relativeTo: .caption) private var categoryChartHeight: CGFloat = 170

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }
    /// A-09: the pace part is hidden during the first 3 days of the month.
    private var showsPace: Bool { snapshot.dayOfMonth > 3 }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    paceHero
                }
                Section {
                    balanceAndMonth
                    ExplorationSpendingBars(spending: snapshot.spendingByCategory, currencyCode: code)
                        .frame(height: categoryChartHeight)
                        .padding(.vertical, 6)
                } header: {
                    Text(Date.now, format: .dateTime.month(.wide))
                }
                if !model.pendingItems.isEmpty {
                    Section("Due soon") {
                        ForEach(model.pendingItems) { item in
                            ExplorationPendingRow(
                                item: item,
                                currencyCode: code,
                                onConfirm: { model.confirm(item) },
                                onSkip: { model.skip(item) }
                            )
                            .padding(.vertical, 4)
                        }
                    }
                }
                if snapshot.owedToYou > 0 {
                    Section {
                        NavigationLink(value: ExplorationDestination.people) {
                            LabeledContent {
                                Text(snapshot.owedToYou, format: .currency(code: code))
                                    .monospacedDigit()
                            } label: {
                                Label {
                                    Text("Owed to you")
                                    Text("\(snapshot.owedPeopleCount) people")
                                } icon: {
                                    Image(systemName: "person.2.fill")
                                }
                            }
                        }
                    }
                }
                Section("Recent") {
                    ForEach(snapshot.recentTransactions) { transaction in
                        ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                    }
                    NavigationLink("See all in History", value: ExplorationDestination.history)
                }
            }
            .listSectionSpacing(.compact)
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add transaction", systemImage: "plus") {
                        model.addingType = .expense
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .explorationScaffold(model)
        }
    }

    // MARK: Hero

    @ViewBuilder
    private var paceHero: some View {
        if let plan = snapshot.plan {
            NavigationLink(value: ExplorationDestination.plan) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        ExplorationStatusLabel(status: plan.status)
                            .font(.headline)
                        Text(heroSentence(plan))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)

                    paceChart(plan)
                        .frame(height: paceChartHeight)

                    legend
                }
                .padding(.vertical, 6)
            }
        } else {
            NavigationLink(value: ExplorationDestination.plan) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Set a Monthly Plan", systemImage: "chart.line.uptrend.xyaxis")
                        .font(.headline)
                    Text("See whether you'll stay within it before the month ends.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func heroSentence(_ plan: ExplorationPlanSummary) -> LocalizedStringKey {
        if showsPace {
            "\(plan.totalSpent, format: .currency(code: code)) spent · heading for \(plan.totalProjected, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code))"
        } else {
            "\(plan.totalSpent, format: .currency(code: code)) spent of \(plan.totalPlanned, format: .currency(code: code))"
        }
    }

    private func paceChart(_ plan: ExplorationPlanSummary) -> some View {
        let today = snapshot.dayOfMonth
        let spentToday = snapshot.dailySpending.last?.cumulative ?? 0

        return Chart {
            ForEach(snapshot.dailySpending) { point in
                AreaMark(
                    x: .value("Day", point.day),
                    y: .value("Spent", point.cumulative.plotValue)
                )
                .foregroundStyle(Color.accentColor.opacity(0.15))
                .interpolationMethod(.stepEnd)

                LineMark(
                    x: .value("Day", point.day),
                    y: .value("Spent", point.cumulative.plotValue),
                    series: .value("Series", "spent")
                )
                .foregroundStyle(Color.accentColor)
                .interpolationMethod(.stepEnd)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .accessibilityLabel(Text("Day \(point.day)"))
                .accessibilityValue(Text(point.cumulative, format: .currency(code: code)))
            }

            if showsPace {
                ForEach([(today, spentToday), (snapshot.daysInMonth, plan.totalProjected)], id: \.0) { day, value in
                    LineMark(
                        x: .value("Day", day),
                        y: .value("Spent", value.plotValue),
                        series: .value("Series", "projected")
                    )
                    .foregroundStyle(plan.status.tint)
                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    .accessibilityLabel(Text("Projected, day \(day)"))
                    .accessibilityValue(Text(value, format: .currency(code: code)))
                }
            }

            RuleMark(y: .value("Planned", plan.totalPlanned.plotValue))
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                .annotation(position: .top, alignment: .leading) {
                    Text("Plan \(plan.totalPlanned, format: .currency(code: code))")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(Text("Planned"))
                .accessibilityValue(Text(plan.totalPlanned, format: .currency(code: code)))

            RuleMark(x: .value("Day", today))
                .foregroundStyle(.tertiary)
                .annotation(position: .bottom) {
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityHidden(true)
        }
        .chartXScale(domain: 1...snapshot.daysInMonth)
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(amount, format: .currency(code: code).precision(.fractionLength(0)))
                    }
                }
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            Label {
                Text("Spent")
            } icon: {
                Capsule().fill(Color.accentColor).frame(width: 14, height: 3)
            }
            if showsPace {
                Label {
                    Text("Projected")
                } icon: {
                    Capsule().stroke(style: StrokeStyle(lineWidth: 2, dash: [3, 2])).frame(width: 14, height: 2)
                }
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityHidden(true)
    }

    // MARK: Balance and month

    private var balanceAndMonth: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Balance") {
                Text(snapshot.balance, format: .currency(code: code))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            LabeledContent("Income") {
                Text(snapshot.monthIncome, format: .currency(code: code))
            }
            LabeledContent("Spending") {
                Text(snapshot.monthSpending, format: .currency(code: code))
            }
            LabeledContent("Difference") {
                Text(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))
            }
        }
        .monospacedDigit()
    }
}

#Preview("06 Pace") {
    PaceHomeView()
}
#endif
