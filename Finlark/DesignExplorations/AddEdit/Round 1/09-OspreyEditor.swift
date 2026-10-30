//
//  09-OspreyEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Osprey": a composer. The screen is just the signed amount and a few
//  words about it; everything else lives in a Liquid Glass bar that rides on top of the keyboard,
//  like the formatting bar in Notes. Each button shows what's set (the category's own icon, a filled
//  note) and opens a small sheet.
//

#if DEBUG
import SwiftUI

struct OspreyEditor: View {
    private enum Sheet: Identifiable {
        case category
        case date
        case note
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
            VStack(spacing: 20) {
                Spacer(minLength: 0)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(verbatim: draft.type == .expense ? "−" : "+")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    AEAmountField(draft: draft, focus: $isAmountFocused, baseSize: 64)
                }
                summary
                Spacer(minLength: 0)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .safeAreaInset(edge: .bottom) { composerBar }
            .aeEditorChrome(draft)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Type", selection: $draft.type) {
                        Text("Expense").tag(ExplorationTransactionType.expense)
                        Text("Income").tag(ExplorationTransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    // Not disabled: in the toolbar a disabled segmented picker hides its selection.
                    // The draft refuses income while split, and the summary says why.
                    .fixedSize()
                }
            }
            .sheet(item: $sheet) { sheet in
                switch sheet {
                case .category: AECategorySheet(draft: draft)
                case .date: AEDateSheet(date: $draft.date)
                case .note: AENoteSheet(note: $draft.note)
                case .split: AESplitSheet(draft: draft)
                }
            }
        }
        .onAppear { isAmountFocused = draft.purpose == .add }
    }

    /// What's set so far, in words.
    private var summary: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                if let category = draft.category {
                    Image(systemName: category.symbol)
                        .foregroundStyle(category.color)
                    Text(category.name)
                } else {
                    Text("No category yet")
                        .foregroundStyle(.secondary)
                }
                Text(verbatim: "·")
                    .foregroundStyle(.tertiary)
                AEDateText(date: draft.date)
            }
            .font(.headline)

            if !draft.note.isEmpty {
                Text(verbatim: draft.note)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if draft.isSplit {
                Text("Split \(draft.splitSummary) · your share \(draft.myShare, format: .currency(code: code))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            if !draft.canChangeType {
                Text("A split expense can't become income. Turn off Split first.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .multilineTextAlignment(.center)
    }

    private var composerBar: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                barButton("Category", symbol: draft.category?.symbol ?? "square.grid.2x2",
                          tint: draft.category?.color, isSet: draft.category != nil) { sheet = .category }
                barButton("Date", symbol: "calendar", isSet: !Calendar.current.isDateInToday(draft.date)) {
                    sheet = .date
                }
                barButton("Note", symbol: draft.note.isEmpty ? "text.bubble" : "text.bubble.fill",
                          isSet: !draft.note.isEmpty) { sheet = .note }
                if draft.type == .expense {
                    barButton("Split", symbol: draft.isSplit ? "person.2.fill" : "person.2",
                              isSet: draft.isSplit) { sheet = .split }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func barButton(
        _ title: LocalizedStringKey,
        symbol: String,
        tint: Color? = nil,
        isSet: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.title3)
                    .foregroundStyle(tint ?? (isSet ? Color.accentColor : Color.primary))
                Text(title)
                    .font(.caption2.weight(.medium))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18, style: .continuous))
        .accessibilityValue(isSet ? Text("Set") : Text("Not set"))
    }
}

#Preview("Osprey · Add") {
    AEHomeHost { OspreyEditor(draft: $0) }
}

#Preview("Osprey · Edit split") {
    AEDetailHost { OspreyEditor(draft: .editSplitSample) }
}
#endif
