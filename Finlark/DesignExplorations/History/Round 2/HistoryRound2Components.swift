//
//  HistoryRound2Components.swift
//  Finlark
//
//  FIN-9 History, Round 2: what every Round 2 variant shares, from the owner's picks in Round 1.
//  Vega's bar (Filter, the month as the title's menu, "+"), a month summary with income, spending and
//  the difference, Mira's chips for what's filtered, each removable in place, Antares' day headings
//  with what was spent, and plain rows instead of glass ones.
//

#if DEBUG
import SwiftUI

// MARK: - Bar (Vega)

/// Filter on the left, the month as the title with its menu, "+" from the host, and search in notes.
struct HY2Chrome: ViewModifier {
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
    func hy2Chrome(store: HYStore, allowsAllMonths: Bool = false) -> some View {
        modifier(HY2Chrome(store: store, allowsAllMonths: allowsAllMonths))
    }
}

// MARK: - Filter chips (Mira)

/// What's filtered, one chip each; tapping a chip removes it. Hidden when nothing is filtered.
struct HY2FilterChips: View {
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
                        HY2Chip(symbol: "calendar", tint: .accentColor) {
                            Text(month, format: .dateTime.month(.wide).year())
                        } action: {
                            remove { store.month = nil }
                        }
                    }
                    if let type = store.type.type {
                        HY2Chip(symbol: type.symbol, tint: .accentColor) {
                            Text(store.type.title)
                        } action: {
                            remove { store.type = .all }
                        }
                    }
                    ForEach(store.selectedCategories) { category in
                        HY2Chip(symbol: category.symbol, tint: category.color) {
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
struct HY2Chip<Title: View>: View {
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
struct HY2MonthBar: View {
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

/// A day heading in Antares' style: the day, and what was spent, in quiet secondary type.
struct HY2DayHeader: View {
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
struct HY2PlainDay: View {
    let day: HYDay
    let code: String

    @ScaledMetric private var dividerInset: CGFloat = 48

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HY2DayHeader(day: day, code: code)
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
