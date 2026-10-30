//
//  03-CygnusHistory.swift
//  Finlark
//
//  FIN-9 History, Round 2 "Cygnus": every month in a plain list over the backdrop. Here the day
//  headings pin as you scroll, the way Messages and Wallet keep the date in view, and each month opens
//  with a glass summary card. Rows are plain, straight on the backdrop.
//

#if DEBUG
import SwiftUI

struct CygnusHistory: View {
    @Bindable var store: HYStore

    var body: some View {
        List {
            if store.filterCount > 0 || store.month != nil {
                HY2FilterChips(store: store, showsMonth: true)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            ForEach(store.monthGroups) { group in
                Section {
                    summary(group)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }

                ForEach(group.days) { day in
                    Section {
                        ForEach(day.records) { record in
                            NavigationLink(value: record) {
                                HYRow(record: record)
                            }
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        HY2DayHeader(day: day, code: store.code)
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { R2Backdrop() }
        .overlay { HYEmptyView(store: store) }
        .hy2Chrome(store: store, allowsAllMonths: true)
    }

    private func summary(_ group: HYMonth) -> some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 10) {
                HYFormat.month(group.month)
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                HY2Figures(totals: group.totals, code: store.code, type: store.type)
                if store.isNarrowed {
                    HYNarrowedNote(store: store)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Cygnus") {
    HYHost(store: .allMonths) { CygnusHistory(store: $0) }
}

#Preview("Cygnus · Filtered") {
    HYHost(store: .filtered(month: nil)) { CygnusHistory(store: $0) }
}

#Preview("Cygnus · Empty") {
    HYHost(store: .empty) { CygnusHistory(store: $0) }
}
#endif
