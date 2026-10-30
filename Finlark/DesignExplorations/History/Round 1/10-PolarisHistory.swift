//
//  10-PolarisHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Polaris": months first. History opens on a card per month, the current one
//  wide, each with its income, spending and how many transactions, so months compare at a glance. A
//  card pushes that month's days, with the type and category filters at the top. Search on the first
//  screen looks through every month.
//

#if DEBUG
import SwiftUI

struct PolarisHistory: View {
    @Bindable var store: HYStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: r2TileSpacing) {
                if store.isSearching {
                    if !store.results.isEmpty {
                        R2Tile {
                            VStack(alignment: .leading, spacing: 8) {
                                HYTotalsRow(totals: store.totals, code: store.code)
                                HYNarrowedNote(store: store)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    ForEach(store.days) { day in
                        HYDayTile(day: day, code: store.code)
                    }
                } else if !store.records.isEmpty {
                    cards
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .overlay {
            if store.records.isEmpty || store.isSearching {
                HYEmptyView(store: store)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: PolarisMonth.self) { month in
            PolarisMonthScreen(store: store, month: month.date)
        }
        .searchable(text: $store.searchText, prompt: Text("Search notes"))
    }

    private var cards: some View {
        let months = store.months
        let columns = dynamicTypeSize.isAccessibilitySize ? 1 : 2

        return VStack(spacing: r2TileSpacing) {
            if let current = months.first {
                card(current, isWide: true)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: r2TileSpacing), count: columns),
                spacing: r2TileSpacing
            ) {
                ForEach(months.dropFirst(), id: \.self) { month in
                    card(month, isWide: false)
                }
            }
        }
    }

    private func card(_ month: Date, isWide: Bool) -> some View {
        let records = store.records.filter { Calendar.current.isDate($0.saved.date, equalTo: month, toGranularity: .month) }
        let totals = HYTotals(records)

        return NavigationLink(value: PolarisMonth(date: month)) {
            R2Tile(padding: isWide ? 18 : 14) {
                VStack(alignment: .leading, spacing: isWide ? 12 : 8) {
                    HStack(alignment: .firstTextBaseline) {
                        HYFormat.month(month)
                            .font(isWide ? .title3.weight(.bold) : .headline)
                        Spacer(minLength: 4)
                        R2Chevron()
                    }
                    if isWide {
                        HYTotalsRow(totals: totals, code: store.code, font: .title2.weight(.bold))
                            .fontDesign(.rounded)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            R2Figure(title: "Income", value: totals.income, code: store.code, font: .subheadline.weight(.semibold))
                            R2Figure(title: "Spending", value: totals.spending, code: store.code, font: .subheadline.weight(.semibold))
                        }
                    }
                    Text("\(records.count) transactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

private struct PolarisMonth: Hashable {
    let date: Date
}

/// One month's days, with the type and category filters and the totals for what's shown.
private struct PolarisMonthScreen: View {
    @Bindable var store: HYStore
    let month: Date

    private var results: [TDRecord] { store.results(in: month) }

    var body: some View {
        let results = results
        let days = HYStore.days(results)

        ScrollView {
            VStack(spacing: r2TileSpacing) {
                R2Tile {
                    VStack(alignment: .leading, spacing: 8) {
                        HYTotalsRow(totals: HYTotals(results), code: store.code)
                        if store.hasFilters {
                            Label("Totals for what's shown.", systemImage: "line.3.horizontal.decrease")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)

                R6SegmentedControl(
                    title: "Type",
                    options: HYTypeFilter.allCases.map { (value: $0, label: $0.title) },
                    selection: $store.type
                )
                .padding(.horizontal)
                HYCategoryChips(store: store)

                if results.isEmpty {
                    ContentUnavailableView {
                        Label("No matches", systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text("Nothing this month matches these filters.")
                    } actions: {
                        Button("Clear filters") { store.clearFilters() }
                            .buttonStyle(.glass)
                    }
                    .padding(.top, 24)
                }

                ForEach(days) { day in
                    HYDayTile(day: day, code: store.code)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background { R2Backdrop() }
        .navigationTitle(Text(month, format: .dateTime.month(.wide).year()))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Polaris") {
    HYHost { PolarisHistory(store: $0) }
}

#Preview("Polaris · Empty") {
    HYHost(store: .empty) { PolarisHistory(store: $0) }
}
#endif
