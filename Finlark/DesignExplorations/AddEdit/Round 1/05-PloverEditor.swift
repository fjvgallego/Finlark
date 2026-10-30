//
//  05-PloverEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Plover": a half sheet for the quick case. Home stays visible behind it;
//  amount, a chip row of frequent categories, date and note fit in the medium detent. Splitting grows
//  the sheet to full height and reveals the split editor below.
//

#if DEBUG
import SwiftUI

struct PloverEditor: View {
    @State private var draft: AEDraft
    @State private var detent: PresentationDetent
    @FocusState private var isAmountFocused: Bool

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
        _detent = State(initialValue: draft.isSplit ? .large : .medium)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Picker("Type", selection: $draft.type) {
                            Label("Expense", systemImage: ExplorationTransactionType.expense.symbol)
                                .tag(ExplorationTransactionType.expense)
                            Label("Income", systemImage: ExplorationTransactionType.income.symbol)
                                .tag(ExplorationTransactionType.income)
                        }
                        .pickerStyle(.menu)
                        .buttonStyle(.glass)
                        .disabled(!draft.canChangeType)

                        Spacer()

                        AEDateMenu(draft: draft) {
                            Label { AEDateText(date: draft.date) } icon: { Image(systemName: "calendar") }
                        }
                        .buttonStyle(.glass)
                    }

                    AEAmountField(draft: draft, focus: $isAmountFocused)

                    AECategoryChips(draft: draft)
                        .scrollClipDisabled()

                    TextField("Note", text: $draft.note, prompt: Text("Add a note"), axis: .vertical)
                        .padding(12)
                        .background(.fill.tertiary, in: .rect(cornerRadius: 14, style: .continuous))

                    if draft.type == .expense {
                        if draft.isSplit {
                            split
                        } else {
                            Button("Split with friends", systemImage: "person.2") {
                                withAnimation {
                                    draft.isSplit = true
                                    detent = .large
                                }
                            }
                            .buttonStyle(.glass)
                        }
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .aeEditorChrome(draft)
        }
        .presentationDetents([.medium, .large], selection: $detent)
        .presentationBackgroundInteraction(.disabled)
        .onAppear { isAmountFocused = draft.purpose == .add }
    }

    private var split: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Split", systemImage: "person.2.fill")
                    .font(.headline)
                Spacer()
                Button("Don't split", role: .destructive) {
                    withAnimation { draft.isSplit = false }
                }
                .font(.subheadline)
            }
            AEPeoplePicker(draft: draft)
            AESplitModePicker(draft: draft)
            if draft.splitMode == .byItem {
                AEItemRows(draft: draft, isCarded: true)
            }
            VStack(spacing: 12) {
                AEShareRows(draft: draft)
            }
            .padding(14)
            .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
            AESplitFooter(draft: draft)
        }
        .padding(.top, 8)
    }
}

#Preview("Plover · Add") {
    AEHomeHost { PloverEditor(draft: $0) }
}

#Preview("Plover · Edit split") {
    AEDetailHost { PloverEditor(draft: .editSplitSample) }
}
#endif
