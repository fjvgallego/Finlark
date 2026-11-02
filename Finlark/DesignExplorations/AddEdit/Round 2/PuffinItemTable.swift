//
//  PuffinItemTable.swift
//  Finlark
//
//  FIN-9 Add & edit, from Round 2 "Puffin": the By item table Dunlin uses. Items run down the side and
//  people across the top, with a check where someone had an item, like ticking a receipt at the table.
//

#if DEBUG
import SwiftUI

/// Items as rows and people as columns; a tap toggles who had what. At accessibility sizes it falls
/// back to the list of items with people chips.
struct PuffinItemTable: View {
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
#endif
