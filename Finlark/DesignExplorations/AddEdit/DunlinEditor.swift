//
//  DunlinEditor.swift
//  Finlark
//
//  FIN-9 Add & edit "Dunlin": the four most used categories stay on top, and the rest sit in a thin bar
//  that expands in place, like Home's Owed to you bar. A category picked from the bar flies up into the
//  first of those slots (a matched geometry effect) while the bar folds back. The split has people
//  chips, the mode, and the By item table.
//

#if DEBUG
import SwiftUI

struct DunlinEditor: View {
    @State private var draft: AEDraft
    private let onSave: (() -> Void)?

    init(draft: AEDraft, onSave: (() -> Void)? = nil) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    var body: some View {
        AEKestrelShell(draft: draft, onSave: onSave) {
            DunlinCategoryPicker(draft: draft)
        } split: {
            DunlinSplitEditor(draft: draft)
        }
    }
}

/// People chips, the mode, the By item table, and the shares.
struct DunlinSplitEditor: View {
    @Bindable var draft: AEDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AEPeoplePicker(draft: draft)
            AESplitModePicker(draft: draft)
            if draft.splitMode == .byItem {
                AEItemTable(draft: draft)
            }
            VStack(spacing: 12) {
                AEShareRows(draft: draft)
            }
            AESplitFooter(draft: draft)
        }
    }
}

/// The four most used categories, and the rest in a bar that expands in place.
struct DunlinCategoryPicker: View {
    @Bindable var draft: AEDraft

    @State private var isShowingMore = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var categoryCells

    /// Without Reduce Motion, a pick from the bar flies into the row above while the bar folds.
    private var pickAnimation: Animation? {
        reduceMotion ? nil : .spring(duration: 0.45, bounce: 0.2)
    }

    /// The selected category first if it isn't among the most used, then the most used.
    private var quickCategories: [ExplorationCategory] {
        var categories = Array(draft.type.frequentCategories.prefix(4))
        if let selected = draft.category, !categories.contains(where: { $0.id == selected.id }) {
            categories = [selected] + categories.prefix(3)
        }
        return categories
    }

    private var moreCategories: [ExplorationCategory] {
        draft.type.frequentCategories.filter { category in
            !quickCategories.contains { $0.id == category.id }
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            AECategoryGrid(
                draft: draft, categories: quickCategories, namespace: categoryCells, pickAnimation: pickAnimation
            )
            if !moreCategories.isEmpty {
                moreSection
            }
        }
    }

    /// A collapsed bar that names how many more there are; expanded, it shows them as a grid.
    private var moreSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? nil : .snappy) { isShowingMore.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text("More categories")
                        .fontWeight(.semibold)
                    Text("\(moreCategories.count)")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Spacer(minLength: 8)
                    if !isShowingMore {
                        // A peek at what's inside, so the bar says more than "more".
                        HStack(spacing: 4) {
                            ForEach(moreCategories.prefix(4)) { category in
                                Image(systemName: category.symbol)
                                    .font(.caption)
                                    .foregroundStyle(category.color)
                            }
                        }
                        .accessibilityHidden(true)
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isShowingMore ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityValue(isShowingMore ? Text("Expanded") : Text("Collapsed"))

            if isShowingMore {
                Divider()
                    .padding(.horizontal, 14)
                AECategoryGrid(
                    draft: draft, categories: moreCategories, namespace: categoryCells, pickAnimation: pickAnimation
                ) {
                    isShowingMore = false
                }
                .padding(8)
            }
        }
        .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

#Preview("Dunlin · Add") {
    AEHomeHost { DunlinEditor(draft: $0) }
}

#Preview("Dunlin · Edit by item") {
    AEDetailHost { DunlinEditor(draft: .editByItemSample) }
}
#endif
