//
//  01-LinenCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Linen": the plainest take on Marsh. Expenses or Income on a segmented
//  control, the active categories of that type in one tile with how many transactions use each, and
//  the archived ones folded away under it. Tapping a category opens the editor in tiles: a preview with
//  the name, then type, color and icon.
//

#if DEBUG
import SwiftUI

struct LinenCategories: View {
    @Bindable var store: CTStore

    @State private var type: ExplorationTransactionType = .expense

    var body: some View {
        CTScreen(store: store, addType: type) { actions in
            CTTypeSwitch(selection: $type)
            CTListTile(
                title: type == .expense ? "Expense categories" : "Income categories",
                symbol: "square.grid.2x2.fill",
                categories: store.active(type),
                actions: actions
            )
            CTArchivedTile(categories: store.archived(type), actions: actions)
            Text("Categories can't be deleted, only archived, so past transactions keep theirs.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
        }
    }
}

#Preview("Linen") {
    CTHost { LinenCategories(store: $0) }
}

#Preview("Linen · Editor") {
    CTHost(opening: .editor(.edit("dining"))) { LinenCategories(store: $0) }
}

#Preview("Linen · Dark") {
    CTHost { LinenCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
