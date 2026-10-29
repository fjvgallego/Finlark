//
//  LagoonHome.swift
//  Finlark
//
//  FIN-9 Round 2 "Lagoon": a hero slider opens the screen (balance, this month, spending chart),
//  with a 2×2 glass bento below it (plan, owed, pending, difference). Tiles that have nothing to show
//  drop out and the grid reflows.
//

#if DEBUG
import SwiftUI

struct LagoonHomeView: View {
    private enum HeroPage: Identifiable, CaseIterable {
        case balance
        case month
        case chart

        var id: Self { self }
    }

    private enum Tile: Identifiable {
        case plan
        case owed
        case pending
        case difference

        var id: Self { self }
    }

    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 44
    @ScaledMetric(relativeTo: .caption) private var donutSize: CGFloat = 116
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 150

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    private var tiles: [Tile] {
        var tiles: [Tile] = [.plan]
        if snapshot.owedToYou > 0 { tiles.append(.owed) }
        if !model.pendingItems.isEmpty { tiles.append(.pending) }
        tiles.append(.difference)
        return tiles
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    GlassEffectContainer(spacing: r2GlassBlendSpacing) {
                        VStack(spacing: r2TileSpacing) {
                            R2Slider(HeroPage.allCases) { page in
                                heroPage(page)
                            }
                            bento(scrollTo: proxy)
                                .padding(.horizontal)
                            Group {
                                if !model.pendingItems.isEmpty {
                                    pendingList
                                        .id(Tile.pending)
                                }
                                recentList
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    }
                }
            }
            .background(R2Backdrop())
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .r2FloatingAddButton { model.addingType = .expense }
            .r2CompactTitle()
            .explorationScaffold(model)
        }
    }

    // MARK: Hero slider

    @ViewBuilder
    private func heroPage(_ page: HeroPage) -> some View {
        switch page {
        case .balance:
            R2Tile(padding: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    R2TileHeader(title: "Balance", symbol: "wallet.bifold.fill")
                    Spacer(minLength: 0)
                    Text(snapshot.balance, format: .currency(code: code))
                        .font(.system(size: heroSize, weight: .bold, design: .rounded).monospacedDigit())
                    Text("Today, \(Date.now, format: .dateTime.day().month(.wide))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            }
        case .month:
            R2Tile(padding: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "This month", symbol: "calendar")
                    HStack(alignment: .center, spacing: 16) {
                        VStack(alignment: .leading, spacing: 10) {
                            R2Figure(title: "Income", value: snapshot.monthIncome, code: code)
                            R2Figure(title: "Spending", value: snapshot.monthSpending, code: code)
                        }
                        Spacer(minLength: 0)
                        ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
                            .frame(width: donutSize, height: donutSize)
                    }
                }
            }
        case .chart:
            R2Tile(padding: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "By category", symbol: "chart.bar.fill")
                    ExplorationSpendingBars(spending: snapshot.spendingByCategory, currencyCode: code)
                        .frame(height: chartHeight)
                }
            }
        }
    }

    // MARK: Bento

    @ViewBuilder
    private func bento(scrollTo proxy: ScrollViewProxy) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: r2TileSpacing) {
                ForEach(tiles) { tile in
                    self.tile(tile, proxy: proxy)
                }
            }
        } else {
            Grid(horizontalSpacing: r2TileSpacing, verticalSpacing: r2TileSpacing) {
                ForEach(Array(stride(from: 0, to: tiles.count, by: 2)), id: \.self) { start in
                    GridRow {
                        if start + 1 < tiles.count {
                            tile(tiles[start], proxy: proxy)
                            tile(tiles[start + 1], proxy: proxy)
                        } else {
                            tile(tiles[start], proxy: proxy).gridCellColumns(2)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func tile(_ tile: Tile, proxy: ScrollViewProxy) -> some View {
        switch tile {
        case .plan:
            NavigationLink(value: ExplorationDestination.plan) {
                LagoonTile(title: "Plan", symbol: "chart.bar.doc.horizontal.fill", isLink: true) {
                    if let plan = snapshot.plan {
                        ExplorationStatusLabel(status: plan.status)
                            .font(.headline)
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        Text("\(plan.totalSpent, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Set up a plan")
                            .font(.headline)
                    }
                }
            }
            .buttonStyle(.plain)
        case .owed:
            NavigationLink(value: ExplorationDestination.people) {
                LagoonTile(title: "Owed to you", symbol: "person.2.fill", isLink: true) {
                    Text(snapshot.owedToYou, format: .currency(code: code))
                        .font(.title3.weight(.bold))
                    Text("\(snapshot.owedPeopleCount) people")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        case .pending:
            Button {
                withAnimation(reduceMotion ? nil : .default) {
                    proxy.scrollTo(Tile.pending, anchor: .top)
                }
            } label: {
                LagoonTile(title: "Pending", symbol: "clock.arrow.2.circlepath", isLink: true) {
                    Text("\(model.pendingItems.count) to confirm")
                        .font(.title3.weight(.bold))
                    if let next = model.pendingItems.first {
                        Text(next.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Shows the pending items below"))
        case .difference:
            LagoonTile(title: "Difference", symbol: "plusminus", isLink: false) {
                Text(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))
                    .font(.title3.weight(.bold))
                Text("Income minus spending")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Lists

    private var pendingList: some View {
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

    private var recentList: some View {
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

private struct LagoonTile<Content: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    let isLink: Bool
    @ViewBuilder let content: Content

    var body: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 6) {
                if isLink {
                    R2TileHeader(title: title, symbol: symbol) { R2Chevron() }
                } else {
                    R2TileHeader(title: title, symbol: symbol)
                }
                Spacer(minLength: 0)
                content
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }
}

#Preview("R2 Lagoon") {
    LagoonHomeView()
}
#endif
