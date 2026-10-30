//
//  08-SparrowEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Sparrow": the split as faces. One compact tile holds the transaction;
//  the split tile shows everyone as a big avatar with their share under it (tap to add or remove),
//  and a bar of the total colored by person, so the split reads at a glance. In Exact amounts the
//  shares under the faces become fields, and the bar shows what's left.
//

#if DEBUG
import SwiftUI

struct SparrowEditor: View {
    @State private var draft: AEDraft
    @FocusState private var isAmountFocused: Bool
    @State private var isAddingPerson = false
    @State private var newName = ""

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    private var code: String { draft.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    transactionTile
                    if draft.type == .expense {
                        splitTile
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background { R2Backdrop() }
            .aeEditorChrome(draft)
        }
        .onAppear { isAmountFocused = draft.purpose == .add }
    }

    private var transactionTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                AETypePicker(draft: draft)
                AEAmountField(draft: draft, focus: $isAmountFocused)
                    .frame(maxWidth: .infinity)
                AECategoryChips(draft: draft)
                HStack(spacing: 12) {
                    DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                        .labelsHidden()
                    TextField("Note", text: $draft.note, prompt: Text("Note"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.fill.tertiary, in: .rect(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private var splitTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                Toggle(isOn: $draft.isSplit.animation()) {
                    Label("Split with friends", systemImage: "person.2.fill")
                        .font(.headline)
                }

                if draft.isSplit {
                    faces
                    SparrowShareBar(draft: draft)
                    AESplitModePicker(draft: draft)
                    if draft.splitMode == .byItem {
                        AEItemRows(draft: draft, isCarded: true)
                    }
                    AESplitFooter(draft: draft)
                }
            }
        }
        .alert("New person", isPresented: $isAddingPerson) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Add") { draft.addPerson(named: newName) }
        } message: {
            Text("They'll be added to this split and to People.")
        }
    }

    private var faces: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 14) {
                SparrowFace(draft: draft, person: .me)
                ForEach(draft.people) { person in
                    SparrowFace(draft: draft, person: person)
                }
                Button {
                    newName = ""
                    isAddingPerson = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .frame(width: 52, height: 52)
                            .overlay {
                                RoundedRectangle(cornerRadius: 17, style: .continuous)
                                    .strokeBorder(.tint, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            }
                        Text("New")
                            .font(.caption)
                    }
                    .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("New person"))
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }
}

/// A person as a big avatar: included people show a check and their share, others are dimmed.
private struct SparrowFace: View {
    let draft: AEDraft
    let person: AEPerson

    var body: some View {
        let isIncluded = draft.isIncluded(person)
        let share = draft.shares.first { $0.id == person.id }

        VStack(spacing: 6) {
            Button {
                withAnimation(.snappy) { draft.toggle(person) }
            } label: {
                AEAvatar(person: person, size: 52)
                    .opacity(isIncluded ? 1 : 0.35)
                    .overlay(alignment: .bottomTrailing) {
                        if isIncluded {
                            Image(systemName: draft.canRemove(person) || person.isMe ? "checkmark.circle.fill" : "lock.circle.fill")
                                .font(.body)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, person.color)
                                .offset(x: 4, y: 4)
                        }
                    }
                    .overlay {
                        // An outline so the face reads as selected without relying on color.
                        RoundedRectangle(cornerRadius: 17, style: .continuous)
                            .strokeBorder(isIncluded ? person.color : .clear, lineWidth: 2)
                    }
            }
            .buttonStyle(.plain)
            .disabled(person.isMe)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(person.displayName)
            .accessibilityValue(isIncluded ? Text("In the split") : Text("Not in the split"))
            .accessibilityAddTraits(isIncluded ? .isSelected : [])

            person.displayName
                .font(.caption.weight(.medium))
                .lineLimit(1)

            if let share {
                if draft.splitMode == .exact {
                    AEMoneyField(title: "Share", text: draft.exactText(for: person), draft: draft)
                        .font(.caption)
                } else {
                    Text(share.amount, format: .currency(code: draft.currencyCode))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
                if share.repaid > 0 {
                    Text("\(share.repaid, format: .currency(code: draft.currencyCode)) repaid")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 64)
    }
}

/// The total as one bar colored by person, in the order of the faces. In Exact amounts, what's
/// still unassigned shows as a hatched gap. Decorative: the shares are written under the faces.
private struct SparrowShareBar: View {
    let draft: AEDraft

    @ScaledMetric(relativeTo: .caption) private var height: CGFloat = 12

    var body: some View {
        let shares = draft.shares.filter { $0.amount > 0 }
        let assigned = shares.reduce(Decimal(0)) { $0 + $1.amount }
        let scale = max(draft.total, assigned).plotValue
        let gap = max(draft.total - assigned, 0).plotValue

        GeometryReader { proxy in
            HStack(spacing: 2) {
                ForEach(shares) { share in
                    Rectangle()
                        .fill(share.person.color.gradient)
                        .frame(width: segmentWidth(share.amount.plotValue, of: scale, in: proxy.size.width, count: shares.count))
                }
                if gap > 0 {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: segmentWidth(gap, of: scale, in: proxy.size.width, count: shares.count))
                }
            }
            .clipShape(.capsule)
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private func segmentWidth(_ value: Double, of scale: Double, in width: CGFloat, count: Int) -> CGFloat {
        guard scale > 0 else { return 0 }
        let available = width - CGFloat(count) * 2
        return max(CGFloat(value / scale) * available, 0)
    }
}

#Preview("Sparrow · Add") {
    AEHomeHost { SparrowEditor(draft: $0) }
}

#Preview("Sparrow · Edit split") {
    AEDetailHost { SparrowEditor(draft: .editSplitSample) }
}
#endif
