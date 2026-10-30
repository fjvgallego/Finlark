//
//  10-RobinEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Robin": a list that opens in place, like Calendar's event editor.
//  Each row shows its value; tapping it expands the control right there (category grid, calendar,
//  split modes with what each one means), and only one row is open at a time. Nothing is pushed or
//  presented, so you never lose sight of the rest.
//

#if DEBUG
import SwiftUI

struct RobinEditor: View {
    private enum Row: Hashable {
        case category
        case date
        case people
        case mode
    }

    @State private var draft: AEDraft
    @State private var expanded: Row?
    @FocusState private var isAmountFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    private var code: String { draft.currencyCode }

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
                    expandableRow(.category, title: "Category") {
                        AECategoryLabel(category: draft.category)
                    } content: {
                        AECategoryGrid(draft: draft) { toggle(.category) }
                            .padding(.vertical, 4)
                    }
                    expandableRow(.date, title: "Date") {
                        AEDateText(date: draft.date)
                    } content: {
                        DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                    }
                    TextField("Note", text: $draft.note, prompt: Text("Note (optional)"), axis: .vertical)
                }

                if draft.type == .expense {
                    splitSections
                }
            }
            .aeEditorChrome(draft)
        }
        .onAppear { isAmountFocused = draft.purpose == .add }
    }

    @ViewBuilder
    private var splitSections: some View {
        Section {
            Toggle(isOn: $draft.isSplit.animation()) {
                Label("Split with friends", systemImage: "person.2.fill")
            }
            if draft.isSplit {
                expandableRow(.people, title: "With") {
                    Text(draft.participants.map(\.name).formatted(.list(type: .and)))
                        .lineLimit(1)
                } content: {
                    AEPeoplePicker(draft: draft)
                        .padding(.vertical, 4)
                }
                expandableRow(.mode, title: "Split mode") {
                    Text(draft.splitMode.title)
                } content: {
                    ForEach(AESplitMode.allCases) { mode in
                        modeOption(mode)
                    }
                }
            }
        } footer: {
            if !draft.isSplit {
                Text("For an expense you paid that others owe you part of.")
            }
        }

        if draft.isSplit {
            if draft.splitMode == .byItem {
                Section("Items") {
                    AEItemRows(draft: draft)
                }
            }
            Section {
                AEShareRows(draft: draft)
            } header: {
                Text("Shares")
            } footer: {
                AESplitFooter(draft: draft)
            }
        }
    }

    /// A mode with its explanation, checked when chosen.
    private func modeOption(_ mode: AESplitMode) -> some View {
        Button {
            draft.splitMode = mode
            toggle(.mode)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: mode.symbol)
                    .foregroundStyle(.tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title)
                        .foregroundStyle(.primary)
                    Text(mode.explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if draft.splitMode == mode {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(draft.splitMode == mode ? .isSelected : [])
    }

    /// A row with its current value; tapping it opens the control below it as another row.
    @ViewBuilder
    private func expandableRow<Value: View, Content: View>(
        _ row: Row,
        title: LocalizedStringKey,
        @ViewBuilder value: () -> Value,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isExpanded = expanded == row
        Button {
            toggle(row)
        } label: {
            LabeledContent {
                value()
                    .foregroundStyle(isExpanded ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            } label: {
                Text(title)
                    .foregroundStyle(.primary)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))

        if isExpanded {
            content()
        }
    }

    private func toggle(_ row: Row) {
        withAnimation(reduceMotion ? nil : .snappy) {
            expanded = expanded == row ? nil : row
        }
    }
}

#Preview("Robin · Add") {
    AEHomeHost { RobinEditor(draft: $0) }
}

#Preview("Robin · Edit split") {
    AEDetailHost { RobinEditor(draft: .editSplitSample) }
}
#endif
