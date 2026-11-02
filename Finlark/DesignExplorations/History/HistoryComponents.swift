//
//  HistoryComponents.swift
//  Finlark
//
//  FIN-9 History: pieces shared by the History explorations (TRX-005). The host is Marsh's tab bar
//  with History selected and its "+" menu (TRX-001); a row pushes Birch (TRX-006). Marsh's look
//  throughout: the tinted backdrop, glass tiles, soft icons, system glass buttons.
//

#if DEBUG
import SwiftUI

// MARK: - Host

/// Marsh's tab bar with History open. "+" adds through Dunlin, and a row opens Birch.
struct HYHost<History: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    /// Dunlin needs a fresh draft each time, and a draft isn't Identifiable.
    private struct NewDraft: Identifiable {
        let id = UUID()
        let draft: AEDraft
    }

    @State private var store: HYStore
    @State private var selection: AppTab = .history
    @State private var adding: NewDraft?
    private let history: (HYStore) -> History

    init(store: HYStore = .sample, @ViewBuilder history: @escaping (HYStore) -> History) {
        _store = State(initialValue: store)
        self.history = history
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                ContentUnavailableView {
                    Label("Home", systemImage: "house")
                } description: {
                    Text("Marsh isn't part of the History exploration.")
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                NavigationStack {
                    history(store)
                        .toolbar { addMenu }
                        .navigationDestination(for: TDRecord.self) { BirchDetail(record: $0) }
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    HMSettingsScreen()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(item: $adding) { new in
            DunlinEditor(draft: new.draft) { store.add(new.draft) }
        }
        .environment(\.explorationIconStyle, .soft)
    }

    /// Marsh's "+": tap adds an expense, hold offers income.
    private var addMenu: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Add expense", systemImage: "arrow.up.right") { add(.expense) }
                Button("Add income", systemImage: "arrow.down.left") { add(.income) }
            } label: {
                Label("Add transaction", systemImage: "plus")
            } primaryAction: {
                add(.expense)
            }
            .buttonStyle(.glassProminent)
        }
    }

    private func add(_ type: ExplorationTransactionType) {
        adding = NewDraft(draft: .new(type))
    }
}

// MARK: - Rows

/// A History row: category icon, note and category name, the amount paid and, for a split, the user's
/// share (TRX-005). At accessibility sizes the amounts move under the text.
struct HYRow: View {
    let record: TDRecord
    var showsChevron = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(spacing: 12))

        HStack(spacing: 10) {
            layout {
                HStack(spacing: 12) {
                    if let category = record.saved.category {
                        ExplorationCategoryIcon(category: category)
                    }
                    HYRowTitle(record: record)
                }
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: 8)
                }
                HYAmounts(record: record, alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
            }
            if showsChevron {
                HMChevron()
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// The note, with the category name under it, or just the category name when there's no note.
struct HYRowTitle: View {
    let record: TDRecord

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            record.title
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            if !record.saved.note.isEmpty, let category = record.saved.category {
                Text(category.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

/// The amount paid with its sign and, for a split, the two-people icon and the user's share (TRX-005).
struct HYAmounts: View {
    let record: TDRecord
    var alignment: HorizontalAlignment = .trailing

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(record.signedAmount, format: .currency(code: record.code).sign(strategy: .always()))
                .fontWeight(.medium)
                .monospacedDigit()
            if record.isSplit {
                HYSplitLabel(record: record)
            }
        }
    }
}

struct HYSplitLabel: View {
    let record: TDRecord

    var body: some View {
        Label {
            Text("Your share \(record.myShare, format: .currency(code: record.code))")
        } icon: {
            Image(systemName: "person.2.fill")
                .accessibilityLabel(Text("Split"))
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .monospacedDigit()
        .lineLimit(1)
    }
}

// MARK: - Months and totals

enum HYFormat {
    /// "October", or "October 2025" outside the current year.
    static func month(_ date: Date) -> Text {
        if Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) {
            Text(date, format: .dateTime.month(.wide))
        } else {
            Text(date, format: .dateTime.month(.wide).year())
        }
    }

    /// "Oct", or "Oct 25" outside the current year.
    static func shortMonth(_ date: Date) -> Text {
        if Calendar.current.isDate(date, equalTo: .now, toGranularity: .year) {
            Text(date, format: .dateTime.month(.abbreviated))
        } else {
            Text(date, format: .dateTime.month(.abbreviated).year(.twoDigits))
        }
    }
}

// MARK: - Filters

/// A picker of the months that have transactions.
struct HYMonthPicker: View {
    @Bindable var store: HYStore
    var allowsAllMonths = false

    var body: some View {
        Picker("Month", selection: $store.month) {
            if allowsAllMonths {
                Text("All months").tag(Date?.none)
            }
            ForEach(store.months, id: \.self) { month in
                Text(month, format: .dateTime.month(.wide).year()).tag(Optional(month))
            }
        }
    }
}

/// Type and categories in one toolbar menu that stays open while you pick (TRX-005).
struct HYFilterMenu: View {
    @Bindable var store: HYStore

    var body: some View {
        Menu {
            Picker("Type", selection: $store.type) {
                ForEach(HYTypeFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.inline)

            Section("Categories") {
                ForEach(store.categoryOptions) { category in
                    Toggle(isOn: store.isSelected(category)) {
                        Label {
                            Text(category.name)
                        } icon: {
                            Image(systemName: category.symbol)
                        }
                    }
                }
            }

            if store.hasFilters {
                Button("Clear filters", systemImage: "xmark.circle") { store.clearFilters() }
            }
        } label: {
            Label(
                "Filter",
                systemImage: store.hasFilters
                    ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease"
            )
        }
        .menuActionDismissBehavior(.disabled)
        .accessibilityValue(store.hasFilters ? Text("\(store.filterCount) on") : Text("Off"))
    }
}

// MARK: - Empty states

/// First launch, a month with nothing in it, filters that match nothing, or a search with no results.
struct HYEmptyView: View {
    let store: HYStore

    var body: some View {
        if store.records.isEmpty {
            ContentUnavailableView {
                Label("No transactions yet", systemImage: "clock.arrow.circlepath")
            } description: {
                Text("Expenses and income you add show up here, newest first.")
            }
        } else if store.results.isEmpty {
            if store.isSearching {
                ContentUnavailableView.search(text: store.searchText)
            } else if store.hasFilters {
                ContentUnavailableView {
                    Label("No matches", systemImage: "line.3.horizontal.decrease.circle")
                } description: {
                    if store.month == nil {
                        Text("Nothing matches these filters.")
                    } else {
                        Text("Nothing this month matches these filters.")
                    }
                } actions: {
                    Button("Clear filters") { store.clearFilters() }
                        .buttonStyle(.glass)
                }
            } else {
                ContentUnavailableView {
                    Label("Nothing this month", systemImage: "calendar")
                } description: {
                    Text("No transactions in this month yet.")
                }
            }
        }
    }
}

// MARK: - Bar

/// Filter on the left, the month as the title with its menu, "+" from the host, and search in notes.
struct HYChrome: ViewModifier {
    @Bindable var store: HYStore
    /// Offers "All months" in the title menu, for the variants that show every month in one scroll.
    var allowsAllMonths = false

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu {
                HYMonthPicker(store: store, allowsAllMonths: allowsAllMonths)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HYFilterMenu(store: store)
                }
            }
            .searchable(text: $store.searchText, prompt: Text("Search notes"))
    }

    private var title: Text {
        if store.isSearching {
            Text("Results")
        } else if let month = store.month {
            Text(month, format: .dateTime.month(.wide).year())
        } else {
            Text("History")
        }
    }
}

extension View {
    func hyChrome(store: HYStore, allowsAllMonths: Bool = false) -> some View {
        modifier(HYChrome(store: store, allowsAllMonths: allowsAllMonths))
    }
}

// MARK: - Filter chips

/// What's filtered, one chip each; tapping a chip removes it. Hidden when nothing is filtered.
struct HYFilterChips: View {
    @Bindable var store: HYStore
    /// Shows the month as a chip too, for the variants where removing it goes back to every month.
    var showsMonth = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var monthChip: Date? {
        showsMonth && !store.isSearching ? store.month : nil
    }

    private var count: Int { store.filterCount + (monthChip == nil ? 0 : 1) }

    var body: some View {
        if count > 0 {
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    if let month = monthChip {
                        HYChip(symbol: "calendar", tint: .accentColor) {
                            Text(month, format: .dateTime.month(.wide).year())
                        } action: {
                            remove { store.month = nil }
                        }
                    }
                    if let type = store.type.type {
                        HYChip(symbol: type.symbol, tint: .accentColor) {
                            Text(store.type.title)
                        } action: {
                            remove { store.type = .all }
                        }
                    }
                    ForEach(store.selectedCategories) { category in
                        HYChip(symbol: category.symbol, tint: category.color) {
                            Text(category.name)
                        } action: {
                            remove { store.toggle(category) }
                        }
                    }
                    if count > 1 {
                        Button("Clear all") {
                            remove {
                                store.clearFilters()
                                if showsMonth { store.month = nil }
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.borderless)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Filters"))
        }
    }

    private func remove(_ change: () -> Void) {
        withAnimation(reduceMotion ? nil : .snappy) { change() }
    }
}

/// A glass capsule with an icon, a name and an ×.
struct HYChip<Title: View>: View {
    let symbol: String
    let tint: Color
    @ViewBuilder var title: Title
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
                    .accessibilityHidden(true)
                title
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Removes this filter"))
    }
}

// MARK: - Month summary

/// A month's name and difference on one line, income and spending under them. Pinned while its days
/// scroll by, in the variants that show every month.
struct HYMonthBar: View {
    let group: HYMonth
    let code: String
    /// With a type filter on, that type's total takes the difference's place and the line under goes.
    var type: HYTypeFilter = .all

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let totals = group.totals
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        VStack(alignment: .leading, spacing: 4) {
            layout {
                HYFormat.month(group.month)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: 0)
                }
                headline(totals)
                    .font(.headline)
                    .monospacedDigit()
            }
            if type == .all {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) { flows(totals) }
                    VStack(alignment: .leading, spacing: 2) { flows(totals) }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func headline(_ totals: HYTotals) -> some View {
        switch type {
        case .all:
            Text(totals.difference, format: .currency(code: code).sign(strategy: .always()))
                .accessibilityLabel(Text("Difference \(totals.difference.formatted(.currency(code: code).sign(strategy: .always())))"))
        case .expense:
            Text("Spent \(totals.spending, format: .currency(code: code))")
        case .income:
            Text("Income \(totals.income, format: .currency(code: code))")
        }
    }

    @ViewBuilder
    private func flows(_ totals: HYTotals) -> some View {
        Text("Income \(totals.income, format: .currency(code: code))")
        Text("Spending \(totals.spending, format: .currency(code: code))")
    }
}

// MARK: - Days (plain rows)

/// A day heading: the day, and what was spent, in quiet secondary type.
struct HYDayHeader: View {
    let day: HYDay
    let code: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            AEDateText(date: day.date)
                .font(.subheadline.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if day.totals.spending > 0 {
                Text("Spent \(day.totals.spending, format: .currency(code: code))")
                    .font(.footnote)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(.secondary)
    }
}

/// A day's heading and its rows, straight on the backdrop with inset dividers: no tile, no glass.
struct HYPlainDay: View {
    let day: HYDay
    let code: String

    @ScaledMetric private var dividerInset: CGFloat = 48

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HYDayHeader(day: day, code: code)
                .padding(.bottom, 4)
            ForEach(day.records) { record in
                if record.id != day.records.first?.id {
                    Divider()
                        .padding(.leading, dividerInset)
                }
                NavigationLink(value: record) {
                    HYRow(record: record, showsChevron: true)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Samples

extension HYStore {
    /// Expenses in Dining and Groceries, to show the chips. `month` nil keeps every month.
    static func filtered(month: Date? = .now) -> HYStore {
        let store = HYStore(sampleRecords, month: month)
        store.type = .expense
        store.categoryIDs = [ExplorationCategory.dining.id, ExplorationCategory.groceries.id]
        return store
    }
}
#endif
