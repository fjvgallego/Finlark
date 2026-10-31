//
//  04-DenimCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Denim": the system's own list, like the rest of Settings. Sections for
//  expenses, income and archived, a search field, and swipe actions: swipe left to archive, right to
//  unarchive. Tapping a row opens the editor in tiles.
//

#if DEBUG
import SwiftUI

struct DenimCategories: View {
    @Bindable var store: CTStore

    @State private var query = ""

    var body: some View {
        CTScreen(store: store, scrolls: false) { actions in
            List {
                let expenses = filtered(store.active(.expense))
                if !expenses.isEmpty {
                    Section("Expenses") {
                        ForEach(expenses) { category in
                            row(category, actions: actions)
                        }
                    }
                }
                let income = filtered(store.active(.income))
                if !income.isEmpty {
                    Section("Income") {
                        ForEach(income) { category in
                            row(category, actions: actions)
                        }
                    }
                }
                let archived = filtered(store.archived)
                if !archived.isEmpty {
                    Section {
                        ForEach(archived) { category in
                            row(category, actions: actions)
                        }
                    } header: {
                        Text("Archived")
                    } footer: {
                        Text("Archived categories don't show when you add a transaction or in the Plan. Their transactions still show them. Swipe right to unarchive.")
                    }
                }
                if expenses.isEmpty, income.isEmpty, archived.isEmpty {
                    ContentUnavailableView.search(text: query)
                        .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .searchable(text: $query, prompt: "Search categories")
        }
    }

    private func filtered(_ categories: [CTCategory]) -> [CTCategory] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return categories }
        return categories.filter { $0.name.localizedStandardContains(trimmed) }
    }

    private func row(_ category: CTCategory, actions: CTActions) -> some View {
        Button { actions.edit(category) } label: {
            CTRow(category: category, detail: category.isArchived ? .typeAndCount : .count)
        }
        // Keeps the row's text out of the button tint.
        .tint(.primary)
        .swipeActions(edge: .trailing) {
            if !category.isArchived {
                Button("Archive", systemImage: "archivebox") { actions.archive(category) }
                    .tint(.indigo)
            }
        }
        .swipeActions(edge: .leading) {
            if category.isArchived {
                Button("Unarchive", systemImage: "tray.and.arrow.up") { actions.unarchive(category) }
                    .tint(.blue)
            }
        }
    }
}

#Preview("Denim") {
    CTHost { DenimCategories(store: $0) }
}

#Preview("Denim · Dark") {
    CTHost { DenimCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
