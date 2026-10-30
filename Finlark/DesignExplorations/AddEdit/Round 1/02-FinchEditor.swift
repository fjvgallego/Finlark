//
//  02-FinchEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Finch": calculator first. A huge amount over an in-app glass keypad,
//  so the screen never jumps when a keyboard appears. Frequent categories sit in a chip row above
//  the keypad, and date, note and split are glass buttons that open small sheets.
//

#if DEBUG
import SwiftUI

struct FinchEditor: View {
    private enum Detail: Identifiable {
        case note
        case split

        var id: Self { self }
    }

    @State private var draft: AEDraft
    @State private var detail: Detail?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    private var code: String { draft.currencyCode }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Scrolls only when large text doesn't fit above the keypad; otherwise stays centered.
                ScrollView {
                    VStack(spacing: 24) {
                        AETypePicker(draft: draft)
                        amount
                    }
                    .padding(.horizontal)
                }
                .defaultScrollAnchor(.center, for: .alignment)
                .scrollBounceBehavior(.basedOnSize)

                VStack(spacing: 14) {
                    AECategoryChips(draft: draft)
                        .contentMargins(.horizontal, 16, for: .scrollContent)
                    detailButtons
                        .padding(.horizontal)
                    AEKeypad(text: $draft.amountText, fractionDigits: draft.fractionDigits)
                        .disabled(draft.isAmountFromItems)
                        .opacity(draft.isAmountFromItems ? 0.4 : 1)
                        .padding(.horizontal)
                }
                .padding(.bottom, 8)
            }
            .aeEditorChrome(draft)
            .sheet(item: $detail) { detail in
                switch detail {
                case .note: AENoteSheet(note: $draft.note)
                case .split: AESplitSheet(draft: draft)
                }
            }
        }
    }

    private var amount: some View {
        VStack(spacing: 6) {
            AEAmountText(text: draft.amountDisplayText, currencyCode: code, baseSize: 64)
            if draft.isAmountFromItems {
                Text("Sum of the items")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if draft.isSplit {
                Text("Your share \(draft.myShare, format: .currency(code: code)) · \(draft.splitSummary)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private var detailButtons: some View {
        GlassEffectContainer(spacing: 8) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 8))
                : AnyLayout(HStackLayout(spacing: 8))
            layout { detailButtonContent }
                .font(.subheadline.weight(.medium))
        }
    }

    @ViewBuilder
    private var detailButtonContent: some View {
        AEDateMenu(draft: draft) {
            Label { AEDateText(date: draft.date) } icon: { Image(systemName: "calendar") }
                .lineLimit(1)
        }
        .buttonStyle(.glass)

        Button {
            detail = .note
        } label: {
            Label {
                draft.note.isEmpty ? Text("Note") : Text(verbatim: draft.note)
            } icon: {
                Image(systemName: "text.bubble")
            }
            .lineLimit(1)
        }
        .buttonStyle(.glass)

        if draft.type == .expense {
            Button {
                detail = .split
            } label: {
                Label {
                    draft.isSplit ? Text("Split · \(draft.everyone.count)") : Text("Split")
                } icon: {
                    Image(systemName: "person.2")
                }
                .lineLimit(1)
            }
            .buttonStyle(.glass)
            .tint(draft.isSplit ? .accentColor : nil)
        }
    }
}

#Preview("Finch · Add") {
    AEHomeHost { FinchEditor(draft: $0) }
}

#Preview("Finch · Edit split") {
    AEDetailHost { FinchEditor(draft: .editSplitSample) }
}
#endif
