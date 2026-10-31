//
//  08-DamaskCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Damask": the paged slider the owner liked in Recurring. Expenses on the
//  first page and income on the second, each a grid of icons with names, as the category picker in
//  Add & edit shows them, ending in a + to add one of that type. Archived categories sit under it.
//

#if DEBUG
import SwiftUI

struct DamaskCategories: View {
    @Bindable var store: CTStore

    var body: some View {
        CTScreen(store: store) { actions in
            RC2Slider(items: ExplorationTransactionType.allCases) { type in
                DamaskPage(store: store, type: type, actions: actions)
            }
            CTArchivedTile(categories: store.archived, actions: actions, detail: .typeAndCount)
        }
    }
}

private struct DamaskPage: View {
    let store: CTStore
    let type: ExplorationTransactionType
    let actions: CTActions

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let categories = store.active(type)
        let count = dynamicTypeSize.isAccessibilitySize ? 2 : 4
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                R2TileHeader(title: type == .expense ? "Expenses" : "Income", symbol: type.symbol) {
                    Text(categories.count, format: .number)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 6, alignment: .top), count: count),
                    spacing: 10
                ) {
                    ForEach(categories) { category in
                        Button { actions.edit(category) } label: {
                            DamaskCell(name: Text(verbatim: category.name)) {
                                ExplorationCategoryIcon(category: category.icon)
                            }
                        }
                        .buttonStyle(.plain)
                        .ctArchiveMenu(category, actions: actions)
                    }
                    Button { actions.add(type) } label: {
                        DamaskCell(name: Text("New")) {
                            Image(systemName: "plus")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.tint)
                                .frame(width: 36, height: 36)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .strokeBorder(.tint.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                                }
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(type == .expense ? Text("New Expense Category") : Text("New Income Category"))
                }
            }
        }
    }
}

/// An icon with its name under it.
private struct DamaskCell<Icon: View>: View {
    let name: Text
    @ViewBuilder let icon: Icon

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(spacing: 6) {
            icon
            name
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2, reservesSpace: !dynamicTypeSize.isAccessibilitySize)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Damask") {
    CTHost { DamaskCategories(store: $0) }
}

#Preview("Damask · Dark") {
    CTHost { DamaskCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
