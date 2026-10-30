//
//  04-DenebHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Deneb": every month in one scroll, like Photos. Each month has a glass bar
//  that pins to the top while you're in it, with its income and spending, so the totals for what you're
//  looking at are always on screen. The month filter narrows to one month or goes back to all of them.
//

#if DEBUG
import SwiftUI

struct DenebHistory: View {
    @Bindable var store: HYStore

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: r2TileSpacing, pinnedViews: [.sectionHeaders]) {
                if store.isNarrowed, !store.results.isEmpty {
                    HYNarrowedNote(store: store)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                }
                ForEach(store.monthGroups) { group in
                    Section {
                        ForEach(group.days) { day in
                            HYDayTile(day: day, code: store.code)
                        }
                        .padding(.bottom, 4)
                    } header: {
                        DenebMonthBar(group: group, code: store.code)
                    }
                }
                if !store.records.isEmpty, store.results.isEmpty {
                    HYEmptyView(store: store)
                        .padding(.top, 24)
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background { R2Backdrop() }
        .overlay {
            if store.records.isEmpty {
                HYEmptyView(store: store)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    HYMonthPicker(store: store, allowsAllMonths: true)
                        .pickerStyle(.inline)
                    Divider()
                    HYFilterMenu(store: store)
                } label: {
                    Label(
                        "Filter",
                        systemImage: store.hasFilters || store.month != nil
                            ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease"
                    )
                }
            }
        }
        .searchable(text: $store.searchText, prompt: Text("Search notes"))
    }

    private var title: Text {
        if let month = store.month, !store.isSearching {
            Text(month, format: .dateTime.month(.wide).year())
        } else {
            Text("History")
        }
    }
}

/// A month's name with its income and spending, pinned while its days scroll under it.
private struct DenebMonthBar: View {
    let group: HYMonth
    let code: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 12))

        layout {
            HYFormat.month(group.month)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
            HStack(spacing: 12) {
                Label {
                    Text(group.totals.income, format: .currency(code: code))
                } icon: {
                    Image(systemName: "arrow.down.left")
                }
                .accessibilityLabel(Text("Income \(group.totals.income.formatted(.currency(code: code)))"))
                Label {
                    Text(group.totals.spending, format: .currency(code: code))
                } icon: {
                    Image(systemName: "arrow.up.right")
                }
                .accessibilityLabel(Text("Spending \(group.totals.spending.formatted(.currency(code: code)))"))
            }
            .font(.subheadline.weight(.medium))
            .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
        .padding(.vertical, 4)
    }
}

#Preview("Deneb") {
    HYHost(store: .allMonths) { DenebHistory(store: $0) }
}

#Preview("Deneb · Empty") {
    HYHost(store: .empty) { DenebHistory(store: $0) }
}
#endif
