//
//  HaloHome.swift
//  Finlark
//
//  FIN-9 Round 2 "Halo": the balance moves into the compact navigation bar, so the content starts
//  with the month figures straight away. The plan is a slider of category cards (the next card peeks in),
//  followed by a small bento of owed and the spending chart.
//

#if DEBUG
import SwiftUI

struct HaloHomeView: View {
    private enum PlanCard: Identifiable {
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
    @ScaledMetric(relativeTo: .caption) private var donutSize: CGFloat = 96

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        R2TabShell(model: model) {
            ScrollView {
                GlassEffectContainer(spacing: r2GlassBlendSpacing) {
                    VStack(alignment: .leading, spacing: r2TileSpacing) {
                        monthStrip
                            .padding(.horizontal)
                        planSlider
                        bento
                            .padding(.horizontal)
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
            .r2CompactTitle()
            .toolbar {
                // The balance replaces the visible title (HOM-001). "Home" stays the title for the back button.
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 0) {
                        Text("Balance")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(snapshot.balance, format: .currency(code: code))
                            .font(.headline)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.isHeader)
                }
            }
        }
    }

    // MARK: Month

    private var monthStrip: some View {
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text(Date.now, format: .dateTime.month(.wide))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top) { monthFigures }
                    VStack(alignment: .leading, spacing: 8) { monthFigures }
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

    // MARK: Plan slider

    @ViewBuilder
    private var planSlider: some View {
        if let plan = snapshot.plan {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Monthly Plan")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    NavigationLink("Open", value: ExplorationDestination.plan)
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.horizontal, 20)

                let cards = [PlanCard.overview(plan)] + plan.categories.map { PlanCard.category($0) }
                R2Slider(cards, peeksNextPage: true) { card in
                    planCard(card)
                }
            }
        } else {
            NavigationLink(value: ExplorationDestination.plan) {
                R2Tile {
                    HStack {
                        Label("Create a Monthly Plan", systemImage: "chart.bar.doc.horizontal.fill")
                            .font(.headline)
                        Spacer(minLength: 8)
                        R2Chevron()
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func planCard(_ card: PlanCard) -> some View {
        switch card {
        case .overview(let plan):
            HaloPlanCard(
                title: Text("All categories"),
                icon: nil,
                spent: plan.totalSpent,
                planned: plan.totalPlanned,
                projected: plan.totalProjected,
                status: plan.status,
                code: code
            )
        case .category(let plan):
            HaloPlanCard(
                title: Text(plan.category.name),
                icon: plan.category,
                spent: plan.spent,
                planned: plan.planned,
                projected: plan.projected,
                status: plan.status,
                code: code
            )
        }
    }

    // MARK: Bento

    @ViewBuilder
    private var bento: some View {
        let showsOwed = snapshot.owedToYou > 0
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: r2TileSpacing) {
                if showsOwed { owedTile }
                chartTile
            }
        } else {
            Grid(horizontalSpacing: r2TileSpacing, verticalSpacing: r2TileSpacing) {
                GridRow {
                    if showsOwed {
                        owedTile
                        chartTile
                    } else {
                        chartTile.gridCellColumns(2)
                    }
                }
            }
        }
    }

    private var owedTile: some View {
        NavigationLink(value: ExplorationDestination.people) {
            R2Tile(padding: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    R2TileHeader(title: "Owed to you", symbol: "person.2.fill") { R2Chevron() }
                    Spacer(minLength: 0)
                    Text(snapshot.owedToYou, format: .currency(code: code))
                        .font(.title2.weight(.bold))
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

    private var chartTile: some View {
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                R2TileHeader(title: "Spending", symbol: "chart.pie.fill")
                ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
                    .frame(width: donutSize, height: donutSize)
                    .frame(maxWidth: .infinity)
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

private struct HaloPlanCard: View {
    let title: Text
    let icon: ExplorationCategory?
    let spent: Decimal
    let planned: Decimal
    let projected: Decimal
    let status: ExplorationPlanStatus
    let code: String

    var body: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    if let icon {
                        ExplorationCategoryIcon(category: icon)
                    }
                    title
                        .font(.headline)
                    Spacer(minLength: 8)
                    ExplorationStatusLabel(status: status)
                        .font(.subheadline.weight(.semibold))
                }
                Text("\(spent, format: .currency(code: code)) of \(planned, format: .currency(code: code))")
                    .font(.title3.weight(.bold))
                ExplorationPlanBar(spent: spent, projected: projected, planned: planned, tint: status.tint)
                Group {
                    if spent > planned {
                        Text("Projected \(projected, format: .currency(code: code)) · \(spent - planned, format: .currency(code: code)) over")
                    } else {
                        Text("Projected \(projected, format: .currency(code: code)) · \(planned - spent, format: .currency(code: code)) left")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview("R2 Halo") {
    HaloHomeView()
}
#endif
