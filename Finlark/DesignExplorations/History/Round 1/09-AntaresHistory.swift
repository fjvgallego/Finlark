//
//  09-AntaresHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Antares": every filter lives in the search field, like Mail and Photos.
//  Typing suggests categories and months as tokens; type is a scope bar under the field. Words that
//  aren't a token search the notes. With nothing in the field, it's every month in a native list,
//  each month opening with its income and spending.
//

#if DEBUG
import SwiftUI

struct AntaresHistory: View {
    @Bindable var store: HYStore

    @State private var tokens: [AntaresToken] = []

    var body: some View {
        List {
            ForEach(store.monthGroups) { group in
                Section {
                    HYTotalsRow(totals: group.totals, code: store.code, font: .headline)
                        .padding(.vertical, 2)
                } header: {
                    HYFormat.month(group.month)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    if store.hasFilters || store.isSearching {
                        Text("Totals for what's shown.")
                    }
                }

                ForEach(group.days) { day in
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
        }
        .overlay { HYEmptyView(store: store) }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $store.searchText,
            tokens: $tokens,
            suggestedTokens: .constant(suggestions),
            prompt: Text("Notes, categories or months")
        ) { token in
            label(for: token)
        }
        .searchScopes($store.type, activation: .onSearchPresentation) {
            ForEach(HYTypeFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }
        .onChange(of: tokens) { apply(tokens) }
    }

    // MARK: Tokens

    private var query: String {
        store.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Categories and months whose names match what's typed, minus the ones already chosen. With
    /// nothing typed, the months come first, then the categories.
    private var suggestions: [AntaresToken] {
        let months = store.months
            .map(AntaresToken.month)
            .filter { !tokens.contains($0) && matches($0) }
        let categories = store.categoryOptions
            .map { AntaresToken.category($0.id) }
            .filter { !tokens.contains($0) && matches($0) }
        return tokens.contains(where: \.isMonth) ? categories : months + categories
    }

    private func matches(_ token: AntaresToken) -> Bool {
        guard !query.isEmpty else { return true }
        return token.name.localizedStandardContains(query)
    }

    private func label(for token: AntaresToken) -> some View {
        Label {
            Text(verbatim: token.name)
        } icon: {
            Image(systemName: token.symbol)
        }
    }

    /// One month token at most: picking a second replaces the first.
    private func apply(_ tokens: [AntaresToken]) {
        let months = tokens.compactMap(\.month)
        if months.count > 1 {
            self.tokens = tokens.filter { $0.month == nil || $0.month == months.last }
            return
        }
        store.month = months.first
        store.categoryIDs = Set(tokens.compactMap(\.categoryID))
    }
}

private enum AntaresToken: Identifiable, Hashable {
    case month(Date)
    case category(String)

    var id: Self { self }

    var month: Date? {
        if case .month(let month) = self { return month }
        return nil
    }

    var isMonth: Bool { month != nil }

    var categoryID: String? {
        if case .category(let id) = self { return id }
        return nil
    }

    private var category: ExplorationCategory? {
        categoryID.flatMap { id in ExplorationCategory.all.first { $0.id == id } }
    }

    /// The localized name, so typing matches what the user reads.
    var name: String {
        switch self {
        case .month(let month): month.formatted(.dateTime.month(.wide).year())
        case .category: category.map { String(localized: $0.name) } ?? ""
        }
    }

    var symbol: String {
        switch self {
        case .month: "calendar"
        case .category: category?.symbol ?? "square.grid.2x2"
        }
    }
}

private extension HYStore {
    /// Every month, and search stays inside a month token when there is one.
    static var antares: HYStore {
        let store = HYStore.allMonths
        store.searchesEveryMonth = false
        return store
    }
}

#Preview("Antares") {
    HYHost(store: .antares) { AntaresHistory(store: $0) }
}

#Preview("Antares · Empty") {
    HYHost(store: .empty) { AntaresHistory(store: $0) }
}
#endif
