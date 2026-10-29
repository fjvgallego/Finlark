//
//  PrismHome.swift
//  Finlark
//
//  FIN-9 Round 2 "Prism": the most direct combination of Round 1 favorites. Glass bento tiles (balance
//  across the top, plan and owed side by side), a month slider that pages from the figures to the chart,
//  a compact title and a floating glass add button.
//

#if DEBUG
import SwiftUI

struct PrismHomeView: View {
    private enum MonthPage: Identifiable, CaseIterable {
        case figures
        case chart

        var id: Self { self }
    }

    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 150

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: r2GlassBlendSpacing) {
                    VStack(spacing: r2TileSpacing) {
                        bento
                            .padding(.horizontal)
                        R2Slider(MonthPage.allCases) { page in
                            monthPage(page)
                        }
                        Group {
                            if !model.pendingItems.isEmpty {
                                pendingTile
                            }
                            recentTile
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .background(R2Backdrop())
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .r2FloatingAddButton { model.addingType = .expense }
            .r2CompactTitle()
            .explorationScaffold(model)
        }
    }

    // MARK: Bento

    @ViewBuilder
    private var bento: some View {
        let showsOwed = snapshot.owedToYou > 0
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: r2TileSpacing) {
                balanceTile
                planTile
                if showsOwed { owedTile }
            }
        } else {
            Grid(horizontalSpacing: r2TileSpacing, verticalSpacing: r2TileSpacing) {
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
            }
        }
    }

    private var balanceTile: some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 4) {
                R2TileHeader(title: "Balance", symbol: "wallet.bifold.fill")
                Text(snapshot.balance, format: .currency(code: code))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text("\(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always())) this month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var planTile: some View {
        NavigationLink(value: ExplorationDestination.plan) {
            R2Tile {
                VStack(alignment: .leading, spacing: 8) {
                    R2TileHeader(title: "Plan", symbol: "chart.bar.doc.horizontal.fill") { R2Chevron() }
                    if let plan = snapshot.plan {
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
                    } else {
                        Text("Set up a Monthly Plan")
                            .font(.headline)
                    }
                }
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }

    private var owedTile: some View {
        NavigationLink(value: ExplorationDestination.people) {
            R2Tile {
                VStack(alignment: .leading, spacing: 8) {
                    R2TileHeader(title: "Owed to you", symbol: "person.2.fill") { R2Chevron() }
                    Text(snapshot.owedToYou, format: .currency(code: code))
                        .font(.title3.weight(.bold))
                        .monospacedDigit()
                    Text("\(snapshot.owedPeopleCount) people")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Month slider

    @ViewBuilder
    private func monthPage(_ page: MonthPage) -> some View {
        switch page {
        case .figures:
            R2Tile {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "This month", symbol: "calendar")
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top) { monthFigures }
                        VStack(alignment: .leading, spacing: 10) { monthFigures }
                    }
                    Text("Swipe for spending by category")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        case .chart:
            R2Tile {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Spending by category", symbol: "chart.bar.fill")
                    ExplorationSpendingBars(spending: snapshot.spendingByCategory, currencyCode: code)
                        .frame(height: chartHeight)
                }
            }
        }
    }

    @ViewBuilder
    private var monthFigures: some View {
        R2Figure(title: "Income", value: snapshot.monthIncome, code: code)
        Spacer(minLength: 8)
        R2Figure(title: "Spending", value: snapshot.monthSpending, code: code)
        Spacer(minLength: 8)
        R2Figure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true)
    }

    // MARK: Lists

    private var pendingTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 14) {
                R2TileHeader(title: "Pending", symbol: "clock.arrow.2.circlepath")
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

    private var recentTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 14) {
                R2TileHeader(title: "Recent", symbol: "clock.fill") {
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

#Preview("R2 Prism") {
    PrismHomeView()
}
#endif
