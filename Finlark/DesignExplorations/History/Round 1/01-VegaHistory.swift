//
//  01-VegaHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Vega": the native list, like Mail or Wallet. The month is the title, and
//  tapping it opens a menu of months. Income and spending sit in the first section; then a section per
//  day. Filter is a toolbar menu with the type and a checklist of categories. Search sits in the
//  navigation bar and looks through every month.
//

#if DEBUG
import SwiftUI

struct VegaHistory: View {
    @Bindable var store: HYStore

    var body: some View {
        List {
            if !store.records.isEmpty, !store.results.isEmpty {
                Section {
                    HYTotalsRow(totals: store.totals, code: store.code)
                        .padding(.vertical, 4)
                } footer: {
                    HYNarrowedNote(store: store)
                }
            }

            ForEach(store.days) { day in
                Section {
                    ForEach(day.records) { record in
                        NavigationLink(value: record) {
                            HYRow(record: record)
                        }
                    }
                } header: {
                    HYDayHeader(day: day, code: store.code)
                }
            }
        }
        .overlay { HYEmptyView(store: store) }
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
        if store.isSearching {
            Text("Results")
        } else if let month = store.month {
            Text(month, format: .dateTime.month(.wide).year())
        } else {
            Text("History")
        }
    }
}

#Preview("Vega") {
    HYHost { VegaHistory(store: $0) }
}

#Preview("Vega · Searching") {
    HYHost(store: .searching) { VegaHistory(store: $0) }
}

#Preview("Vega · Empty") {
    HYHost(store: .empty) { VegaHistory(store: $0) }
}
#endif
