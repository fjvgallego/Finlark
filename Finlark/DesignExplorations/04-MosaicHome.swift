//
//  04-MosaicHome.swift
//  Finlark
//
//  FIN-9 exploration 04 "Mosaic": bento tiles of mixed sizes on a two-column grid.
//  Collapses to a single column at accessibility Dynamic Type sizes.
//

#if DEBUG
import SwiftUI

struct MosaicHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var chartSize: CGFloat = 150

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }
    private var showsOwed: Bool { snapshot.owedToYou > 0 }

    var body: some View {
        NavigationStack {
            ScrollView {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        VStack(spacing: 12) {
                            balanceTile
                            planTile
                            if showsOwed { owedTile }
                            monthTile
                            pendingTile
                            recentTile
                        }
                    } else {
                        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                            GridRow {
                                balanceTile.gridCellColumns(2)
                            }
                            GridRow {
                                if showsOwed {
                                    planTile
                                    owedTile
                                } else {
                                    planTile.gridCellColumns(2)
                                }
                            }
                            GridRow {
                                monthTile.gridCellColumns(2)
                            }
                            GridRow {
                                pendingTile.gridCellColumns(2)
                            }
                            GridRow {
                                recentTile.gridCellColumns(2)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
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

    private var balanceTile: some View {
        MosaicTile(tint: .indigo) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Balance", systemImage: "wallet.bifold.fill")
                    .font(.subheadline.weight(.semibold))
                Text(snapshot.balance, format: .currency(code: code))
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .monospacedDigit()
            }
            .foregroundStyle(.white)
            .accessibilityElement(children: .combine)
        }
    }

    private var planTile: some View {
        NavigationLink(value: ExplorationDestination.plan) {
            MosaicTile {
                if let plan = snapshot.plan {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Plan")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(plan.totalSpent, format: .currency(code: code))
                            .font(.title3.weight(.bold))
                        Text("of \(plan.totalPlanned, format: .currency(code: code))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        ExplorationStatusLabel(status: plan.status)
                            .font(.caption.weight(.semibold))
                    }
                    .monospacedDigit()
                    .accessibilityElement(children: .combine)
                } else {
                    Label("Create a plan", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var owedTile: some View {
        NavigationLink(value: ExplorationDestination.people) {
            MosaicTile {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Owed to you")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(snapshot.owedToYou, format: .currency(code: code))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                    Spacer(minLength: 0)
                    Label("\(snapshot.owedPeopleCount) people", systemImage: "person.2.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }

    private var monthTile: some View {
        MosaicTile {
            VStack(alignment: .leading, spacing: 12) {
                Text(Date.now, format: .dateTime.month(.wide))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 16) {
                        monthFigures
                        Spacer(minLength: 0)
                        ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
                            .frame(width: chartSize, height: chartSize)
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        monthFigures
                        ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
                            .frame(width: chartSize, height: chartSize)
                    }
                }
            }
        }
    }

    private var monthFigures: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Income") {
                Text(snapshot.monthIncome, format: .currency(code: code))
            }
            LabeledContent("Spending") {
                Text(snapshot.monthSpending, format: .currency(code: code))
            }
            Divider()
            LabeledContent("Difference") {
                Text(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))
                    .fontWeight(.bold)
            }
        }
        .monospacedDigit()
        .fixedSize()
    }

    @ViewBuilder
    private var pendingTile: some View {
        if !model.pendingItems.isEmpty {
            MosaicTile {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Pending", systemImage: "clock.arrow.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(model.pendingItems) { item in
                        ExplorationPendingRow(
                            item: item,
                            currencyCode: code,
                            onConfirm: { model.confirm(item) },
                            onSkip: { model.skip(item) }
                        )
                    }
                }
            }
        }
    }

    private var recentTile: some View {
        MosaicTile {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    NavigationLink("History", value: ExplorationDestination.history)
                        .font(.subheadline.weight(.semibold))
                }
                ForEach(snapshot.recentTransactions) { transaction in
                    ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                }
            }
        }
    }
}

private struct MosaicTile<Content: View>: View {
    var tint: Color?
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background {
                if let tint {
                    RoundedRectangle(cornerRadius: 24).fill(tint.gradient)
                } else {
                    RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemGroupedBackground))
                }
            }
    }
}

#Preview("04 Mosaic") {
    MosaicHomeView()
}
#endif
