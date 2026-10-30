//
//  07-CapellaHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Capella": the month's spending as a bar per day, at the top in a glass tile
//  with the totals. Drag across the bars to pick a day and the list shows just that day; "All days"
//  brings the month back. The month is the title's menu, as in Vega. Filters change the bars too.
//

#if DEBUG
import SwiftUI
import Charts

struct CapellaHistory: View {
    @Bindable var store: HYStore

    var body: some View {
        ScrollView {
            VStack(spacing: r2TileSpacing) {
                if !store.records.isEmpty {
                    if store.isSearching {
                        R2Tile {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Results")
                                    .font(.headline)
                                    .accessibilityAddTraits(.isHeader)
                                HYTotalsRow(totals: store.totals, code: store.code)
                                HYNarrowedNote(store: store)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else if let month = store.month {
                        CapellaChartTile(store: store, month: month)
                    }
                    if store.results.isEmpty {
                        HYEmptyView(store: store)
                            .padding(.top, 24)
                    }
                    ForEach(store.days) { day in
                        HYDayTile(day: day, code: store.code)
                    }
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .overlay {
            if store.records.isEmpty {
                HYEmptyView(store: store)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarTitleMenu {
            HYMonthPicker(store: store)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HYFilterMenu(store: store)
            }
        }
        .searchable(text: $store.searchText, prompt: Text("Search notes"))
        .onChange(of: store.month) { store.day = nil }
    }

    private var title: Text {
        if let month = store.month, !store.isSearching {
            Text(month, format: .dateTime.month(.wide).year())
        } else {
            Text("History")
        }
    }
}

private struct CapellaChartTile: View {
    @Bindable var store: HYStore
    let month: Date

    @State private var scrubbed: Date?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Point: Identifiable {
        let date: Date
        let spending: Decimal
        var id: Date { date }
    }

    private var calendar: Calendar { .current }

    /// Every day of the month up to today, so empty days keep their place on the axis.
    private var points: [Point] {
        let spending = Dictionary(uniqueKeysWithValues: HYStore.days(store.results(in: month)).map {
            ($0.date, $0.totals.spending)
        })
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
            .filter { $0 <= .now }
            .map { Point(date: $0, spending: spending[$0] ?? 0) }
    }

    private var monthEnd: Date {
        calendar.date(byAdding: .month, value: 1, to: month) ?? month
    }

    var body: some View {
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Group {
                        if let day = store.day {
                            AEDateText(date: day)
                        } else {
                            Text("Spending by day")
                        }
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    if store.day != nil {
                        Button("All days") {
                            withAnimation(reduceMotion ? nil : .snappy) { store.day = nil }
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.glass)
                    }
                }

                HYTotalsRow(totals: store.totals, code: store.code)

                chart
                    .frame(height: 120)

                if store.hasFilters {
                    HYNarrowedNote(store: store)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var chart: some View {
        Chart(points) { point in
            BarMark(
                x: .value("Day", point.date, unit: .day),
                y: .value("Spending", point.spending.plotValue)
            )
            .foregroundStyle(isHighlighted(point.date) ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.3)))
            .clipShape(.rect(cornerRadius: 2))
            .accessibilityLabel(Text(point.date, format: .dateTime.weekday(.wide).day().month(.wide)))
            .accessibilityValue(Text(point.spending, format: .currency(code: store.code)))
        }
        .chartXScale(domain: month...monthEnd)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: 7)) {
                AxisValueLabel(format: .dateTime.day())
            }
        }
        .chartYAxis(.hidden)
        // Rent would flatten every other day on a linear scale.
        .chartYScale(type: .squareRoot)
        .chartXSelection(value: $scrubbed)
        .onChange(of: scrubbed) { _, date in
            guard let date else { return }
            let day = calendar.startOfDay(for: date)
            if store.day != day, day <= .now {
                store.day = day
            }
        }
        .sensoryFeedback(.selection, trigger: store.day)
        .accessibilityHint(Text("Drag across the bars to show one day"))
    }

    private func isHighlighted(_ date: Date) -> Bool {
        guard let day = store.day else { return true }
        return calendar.isDate(day, inSameDayAs: date)
    }
}

#Preview("Capella") {
    HYHost { CapellaHistory(store: $0) }
}

#Preview("Capella · Empty") {
    HYHost(store: .empty) { CapellaHistory(store: $0) }
}
#endif
