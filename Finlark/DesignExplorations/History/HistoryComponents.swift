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
                    R2SettingsScreen()
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
                R2Chevron()
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

/// Today, Yesterday or the date, and what was spent that day.
struct HYDayHeader: View {
    let day: HYDay
    let code: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            AEDateText(date: day.date)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if day.totals.spending > 0 {
                Text("Spent \(day.totals.spending, format: .currency(code: code))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .textCase(nil)
    }
}

/// A day's rows in one glass tile, with dividers.
struct HYDayTile: View {
    let day: HYDay
    let code: String
    var showsHeader = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showsHeader {
                HYDayHeader(day: day, code: code)
                    .padding(.horizontal, 6)
            }
            R2Tile(padding: 14) {
                VStack(spacing: 12) {
                    ForEach(day.records) { record in
                        if record.id != day.records.first?.id {
                            Divider()
                        }
                        NavigationLink(value: record) {
                            HYRow(record: record, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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

/// Income and spending side by side, or stacked when they don't fit (TRX-005).
struct HYTotalsRow: View {
    let totals: HYTotals
    let code: String
    var font: Font = .title3.weight(.semibold)

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) { figures }
            VStack(alignment: .leading, spacing: 10) { figures }
        }
    }

    @ViewBuilder
    private var figures: some View {
        R2Figure(title: "Income", value: totals.income, code: code, font: font)
        R2Figure(title: "Spending", value: totals.spending, code: code, font: font)
    }
}

/// Says the totals cover what's shown when filters or search narrow the list.
struct HYNarrowedNote: View {
    let store: HYStore

    var body: some View {
        if store.isSearching, store.searchesEveryMonth {
            Label("Totals for these results, across every month.", systemImage: "magnifyingglass")
        } else if store.isNarrowed {
            Label("Totals for what's shown.", systemImage: "line.3.horizontal.decrease")
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

/// Every category of the type filter as a toggle chip, in a horizontal row.
struct HYCategoryChips: View {
    @Bindable var store: HYStore

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(store.categoryOptions) { category in
                    AE2CategoryChip(category: category, isSelected: store.categoryIDs.contains(category.id)) {
                        store.toggle(category)
                    }
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
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
                    Text("Nothing this month matches these filters.")
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
#endif
