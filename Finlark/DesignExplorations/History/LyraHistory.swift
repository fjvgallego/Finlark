//
//  LyraHistory.swift
//  Finlark
//
//  FIN-9 History "Lyra": sections with plain rows. Every month in one scroll; each month's glass bar
//  pins to the top with its difference, income and spending. The only glass is that bar and the chips.
//  Picking a month in the title's menu narrows to it and names it in the title; All months, in the same
//  menu, goes back. The chips are only for type and categories.
//

#if DEBUG
import SwiftUI

struct LyraHistory: View {
    @Bindable var store: HYStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ScrollView {
            // At accessibility sizes a pinned bar would cover a third of the screen, so it scrolls away.
            LazyVStack(
                alignment: .leading, spacing: 0,
                pinnedViews: dynamicTypeSize.isAccessibilitySize ? [] : [.sectionHeaders]
            ) {
                HYFilterChips(store: store)
                    .padding(.bottom, 8)

                ForEach(store.monthGroups) { group in
                    Section {
                        VStack(spacing: 20) {
                            ForEach(group.days) { day in
                                HYPlainDay(day: day, code: store.code)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                    } header: {
                        HYMonthBar(group: group, code: store.code, type: store.type)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                    }
                }

                if !store.records.isEmpty, store.results.isEmpty {
                    HYEmptyView(store: store)
                        .padding(.top, 24)
                }
            }
            .padding(.vertical, 8)
        }
        .background { HMBackdrop() }
        .overlay {
            if store.records.isEmpty {
                HYEmptyView(store: store)
            }
        }
        .hyChrome(store: store, allowsAllMonths: true)
    }
}

#Preview("Lyra") {
    HYHost(store: .allMonths) { LyraHistory(store: $0) }
}

#Preview("Lyra · Filtered") {
    HYHost(store: .filtered()) { LyraHistory(store: $0) }
}

#Preview("Lyra · Empty") {
    HYHost(store: .empty) { LyraHistory(store: $0) }
}
#endif
