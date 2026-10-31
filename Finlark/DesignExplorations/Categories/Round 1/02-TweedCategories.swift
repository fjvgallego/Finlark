//
//  02-TweedCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Tweed": everything on one page, no switch. Expenses in one tile and
//  income in the next, each ending in a row to add one of that type, then every archived category with
//  its type and an Unarchive button, open. Rows keep to the name, so the page stays short.
//

#if DEBUG
import SwiftUI

struct TweedCategories: View {
    @Bindable var store: CTStore

    var body: some View {
        CTScreen(store: store) { actions in
            CTListTile(
                title: "Expenses",
                symbol: ExplorationTransactionType.expense.symbol,
                categories: store.active(.expense),
                actions: actions,
                detail: .none,
                addType: .expense
            )
            CTListTile(
                title: "Income",
                symbol: ExplorationTransactionType.income.symbol,
                categories: store.active(.income),
                actions: actions,
                detail: .none,
                addType: .income
            )
            CTArchivedTile(categories: store.archived, actions: actions, detail: .typeAndCount, startsExpanded: true)
        }
    }
}

#Preview("Tweed") {
    CTHost { TweedCategories(store: $0) }
}

#Preview("Tweed · Just onboarded") {
    CTHost(store: .fresh) { TweedCategories(store: $0) }
}

#Preview("Tweed · Dark") {
    CTHost { TweedCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
