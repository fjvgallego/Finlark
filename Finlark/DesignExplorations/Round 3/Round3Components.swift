//
//  Round3Components.swift
//  Finlark
//
//  FIN-9 Round 3: building blocks for the Facet variants. They vary three things the owner asked
//  about: where the add expense and income controls live, a spending chart that names every category
//  and its amount (replacing the donut), and a roomier plan section. Tiles, the slider, the History and
//  Settings mocks and the tab routing come from Round 2.
//

#if DEBUG
import SwiftUI
import Charts

// MARK: - Quick add placement

/// Where the add expense and income controls live (HOM-007, TRX-001: on Home and History).
enum R3QuickAdd {
    /// Toolbar "+" button: tap adds an expense, long press offers income.
    case toolbarMenu
    /// Toolbar "Add" button that always asks: Expense or Income.
    case toolbarChoice
    /// Two toolbar text buttons: Income and a prominent Expense.
    case toolbarPair
    /// Two large buttons on Home itself. History gets the toolbar "+" button.
    case homeButtons
    /// Bar above the tab bar with Expense and Income at equal weight.
    case accessoryEqual
    /// Bar above the tab bar with "Add expense" first and an Income shortcut (Round 2).
    case accessoryExpenseFirst

    var usesAccessory: Bool {
        switch self {
        case .accessoryEqual, .accessoryExpenseFirst: true
        default: false
        }
    }
}

/// Round 2's tab bar (Home, History, Settings) with a configurable quick-add placement.
struct R3TabShell<Home: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    let model: ExplorationHomeModel
    let quickAdd: R3QuickAdd
    private let home: Home

    @State private var selection: AppTab = .home
    @State private var router = R2TabRouter(tabDestinations: [.history])

    init(model: ExplorationHomeModel, quickAdd: R3QuickAdd, @ViewBuilder home: () -> Home) {
        self.model = model
        self.quickAdd = quickAdd
        self.home = home()
    }

    var body: some View {
        @Bindable var model = model

        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    home
                        .modifier(R3QuickAddToolbar(model: model, quickAdd: quickAdd, isHome: true))
                        .r2Destinations()
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                NavigationStack {
                    R2HistoryScreen(model: model)
                        .modifier(R3QuickAddToolbar(model: model, quickAdd: quickAdd, isHome: false))
                        .r2Destinations()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    R2SettingsScreen()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: quickAdd.usesAccessory && selection != .settings) {
            R3QuickAddAccessory(model: model, quickAdd: quickAdd)
        }
        .environment(router)
        .onChange(of: router.requested) { _, destination in
            guard destination != nil else { return }
            selection = .history
            router.requested = nil
        }
        .sheet(item: $model.addingType) { type in
            ExplorationAddSheet(type: type, currencyCode: model.snapshot.currencyCode)
        }
    }
}

private struct R3QuickAddToolbar: ViewModifier {
    let model: ExplorationHomeModel
    let quickAdd: R3QuickAdd
    let isHome: Bool

    func body(content: Content) -> some View {
        switch quickAdd {
        case .toolbarMenu:
            content.toolbar { plusMenu }
        case .homeButtons:
            if isHome {
                content
            } else {
                content.toolbar { plusMenu }
            }
        case .toolbarChoice:
            content.toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Expense", systemImage: "arrow.up.right") { model.addingType = .expense }
                        Button("Income", systemImage: "arrow.down.left") { model.addingType = .income }
                    } label: {
                        Label("Add", systemImage: "plus")
                            .labelStyle(.titleAndIcon)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        case .toolbarPair:
            content.toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Income") { model.addingType = .income }
                }
                ToolbarSpacer(.fixed, placement: .primaryAction)
                ToolbarItem(placement: .primaryAction) {
                    Button("Expense") { model.addingType = .expense }
                        .buttonStyle(.glassProminent)
                }
            }
        case .accessoryEqual, .accessoryExpenseFirst:
            content
        }
    }

    private var plusMenu: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Add expense", systemImage: "arrow.up.right") { model.addingType = .expense }
                Button("Add income", systemImage: "arrow.down.left") { model.addingType = .income }
            } label: {
                Label("Add transaction", systemImage: "plus")
            } primaryAction: {
                model.addingType = .expense
            }
            .buttonStyle(.glassProminent)
        }
    }
}

private struct R3QuickAddAccessory: View {
    let model: ExplorationHomeModel
    let quickAdd: R3QuickAdd
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        Group {
            if placement == .inline {
                HStack(spacing: 20) {
                    Button("Add expense", systemImage: "arrow.up.right") { model.addingType = .expense }
                    Button("Add income", systemImage: "arrow.down.left") { model.addingType = .income }
                }
                .labelStyle(.iconOnly)
            } else if quickAdd == .accessoryEqual {
                HStack(spacing: 0) {
                    Button { model.addingType = .expense } label: {
                        Label("Expense", systemImage: "arrow.up.right")
                            .frame(maxWidth: .infinity)
                    }
                    Divider()
                        .padding(.vertical, 8)
                    Button { model.addingType = .income } label: {
                        Label("Income", systemImage: "arrow.down.left")
                            .frame(maxWidth: .infinity)
                    }
                }
                .font(.headline)
            } else {
                HStack(spacing: 0) {
                    Button { model.addingType = .expense } label: {
                        Label("Add expense", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    Divider()
                        .padding(.vertical, 8)
                    Button { model.addingType = .income } label: {
                        Label("Income", systemImage: "arrow.down.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .frame(maxWidth: 140)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// Large Expense and Income buttons placed on Home itself (`R3QuickAdd.homeButtons`).
struct R3HomeAddButtons: View {
    let model: ExplorationHomeModel

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: r2TileSpacing) { buttons }
            VStack(spacing: r2TileSpacing) { buttons }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Button { model.addingType = .expense } label: {
            Label("Add expense", systemImage: "arrow.up.right")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glassProminent)
        Button { model.addingType = .income } label: {
            Label("Add income", systemImage: "arrow.down.left")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
    }
}

// MARK: - Spending by category (HOM-002)

private let r3RestCategory = ExplorationCategory(
    id: "r3-rest", name: "Everything else", symbol: "ellipsis.circle.fill", color: .gray
)

extension ExplorationHomeSnapshot {
    /// The largest spending categories, with the rest summed into one "Everything else" entry.
    func r3TopSpending(limit: Int) -> [ExplorationCategorySpending] {
        let sorted = spendingByCategory.sorted { $0.amount > $1.amount }
        guard sorted.count > limit + 1 else { return sorted }
        let rest = sorted.dropFirst(limit).reduce(Decimal(0)) { $0 + $1.amount }
        return Array(sorted.prefix(limit)) + [ExplorationCategorySpending(category: r3RestCategory, amount: rest)]
    }

    var r3DaysLeft: Int { daysInMonth - dayOfMonth }
}

/// Horizontal bars on a shared scale, each with its category name and amount written above it,
/// so no legend is needed. Labels are plain text rather than chart annotations, which didn't render.
struct R3LabeledBars: View {
    let spending: [ExplorationCategorySpending]
    let code: String

    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 8

    var body: some View {
        let maxValue = spending.map(\.amount.plotValue).max() ?? 0

        VStack(alignment: .leading, spacing: 10) {
            ForEach(spending) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.category.name)
                        Spacer(minLength: 8)
                        Text(item.amount, format: .currency(code: code))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .font(.subheadline)

                    Chart {
                        BarMark(xStart: .value("Start", 0), xEnd: .value("Amount", item.amount.plotValue))
                            .foregroundStyle(item.category.color)
                            .cornerRadius(barHeight / 2)
                    }
                    .chartXScale(domain: 0...max(maxValue, 1))
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: barHeight)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.category.name))
                .accessibilityValue(Text(item.amount, format: .currency(code: code)))
            }
        }
    }
}

/// One bar split by category, with a legend that names each color and gives its amount and share.
struct R3StackedSpending: View {
    let spending: [ExplorationCategorySpending]
    let code: String

    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 16
    @ScaledMetric(relativeTo: .subheadline) private var swatchSize: CGFloat = 10

    private var total: Decimal { spending.reduce(0) { $0 + $1.amount } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Chart(spending) { item in
                BarMark(x: .value("Amount", item.amount.plotValue))
                    .foregroundStyle(item.category.color)
            }
            .chartXScale(domain: 0...max(total.plotValue, 1))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: barHeight)
            .clipShape(.capsule)
            .accessibilityHidden(true) // The legend below reads out every category.

            VStack(spacing: 8) {
                ForEach(spending) { item in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.category.color)
                            .frame(width: swatchSize, height: swatchSize)
                            .accessibilityHidden(true)
                        Text(item.category.name)
                        Spacer(minLength: 8)
                        Text(item.amount, format: .currency(code: code))
                            .fontWeight(.medium)
                        if total > 0 {
                            Text(item.amount / total, format: .percent.precision(.fractionLength(0)))
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 36, alignment: .trailing)
                        }
                    }
                    .font(.subheadline)
                    .monospacedDigit()
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }
}

// MARK: - Plan (HOM-003)

/// The whole plan in one full-width tile: status, the three figures labeled with the bar's own
/// marks, the bar, and what's left with the days to go.
struct R3PlanFiguresTile: View {
    let snapshot: ExplorationHomeSnapshot

    private var code: String { snapshot.currencyCode }

    var body: some View {
        R2Link(destination: .plan) {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    R2TileHeader(title: "Monthly Plan", symbol: "chart.bar.doc.horizontal.fill") { R2Chevron() }
                    if let plan = snapshot.plan {
                        ExplorationStatusLabel(status: plan.status)
                            .font(.title3.weight(.semibold))
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top) { figures(plan) }
                            VStack(alignment: .leading, spacing: 10) { figures(plan) }
                        }
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        .padding(.vertical, 2)
                        HStack {
                            R3RemainingText(planned: plan.totalPlanned, spent: plan.totalSpent, code: code)
                            Spacer(minLength: 8)
                            Text("\(snapshot.r3DaysLeft) days to go")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    } else {
                        R3PlanInvite()
                    }
                }
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func figures(_ plan: ExplorationPlanSummary) -> some View {
        R3PlanFigure(title: "Spent", value: plan.totalSpent, code: code, swatch: .spent(plan.status.tint))
        Spacer(minLength: 8)
        R3PlanFigure(title: "Projected", value: plan.totalProjected, code: code, swatch: .projected(plan.status.tint))
        Spacer(minLength: 8)
        R3PlanFigure(title: "Planned", value: plan.totalPlanned, code: code, swatch: .planned)
    }
}

/// Plan headline plus the categories that need attention (At risk or Over), so the details of the
/// plan surface on Home without opening it.
struct R3PlanAttentionTile: View {
    let snapshot: ExplorationHomeSnapshot

    private var code: String { snapshot.currencyCode }

    var body: some View {
        R2Link(destination: .plan) {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    R2TileHeader(title: "Monthly Plan", symbol: "chart.bar.doc.horizontal.fill") { R2Chevron() }
                    if let plan = snapshot.plan {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(plan.totalSpent, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code)) spent")
                                .font(.title3.weight(.semibold))
                            ExplorationPlanBar(
                                spent: plan.totalSpent,
                                projected: plan.totalProjected,
                                planned: plan.totalPlanned,
                                tint: plan.status.tint
                            )
                            ViewThatFits(in: .horizontal) {
                                HStack {
                                    ExplorationStatusLabel(status: plan.status)
                                    Spacer(minLength: 8)
                                    Text("Projected \(plan.totalProjected, format: .currency(code: code))")
                                        .foregroundStyle(.secondary)
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    ExplorationStatusLabel(status: plan.status)
                                    Text("Projected \(plan.totalProjected, format: .currency(code: code))")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .font(.subheadline.weight(.medium))
                        }
                        .accessibilityElement(children: .combine)

                        let flagged = plan.categories.filter { $0.status != .onTrack }
                        if !flagged.isEmpty {
                            Divider()
                            Text("Needs attention")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            ForEach(flagged) { category in
                                R3AttentionRow(plan: category, code: code)
                            }
                        }
                    } else {
                        R3PlanInvite()
                    }
                }
                .monospacedDigit()
            }
        }
        .buttonStyle(.plain)
    }
}

private struct R3AttentionRow: View {
    let plan: ExplorationCategoryPlan
    let code: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ExplorationCategoryIcon(category: plan.category)
            VStack(alignment: .leading, spacing: 2) {
                Text(plan.category.name)
                    .font(.body.weight(.medium))
                ExplorationStatusLabel(status: plan.status)
                    .font(.subheadline)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(plan.spent, format: .currency(code: code)) of \(plan.planned, format: .currency(code: code))")
                    .font(.subheadline.weight(.medium))
                Text("Projected \(plan.projected, format: .currency(code: code))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// One planned category as a bullet chart: planned (track), projected (faded) and spent (solid),
/// with its name, figures and status written above the bar. Several rows together double as the
/// spending-by-category chart.
struct R3PlanBulletRow: View {
    let plan: ExplorationCategoryPlan
    let code: String

    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 10

    var body: some View {
        let scale = max(plan.planned, plan.spent, plan.projected).plotValue

        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: plan.category.symbol)
                    .foregroundStyle(plan.category.color)
                    .frame(minWidth: 22)
                    .accessibilityHidden(true)
                Text(plan.category.name)
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 8)
                Text("\(plan.spent, format: .currency(code: code)) of \(plan.planned, format: .currency(code: code))")
                    .font(.subheadline)
                    .monospacedDigit()
                Image(systemName: plan.status.symbol)
                    .foregroundStyle(plan.status.tint)
                    .accessibilityLabel(Text(plan.status.title))
            }

            Chart {
                BarMark(xStart: .value("Start", 0), xEnd: .value("Planned", plan.planned.plotValue))
                    .foregroundStyle(Color.secondary.opacity(0.2))
                BarMark(xStart: .value("Start", 0), xEnd: .value("Projected", plan.projected.plotValue))
                    .foregroundStyle(plan.status.tint.opacity(0.35))
                BarMark(xStart: .value("Start", 0), xEnd: .value("Spent", plan.spent.plotValue))
                    .foregroundStyle(plan.status.tint)
                RuleMark(x: .value("Planned", plan.planned.plotValue))
                    .foregroundStyle(.primary)
                    .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartXScale(domain: 0...max(scale, 1))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: barHeight)
            .clipShape(.capsule)
            .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// "€240.97 left", or "€16.50 over" once spending passes the plan.
struct R3RemainingText: View {
    let planned: Decimal
    let spent: Decimal
    let code: String

    var body: some View {
        if spent > planned {
            Text("\(spent - planned, format: .currency(code: code)) over")
        } else {
            Text("\(planned - spent, format: .currency(code: code)) left")
        }
    }
}

struct R3PlanFigure: View {
    enum Swatch {
        case spent(Color)
        case projected(Color)
        case planned
    }

    let title: LocalizedStringKey
    let value: Decimal
    let code: String
    let swatch: Swatch

    @ScaledMetric(relativeTo: .caption) private var swatchSize: CGFloat = 9

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                swatchView
                    .accessibilityHidden(true)
                Text(title)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code))
                .font(.headline)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var swatchView: some View {
        switch swatch {
        case .spent(let tint):
            Capsule().fill(tint).frame(width: swatchSize * 1.6, height: swatchSize * 0.7)
        case .projected(let tint):
            Capsule().fill(tint.opacity(0.35)).frame(width: swatchSize * 1.6, height: swatchSize * 0.7)
        case .planned:
            Capsule().fill(.primary).frame(width: 2, height: swatchSize * 1.3)
        }
    }
}

struct R3PlanInvite: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Set up your Monthly Plan")
                .font(.headline)
            Text("Plan how much you'll spend per category and see if you're on track.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Tiles shared by every variant

/// Balance (HOM-001) and the month figures (HOM-002), with an optional footer such as a chart.
struct R3SummaryTile<Footer: View>: View {
    let snapshot: ExplorationHomeSnapshot
    @ViewBuilder var footer: Footer

    private var code: String { snapshot.currencyCode }

    var body: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
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
                Divider()
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top) { monthFigures }
                    VStack(alignment: .leading, spacing: 8) { monthFigures }
                }
                footer
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
}

extension R3SummaryTile where Footer == EmptyView {
    init(snapshot: ExplorationHomeSnapshot) {
        self.init(snapshot: snapshot) { EmptyView() }
    }
}

/// Owed to you (HOM-004) as a full-width row. Hidden when nothing is owed.
struct R3OwedRow: View {
    let snapshot: ExplorationHomeSnapshot

    var body: some View {
        if snapshot.owedToYou > 0 {
            R2Link(destination: .people) {
                R2Tile(padding: 16) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.2.fill")
                            .font(.title3)
                            .foregroundStyle(.tint)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Owed to you")
                                .font(.headline)
                            Text("\(snapshot.owedPeopleCount) people")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(snapshot.owedToYou, format: .currency(code: snapshot.currencyCode))
                            .font(.headline)
                            .monospacedDigit()
                        R2Chevron()
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

/// Pending recurring items (HOM-005) as Facet's slider of cards. Hidden when there are none.
struct R3PendingSection: View {
    let model: ExplorationHomeModel

    private var code: String { model.snapshot.currencyCode }

    var body: some View {
        if !model.pendingItems.isEmpty {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                R3SectionHeader(title: "Pending", count: model.pendingItems.count)
                R2Slider(model.pendingItems) { item in
                    card(item)
                }
            }
        }
    }

    private func card(_ item: ExplorationPendingItem) -> some View {
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
}

/// Recent transactions (HOM-006) as Facet's row of glass cards, with a link to History.
struct R3RecentSection: View {
    let snapshot: ExplorationHomeSnapshot

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var chipWidth: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: r2TileSpacing) {
            R3SectionHeader(title: "Recent") {
                R2Link(destination: .history) { Text("History") }
                    .font(.subheadline.weight(.semibold))
            }
            if dynamicTypeSize.isAccessibilitySize {
                R2Tile {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(snapshot.recentTransactions) { transaction in
                            ExplorationTransactionRow(transaction: transaction, currencyCode: snapshot.currencyCode)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 10) {
                        ForEach(snapshot.recentTransactions) { transaction in
                            R3TransactionChip(transaction: transaction, code: snapshot.currencyCode)
                                .frame(width: chipWidth)
                        }
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
    }
}

private struct R3TransactionChip: View {
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

struct R3SectionHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    var count: Int?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.headline)
            if let count {
                Text(count, format: .number)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            trailing
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }
}

extension R3SectionHeader where Trailing == EmptyView {
    init(title: LocalizedStringKey, count: Int? = nil) {
        self.init(title: title, count: count) { EmptyView() }
    }
}

/// The scrolling Home canvas every variant uses: Round 2's backdrop, one glass container, a compact title.
struct R3HomeScroll<Content: View>: View {
    let model: ExplorationHomeModel
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: r2GlassBlendSpacing) {
                VStack(alignment: .leading, spacing: r2TileSpacing) {
                    content
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .background(R2Backdrop())
        .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
        .r2CompactTitle()
    }
}
#endif
