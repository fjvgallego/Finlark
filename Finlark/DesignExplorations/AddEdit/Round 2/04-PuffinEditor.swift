//
//  04-PuffinEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2 "Puffin". Category: the four most used as big buttons plus "All", which
//  opens a searchable list. Split: By item becomes a table, items down the side and people across the
//  top, with a check where someone had an item, like ticking a receipt at the table.
//

#if DEBUG
import SwiftUI

struct PuffinEditor: View {
    @State private var draft: AEDraft
    @State private var isShowingAll = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var iconSize: CGFloat = 36

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    /// The selected category first if it isn't among the most used, then the most used.
    private var quickCategories: [ExplorationCategory] {
        var categories = Array(draft.type.frequentCategories.prefix(4))
        if let selected = draft.category, !categories.contains(where: { $0.id == selected.id }) {
            categories = [selected] + categories.prefix(3)
        }
        return categories
    }

    private var columnCount: Int { dynamicTypeSize.isAccessibilitySize ? 3 : 5 }

    var body: some View {
        AE2KestrelShell(draft: draft) {
            // Five equal cells: four categories and "All". Two rows of three at accessibility sizes.
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: columnCount), spacing: 6) {
                ForEach(quickCategories) { category in
                    quickCell(category)
                }
                Button {
                    isShowingAll = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                            .frame(width: iconSize, height: iconSize)
                            .background(.fill.tertiary, in: .rect(cornerRadius: iconSize * 0.3, style: .continuous))
                        Text("All")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(.tint)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("All categories"))
            }
            .sheet(isPresented: $isShowingAll) {
                PuffinCategorySearch(draft: draft)
            }
        } split: {
            VStack(alignment: .leading, spacing: 16) {
                AEPeoplePicker(draft: draft)
                AESplitModePicker(draft: draft)
                if draft.splitMode == .byItem {
                    PuffinItemTable(draft: draft)
                }
                VStack(spacing: 12) {
                    AEShareRows(draft: draft)
                }
                AESplitFooter(draft: draft)
            }
        }
    }
}

extension PuffinEditor {
    private func quickCell(_ category: ExplorationCategory) -> some View {
        let isSelected = draft.categoryID == category.id
        return Button {
            draft.categoryID = category.id
        } label: {
            VStack(spacing: 6) {
                ExplorationCategoryIcon(category: category)
                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? category.color.opacity(0.14) : .clear, in: .rect(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? category.color : .clear, lineWidth: 1.5)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Every category in a list you can search, with the most used first.
private struct PuffinCategorySearch: View {
    @Bindable var draft: AEDraft
    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    private var matches: [ExplorationCategory] {
        draft.type.frequentCategories.filter {
            query.isEmpty || String(localized: $0.name).localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            List(matches) { category in
                Button {
                    draft.categoryID = category.id
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ExplorationCategoryIcon(category: category)
                        Text(category.name)
                        Spacer()
                        if draft.categoryID == category.id {
                            Image(systemName: "checkmark")
                                .fontWeight(.semibold)
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(draft.categoryID == category.id ? .isSelected : [])
            }
            .overlay {
                if matches.isEmpty {
                    ContentUnavailableView.search(text: query)
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search categories"))
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", role: .close) { dismiss() }
                }
            }
        }
        .environment(\.explorationIconStyle, .soft)
    }
}

/// Items as rows and people as columns; a tap toggles who had what. At accessibility sizes it falls
/// back to the list of items with people chips.
private struct PuffinItemTable: View {
    @Bindable var draft: AEDraft

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric private var column: CGFloat = 34

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) {
                AEItemRows(draft: draft, isCarded: true)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Grid(alignment: .leading, horizontalSpacing: 6, verticalSpacing: 10) {
                    GridRow {
                        Text("Item")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .gridColumnAlignment(.leading)
                        ForEach(draft.everyone) { person in
                            // Hidden from VoiceOver: each check is labeled with the item and the person.
                            AEAvatar(person: person, size: 26)
                                .frame(width: column)
                        }
                    }
                    Divider()
                    ForEach($draft.items) { $item in
                        GridRow {
                            VStack(alignment: .leading, spacing: 4) {
                                TextField("Item", text: $item.name, prompt: Text("Item"))
                                AEMoneyField(title: "Item amount", text: $item.amountText, draft: draft)
                                    .font(.subheadline)
                            }
                            ForEach(draft.everyone) { person in
                                check(item: item, person: person)
                            }
                        }
                        .contextMenu {
                            if draft.items.count > 1 {
                                Button("Remove item", systemImage: "trash", role: .destructive) {
                                    draft.removeItem(item.id)
                                }
                            }
                        }
                    }
                }
                Button("Add item", systemImage: "plus.circle.fill") { draft.addItem() }
                Text("Touch and hold an item to remove it. Items with no one ticked count as yours.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func check(item: AESplitItem, person: AEPerson) -> some View {
        let isAssigned = item.assignees.contains(person.id)
        return Button {
            draft.toggle(person, on: item.id)
        } label: {
            Image(systemName: isAssigned ? "checkmark.square.fill" : "square")
                .font(.title3)
                .foregroundStyle(isAssigned ? AnyShapeStyle(person.color) : AnyShapeStyle(.tertiary))
                .frame(width: column, height: column)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(item.name.isEmpty ? String(localized: "Item") : item.name), \(person.isMe ? String(localized: "You") : person.name)"))
        .accessibilityAddTraits(isAssigned ? .isSelected : [])
    }
}

#Preview("Puffin · Add") {
    AEHomeHost { PuffinEditor(draft: $0) }
}

#Preview("Puffin · Edit by item") {
    AEDetailHost { PuffinEditor(draft: .editByItemSample) }
}
#endif
