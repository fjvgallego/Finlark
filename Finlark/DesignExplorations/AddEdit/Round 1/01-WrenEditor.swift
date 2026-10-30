//
//  01-WrenEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Wren": the native baseline. A grouped Form like Settings or Calendar:
//  type, a big amount field, then rows for category (pushed list), date and note, and the split as
//  extra sections that appear when it's turned on.
//

#if DEBUG
import SwiftUI

struct WrenEditor: View {
    @State private var draft: AEDraft
    @FocusState private var isAmountFocused: Bool

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    AETypePicker(draft: draft)
                        .listRowBackground(Color.clear)
                }

                Section {
                    AEAmountField(draft: draft, focus: $isAmountFocused)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                Section {
                    NavigationLink {
                        AECategoryListScreen(draft: draft)
                    } label: {
                        LabeledContent("Category") {
                            AECategoryLabel(category: draft.category)
                        }
                    }
                    DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                    TextField("Note", text: $draft.note, prompt: Text("Note (optional)"), axis: .vertical)
                }

                if draft.type == .expense {
                    AESplitFormSections(draft: draft)
                }
            }
            .aeEditorChrome(draft)
        }
        .onAppear { isAmountFocused = draft.purpose == .add }
    }
}

#Preview("Wren · Add") {
    AEHomeHost { WrenEditor(draft: $0) }
}

#Preview("Wren · Edit split") {
    AEDetailHost { WrenEditor(draft: .editSplitSample) }
}
#endif
