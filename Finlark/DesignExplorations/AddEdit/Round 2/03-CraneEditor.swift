//
//  03-CraneEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2 "Crane". Category: every category as wrapping chips, all visible at once.
//  Split: people go in a "With:" field like Mail's "To:" field. Type a name, pick a suggestion or add
//  someone new, and remove people with the ×. The mode is a pull-down menu.
//

#if DEBUG
import SwiftUI

struct CraneEditor: View {
    @State private var draft: AEDraft

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        AE2KestrelShell(draft: draft) {
            AE2CategoryChipFlow(draft: draft)
        } split: {
            VStack(alignment: .leading, spacing: 14) {
                CraneRecipientField(draft: draft)
                Divider()
                HStack {
                    Text("Split")
                        .foregroundStyle(.secondary)
                    Menu {
                        Picker("Split mode", selection: $draft.splitMode) {
                            ForEach(AESplitMode.allCases) { mode in
                                Label {
                                    Text(mode.title)
                                    Text(mode.shortExplanation)
                                } icon: {
                                    Image(systemName: mode.symbol)
                                }
                                .tag(mode)
                            }
                        }
                    } label: {
                        Label {
                            Text(draft.splitMode.title)
                        } icon: {
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .labelStyle(CraneTrailingIconLabelStyle())
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(Text("Split mode"))
                    .accessibilityValue(Text(draft.splitMode.title))
                    Spacer()
                }
                AE2SharesBlock(draft: draft)
            }
        }
    }
}

/// A token per participant plus a text field, with suggestions underneath while typing.
private struct CraneRecipientField: View {
    @Bindable var draft: AEDraft

    @State private var query = ""
    @FocusState private var isFocused: Bool

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }

    private var suggestions: [AEPerson] {
        draft.people.filter { person in
            !draft.isIncluded(person)
                && (trimmedQuery.isEmpty || person.name.localizedCaseInsensitiveContains(trimmedQuery))
        }
    }

    private var canAddNew: Bool {
        !trimmedQuery.isEmpty
            && !draft.people.contains { $0.name.localizedCaseInsensitiveCompare(trimmedQuery) == .orderedSame }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AEFlowLayout(spacing: 6, lineSpacing: 8) {
                Text("With:")
                    .foregroundStyle(.secondary)
                AEPersonChip(person: .me, isSelected: true, isLocked: false) {}
                    .disabled(true)
                ForEach(draft.participants) { person in
                    token(person)
                }
                TextField("Add a person", text: $query)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit(addTypedPerson)
                    .fixedSize()
            }

            if isFocused, !suggestions.isEmpty || canAddNew {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { person in
                        Button {
                            draft.toggle(person)
                            query = ""
                        } label: {
                            HStack(spacing: 10) {
                                AEAvatar(person: person, size: 26)
                                person.displayName
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                    if canAddNew {
                        Button(action: addTypedPerson) {
                            Label("Add “\(trimmedQuery)” as a new person", systemImage: "person.badge.plus")
                                .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(.fill.quaternary, in: .rect(cornerRadius: 14, style: .continuous))
            }
        }
    }

    private func token(_ person: AEPerson) -> some View {
        let canRemove = draft.canRemove(person)
        return Button {
            draft.toggle(person)
        } label: {
            HStack(spacing: 6) {
                AEAvatar(person: person, size: 22)
                person.displayName
                Image(systemName: canRemove ? "xmark" : "lock.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline.weight(.medium))
            .padding(.leading, 4)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
            .background(person.color.opacity(0.16), in: .capsule)
        }
        .buttonStyle(.plain)
        .disabled(!canRemove)
        .accessibilityLabel(person.displayName)
        .accessibilityHint(canRemove ? Text("Removes them from the split") : Text("Has already repaid part of the share, so can't be removed."))
    }

    /// Return adds the top suggestion, as Mail does, or a new person when nobody matches.
    private func addTypedPerson() {
        guard !trimmedQuery.isEmpty else { return }
        if let match = suggestions.first {
            draft.toggle(match)
        } else if canAddNew {
            draft.addPerson(named: trimmedQuery)
        }
        query = ""
    }
}

private struct CraneTrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
                .font(.caption.weight(.semibold))
        }
    }
}

#Preview("Crane · Add") {
    AEHomeHost { CraneEditor(draft: $0) }
}

#Preview("Crane · Edit split") {
    AEDetailHost { CraneEditor(draft: .editSplitSample) }
}
#endif
