//
//  05-SiriusHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Sirius": a month calendar in a glass tile. Days with spending get a dot that
//  grows with what was spent, and days with income get a plus, so the month reads at a glance. Tap a
//  day to see only that day; tap it again for the whole month. Filters change the dots too.
//

#if DEBUG
import SwiftUI

struct SiriusHistory: View {
    @Bindable var store: HYStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: r2TileSpacing) {
                if !store.records.isEmpty {
                    if !store.isSearching, let month = store.month {
                        R2Tile(padding: 14) {
                            SiriusCalendar(store: store, month: month)
                        }
                    }
                    summary
                    if store.results.isEmpty {
                        HYEmptyView(store: store)
                            .padding(.top, 24)
                    }
                    ForEach(store.days) { day in
                        HYDayTile(day: day, code: store.code, showsHeader: store.day == nil)
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
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HYFilterMenu(store: store)
            }
        }
        .searchable(text: $store.searchText, prompt: Text("Search notes"))
    }

    /// The month's totals, or the picked day's, with a way back to the whole month.
    private var summary: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Group {
                        if store.isSearching {
                            Text("Results")
                        } else if let day = store.day {
                            AEDateText(date: day)
                        } else if let month = store.month {
                            Text(month, format: .dateTime.month(.wide).year())
                        }
                    }
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: 8)
                    if store.day != nil, !store.isSearching {
                        Button("Whole month") {
                            withAnimation(reduceMotion ? nil : .snappy) { store.day = nil }
                        }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.glass)
                    }
                }
                HYTotalsRow(totals: store.totals, code: store.code)
                if store.hasFilters || store.isSearching {
                    HYNarrowedNote(store: store)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// The month as a grid, starting on the locale's first weekday, with arrows to change month.
private struct SiriusCalendar: View {
    @Bindable var store: HYStore
    let month: Date

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .callout) private var cellHeight: CGFloat = 44

    private var calendar: Calendar { .current }

    private var dates: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        return range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
    }

    /// Blank cells before the 1st.
    private var leading: Int {
        (calendar.component(.weekday, from: month) - calendar.firstWeekday + 7) % 7
    }

    private var weekdays: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var totalsByDay: [Date: HYTotals] {
        Dictionary(uniqueKeysWithValues: HYStore.days(store.results(in: month)).map { ($0.date, $0.totals) })
    }

    var body: some View {
        let totals = totalsByDay
        let largest = totals.values.map(\.spending).max() ?? 0

        VStack(spacing: 10) {
            HStack {
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Previous month", systemImage: "chevron.left") { step(by: -1) }
                    .disabled(!store.canGoBack)
                Button("Next month", systemImage: "chevron.right") { step(by: 1) }
                    .disabled(!store.canGoForward)
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 4) {
                ForEach(weekdays.indices, id: \.self) { index in
                    Text(verbatim: weekdays[index])
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                ForEach(0..<leading, id: \.self) { _ in
                    Color.clear
                        .frame(height: cellHeight)
                        .accessibilityHidden(true)
                }
                ForEach(dates, id: \.self) { date in
                    cell(date, totals: totals[date], largest: largest)
                }
            }
            // Seven columns can't take accessibility sizes, as in Calendar. Each day still reads in full
            // to VoiceOver, and the list below scales.
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }

    private func cell(_ date: Date, totals: HYTotals?, largest: Decimal) -> some View {
        let isSelected = store.day.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > .now
        let spending = totals?.spending ?? 0
        let income = totals?.income ?? 0
        let ratio = largest > 0 ? spending.plotValue / largest.plotValue : 0

        return Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                store.day = isSelected ? nil : date
            }
        } label: {
            VStack(spacing: 3) {
                Text(date, format: .dateTime.day())
                    .font(.callout.weight(isToday || isSelected ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isSelected ? Color.white : isFuture ? Color.secondary : Color.primary)
                HStack(spacing: 2) {
                    if spending > 0 {
                        Circle()
                            .fill(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
                            .frame(width: 4 + 4 * ratio, height: 4 + 4 * ratio)
                    }
                    if income > 0 {
                        Image(systemName: "plus")
                            .font(.system(size: 8, weight: .heavy))
                            .foregroundStyle(isSelected ? Color.white : Color.secondary)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity, minHeight: cellHeight)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.tint)
                } else if isToday {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.tint, lineWidth: 1.5)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(totals == nil)
        .accessibilityLabel(Text(date, format: .dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(value(spending: spending, income: income, hasTransactions: totals != nil))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func value(spending: Decimal, income: Decimal, hasTransactions: Bool) -> Text {
        guard hasTransactions else { return Text("No transactions") }
        let code = store.code
        if spending > 0, income > 0 {
            return Text("Spent \(spending.formatted(.currency(code: code))), income \(income.formatted(.currency(code: code)))")
        } else if income > 0 {
            return Text("Income \(income.formatted(.currency(code: code)))")
        }
        return Text("Spent \(spending.formatted(.currency(code: code)))")
    }

    private func step(by months: Int) {
        withAnimation(reduceMotion ? nil : .snappy) { store.step(by: months) }
    }
}

#Preview("Sirius") {
    HYHost { SiriusHistory(store: $0) }
}

#Preview("Sirius · Empty") {
    HYHost(store: .empty) { SiriusHistory(store: $0) }
}
#endif
