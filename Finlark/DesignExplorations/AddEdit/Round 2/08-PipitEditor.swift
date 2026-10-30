//
//  08-PipitEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2 "Pipit". Category: type to find it. A search field with matching chips
//  underneath; once picked, it becomes a single chip you can clear. Split: each person is a pill
//  with their share on it, and tapping one opens a popover to set what they pay or which items they had.
//

#if DEBUG
import SwiftUI

struct PipitEditor: View {
    @State private var draft: AEDraft

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        AE2KestrelShell(draft: draft) {
            PipitCategorySearch(draft: draft)
        } split: {
            VStack(alignment: .leading, spacing: 14) {
                AESplitModePicker(draft: draft)
                AEFlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(draft.shares) { share in
                        PipitSharePill(draft: draft, share: share)
                    }
                }
                Text("Tap someone to change their part.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Divider()
                Text("People")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                AEPeoplePicker(draft: draft)
                if draft.splitMode == .byItem {
                    Divider()
                    AEItemRows(draft: draft, isCarded: true)
                }
                AESplitFooter(draft: draft)
            }
        }
    }
}

/// A search field that suggests categories as you type. With nothing typed it suggests the most used.
private struct PipitCategorySearch: View {
    @Bindable var draft: AEDraft

    @State private var query = ""

    private var matches: [ExplorationCategory] {
        let all = draft.type.frequentCategories
        guard !query.isEmpty else { return Array(all.prefix(5)) }
        return all.filter { String(localized: $0.name).localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        if let category = draft.category {
            AE2CategoryChip(category: category, isSelected: true, showsRemove: true) {
                draft.categoryID = nil
            }
            .accessibilityHint(Text("Clears the category"))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Category", text: $query, prompt: Text("Type a category"))
                        .submitLabel(.done)
                        .onSubmit {
                            if let first = matches.first {
                                draft.categoryID = first.id
                                query = ""
                            }
                        }
                }
                .padding(10)
                .background(.fill.tertiary, in: .rect(cornerRadius: 12, style: .continuous))

                if matches.isEmpty {
                    Text("No category matches “\(query)”.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    AEFlowLayout(spacing: 8, lineSpacing: 8) {
                        ForEach(matches) { category in
                            AE2CategoryChip(category: category, isSelected: false) {
                                draft.categoryID = category.id
                                query = ""
                            }
                        }
                    }
                }
            }
        }
    }
}

/// A participant with their share; tapping opens a popover to edit their part.
private struct PipitSharePill: View {
    let draft: AEDraft
    let share: AEShare

    @State private var isEditing = false

    var body: some View {
        let person = share.person
        Button {
            isEditing = true
        } label: {
            HStack(spacing: 6) {
                AEAvatar(person: person, size: 24)
                person.displayName
                Text(share.amount, format: .currency(code: draft.currencyCode))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .font(.subheadline)
            .padding(.leading, 4)
            .padding(.trailing, 12)
            .padding(.vertical, 4)
            .background(person.color.opacity(0.16), in: .capsule)
            .overlay { Capsule().strokeBorder(person.color.opacity(0.5), lineWidth: 1) }
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text("Edit their part"))
        .popover(isPresented: $isEditing) {
            PipitShareEditor(draft: draft, person: person)
                .presentationCompactAdaptation(.popover)
        }
    }
}

private struct PipitShareEditor: View {
    @Bindable var draft: AEDraft
    let person: AEPerson

    private var share: AEShare? { draft.shares.first { $0.id == person.id } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                AEAvatar(person: person)
                person.displayName
                    .font(.headline)
            }
            switch draft.splitMode {
            case .equal:
                if let share {
                    Text("Pays \(share.amount, format: .currency(code: draft.currencyCode)), the same as everyone.")
                }
                Button("Set an exact amount", systemImage: "number") {
                    draft.splitMode = .exact
                }
                .buttonStyle(.glass)
            case .exact:
                LabeledContent("Share") {
                    AEMoneyField(title: "Share", text: draft.exactText(for: person), draft: draft)
                }
                AERemainingLabel(draft: draft)
                    .font(.footnote.weight(.medium))
            case .byItem:
                Text("Had")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(draft.items) { item in
                    let isAssigned = item.assignees.contains(person.id)
                    Button {
                        draft.toggle(person, on: item.id)
                    } label: {
                        HStack {
                            Image(systemName: isAssigned ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isAssigned ? AnyShapeStyle(person.color) : AnyShapeStyle(.tertiary))
                            item.name.isEmpty ? Text("Item") : Text(verbatim: item.name)
                            Spacer()
                            Text(AEMoney.parse(item.amountText) ?? 0, format: .currency(code: draft.currencyCode))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isAssigned ? .isSelected : [])
                }
            }
            if let share, share.repaid > 0 {
                Text("Has repaid \(share.repaid, format: .currency(code: draft.currencyCode)) already.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(width: 280, alignment: .leading)
    }
}

#Preview("Pipit · Add") {
    AEHomeHost { PipitEditor(draft: $0) }
}

#Preview("Pipit · Edit split") {
    AEDetailHost { PipitEditor(draft: .editSplitSample) }
}
#endif
