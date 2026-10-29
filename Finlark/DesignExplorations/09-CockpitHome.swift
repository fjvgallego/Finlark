//
//  09-CockpitHome.swift
//  Finlark
//
//  FIN-9 exploration 09 "Cockpit": data-dense. A stat strip, per-category plan rows with mini bars,
//  a compact category chart and a tight recent-transactions table. Everything fits in about two screens.
//

#if DEBUG
import SwiftUI
import Charts

struct CockpitHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 110

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    statStrip
                    planPanel
                    chartPanel
                    if !model.pendingItems.isEmpty {
                        pendingPanel
                    }
                    recentPanel
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Add expense", systemImage: "minus.circle") { model.addingType = .expense }
                        Button("Add income", systemImage: "plus.circle") { model.addingType = .income }
                    } label: {
                        Label("Add transaction", systemImage: "plus")
                    } primaryAction: {
                        model.addingType = .expense
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .explorationScaffold(model)
        }
    }

    // MARK: Stat strip

    private var statStrip: some View {
        let columns = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns), spacing: 8) {
            CockpitStat(title: "Balance", value: snapshot.balance, code: code)
            CockpitStat(title: "Income", value: snapshot.monthIncome, code: code)
            CockpitStat(title: "Spending", value: snapshot.monthSpending, code: code)
            CockpitStat(title: "Difference", value: snapshot.monthDifference, code: code, signed: true)
            if snapshot.owedToYou > 0 {
                NavigationLink(value: ExplorationDestination.people) {
                    CockpitStat(
                        title: "Owed to you",
                        value: snapshot.owedToYou,
                        code: code,
                        footnote: "\(snapshot.owedPeopleCount) people",
                        showsChevron: true
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Plan

    private var planPanel: some View {
        NavigationLink(value: ExplorationDestination.plan) {
            CockpitPanel(title: "Plan", trailing: snapshot.plan.map { AnyView(ExplorationStatusLabel(status: $0.status)) }) {
                if let plan = snapshot.plan {
                    VStack(spacing: 10) {
                        HStack {
                            Text("\(plan.totalSpent, format: .currency(code: code)) / \(plan.totalPlanned, format: .currency(code: code))")
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: 8)
                            Text("Proj. \(plan.totalProjected, format: .currency(code: code))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        ForEach(plan.categories) { category in
                            CockpitPlanRow(plan: category, code: code)
                        }
                        if plan.unplannedSpent > 0 {
                            HStack {
                                Text("Unplanned")
                                Spacer(minLength: 8)
                                Text(plan.unplannedSpent, format: .currency(code: code))
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .monospacedDigit()
                } else {
                    Label("No plan yet. Tap to set one.", systemImage: "plus.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Chart

    private var chartPanel: some View {
        CockpitPanel(title: "By category") {
            Chart(snapshot.spendingByCategory) { item in
                BarMark(
                    x: .value("Category", item.category.id),
                    y: .value("Amount", item.amount.plotValue)
                )
                .foregroundStyle(item.category.color)
                .cornerRadius(3)
                .accessibilityLabel(Text(item.category.name))
                .accessibilityValue(Text(item.amount, format: .currency(code: code)))
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount, format: .currency(code: code).precision(.fractionLength(0)))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let id = value.as(String.self),
                           let item = snapshot.spendingByCategory.first(where: { $0.id == id }) {
                            Image(systemName: item.category.symbol)
                                .accessibilityLabel(Text(item.category.name))
                        }
                    }
                }
            }
            .frame(height: chartHeight)
        }
    }

    // MARK: Pending

    private var pendingPanel: some View {
        CockpitPanel(title: "Pending") {
            VStack(spacing: 8) {
                ForEach(model.pendingItems) { item in
                    HStack(spacing: 10) {
                        Image(systemName: item.category.symbol)
                            .foregroundStyle(item.category.color)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(item.note)
                                .font(.subheadline)
                            ExplorationDueText(date: item.dueDate)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(item.type == .expense ? -item.amount : item.amount,
                             format: .currency(code: code).sign(strategy: .always()))
                            .font(.subheadline.monospacedDigit())
                        Button("Skip", systemImage: "xmark") { model.skip(item) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.bordered)
                            .buttonBorderShape(.circle)
                            .accessibilityLabel(Text("Skip \(item.note)"))
                        Button("Confirm", systemImage: "checkmark") { model.confirm(item) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.circle)
                            .accessibilityLabel(Text("Confirm \(item.note)"))
                    }
                    .controlSize(.small)
                }
            }
        }
    }

    // MARK: Recent

    private var recentPanel: some View {
        CockpitPanel(title: "Recent") {
            VStack(spacing: 0) {
                ForEach(snapshot.recentTransactions) { transaction in
                    CockpitTransactionRow(transaction: transaction, code: code)
                    Divider()
                }
                NavigationLink(value: ExplorationDestination.history) {
                    HStack {
                        Text("All transactions")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.top, 10)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CockpitStat: View {
    let title: LocalizedStringKey
    let value: Decimal
    let code: String
    var signed = false
    var footnote: LocalizedStringKey?
    var showsChevron = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if showsChevron {
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
            }
            Text(value, format: .currency(code: code).sign(strategy: signed ? .always() : .automatic))
                .font(.headline.monospacedDigit())
            if let footnote {
                Text(footnote)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}

private struct CockpitPanel<Content: View>: View {
    let title: LocalizedStringKey
    var trailing: AnyView?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                trailing?
                    .font(.footnote.weight(.semibold))
            }
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
    }
}

private struct CockpitPlanRow: View {
    let plan: ExplorationCategoryPlan
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: plan.category.symbol)
                    .foregroundStyle(plan.category.color)
                    .frame(minWidth: 20)
                    .accessibilityHidden(true)
                Text(plan.category.name)
                Spacer(minLength: 8)
                Text("\(plan.spent, format: .currency(code: code)) / \(plan.planned, format: .currency(code: code))")
                    .foregroundStyle(.secondary)
                Image(systemName: plan.status.symbol)
                    .foregroundStyle(plan.status.tint)
                    .accessibilityLabel(Text(plan.status.title))
            }
            .font(.caption)
            ExplorationPlanBar(spent: plan.spent, projected: plan.projected, planned: plan.planned, tint: plan.status.tint)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct CockpitTransactionRow: View {
    let transaction: ExplorationTransaction
    let code: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(transaction.date, format: .dateTime.day().month(.abbreviated))
                .foregroundStyle(.secondary)
                .frame(minWidth: 44, alignment: .leading)
            Image(systemName: transaction.category.symbol)
                .foregroundStyle(transaction.category.color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(transaction.note ?? String(localized: transaction.category.name))
                    .lineLimit(2)
                if let share = transaction.myShare {
                    Label("Split · mine \(share, format: .currency(code: code))", systemImage: "person.2.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            Text(transaction.signedAmount, format: .currency(code: code).sign(strategy: .always()))
                .monospacedDigit()
        }
        .font(.subheadline)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

#Preview("09 Cockpit") {
    CockpitHomeView()
}
#endif
