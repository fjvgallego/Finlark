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
            if let addEditor = model.addEditor {
                addEditor(type)
            } else {
                ExplorationAddSheet(type: type, currencyCode: model.snapshot.currencyCode)
            }
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

// MARK: - Plan (HOM-003)

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
                    .explorationButton(.secondary)
                    .accessibilityLabel(Text("Skip \(item.note)"))
                    Button { model.confirm(item) } label: {
                        Label("Confirm", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .explorationButton(.primary)
                    .accessibilityLabel(Text("Confirm \(item.note)"))
                }
            }
        }
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
