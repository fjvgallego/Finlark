//
//  05-CarinaHistory.swift
//  Finlark
//
//  FIN-9 History, Round 2 "Carina": one month at a time with the most rows on screen. The summary moves
//  to a glass bar above the tab bar, as in Mira, now with the difference, so it stays in view while
//  the days scroll. The chips and the rows are all that's left at the top.
//

#if DEBUG
import SwiftUI

struct CarinaHistory: View {
    @Bindable var store: HYStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HY2FilterChips(store: store)

                // At accessibility sizes the bar would cover the rows, so the summary scrolls with them.
                if dynamicTypeSize.isAccessibilitySize, !store.results.isEmpty {
                    summaryBar
                }

                if !store.records.isEmpty, store.results.isEmpty {
                    HYEmptyView(store: store)
                        .padding(.top, 24)
                }

                ForEach(store.days) { day in
                    HY2PlainDay(day: day, code: store.code)
                        .padding(.horizontal, 20)
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
        .safeAreaInset(edge: .bottom) {
            if !dynamicTypeSize.isAccessibilitySize, !store.results.isEmpty {
                summaryBar
            }
        }
        .hy2Chrome(store: store)
    }

    private var summaryBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HY2Figures(totals: store.totals, code: store.code, type: store.type, font: .subheadline.weight(.semibold))
            if store.isNarrowed {
                HYNarrowedNote(store: store)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 22))
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview("Carina") {
    HYHost { CarinaHistory(store: $0) }
}

#Preview("Carina · Filtered") {
    HYHost(store: .filtered()) { CarinaHistory(store: $0) }
}

#Preview("Carina · Empty") {
    HYHost(store: .empty) { CarinaHistory(store: $0) }
}
#endif
