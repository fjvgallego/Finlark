//
//  06-StarlingEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Starling": the transaction as a sentence you fill in. "I spent [€24]
//  on [Dining] [today]", where every bracket is a control. A split adds a second sentence ("Split
//  [equally] with [Marta, Luis]") and the result in words. Fragments are localized one by one, so
//  each language needs its word order checked (Spanish reads the same way).
//

#if DEBUG
import SwiftUI

struct StarlingEditor: View {
    private enum Sheet: Identifiable {
        case category
        case split

        var id: Self { self }
    }

    @State private var draft: AEDraft
    @State private var sheet: Sheet?
    @FocusState private var isAmountFocused: Bool

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    private var code: String { draft.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    mainSentence
                    if draft.isSplit {
                        splitSentence
                    } else if draft.type == .expense {
                        Button("Split it with friends", systemImage: "person.2") {
                            draft.isSplit = true
                            sheet = .split
                        }
                        .buttonStyle(.glass)
                    }

                    TextField("Note", text: $draft.note, prompt: Text("Add a note"), axis: .vertical)
                        .font(.title3)
                        .padding(14)
                        .background(.fill.tertiary, in: .rect(cornerRadius: 16, style: .continuous))

                    if draft.purpose == .add, draft.total > 0 {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("When you save")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                            AEImpactSummary(draft: draft)
                        }
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .aeEditorChrome(draft)
            .sheet(item: $sheet) { sheet in
                switch sheet {
                case .category: AECategorySheet(draft: draft)
                case .split: AESplitSheet(draft: draft)
                }
            }
        }
        .onAppear { isAmountFocused = draft.purpose == .add }
    }

    // MARK: Sentences

    private var mainSentence: some View {
        AEFlowLayout(spacing: 8, lineSpacing: 10) {
            Menu {
                Picker("Type", selection: $draft.type) {
                    Text("I spent").tag(ExplorationTransactionType.expense)
                    Text("I received").tag(ExplorationTransactionType.income)
                }
            } label: {
                StarlingToken(isEmpty: false) {
                    draft.type == .expense ? Text("I spent") : Text("I received")
                }
            }
            .disabled(!draft.canChangeType)
            .accessibilityLabel(Text("Type"))
            .accessibilityValue(Text(draft.type.title))

            if draft.isAmountFromItems {
                StarlingToken(isEmpty: false) {
                    Text(draft.total, format: .currency(code: code))
                }
                .accessibilityLabel(Text("Amount, sum of the items"))
            } else {
                StarlingToken(isEmpty: draft.amountText.isEmpty) {
                    AEAmountField(draft: draft, focus: $isAmountFocused, baseSize: 28)
                }
            }

            draft.type == .expense ? Text("on") : Text("from")

            Button {
                sheet = .category
            } label: {
                StarlingToken(isEmpty: draft.category == nil) {
                    if let category = draft.category {
                        Label {
                            Text(category.name)
                        } icon: {
                            Image(systemName: category.symbol)
                                .foregroundStyle(category.color)
                        }
                    } else {
                        Text("a category")
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Category"))

            AEDateMenu(draft: draft) {
                StarlingToken(isEmpty: false) {
                    AEDateText(date: draft.date, inSentence: true)
                }
            }
            .accessibilityLabel(Text("Date"))
        }
        .font(.system(.title, design: .rounded, weight: .semibold))
    }

    private var splitSentence: some View {
        VStack(alignment: .leading, spacing: 12) {
            AEFlowLayout(spacing: 8, lineSpacing: 10) {
                Text("Split")
                Menu {
                    Picker("Split mode", selection: $draft.splitMode) {
                        ForEach(AESplitMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                } label: {
                    StarlingToken(isEmpty: false) { modeWords }
                }
                .accessibilityLabel(Text("Split mode"))
                Text("with")
                Button {
                    sheet = .split
                } label: {
                    StarlingToken(isEmpty: draft.participants.isEmpty) {
                        if draft.participants.isEmpty {
                            Text("someone")
                        } else {
                            Text(draft.participants.map(\.name).formatted(.list(type: .and)))
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("People and shares"))
            }
            .font(.system(.title, design: .rounded, weight: .semibold))

            Text(resultSentence)
                .font(.title3)
                .foregroundStyle(.secondary)

            if !draft.splitIssues.isEmpty || draft.splitMode != .equal {
                Button("Edit shares", systemImage: "slider.horizontal.3") { sheet = .split }
                    .buttonStyle(.glass)
                AESplitFooter(draft: draft)
            }
        }
    }

    private var modeWords: Text {
        switch draft.splitMode {
        case .equal: Text("equally")
        case .exact: Text("by exact amounts")
        case .byItem: Text("by item")
        }
    }

    private var resultSentence: LocalizedStringKey {
        "Your share is \(draft.myShare, format: .currency(code: code)), and \(draft.owedToYou, format: .currency(code: code)) is owed to you."
    }
}

/// A fill-in-the-blank slot in the sentence: tinted when filled, dashed when still empty.
private struct StarlingToken<Content: View>: View {
    let isEmpty: Bool
    @ViewBuilder let content: Content

    var body: some View {
        content
            .foregroundStyle(isEmpty ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
            .padding(.horizontal, 10)
            .padding(.vertical, 2)
            .background {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isEmpty ? AnyShapeStyle(.clear) : AnyShapeStyle(.tint.opacity(0.12)))
            }
            .overlay {
                if isEmpty {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                }
            }
    }
}

#Preview("Starling · Add") {
    AEHomeHost { StarlingEditor(draft: $0) }
}

#Preview("Starling · Edit split") {
    AEDetailHost { StarlingEditor(draft: .editSplitSample) }
}
#endif
