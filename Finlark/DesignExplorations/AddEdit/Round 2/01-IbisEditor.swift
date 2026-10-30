//
//  01-IbisEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2 "Ibis". Category: Kestrel's grid that folds away once you pick, leaving
//  the choice and a Change button. Split: a summary card in the tile (faces, mode, your share), with
//  the full editor in a sheet, so the main screen stays short.
//

#if DEBUG
import SwiftUI

struct IbisEditor: View {
    @State private var draft: AEDraft
    @State private var isChoosingCategory: Bool
    @State private var isEditingSplit = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
        _isChoosingCategory = State(initialValue: draft.categoryID == nil)
    }

    var body: some View {
        AE2KestrelShell(draft: draft) {
            category
        } split: {
            splitSummary
        }
        .sheet(isPresented: $isEditingSplit) {
            AESplitSheet(draft: draft, showsToggle: false)
        }
        .onChange(of: draft.isSplit) { _, isSplit in
            // Turning the split on goes straight to choosing people.
            if isSplit, draft.participants.isEmpty { isEditingSplit = true }
        }
    }

    @ViewBuilder
    private var category: some View {
        if isChoosingCategory || draft.category == nil {
            AECategoryGrid(draft: draft) {
                withAnimation(reduceMotion ? nil : .snappy) { isChoosingCategory = false }
            }
        } else if let category = draft.category {
            HStack(spacing: 12) {
                ExplorationCategoryIcon(category: category)
                Text(category.name)
                    .font(.headline)
                Spacer(minLength: 8)
                Button("Change") {
                    withAnimation(reduceMotion ? nil : .snappy) { isChoosingCategory = true }
                }
                .buttonStyle(.glass)
                .accessibilityLabel(Text("Change category"))
            }
        }
    }

    private var splitSummary: some View {
        let code = draft.currencyCode
        return VStack(alignment: .leading, spacing: 12) {
            Button {
                isEditingSplit = true
            } label: {
                HStack(spacing: 12) {
                    HStack(spacing: -8) {
                        ForEach(draft.everyone) { person in
                            AEAvatar(person: person, size: 34)
                                .background(Color(.systemBackground), in: .rect(cornerRadius: 12, style: .continuous))
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        draft.splitSummary
                            .font(.subheadline.weight(.semibold))
                        Text("Your share \(draft.myShare, format: .currency(code: code)) · owed \(draft.owedToYou, format: .currency(code: code))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Spacer(minLength: 4)
                    R2Chevron()
                }
                .padding(12)
                .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Edit people, mode and shares"))

            if !draft.splitIssues.isEmpty || draft.splitMode == .exact {
                AESplitFooter(draft: draft)
            }
        }
    }
}

#Preview("Ibis · Add") {
    AEHomeHost { IbisEditor(draft: $0) }
}

#Preview("Ibis · Edit split") {
    AEDetailHost { IbisEditor(draft: .editSplitSample) }
}
#endif
