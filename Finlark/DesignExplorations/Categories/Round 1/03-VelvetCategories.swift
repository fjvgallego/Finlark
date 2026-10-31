//
//  03-VelvetCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Velvet": swatches. Each category is a glass tile in a three-column grid,
//  with a big icon, its name and how often it's used, and the last tile adds one. Archived categories
//  follow in the same grid, gray, with Unarchive on long press. One type at a time.
//

#if DEBUG
import SwiftUI

struct VelvetCategories: View {
    @Bindable var store: CTStore

    @State private var type: ExplorationTransactionType = .expense
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 3
        return Array(repeating: GridItem(.flexible(), spacing: r2TileSpacing, alignment: .top), count: count)
    }

    var body: some View {
        CTScreen(store: store, addType: type) { actions in
            CTTypeSwitch(selection: $type)
            LazyVGrid(columns: columns, spacing: r2TileSpacing) {
                ForEach(store.active(type)) { category in
                    VelvetSwatch(category: category, actions: actions)
                }
                VelvetAddSwatch { actions.add(type) }
            }
            let archived = store.archived(type)
            if !archived.isEmpty {
                RCSectionTitle(title: "Archived", count: archived.count)
                    .padding(.top, 8)
                LazyVGrid(columns: columns, spacing: r2TileSpacing) {
                    ForEach(archived) { category in
                        VelvetSwatch(category: category, actions: actions)
                    }
                }
                Text("Touch and hold an archived category to unarchive it. Their transactions still show them.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
        }
    }
}

/// A category as a tile: big icon, name, usage. Archived ones are gray with a box on the corner.
private struct VelvetSwatch: View {
    let category: CTCategory
    let actions: CTActions

    var body: some View {
        Button { actions.edit(category) } label: {
            R2Tile(padding: 8) {
                VStack(spacing: 8) {
                    CTBadge(symbol: category.symbol, color: category.color, size: 48)
                        .saturation(category.isArchived ? 0 : 1)
                        .overlay(alignment: .topTrailing) {
                            if category.isArchived {
                                Image(systemName: "archivebox.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(4)
                                    .background(.background, in: .circle)
                                    .offset(x: 8, y: -8)
                            }
                        }
                    Text(verbatim: category.name)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(category.isArchived ? .secondary : .primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2, reservesSpace: true)
                        .minimumScaleFactor(0.85)
                    CTUsage.count(category)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
            }
            .contentShape(.rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .ctArchiveMenu(category, actions: actions)
        .accessibilityElement(children: .combine)
        .accessibilityValue(category.isArchived ? Text("Archived") : Text(""))
    }
}

/// The last tile: a new category of the type shown.
private struct VelvetAddSwatch: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .frame(width: 48, height: 48)
                Text("New")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2, reservesSpace: true)
            }
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(12)
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.tint.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
            }
            .contentShape(.rect(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("New Category"))
    }
}

#Preview("Velvet") {
    CTHost { VelvetCategories(store: $0) }
}

#Preview("Velvet · Dark") {
    CTHost { VelvetCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
