//
//  03-HeronEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Heron": one question per screen. Amount, then category (a tap moves
//  on), then details and the split, with "Step 1 of 3" under the title. Editing skips the steps and
//  opens on the details, where amount and category rows push their step screens.
//

#if DEBUG
import SwiftUI

struct HeronEditor: View {
    enum Step: Hashable {
        case amount
        case category
        case details
    }

    @State private var draft: AEDraft
    @State private var path: [Step] = []

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack(path: $path) {
            root
                .navigationDestination(for: Step.self) { step in
                    switch step {
                    case .amount:
                        HeronAmountStep(draft: draft, isAdding: false) { path.removeLast() }
                    case .category:
                        HeronCategoryStep(draft: draft, isAdding: path == [.category]) {
                            // Moving forward only on the first pass; from the details, a pick goes back.
                            if path == [.category] {
                                path.append(.details)
                            } else {
                                path.removeLast()
                            }
                        }
                    case .details:
                        HeronDetailsStep(draft: draft, path: $path)
                    }
                }
        }
        .environment(\.explorationIconStyle, .soft)
    }

    @ViewBuilder
    private var root: some View {
        if draft.purpose == .add {
            HeronAmountStep(draft: draft, isAdding: true) { path.append(.category) }
        } else {
            HeronDetailsStep(draft: draft, path: $path)
        }
    }
}

private struct HeronAmountStep: View {
    @Bindable var draft: AEDraft
    let isAdding: Bool
    let onNext: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            AETypePicker(draft: draft)
            Spacer()
            AEAmountField(draft: draft, focus: $isFocused, baseSize: 64)
            Spacer()
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            Button(action: onNext) {
                Text(isAdding ? "Next" : "Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 34)
            }
            .buttonStyle(.glassProminent)
            .disabled((draft.amount ?? 0) <= 0)
            .padding()
        }
        .aeEditorChrome(draft, title: "Amount", showsCancel: isAdding, showsSave: false)
        .navigationSubtitle(isAdding ? Text("Step 1 of 3") : Text(""))
        .onAppear { isFocused = true }
    }
}

private struct HeronCategoryStep: View {
    @Bindable var draft: AEDraft
    let isAdding: Bool
    let onPick: () -> Void

    var body: some View {
        ScrollView {
            AECategoryGrid(draft: draft, columns: 3, onPick: onPick)
                .padding()
        }
        .aeEditorChrome(draft, title: "Category", showsCancel: false, showsSave: false)
        .navigationSubtitle(isAdding ? Text("Step 2 of 3") : Text(""))
    }
}

private struct HeronDetailsStep: View {
    @Bindable var draft: AEDraft
    @Binding var path: [HeronEditor.Step]

    var body: some View {
        Form {
            Section {
                Button {
                    path.append(.amount)
                } label: {
                    LabeledContent {
                        Text(draft.total, format: .currency(code: draft.currencyCode))
                            .monospacedDigit()
                            .foregroundStyle(.primary)
                    } label: {
                        Label {
                            Text(draft.type.title)
                        } icon: {
                            Image(systemName: draft.type.symbol)
                        }
                    }
                }
                .disabled(draft.isAmountFromItems)
                Button {
                    path.append(.category)
                } label: {
                    LabeledContent("Category") {
                        AECategoryLabel(category: draft.category)
                            .foregroundStyle(.primary)
                    }
                }
            } footer: {
                if draft.isAmountFromItems {
                    Text("In By item mode, the amount is the sum of the items.")
                }
            }
            .tint(.primary)

            Section {
                DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                TextField("Note", text: $draft.note, prompt: Text("Note (optional)"), axis: .vertical)
            }

            if draft.type == .expense {
                AESplitFormSections(draft: draft)
            }
        }
        .aeEditorChrome(
            draft,
            title: draft.purpose == .add ? "Details" : nil,
            showsCancel: draft.purpose == .edit
        )
        .navigationSubtitle(draft.purpose == .add ? Text("Step 3 of 3") : Text(""))
    }
}

#Preview("Heron · Add") {
    AEHomeHost { HeronEditor(draft: $0) }
}

#Preview("Heron · Edit split") {
    AEDetailHost { HeronEditor(draft: .editSplitSample) }
}
#endif
