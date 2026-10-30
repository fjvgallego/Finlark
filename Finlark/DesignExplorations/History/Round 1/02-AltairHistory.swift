//
//  02-AltairHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Altair": Marsh's glass, top to bottom. Months are glass capsules you tap;
//  the month's income and spending fill a tile; Marsh's segmented control picks the type and a row of
//  category chips narrows it further. Each day is its own glass tile.
//

#if DEBUG
import SwiftUI

struct AltairHistory: View {
    @Bindable var store: HYStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: r2TileSpacing) {
                if !store.records.isEmpty {
                    if !store.isSearching {
                        monthCapsules
                    }
                    totalsTile
                        .padding(.horizontal)
                    filters
                    if store.results.isEmpty {
                        HYEmptyView(store: store)
                            .padding(.top, 24)
                    }
                }

                ForEach(store.days) { day in
                    HYDayTile(day: day, code: store.code)
                        .padding(.horizontal)
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
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $store.searchText, prompt: Text("Search notes"))
    }

    private var monthCapsules: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(store.months, id: \.self) { month in
                    monthCapsule(month)
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    @ViewBuilder
    private func monthCapsule(_ month: Date) -> some View {
        let isSelected = store.month == month
        let button = Button {
            withAnimation(reduceMotion ? nil : .snappy) { store.month = month }
        } label: {
            HYFormat.month(month)
                .fontWeight(.semibold)
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])

        if isSelected {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }

    private var totalsTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                Group {
                    if store.isSearching {
                        Text("Results")
                    } else if let month = store.month {
                        Text(month, format: .dateTime.month(.wide).year())
                    }
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)

                HYTotalsRow(totals: store.totals, code: store.code, font: .title2.weight(.bold))
                    .fontDesign(.rounded)

                HYNarrowedNote(store: store)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var filters: some View {
        VStack(spacing: 10) {
            R6SegmentedControl(
                title: "Type",
                options: HYTypeFilter.allCases.map { (value: $0, label: $0.title) },
                selection: $store.type
            )
            .padding(.horizontal)
            HYCategoryChips(store: store)
        }
    }
}

#Preview("Altair") {
    HYHost { AltairHistory(store: $0) }
}

#Preview("Altair · Empty") {
    HYHost(store: .empty) { AltairHistory(store: $0) }
}
#endif
