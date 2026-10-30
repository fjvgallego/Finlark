//
//  04-DracoHistory.swift
//  Finlark
//
//  FIN-9 History, Round 2 "Draco": a middle ground on glass. Every month in one scroll, and each month
//  is a single glass card: its summary at the top, then its days with plain rows inside. One surface
//  per month instead of one per day, and nothing pins.
//

#if DEBUG
import SwiftUI

struct DracoHistory: View {
    @Bindable var store: HYStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HY2FilterChips(store: store, showsMonth: true)

                ForEach(store.monthGroups) { group in
                    card(group)
                        .padding(.horizontal)
                }

                if !store.records.isEmpty, store.results.isEmpty {
                    HYEmptyView(store: store)
                        .padding(.top, 24)
                }
            }
            .padding(.vertical)
        }
        .background { R2Backdrop() }
        .overlay {
            if store.records.isEmpty {
                HYEmptyView(store: store)
            }
        }
        .hy2Chrome(store: store, allowsAllMonths: true)
    }

    private func card(_ group: HYMonth) -> some View {
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 0) {
                HYFormat.month(group.month)
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 10)
                HY2Figures(totals: group.totals, code: store.code, type: store.type)
                if store.isNarrowed {
                    HYNarrowedNote(store: store)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                Divider()
                    .padding(.vertical, 14)
                VStack(spacing: 18) {
                    ForEach(group.days) { day in
                        HY2PlainDay(day: day, code: store.code)
                    }
                }
            }
        }
    }
}

#Preview("Draco") {
    HYHost(store: .allMonths) { DracoHistory(store: $0) }
}

#Preview("Draco · Filtered") {
    HYHost(store: .filtered()) { DracoHistory(store: $0) }
}

#Preview("Draco · Empty") {
    HYHost(store: .empty) { DracoHistory(store: $0) }
}
#endif
