//
//  Round3Components.swift
//  Finlark
//
//  FIN-9 Round 3: shared pieces for the tab bar variations of Round 2's Facet Home. The Facet content
//  is reused without its floating add button, and the Transactions and Settings tabs are light mocks
//  so the shell feels real. Only the tab bar and the quick-add placement differ between variations.
//

#if DEBUG
import SwiftUI

// MARK: - Routing

/// Lets Home's links switch tabs. Destinations listed in `tabDestinations` are tabs in the current shell,
/// so links to them set `requested` (the shell switches tab) instead of pushing a screen.
@Observable
final class R3TabRouter {
    let tabDestinations: Set<ExplorationDestination>
    var requested: ExplorationDestination?

    init(tabDestinations: Set<ExplorationDestination>) {
        self.tabDestinations = tabDestinations
    }
}

/// Pushes the destination, or switches to its tab when the shell has one for it.
struct R3Link<Label: View>: View {
    let destination: ExplorationDestination
    @ViewBuilder let label: Label

    @Environment(R3TabRouter.self) private var router: R3TabRouter?

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
    func r3Destinations() -> some View {
        navigationDestination(for: ExplorationDestination.self) { destination in
            ExplorationPlaceholderScreen(destination: destination)
        }
    }

    /// The add sheet (TRX-001/TRX-002), presented above the whole tab view.
    func r3AddSheet(_ model: ExplorationHomeModel) -> some View {
        modifier(R3AddSheet(model: model))
    }
}

private struct R3AddSheet: ViewModifier {
    @Bindable var model: ExplorationHomeModel

    func body(content: Content) -> some View {
        content.sheet(item: $model.addingType) { type in
            ExplorationAddSheet(type: type, currencyCode: model.snapshot.currencyCode)
        }
    }
}

/// A toolbar add button: tap adds an expense, long press offers income (HOM-007).
struct R3AddMenuButton: View {
    let model: ExplorationHomeModel

    var body: some View {
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

// MARK: - Facet Home content

/// Round 2 Facet without its floating add button and navigation stack.
struct R3FacetHome: View {
    let model: ExplorationHomeModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var donutSize: CGFloat = 84
    @ScaledMetric private var chipWidth: CGFloat = 150

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
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
                        R3Link(destination: .history) {
                            Text("See all")
                        }
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
        R3Link(destination: .plan) {
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
        R3Link(destination: .people) {
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
                        R3TransactionChip(transaction: transaction, code: code)
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

// MARK: - Transactions tab (mock of TRX-005)

struct R3TransactionsScreen: View {
    let model: ExplorationHomeModel
    var isSearchable = true

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
            if days.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .modifier(R3OptionalSearch(isEnabled: isSearchable, text: $searchText))
    }
}

private struct R3OptionalSearch: ViewModifier {
    let isEnabled: Bool
    @Binding var text: String

    func body(content: Content) -> some View {
        if isEnabled {
            content.searchable(text: $text, prompt: Text("Search notes"))
        } else {
            content
        }
    }
}

// MARK: - Settings tab (mock of SET-001)

struct R3SettingsScreen: View {
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
#endif
