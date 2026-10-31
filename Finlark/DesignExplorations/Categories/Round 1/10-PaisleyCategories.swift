//
//  10-PaisleyCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Paisley": find or add. A field on top filters every category, archived
//  ones included, and offers to add what was typed as an expense or income category when it doesn't
//  exist yet. The editor suggests icons from the name ("Kids" → a parent and child) and uses the best
//  one until an icon is picked by hand.
//

#if DEBUG
import SwiftUI

struct PaisleyCategories: View {
    @Bindable var store: CTStore

    @State private var query: String

    init(store: CTStore, query: String = "") {
        self.store = store
        _query = State(initialValue: query)
    }

    var body: some View {
        CTScreen(store: store, editorStyle: .suggest) { actions in
            CTSearchField(text: $query, prompt: "Find or add a category")
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                CTListTile(
                    title: "Expenses",
                    symbol: ExplorationTransactionType.expense.symbol,
                    categories: store.active(.expense),
                    actions: actions,
                    detail: .none
                )
                CTListTile(
                    title: "Income",
                    symbol: ExplorationTransactionType.income.symbol,
                    categories: store.active(.income),
                    actions: actions,
                    detail: .none
                )
                CTArchivedTile(categories: store.archived, actions: actions, detail: .typeAndCount)
            } else {
                PaisleyResults(store: store, query: trimmed, actions: actions)
            }
        }
    }
}

/// What matches, archived ones with Unarchive, then adding the text as a new category.
private struct PaisleyResults: View {
    let store: CTStore
    let query: String
    let actions: CTActions

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let matches = store.categories.filter { $0.name.localizedStandardContains(query) }
        if !matches.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Found", symbol: "magnifyingglass")
                    ForEach(matches) { category in
                        let layout = dynamicTypeSize.isAccessibilitySize
                            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                            : AnyLayout(HStackLayout(spacing: 12))
                        layout {
                            Button { actions.edit(category) } label: {
                                CTRow(category: category, detail: .typeAndCount, showsChevron: !category.isArchived)
                            }
                            .buttonStyle(.plain)
                            if category.isArchived {
                                Button("Unarchive") { actions.unarchive(category) }
                                    .buttonStyle(.glass)
                                    .controlSize(.small)
                            }
                        }
                        if category.id != matches.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }

        let types = ExplorationTransactionType.allCases.filter {
            store.nameIssue(query, type: $0, excluding: nil) == nil
        }
        if !types.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Add", symbol: "plus")
                    ForEach(types) { type in
                        Button { actions.addNamed(type, query) } label: {
                            PaisleyAddRow(query: query, type: type)
                        }
                        .buttonStyle(.plain)
                        if type != types.last {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

/// "Add “Kids”, as an expense category", with the icon it would get.
private struct PaisleyAddRow: View {
    let query: String
    let type: ExplorationTransactionType

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            if !dynamicTypeSize.isAccessibilitySize {
                CTBadge(symbol: CTSymbolGroup.suggestions(for: query).first?.name ?? "tag.fill", color: .blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("Add “\(query)”")
                    .font(.body.weight(.semibold))
                Group {
                    if type == .expense {
                        Text("As an expense category")
                    } else {
                        Text("As an income category")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// The name first, with icons suggested from it, then color, type and every icon.
struct PaisleySuggestEditor: View {
    let store: CTStore
    @Bindable var draft: CTDraft

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let suggestions = Array(CTSymbolGroup.suggestions(for: name).prefix(8))
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        CTBadge(symbol: draft.symbol, color: draft.color, size: 56)
                    }
                    CTNameField(store: store, draft: draft)
                }
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Suggested for “\(name)”")
                        } icon: {
                            Image(systemName: "sparkles")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(suggestions) { symbol in
                                    CTSymbolCell(symbol: symbol, color: draft.color, isSelected: draft.symbol == symbol.name) {
                                        draft.symbol = symbol.name
                                        draft.pickedSymbol = true
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        .scrollClipDisabled()
                    }
                }
            }
        }
        .onChange(of: draft.name) {
            // Until an icon is picked by hand, the best match follows the name.
            if !draft.pickedSymbol, let best = CTSymbolGroup.suggestions(for: draft.name).first {
                draft.symbol = best.name
            }
        }
        R2Tile {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Color", symbol: "paintpalette.fill")
                CTColorPalette(selection: $draft.color)
            }
        }
        R2Tile {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Type", symbol: "arrow.up.arrow.down")
                CTTypeControl(draft: draft)
            }
        }
        R2Tile {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "All icons", symbol: "square.grid.2x2.fill")
                CTSymbolPicker(draft: draft)
            }
        }
    }
}

#Preview("Paisley") {
    CTHost { PaisleyCategories(store: $0) }
}

#Preview("Paisley · Searching") {
    CTHost { PaisleyCategories(store: $0, query: "co") }
}

#Preview("Paisley · New") {
    CTHost(opening: .editor(.new(.expense, name: "Kids"))) { PaisleyCategories(store: $0) }
}

#Preview("Paisley · Dark") {
    CTHost { PaisleyCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
