//
//  09-GinghamCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Gingham": tags. Each category is a chip in its color that wraps onto the
//  next line, so a dozen fit in a few rows, with a dashed + chip to add one. Archived chips are dashed
//  and gray. The editor is a half-height sheet with the icons in rows that scroll sideways.
//

#if DEBUG
import SwiftUI

struct GinghamCategories: View {
    @Bindable var store: CTStore

    var body: some View {
        CTScreen(store: store, editorStyle: .compact) { actions in
            GinghamSection(
                title: "Expenses",
                symbol: ExplorationTransactionType.expense.symbol,
                categories: store.active(.expense),
                addType: .expense,
                actions: actions
            )
            GinghamSection(
                title: "Income",
                symbol: ExplorationTransactionType.income.symbol,
                categories: store.active(.income),
                addType: .income,
                actions: actions
            )
            if !store.archived.isEmpty {
                GinghamSection(
                    title: "Archived",
                    symbol: "archivebox.fill",
                    categories: store.archived,
                    addType: nil,
                    actions: actions
                ) {
                    Text("Touch and hold to unarchive. Their transactions still show them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct GinghamSection<Footer: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    let categories: [CTCategory]
    let addType: ExplorationTransactionType?
    let actions: CTActions
    @ViewBuilder var footer: Footer

    var body: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: title, symbol: symbol) {
                    Text(categories.count, format: .number)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                GinghamFlow(spacing: 8) {
                    ForEach(categories) { category in
                        GinghamChip(category: category, actions: actions)
                    }
                    if let addType {
                        Button { actions.add(addType) } label: {
                            Label("New", systemImage: "plus")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.tint)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .overlay {
                                    Capsule().strokeBorder(.tint.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                                }
                                .contentShape(.capsule)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(addType == .expense ? Text("New Expense Category") : Text("New Income Category"))
                    }
                }
                footer
            }
        }
    }
}

extension GinghamSection where Footer == EmptyView {
    init(
        title: LocalizedStringKey,
        symbol: String,
        categories: [CTCategory],
        addType: ExplorationTransactionType?,
        actions: CTActions
    ) {
        self.init(title: title, symbol: symbol, categories: categories, addType: addType, actions: actions) {
            EmptyView()
        }
    }
}

private struct GinghamChip: View {
    let category: CTCategory
    let actions: CTActions

    var body: some View {
        Button { actions.edit(category) } label: {
            Label {
                Text(verbatim: category.name)
                    .foregroundStyle(category.isArchived ? .secondary : .primary)
            } icon: {
                Image(systemName: category.symbol)
                    .foregroundStyle(category.isArchived ? Color.secondary : category.color.color)
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(category.isArchived ? Color.clear : category.color.color.opacity(0.14), in: .capsule)
            .overlay {
                if category.isArchived {
                    Capsule().strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .ctArchiveMenu(category, actions: actions)
        .accessibilityValue(category.isArchived ? Text("Archived") : Text(""))
    }
}

/// Lays chips out left to right, wrapping onto the next line when one doesn't fit.
private struct GinghamFlow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width
            widest = max(widest, x)
            x += spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? widest, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// A half-height editor: icon and name, colors in a row, then the icons in a row per group.
struct GinghamCompactEditor: View {
    let store: CTStore
    @Bindable var draft: CTDraft

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 14) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        CTBadge(symbol: draft.symbol, color: draft.color, size: 52)
                    }
                    CTNameField(store: store, draft: draft)
                }
                CTColorPalette(selection: $draft.color, layout: .row)
            }
        }
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Icon", symbol: "square.grid.2x2.fill")
                ForEach(CTSymbolGroup.all) { group in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(group.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)
                        ScrollView(.horizontal) {
                            HStack(spacing: 8) {
                                ForEach(group.symbols) { symbol in
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
        R2Tile(padding: 16) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Type", symbol: "arrow.up.arrow.down")
                CTTypeControl(draft: draft)
            }
        }
    }
}

#Preview("Gingham") {
    CTHost { GinghamCategories(store: $0) }
}

#Preview("Gingham · Editor") {
    CTHost(opening: .editor(.edit("pets"))) { GinghamCategories(store: $0) }
}

#Preview("Gingham · Dark") {
    CTHost { GinghamCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
