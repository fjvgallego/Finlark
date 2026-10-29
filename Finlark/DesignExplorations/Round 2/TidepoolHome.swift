//
//  TidepoolHome.swift
//  Finlark
//
//  FIN-9 Round 2 "Tidepool": the sliders live inside the bento tiles. The month tile swipes through
//  income, spending and difference, and the plan tile swipes from the overall plan to each category.
//  The grid stays small, but each tile holds more.
//

#if DEBUG
import SwiftUI

struct TidepoolHomeView: View {
    private enum MonthFigure: Identifiable, CaseIterable {
        case income
        case spending
        case difference

        var id: Self { self }
    }

    private enum PlanPage: Identifiable {
        case overview(ExplorationPlanSummary)
        case category(ExplorationCategoryPlan)

        var id: String {
            switch self {
            case .overview: "overview"
            case .category(let plan): plan.id
            }
        }
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
        R2TabShell(model: model) {
            ScrollView {
                GlassEffectContainer(spacing: r2GlassBlendSpacing) {
                    VStack(spacing: r2TileSpacing) {
                        bento
                        if !model.pendingItems.isEmpty {
                            pendingTile
                        }
                        recentTile
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
            .background(R2Backdrop())
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .r2CompactTitle()
        }
    }

    // MARK: Bento

    @ViewBuilder
    private var bento: some View {
        let showsOwed = snapshot.owedToYou > 0
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: r2TileSpacing) {
                balanceTile
                monthTile
                if showsOwed { owedTile }
                planTile
                chartTile
            }
        } else {
            Grid(horizontalSpacing: r2TileSpacing, verticalSpacing: r2TileSpacing) {
                GridRow {
                    balanceTile.gridCellColumns(2)
                }
                GridRow {
                    if showsOwed {
                        monthTile
                        owedTile
                    } else {
                        monthTile.gridCellColumns(2)
                    }
                }
                GridRow {
                    planTile.gridCellColumns(2)
                }
                GridRow {
                    chartTile.gridCellColumns(2)
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
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var monthTile: some View {
        R2Tile(padding: 0) {
            VStack(alignment: .leading, spacing: 4) {
                R2TileHeader(title: "This month", symbol: "calendar")
                    .padding([.horizontal, .top], 14)
                R2Slider(MonthFigure.allCases, spacing: 0, margin: 14, indicatorOnGlass: false) { figure in
                    monthFigure(figure)
                }
                .padding(.bottom, 8)
            }
        }
    }

    @ViewBuilder
    private func monthFigure(_ figure: MonthFigure) -> some View {
        switch figure {
        case .income:
            R2Figure(title: "Income", value: snapshot.monthIncome, code: code, font: .title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
        case .spending:
            R2Figure(title: "Spending", value: snapshot.monthSpending, code: code, font: .title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
        case .difference:
            R2Figure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true,
                     font: .title3.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var owedTile: some View {
        NavigationLink(value: ExplorationDestination.people) {
            R2Tile(padding: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    R2TileHeader(title: "Owed to you", symbol: "person.2.fill") { R2Chevron() }
                    Spacer(minLength: 0)
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

    private var planTile: some View {
        R2Tile(padding: 0) {
            VStack(alignment: .leading, spacing: 8) {
                R2TileHeader(title: "Monthly Plan", symbol: "chart.bar.doc.horizontal.fill") {
                    NavigationLink("Open", value: ExplorationDestination.plan)
                        .font(.subheadline.weight(.semibold))
                }
                .padding([.horizontal, .top], 14)

                if let plan = snapshot.plan {
                    let pages = [PlanPage.overview(plan)] + plan.categories.map { PlanPage.category($0) }
                    R2Slider(pages, spacing: 0, margin: 14, indicatorOnGlass: false) { page in
                        planPage(page)
                    }
                    .padding(.bottom, 8)
                } else {
                    NavigationLink(value: ExplorationDestination.plan) {
                        Label("Set planned amounts for your categories", systemImage: "plus.circle")
                            .font(.headline)
                    }
                    .padding([.horizontal, .bottom], 14)
                }
            }
        }
    }

    @ViewBuilder
    private func planPage(_ page: PlanPage) -> some View {
        switch page {
        case .overview(let plan):
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text("All categories")
                        .font(.headline)
                    Spacer(minLength: 8)
                    ExplorationStatusLabel(status: plan.status)
                        .font(.subheadline.weight(.semibold))
                }
                ExplorationPlanBar(
                    spent: plan.totalSpent,
                    projected: plan.totalProjected,
                    planned: plan.totalPlanned,
                    tint: plan.status.tint
                )
                Text("\(plan.totalSpent, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code)) · projected \(plan.totalProjected, format: .currency(code: code))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        case .category(let plan):
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 10) {
                    ExplorationCategoryIcon(category: plan.category)
                    Text(plan.category.name)
                        .font(.headline)
                    Spacer(minLength: 8)
                    ExplorationStatusLabel(status: plan.status)
                        .font(.subheadline.weight(.semibold))
                }
                ExplorationPlanBar(spent: plan.spent, projected: plan.projected, planned: plan.planned, tint: plan.status.tint)
                Text("\(plan.spent, format: .currency(code: code)) of \(plan.planned, format: .currency(code: code)) · projected \(plan.projected, format: .currency(code: code))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }

    private var chartTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Spending by category", symbol: "chart.bar.fill")
                ExplorationSpendingBars(spending: snapshot.spendingByCategory, currencyCode: code)
                    .frame(height: chartHeight)
            }
        }
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
                    R2Link(destination: .history) { Text("See all") }
                        .font(.subheadline.weight(.semibold))
                }
                ForEach(snapshot.recentTransactions) { transaction in
                    ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                }
            }
        }
    }
}

#Preview("R2 Tidepool") {
    TidepoolHomeView()
}
#endif
