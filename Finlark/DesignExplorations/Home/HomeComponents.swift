//
//  HomeComponents.swift
//  Finlark
//
//  FIN-9 Home: the pieces Marsh is built from, most of which the other flows share too: the tinted
//  backdrop, glass tiles, the tab bar and quick add, the scrolling Home canvas, the pending and recent
//  lists, the plan tile, the month figures and the Owed to you bar (HOM-001…007).
//

#if DEBUG
import Charts
import SwiftUI

// MARK: - Surfaces, tiles and the tab shell

/// Where content tiles get their surface: glass or solid grouped backgrounds, which keeps
/// Liquid Glass on the controls layer only.
enum HMSurface {
    case glass
    case solid
}

extension EnvironmentValues {
    @Entry var hmSurface: HMSurface = .glass
}

/// The gap between tiles. Glass containers use a smaller spacing so neighboring tiles don't blend together.
let hmTileSpacing: CGFloat = 12
let hmGlassBlendSpacing: CGFloat = 4

struct HMBackdrop: View {
    @Environment(\.hmSurface) private var surface

    var body: some View {
        Group {
            switch surface {
            case .glass:
                LinearGradient(
                    colors: [Color.indigo.opacity(0.28), Color.teal.opacity(0.16), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .solid:
                Color(.systemGroupedBackground)
            }
        }
        .ignoresSafeArea()
    }
}

/// A bento tile. Fills the height of its grid row so tiles side by side line up.
struct HMTile<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder let content: Content

    @Environment(\.hmSurface) private var surface

    var body: some View {
        let laidOut = content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        switch surface {
        case .glass:
            laidOut.glassEffect(.regular, in: .rect(cornerRadius: 24))
        case .solid:
            laidOut.background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
        }
    }
}

/// A tile's small uppercase heading, with an optional trailing accessory.
struct HMTileHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            trailing
        }
    }
}

extension HMTileHeader where Trailing == EmptyView {
    init(title: LocalizedStringKey, symbol: String) {
        self.init(title: title, symbol: symbol) { EmptyView() }
    }
}

/// A chevron that marks a tile as tappable.
struct HMChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

/// A horizontal, snapping slider of full-width pages with a glass page indicator.
/// Pages share the height of the tallest one. At accessibility sizes the pages stack vertically instead.
struct HMSlider<Item: Identifiable, Page: View>: View {
    private let items: [Item]
    private let spacing: CGFloat
    private let margin: CGFloat
    private let indicatorOnGlass: Bool
    private let peeksNextPage: Bool
    private let page: (Item) -> Page

    @State private var currentID: Item.ID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - margin: horizontal inset around the pages. A non-zero margin lets the next page peek in.
    ///   - indicatorOnGlass: false when the slider already sits inside a glass tile, to avoid glass on glass.
    ///   - peeksNextPage: narrows each page so the edge of the next one shows, hinting that it scrolls.
    init(
        _ items: [Item],
        spacing: CGFloat = hmTileSpacing,
        margin: CGFloat = 16,
        indicatorOnGlass: Bool = true,
        peeksNextPage: Bool = false,
        @ViewBuilder page: @escaping (Item) -> Page
    ) {
        self.items = items
        self.spacing = spacing
        self.margin = margin
        self.indicatorOnGlass = indicatorOnGlass
        self.peeksNextPage = peeksNextPage
        self.page = page
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: spacing) {
                ForEach(items) { item in
                    page(item)
                }
            }
            .padding(.horizontal, margin)
        } else {
            VStack(spacing: 8) {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(items) { item in
                            page(item)
                                .containerRelativeFrame(.horizontal, count: peeksNextPage ? 8 : 1, span: peeksNextPage ? 7 : 1, spacing: spacing)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentID)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .contentMargins(.horizontal, margin, for: .scrollContent)

                if items.count > 1 {
                    HMPageDots(count: items.count, index: currentIndex, onGlass: indicatorOnGlass)
                }
            }
        }
    }

    private var currentIndex: Int {
        items.firstIndex { $0.id == currentID } ?? 0
    }
}

struct HMPageDots: View {
    let count: Int
    let index: Int
    var onGlass = true

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { position in
                Capsule()
                    .fill(position == index ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .frame(width: position == index ? 16 : 6, height: 6)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(onGlass ? .regular : .identity, in: .capsule)
        .accessibilityHidden(true) // VoiceOver reaches every page by swiping.
    }
}

extension View {
    /// A compact title: "Home" stays small and inline instead of taking a large-title row.
    func hmCompactTitle() -> some View {
        navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Routing

/// Lets Home's links switch tabs. Destinations in `tabDestinations` are tabs in the shell, so links to
/// them set `requested` (the shell switches tab) instead of pushing a screen.
@Observable
final class HMTabRouter {
    let tabDestinations: Set<ExplorationDestination>
    var requested: ExplorationDestination?

    init(tabDestinations: Set<ExplorationDestination>) {
        self.tabDestinations = tabDestinations
    }
}

/// Pushes the destination, or switches to its tab when the shell has one for it.
struct HMLink<Label: View>: View {
    let destination: ExplorationDestination
    @ViewBuilder let label: Label

    @Environment(HMTabRouter.self) private var router: HMTabRouter?

    var body: some View {
        if let router, router.tabDestinations.contains(destination) {
            Button {
                router.requested = destination
            } label: {
                label
            }
        } else {
            NavigationLink(value: destination) {
                label
            }
        }
    }
}

extension View {
    /// Placeholder pushes for destinations that aren't tabs. Apply inside each tab's NavigationStack.
    func hmDestinations() -> some View {
        navigationDestination(for: ExplorationDestination.self) { destination in
            ExplorationPlaceholderScreen(destination: destination)
        }
    }
}

// MARK: - History tab (mock of TRX-005)

/// A light mock of the History screen so the tab bar feels real, with search in notes (TRX-005).
struct HMHistoryScreen: View {
    let model: ExplorationHomeModel

    @State private var searchText = ""

    private var code: String { model.snapshot.currencyCode }

    private var days: [(day: Date, transactions: [ExplorationTransaction])] {
        let matching = model.snapshot.recentTransactions.filter { transaction in
            searchText.isEmpty || (transaction.note ?? "").localizedStandardContains(searchText)
        }
        let grouped = Dictionary(grouping: matching) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { (day: $0, transactions: grouped[$0] ?? []) }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Income") {
                    Text(model.snapshot.monthIncome, format: .currency(code: code))
                }
                LabeledContent("Spending") {
                    Text(model.snapshot.monthSpending, format: .currency(code: code))
                }
            } header: {
                Text(Date.now, format: .dateTime.month(.wide).year())
            }
            .monospacedDigit()

            ForEach(days, id: \.day) { day in
                Section {
                    ForEach(day.transactions) { transaction in
                        ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                    }
                } header: {
                    Text(day.day, format: .dateTime.weekday(.wide).day().month(.wide))
                }
            }
        }
        .overlay {
            if days.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("Search notes"))
    }
}

// MARK: - Settings tab (mock of SET-001)

struct HMSettingsScreen: View {
    @State private var recurringNotifications = true
    @State private var iouNotifications = true
    @State private var appLock = false

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Name", value: "Main account")
                LabeledContent("Starting balance") {
                    Text(Decimal(1000), format: .currency(code: "EUR"))
                }
                LabeledContent("Home currency", value: "EUR")
            }
            Section {
                Label("Categories", systemImage: "square.grid.2x2")
                Label("Recurring", systemImage: "repeat")
            }
            Section("Notifications") {
                Toggle("Recurring due", isOn: $recurringNotifications)
                Toggle("IOU reminders", isOn: $iouNotifications)
            }
            Section("Security") {
                Toggle("App lock", isOn: $appLock)
            }
            Section("iCloud") {
                LabeledContent("Sync", value: String(localized: "Up to date"))
            }
            Section {
                Button("Delete all data", role: .destructive) {}
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Figures

/// An amount with a caption above it, used by the month figures in several variations.
struct HMFigure: View {
    let title: LocalizedStringKey
    let value: Decimal
    let code: String
    var signed = false
    var font: Font = .headline

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code).sign(strategy: signed ? .always() : .automatic))
                .font(font)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Quick add placement

/// Where the add expense and income controls live (HOM-007, TRX-001: on Home and History).
enum HMQuickAdd {
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
    /// Bar above the tab bar with "Add expense" first and an Income shortcut.
    case accessoryExpenseFirst

    var usesAccessory: Bool {
        switch self {
        case .accessoryEqual, .accessoryExpenseFirst: true
        default: false
        }
    }
}

/// The tab bar (Home, History, Settings) with a configurable quick-add placement.
struct HMTabShell<Home: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    let model: ExplorationHomeModel
    let quickAdd: HMQuickAdd
    private let home: Home

    @State private var selection: AppTab = .home
    @State private var router = HMTabRouter(tabDestinations: [.history])

    init(model: ExplorationHomeModel, quickAdd: HMQuickAdd, @ViewBuilder home: () -> Home) {
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
                        .modifier(HMQuickAddToolbar(model: model, quickAdd: quickAdd, isHome: true))
                        .hmDestinations()
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                NavigationStack {
                    HMHistoryScreen(model: model)
                        .modifier(HMQuickAddToolbar(model: model, quickAdd: quickAdd, isHome: false))
                        .hmDestinations()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    HMSettingsScreen()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .modifier(
            HMBottomAccessory(isEnabled: quickAdd.usesAccessory && selection != .settings) {
                HMQuickAddAccessory(model: model, quickAdd: quickAdd)
            }
        )
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

/// C-1: `tabViewBottomAccessory(isEnabled:content:)` needs iOS 26.1. On iOS 26.0 the accessory is added or left out
/// instead.
private struct HMBottomAccessory<Accessory: View>: ViewModifier {
    let isEnabled: Bool
    @ViewBuilder let accessory: Accessory

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: isEnabled) { accessory }
        } else if isEnabled {
            content.tabViewBottomAccessory { accessory }
        } else {
            content
        }
    }
}

private struct HMQuickAddToolbar: ViewModifier {
    let model: ExplorationHomeModel
    let quickAdd: HMQuickAdd
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

private struct HMQuickAddAccessory: View {
    let model: ExplorationHomeModel
    let quickAdd: HMQuickAdd
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

private let hmRestCategory = ExplorationCategory(
    id: "r3-rest", name: "Everything else", symbol: "ellipsis.circle.fill", color: .gray
)

extension ExplorationHomeSnapshot {
    /// The largest spending categories, with the rest summed into one "Everything else" entry.
    func hmTopSpending(limit: Int) -> [ExplorationCategorySpending] {
        let sorted = spendingByCategory.sorted { $0.amount > $1.amount }
        guard sorted.count > limit + 1 else { return sorted }
        let rest = sorted.dropFirst(limit).reduce(Decimal(0)) { $0 + $1.amount }
        return Array(sorted.prefix(limit)) + [ExplorationCategorySpending(category: hmRestCategory, amount: rest)]
    }

    var hmDaysLeft: Int { daysInMonth - dayOfMonth }
}

// MARK: - Plan (HOM-003)

/// "€240.97 left", or "€16.50 over" once spending passes the plan.
struct HMRemainingText: View {
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

struct HMPlanFigure: View {
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

struct HMPlanInvite: View {
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
struct HMSummaryTile<Footer: View>: View {
    let snapshot: ExplorationHomeSnapshot
    @ViewBuilder var footer: Footer

    private var code: String { snapshot.currencyCode }

    var body: some View {
        HMTile(padding: 18) {
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
        HMFigure(title: "Income", value: snapshot.monthIncome, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        HMFigure(title: "Spending", value: snapshot.monthSpending, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        HMFigure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true,
                 font: .subheadline.weight(.semibold))
    }
}

extension HMSummaryTile where Footer == EmptyView {
    init(snapshot: ExplorationHomeSnapshot) {
        self.init(snapshot: snapshot) { EmptyView() }
    }
}

/// Pending recurring items (HOM-005) as a slider of cards. Hidden when there are none.
struct HMPendingSection: View {
    let model: ExplorationHomeModel

    private var code: String { model.snapshot.currencyCode }

    var body: some View {
        if !model.pendingItems.isEmpty {
            VStack(alignment: .leading, spacing: hmTileSpacing) {
                HMSectionHeader(title: "Pending", count: model.pendingItems.count)
                HMSlider(model.pendingItems) { item in
                    card(item)
                }
            }
        }
    }

    private func card(_ item: ExplorationPendingItem) -> some View {
        HMTile(padding: 14) {
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

struct HMSectionHeader<Trailing: View>: View {
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

extension HMSectionHeader where Trailing == EmptyView {
    init(title: LocalizedStringKey, count: Int? = nil) {
        self.init(title: title, count: count) { EmptyView() }
    }
}

/// The scrolling Home canvas Marsh uses: the backdrop, one glass container, a compact title.
struct HMHomeScroll<Content: View>: View {
    let model: ExplorationHomeModel
    @ViewBuilder let content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            GlassEffectContainer(spacing: hmGlassBlendSpacing) {
                VStack(alignment: .leading, spacing: hmTileSpacing) {
                    content
                }
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
        }
        .background(HMBackdrop())
        .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
        .hmCompactTitle()
    }
}

// MARK: - Spending strip and recent list

/// Recent transactions (HOM-006) as a vertical list inside one tile, instead of cards.
struct HMRecentList: View {
    let snapshot: ExplorationHomeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: hmTileSpacing) {
            HMSectionHeader(title: "Recent") {
                HMLink(destination: .history) { Text("History") }
                    .font(.subheadline.weight(.semibold))
            }
            HMTile(padding: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(snapshot.recentTransactions) { transaction in
                        ExplorationTransactionRow(transaction: transaction, currencyCode: snapshot.currencyCode)
                        if transaction.id != snapshot.recentTransactions.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Plan with the pace sentence

extension ExplorationHomeSnapshot {
    /// A one-sentence read of the plan's pace ("At this pace you'll go €50.07 over plan.").
    func hmPaceSentence(for plan: ExplorationPlanSummary) -> LocalizedStringKey {
        // A-09: no pace estimate during the first 3 days of the month.
        guard dayOfMonth > 3 else {
            return "\(plan.totalRemaining, format: .currency(code: currencyCode)) left to spend this month."
        }
        switch plan.status {
        case .onTrack:
            return "You're on track, with \(plan.totalRemaining, format: .currency(code: currencyCode)) left to spend."
        case .atRisk:
            return "At this pace you'll go \(plan.totalProjected - plan.totalPlanned, format: .currency(code: currencyCode)) over plan."
        case .over:
            return "You're already \(plan.totalSpent - plan.totalPlanned, format: .currency(code: currencyCode)) over plan."
        }
    }
}

// MARK: - Summary pieces

struct HMBalanceHeader: View {
    let snapshot: ExplorationHomeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Balance")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(snapshot.balance, format: .currency(code: snapshot.currencyCode))
                .font(.system(.title, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

extension ExplorationHomeSnapshot {
    /// Share of the month's spending, for chart captions.
    func hmShare(of amount: Decimal) -> Decimal {
        monthSpending > 0 ? amount / monthSpending : 0
    }
}

// MARK: - Minimal category charts (HOM-002)

/// One bar of the whole month you can scrub: touching a segment colors it and names it above.
/// Untouched, it shows the largest category, so it reads without interaction. VoiceOver reads every
/// segment through the chart's own marks.
struct HMScrubBar: View {
    let snapshot: ExplorationHomeSnapshot

    @State private var rawSelection: Double?
    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 14

    private var sorted: [ExplorationCategorySpending] {
        snapshot.spendingByCategory.sorted { $0.amount > $1.amount }
    }

    /// The segment under the finger. Segments stack in order, so walk the running total.
    private var selected: ExplorationCategorySpending? {
        guard let rawSelection else { return sorted.first }
        var runningTotal = 0.0
        for item in sorted {
            runningTotal += item.amount.plotValue
            if rawSelection <= runningTotal { return item }
        }
        return sorted.last
    }

    var body: some View {
        if let selected {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: selected.category.symbol)
                        .foregroundStyle(selected.category.color)
                        .accessibilityHidden(true)
                    Text(selected.category.name)
                        .fontWeight(.semibold)
                    Text(selected.amount, format: .currency(code: snapshot.currencyCode))
                        .monospacedDigit()
                    Text(snapshot.hmShare(of: selected.amount), format: .percent.precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.subheadline)
                .accessibilityHidden(true) // The chart marks carry the same information.

                Chart(sorted) { item in
                    BarMark(x: .value("Amount", item.amount.plotValue))
                        .foregroundStyle(item.id == selected.id ? item.category.color : Color.secondary.opacity(0.25))
                        .accessibilityLabel(Text(item.category.name))
                        .accessibilityValue(Text(item.amount, format: .currency(code: snapshot.currencyCode)))
                }
                .chartXScale(domain: 0...max(snapshot.monthSpending.plotValue, 1))
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartXSelection(value: $rawSelection)
                .frame(height: barHeight)
                .clipShape(.capsule)

                Text("Touch and drag the bar to see each category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}

// MARK: - Mock debtors

/// A person with open shares (PPL-003), mocked so Settle all (SPL-008) can be tried from Home.
struct HMDebtor: Identifiable {
    struct OpenShare: Identifiable {
        let id = UUID()
        let ticket: String
        let date: Date
        let remaining: Decimal
    }

    let id = UUID()
    let name: String
    let shares: [OpenShare]

    var total: Decimal { shares.reduce(0) { $0 + $1.remaining } }
    var initial: String { String(name.prefix(1)) }

    /// A stable color per person, so the same friend always looks the same.
    var color: Color {
        let palette: [Color] = [.orange, .pink, .teal, .purple, .indigo, .mint, .cyan]
        let seed = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[seed % palette.count]
    }

    /// Matches the sample snapshot: €85.00 owed by 2 people.
    static let sample: [HMDebtor] = [
        HMDebtor(name: "Marta", shares: [
            OpenShare(ticket: "Dinner at Casa Pepe", date: .now, remaining: 30),
            OpenShare(ticket: "Cinema", date: Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now,
                      remaining: 25),
        ]),
        HMDebtor(name: "Luis", shares: [
            OpenShare(ticket: "Dinner at Casa Pepe", date: .now, remaining: 30),
        ]),
    ]
}

// MARK: - Owed to you bar (HOM-004)

/// A thin, collapsed bar at the top of Home. Expanded, it shows a row of people who owe you; tapping
/// one opens a popover to settle everything they owe. Hidden when nothing is owed.
struct HMOwedBar: View {
    @Binding var debtors: [HMDebtor]
    let code: String

    @State private var isExpanded = false
    @State private var selectedID: HMDebtor.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var total: Decimal { debtors.reduce(0) { $0 + $1.total } }

    var body: some View {
        if !debtors.isEmpty {
            HMTile(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if isExpanded {
                        Divider()
                            .padding(.horizontal, 16)
                        people
                    }
                }
            }
        }
    }

    private var header: some View {
        Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                // Multicolor keeps the black exclamation mark, so the yellow symbol stays legible
                // on light backgrounds.
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .accessibilityHidden(true)
                Text("Owed to you")
                    .fontWeight(.semibold)
                Text("\(debtors.count) people")
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(total, format: .currency(code: code))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
        .accessibilityHint(Text("Shows who owes you"))
    }

    private var people: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(debtors) { debtor in
                    personChip(debtor)
                }
                // HOM-004: People stays one tap away.
                HMLink(destination: .people) {
                    Label("People", systemImage: "chevron.right")
                        .labelStyle(HMTrailingIconLabelStyle())
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    @Environment(\.explorationIconStyle) private var iconStyle

    private func personChip(_ debtor: HMDebtor) -> some View {
        Button {
            selectedID = debtor.id
        } label: {
            HStack(spacing: 8) {
                HMAvatar(debtor: debtor)
                VStack(alignment: .leading, spacing: 0) {
                    Text(debtor.name)
                        .font(.subheadline.weight(.semibold))
                    Text(debtor.total, format: .currency(code: code))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
            .background(iconStyle == .soft ? AnyShapeStyle(debtor.color.opacity(0.12)) : AnyShapeStyle(.fill.tertiary),
                        in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens options to settle up"))
        .popover(isPresented: isPresented(debtor)) {
            HMSettlePopover(debtor: debtor, code: code) {
                selectedID = nil
                withAnimation(reduceMotion ? nil : .snappy) {
                    debtors.removeAll { $0.id == debtor.id }
                }
            }
            .presentationCompactAdaptation(.popover)
        }
    }

    private func isPresented(_ debtor: HMDebtor) -> Binding<Bool> {
        Binding {
            selectedID == debtor.id
        } set: { isPresented in
            if !isPresented { selectedID = nil }
        }
    }
}

/// What a person owes, share by share, with Settle all (SPL-008). Settling asks for confirmation
/// first, since recording repayments by mistake is easy to do and annoying to undo.
private struct HMSettlePopover: View {
    let debtor: HMDebtor
    let code: String
    let onSettle: () -> Void

    @State private var isConfirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                HMAvatar(debtor: debtor)
                VStack(alignment: .leading, spacing: 0) {
                    Text(debtor.name)
                        .font(.headline)
                    Text("Owes you \(debtor.total, format: .currency(code: code))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            Divider()

            ForEach(debtor.shares) { share in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(share.ticket)
                        Text(share.date, format: .dateTime.day().month())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Text(share.remaining, format: .currency(code: code))
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }

            Button {
                isConfirming = true
            } label: {
                Label("Settle all · \(debtor.total, format: .currency(code: code))", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .explorationButton(.primary)
            .alert(Text("Settle all with \(debtor.name)?"), isPresented: $isConfirming) {
                Button("Cancel", role: .cancel) {}
                Button("Settle all", action: onSettle)
            } message: {
                Text("This records \(debtor.total, format: .currency(code: code)) in repayments for \(debtor.shares.count) shares, dated today.")
            }

            Text("Records a repayment for each open share, dated today.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 300)
    }
}

private struct HMAvatar: View {
    let debtor: HMDebtor
    @ScaledMetric private var size: CGFloat = 30
    @Environment(\.explorationIconStyle) private var style

    var body: some View {
        switch style {
        case .solid:
            Text(debtor.initial)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Color.accentColor.gradient, in: .circle)
                .accessibilityHidden(true)
        case .soft:
            Text(debtor.initial)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(debtor.color)
                .frame(width: size, height: size)
                .background(debtor.color.opacity(0.2), in: .rect(cornerRadius: size * 0.32, style: .continuous))
                .accessibilityHidden(true)
        }
    }
}

private struct HMTrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
                .font(.caption.weight(.bold))
        }
    }
}

// MARK: - Plan (HOM-003)

/// The plan's pace sentence over its labeled figures and bar.
struct HMPlanTile: View {
    let snapshot: ExplorationHomeSnapshot

    private var code: String { snapshot.currencyCode }

    var body: some View {
        HMLink(destination: .plan) {
            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    HMTileHeader(title: "Monthly Plan", symbol: "chart.bar.doc.horizontal.fill") { HMChevron() }
                    if let plan = snapshot.plan {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(snapshot.hmPaceSentence(for: plan))
                                .font(.title3.weight(.semibold))
                            ExplorationStatusLabel(status: plan.status)
                                .font(.subheadline.weight(.semibold))
                        }
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
                            HMRemainingText(planned: plan.totalPlanned, spent: plan.totalSpent, code: code)
                            Spacer(minLength: 8)
                            Text("\(snapshot.hmDaysLeft) days to go")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    } else {
                        HMPlanInvite()
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
        HMPlanFigure(title: "Spent", value: plan.totalSpent, code: code, swatch: .spent(plan.status.tint))
        Spacer(minLength: 8)
        HMPlanFigure(title: "Projected", value: plan.totalProjected, code: code, swatch: .projected(plan.status.tint))
        Spacer(minLength: 8)
        HMPlanFigure(title: "Planned", value: plan.totalPlanned, code: code, swatch: .planned)
    }
}

// MARK: - Segmented control

/// A two-or-more option switch. With the system button look it's a segmented Picker; with the brand
/// look, the selected option is a brand-colored rounded pill that slides between options.
struct HMSegmentedControl<Value: Hashable>: View {
    let title: LocalizedStringKey
    let options: [(value: Value, label: LocalizedStringKey)]
    @Binding var selection: Value

    @Environment(\.explorationButtonLook) private var look
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var namespace

    var body: some View {
        switch look {
        case .system:
            Picker(title, selection: $selection.animation(reduceMotion ? nil : .snappy)) {
                ForEach(options.indices, id: \.self) { index in
                    Text(options[index].label).tag(options[index].value)
                }
            }
            .pickerStyle(.segmented)
        case .brandGlass(let tint):
            HStack(spacing: 4) {
                ForEach(options.indices, id: \.self) { index in
                    let option = options[index]
                    let isSelected = option.value == selection
                    Button {
                        withAnimation(reduceMotion ? nil : .snappy) {
                            selection = option.value
                        }
                    } label: {
                        Text(option.label)
                            .font(.subheadline.weight(.semibold))
                            .fontDesign(.rounded)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .frame(maxWidth: .infinity, minHeight: 34)
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(tint.gradient)
                                        .matchedGeometryEffect(id: "selection", in: namespace)
                                }
                            }
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(4)
            // A plain track rather than glass, since the control already sits on a glass tile.
            .background(tint.opacity(0.1), in: .rect(cornerRadius: 15, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text(title))
        }
    }
}

// MARK: - Label and value rows

/// A label and a value on one row.
struct HMRow<Value: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let value: Value

    init(_ title: LocalizedStringKey, @ViewBuilder value: () -> Value) {
        self.title = title
        self.value = value()
    }

    var body: some View {
        LabeledContent {
            value
                .foregroundStyle(.primary)
                .monospacedDigit()
        } label: {
            Text(title)
        }
        .padding(.vertical, 10)
    }
}

/// Income, Spending and Difference as labeled rows with dividers.
struct HMMonthRows: View {
    let snapshot: ExplorationHomeSnapshot

    private var code: String { snapshot.currencyCode }

    var body: some View {
        VStack(spacing: 0) {
            HMRow("Income") { Text(snapshot.monthIncome, format: .currency(code: code)) }
            Divider()
            HMRow("Spending") { Text(snapshot.monthSpending, format: .currency(code: code)) }
            Divider()
            HMRow("Difference") {
                Text(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))
                    .fontWeight(.semibold)
            }
        }
    }
}

/// One category as a row: icon, name, an inline bar on a shared scale, amount and share.
/// The amount column has a fixed width so every bar starts at the same x.
struct HMCategoryRow: View {
    let item: ExplorationCategorySpending
    let snapshot: ExplorationHomeSnapshot
    let scale: Double
    var verticalPadding: CGFloat = 9

    @ScaledMetric(relativeTo: .caption) private var barWidth: CGFloat = 56
    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 6
    @ScaledMetric(relativeTo: .subheadline) private var amountWidth: CGFloat = 84

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.category.symbol)
                .foregroundStyle(item.category.color)
                .frame(minWidth: 22)
                .accessibilityHidden(true)
            Text(item.category.name)
            Spacer(minLength: 8)
            Chart {
                BarMark(xStart: .value("Start", 0), xEnd: .value("Amount", item.amount.plotValue))
                    .foregroundStyle(item.category.color)
                    .cornerRadius(barHeight / 2)
            }
            .chartXScale(domain: 0...max(scale, 1))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(width: barWidth, height: barHeight)
            .accessibilityHidden(true)
            Text(item.amount, format: .currency(code: snapshot.currencyCode))
                .fontWeight(.medium)
                .monospacedDigit()
                .frame(minWidth: amountWidth, alignment: .trailing)
            Text(snapshot.hmShare(of: item.amount), format: .percent.precision(.fractionLength(0)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: 32, alignment: .trailing)
        }
        .padding(.vertical, verticalPadding)
        .accessibilityElement(children: .combine)
    }
}
#endif
