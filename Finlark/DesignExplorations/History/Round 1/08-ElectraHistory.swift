//
//  08-ElectraHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Electra": a ledger, like a bank statement. One line per transaction in a
//  single tile, the day down the left, and two money columns: Paid, what left or entered the account,
//  and Yours, the share that counts as spending on a split. Totals close the tile. At accessibility
//  sizes it falls back to the regular rows.
//

#if DEBUG
import SwiftUI

struct ElectraHistory: View {
    @Bindable var store: HYStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(spacing: r2TileSpacing) {
                if !store.records.isEmpty {
                    if store.results.isEmpty {
                        HYEmptyView(store: store)
                            .padding(.top, 24)
                    } else if dynamicTypeSize.isAccessibilitySize {
                        totalsTile
                        ForEach(store.days) { day in
                            HYDayTile(day: day, code: store.code)
                        }
                    } else {
                        ledger
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
    }

    private var title: Text {
        if let month = store.month, !store.isSearching {
            Text(month, format: .dateTime.month(.wide).year())
        } else {
            Text("Results")
        }
    }

    private var totalsTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 8) {
                HYTotalsRow(totals: store.totals, code: store.code)
                HYNarrowedNote(store: store)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Ledger

    private var ledger: some View {
        R2Tile(padding: 14) {
            VStack(spacing: 0) {
                ElectraColumns {
                    Text("Day")
                } item: {
                    Text("Item")
                } paid: {
                    Text("Paid")
                } yours: {
                    Text("Yours")
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.bottom, 8)
                .accessibilityHidden(true)

                ForEach(store.days) { day in
                    Divider()
                        .overlay(.primary.opacity(0.25))
                    ForEach(day.records) { record in
                        if record.id != day.records.first?.id {
                            Divider()
                                .padding(.leading, 40)
                        }
                        NavigationLink(value: record) {
                            line(record, day: day)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider()
                    .overlay(.primary.opacity(0.4))
                totals
                    .padding(.top, 12)
            }
        }
    }

    private func line(_ record: TDRecord, day: HYDay) -> some View {
        let isFirst = record.id == day.records.first?.id

        return ElectraColumns {
            if isFirst {
                VStack(spacing: 0) {
                    Text(day.date, format: .dateTime.day())
                        .font(.headline)
                        .monospacedDigit()
                    Text(day.date, format: .dateTime.weekday(.abbreviated))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                }
            } else {
                Color.clear
                    .frame(height: 1)
            }
        } item: {
            HStack(spacing: 8) {
                if let category = record.saved.category {
                    Image(systemName: category.symbol)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(category.color)
                        .frame(width: 18)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 1) {
                    record.title
                        .font(.subheadline)
                        .lineLimit(1)
                    if !record.saved.note.isEmpty, let category = record.saved.category {
                        Text(category.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        } paid: {
            Text(record.signedAmount, format: .currency(code: record.code).sign(strategy: .always()))
                .font(.subheadline.weight(.medium))
        } yours: {
            if record.isSplit {
                Label {
                    Text(record.myShare, format: .currency(code: record.code))
                } icon: {
                    Image(systemName: "person.2.fill")
                }
                .labelStyle(ElectraTrailingIconStyle())
                .font(.subheadline)
            } else {
                Text(verbatim: "–")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 10)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(record, day: day))
        .accessibilityAddTraits(.isButton)
    }

    private func accessibilityLabel(_ record: TDRecord, day: HYDay) -> Text {
        let amount = record.signedAmount.formatted(.currency(code: record.code).sign(strategy: .always()))
        let date = day.date.formatted(.dateTime.weekday(.wide).day().month(.wide))
        let category = record.saved.category.map { String(localized: $0.name) } ?? ""
        if record.isSplit {
            let share = record.myShare.formatted(.currency(code: record.code))
            return Text("\(record.title), \(category), \(date). Paid \(amount). Split, your share \(share)")
        }
        return Text("\(record.title), \(category), \(date). \(amount)")
    }

    private var totals: some View {
        VStack(alignment: .leading, spacing: 8) {
            HYTotalsRow(totals: store.totals, code: store.code, font: .headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            HYNarrowedNote(store: store)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

/// The ledger's four columns, with fixed widths for the day and money so they line up down the tile.
private struct ElectraColumns<Day: View, Item: View, Paid: View, Yours: View>: View {
    @ViewBuilder var day: Day
    @ViewBuilder var item: Item
    @ViewBuilder var paid: Paid
    @ViewBuilder var yours: Yours

    @ScaledMetric(relativeTo: .subheadline) private var dayWidth: CGFloat = 32
    @ScaledMetric(relativeTo: .subheadline) private var paidWidth: CGFloat = 86
    @ScaledMetric(relativeTo: .subheadline) private var yoursWidth: CGFloat = 72

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            day
                .frame(width: dayWidth)
            item
                .frame(maxWidth: .infinity, alignment: .leading)
            paid
                .frame(width: paidWidth, alignment: .trailing)
            yours
                .frame(width: yoursWidth, alignment: .trailing)
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }
}

private struct ElectraTrailingIconStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.icon
                .font(.caption2)
                .foregroundStyle(.secondary)
            configuration.title
        }
    }
}

#Preview("Electra") {
    HYHost { ElectraHistory(store: $0) }
}

#Preview("Electra · Empty") {
    HYHost(store: .empty) { ElectraHistory(store: $0) }
}
#endif
