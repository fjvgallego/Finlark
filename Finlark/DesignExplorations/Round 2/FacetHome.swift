//
//  FacetHome.swift
//  Finlark
//
//  FIN-9 Round 2 "Facet": the most compact variation. Balance, month figures, chart, plan and owed
//  fit in two tile rows. Pending items become a slider of one card each, and recent transactions are
//  a row of glass chips, so the whole Home fits on about one screen.
//

#if DEBUG
import SwiftUI

struct FacetHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var donutSize: CGFloat = 84
    @ScaledMetric private var chipWidth: CGFloat = 150

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: r2GlassBlendSpacing) {
                    VStack(alignment: .leading, spacing: r2TileSpacing) {
                        bento
                            .padding(.horizontal)
                        if !model.pendingItems.isEmpty {
                            sectionHeader("Pending", count: model.pendingItems.count)
                            R2Slider(model.pendingItems) { item in
                                pendingCard(item)
                            }
                        }
                        sectionHeader("Recent") {
                            NavigationLink("History", value: ExplorationDestination.history)
                                .font(.subheadline.weight(.semibold))
                        }
                        recentChips
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
                summaryTile
                planTile
                if showsOwed { owedTile }
            }
        } else {
            Grid(horizontalSpacing: r2TileSpacing, verticalSpacing: r2TileSpacing) {
                GridRow {
                    summaryTile.gridCellColumns(2)
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

    /// Balance (HOM-001) and the month summary with its chart (HOM-002) in one tile.
    private var summaryTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Balance")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                        Text(snapshot.balance, format: .currency(code: code))
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    Spacer(minLength: 8)
                    if !dynamicTypeSize.isAccessibilitySize {
                        ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
                            .frame(width: donutSize, height: donutSize)
                    }
                }
                Divider()
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top) { monthFigures }
                    VStack(alignment: .leading, spacing: 8) { monthFigures }
                }
                if dynamicTypeSize.isAccessibilitySize {
                    ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
                        .frame(width: donutSize, height: donutSize)
                }
            }
        }
    }

    @ViewBuilder
    private var monthFigures: some View {
        R2Figure(title: "Income", value: snapshot.monthIncome, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        R2Figure(title: "Spending", value: snapshot.monthSpending, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        R2Figure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true,
                 font: .subheadline.weight(.semibold))
    }

    private var planTile: some View {
        NavigationLink(value: ExplorationDestination.plan) {
            R2Tile(padding: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    R2TileHeader(title: "Plan", symbol: "chart.bar.doc.horizontal.fill") { R2Chevron() }
                    if let plan = snapshot.plan {
                        ExplorationStatusLabel(status: plan.status)
                            .font(.subheadline.weight(.semibold))
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        Text("\(plan.totalRemaining, format: .currency(code: code)) left")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Set up a plan")
                            .font(.subheadline.weight(.semibold))
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
            R2Tile(padding: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    R2TileHeader(title: "Owed to you", symbol: "person.2.fill") { R2Chevron() }
                    Text(snapshot.owedToYou, format: .currency(code: code))
                        .font(.headline)
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

    // MARK: Pending slider

    private func pendingCard(_ item: ExplorationPendingItem) -> some View {
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ExplorationCategoryIcon(category: item.category)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.note)
                            .font(.headline)
                        ExplorationDueText(date: item.dueDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Text(item.type == .expense ? -item.amount : item.amount,
                         format: .currency(code: code).sign(strategy: .always()))
                        .font(.headline)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                HStack(spacing: 10) {
                    Button { model.skip(item) } label: {
                        Label("Skip", systemImage: "forward.end")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(Text("Skip \(item.note)"))
                    Button { model.confirm(item) } label: {
                        Label("Confirm", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .accessibilityLabel(Text("Confirm \(item.note)"))
                }
            }
        }
    }

    // MARK: Recent chips

    @ViewBuilder
    private var recentChips: some View {
        if dynamicTypeSize.isAccessibilitySize {
            R2Tile {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(snapshot.recentTransactions) { transaction in
                        ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                    }
                }
            }
            .padding(.horizontal)
        } else {
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(snapshot.recentTransactions) { transaction in
                        FacetChip(transaction: transaction, code: code)
                            .frame(width: chipWidth)
                    }
                    NavigationLink(value: ExplorationDestination.history) {
                        Label("See all", systemImage: "arrow.right")
                            .labelStyle(.iconOnly)
                            .font(.headline)
                            .padding(18)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("See all in History"))
                }
                .fixedSize(horizontal: false, vertical: true)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .contentMargins(.horizontal, 16, for: .scrollContent)
        }
    }

    // MARK: Helpers

    private func sectionHeader(_ title: LocalizedStringKey, count: Int? = nil) -> some View {
        sectionHeader(title, count: count) { EmptyView() }
    }

    private func sectionHeader<Trailing: View>(
        _ title: LocalizedStringKey,
        count: Int? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.headline)
            if let count {
                Text(count, format: .number)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            trailing()
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
}

private struct FacetChip: View {
    let transaction: ExplorationTransaction
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ExplorationCategoryIcon(category: transaction.category)
                Spacer(minLength: 4)
                if transaction.isSplit {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("Split"))
                }
            }
            Text(transaction.signedAmount, format: .currency(code: code).sign(strategy: .always()))
                .font(.headline)
                .monospacedDigit()
            if let share = transaction.myShare {
                Text("Your share \(share, format: .currency(code: code))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            VStack(alignment: .leading, spacing: 0) {
                if let note = transaction.note {
                    Text(note)
                        .lineLimit(2)
                }
                Text(transaction.category.name)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

#Preview("R2 Facet") {
    FacetHomeView()
}
#endif
