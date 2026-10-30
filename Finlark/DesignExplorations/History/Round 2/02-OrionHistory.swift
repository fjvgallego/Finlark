//
//  02-OrionHistory.swift
//  Finlark
//
//  FIN-9 History, Round 2 "Orion": Vega made complete, the most native option. One month at a time in
//  a grouped list; the summary section adds the difference; Mira's chips sit above it; days are list
//  sections with Antares' headings. Rows sit in the list's own cells, with no glass.
//

#if DEBUG
import SwiftUI

struct OrionHistory: View {
    @Bindable var store: HYStore

    var body: some View {
        List {
            if store.hasFilters {
                Section {
                    HY2FilterChips(store: store)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                .listSectionSpacing(.compact)
            }

            if !store.results.isEmpty {
                Section {
                    HY2Figures(totals: store.totals, code: store.code, type: store.type)
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
        .hy2Chrome(store: store)
    }
}

#Preview("Orion") {
    HYHost { OrionHistory(store: $0) }
}

#Preview("Orion · Filtered") {
    HYHost(store: .filtered()) { OrionHistory(store: $0) }
}

#Preview("Orion · Empty") {
    HYHost(store: .empty) { OrionHistory(store: $0) }
}
#endif
