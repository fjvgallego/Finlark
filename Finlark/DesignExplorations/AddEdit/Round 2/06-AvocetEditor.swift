//
//  06-AvocetEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2 "Avocet". Category: the system wheel, compact and familiar from the
//  Clock and Calendar pickers. Split: each participant is a card in a row that scrolls sideways,
//  holding their share (a field in Exact amounts), what they've repaid and a remove button. The last
//  card adds people.
//

#if DEBUG
import SwiftUI

struct AvocetEditor: View {
    @State private var draft: AEDraft

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        AE2KestrelShell(draft: draft) {
            Picker("Category", selection: $draft.categoryID) {
                Text("Choose a category")
                    .foregroundStyle(.secondary)
                    .tag(String?.none)
                ForEach(draft.type.frequentCategories) { category in
                    HStack(spacing: 8) {
                        Image(systemName: category.symbol)
                            .foregroundStyle(category.color)
                        Text(category.name)
                    }
                    .tag(Optional(category.id))
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 150)
        } split: {
            VStack(alignment: .leading, spacing: 14) {
                AESplitModePicker(draft: draft)
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 10) {
                        ForEach(draft.shares) { share in
                            AvocetPersonCard(draft: draft, share: share)
                        }
                        AvocetAddCard(draft: draft)
                    }
                    // Cards share the height of the tallest.
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                if draft.splitMode == .byItem {
                    AEItemRows(draft: draft, isCarded: true)
                }
                AESplitFooter(draft: draft)
            }
        }
    }
}

private struct AvocetPersonCard: View {
    let draft: AEDraft
    let share: AEShare

    @ScaledMetric private var width: CGFloat = 128

    var body: some View {
        let person = share.person
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                AEAvatar(person: person, size: 36)
                Spacer(minLength: 4)
                if !person.isMe {
                    if draft.canRemove(person) {
                        Button("Remove", systemImage: "xmark.circle.fill") {
                            withAnimation(.snappy) { draft.toggle(person) }
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel(Text("Remove \(person.name)"))
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("Can't be removed: has repaid part of the share"))
                    }
                }
            }
            person.displayName
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            if draft.splitMode == .exact {
                AEMoneyField(title: "Share", text: draft.exactText(for: person), draft: draft)
            } else {
                Text(share.amount, format: .currency(code: draft.currencyCode))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }
            Group {
                if share.repaid > 0 {
                    Text("\(share.repaid, format: .currency(code: draft.currencyCode)) repaid")
                } else if person.isMe {
                    Text("Your spending")
                } else {
                    Text("Owes you")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(width: width, alignment: .leading)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(person.color.opacity(0.1), in: .rect(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(person.color.opacity(0.35), lineWidth: 1)
        }
    }
}

/// A dashed card with a menu of people not in the split yet, plus "New person".
private struct AvocetAddCard: View {
    @Bindable var draft: AEDraft

    @State private var isAddingPerson = false
    @State private var newName = ""
    @ScaledMetric private var width: CGFloat = 104

    var body: some View {
        Menu {
            ForEach(draft.people.filter { !draft.isIncluded($0) }) { person in
                Button {
                    withAnimation(.snappy) { draft.toggle(person) }
                } label: {
                    Text(verbatim: person.name)
                }
            }
            Divider()
            Button("New person…", systemImage: "person.badge.plus") {
                newName = ""
                isAddingPerson = true
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                Text("Add person")
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(.tint)
            .frame(width: width)
            .frame(maxHeight: .infinity)
            .padding(.vertical, 12)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(.tint, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
            }
        }
        .buttonStyle(.plain)
        .alert("New person", isPresented: $isAddingPerson) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Add") { draft.addPerson(named: newName) }
        } message: {
            Text("They'll be added to this split and to People.")
        }
    }
}

#Preview("Avocet · Add") {
    AEHomeHost { AvocetEditor(draft: $0) }
}

#Preview("Avocet · Edit split") {
    AEDetailHost { AvocetEditor(draft: .editSplitSample) }
}
#endif
