//
//  05-GannetEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2 "Gannet". Category: one pull-down button, the most compact option.
//  Split: no mode control at all. It starts equal, and every share is a field: typing in one switches
//  to exact amounts (with "Reset to equal"), and "Itemize the ticket" switches to By item. The mode is
//  still one of the three in the requirements; only the way you reach it changes.
//

#if DEBUG
import SwiftUI

struct GannetEditor: View {
    @State private var draft: AEDraft

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        AE2KestrelShell(draft: draft) {
            Menu {
                Picker("Category", selection: $draft.categoryID) {
                    ForEach(draft.type.frequentCategories) { category in
                        Label {
                            Text(category.name)
                        } icon: {
                            Image(systemName: category.symbol)
                        }
                        .tag(Optional(category.id))
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    if let category = draft.category {
                        ExplorationCategoryIcon(category: category)
                        Text(category.name)
                            .foregroundStyle(.primary)
                    } else {
                        Image(systemName: "square.grid.2x2")
                            .frame(width: 36, height: 36)
                            .background(.fill.tertiary, in: .rect(cornerRadius: 11, style: .continuous))
                        Text("Choose a category")
                    }
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Category"))
            .accessibilityValue(draft.category.map { Text($0.name) } ?? Text("None"))
        } split: {
            VStack(alignment: .leading, spacing: 14) {
                AEPeoplePicker(draft: draft)
                modeLine
                if draft.splitMode == .byItem {
                    AEItemRows(draft: draft, isCarded: true)
                }
                VStack(spacing: 12) {
                    ForEach(draft.shares) { share in
                        AEShareRow(share: share, currencyCode: draft.currencyCode) {
                            if draft.splitMode == .byItem {
                                Text(share.amount, format: .currency(code: draft.currencyCode))
                                    .monospacedDigit()
                                    .fontWeight(.medium)
                            } else {
                                AEMoneyField(title: "Share", text: shareText(for: share), draft: draft)
                            }
                        }
                    }
                }
                AESplitFooter(draft: draft)
            }
        }
    }

    /// Says how it's split and offers the way back or out.
    private var modeLine: some View {
        HStack(spacing: 8) {
            Label {
                Text(modeTitle)
            } icon: {
                Image(systemName: draft.splitMode.symbol)
            }
            .font(.subheadline.weight(.semibold))
            Spacer(minLength: 4)
            switch draft.splitMode {
            case .equal:
                Button("Itemize the ticket", systemImage: "list.bullet.rectangle") {
                    withAnimation { draft.splitMode = .byItem }
                }
            case .exact, .byItem:
                Button("Reset to equal", systemImage: "arrow.uturn.backward") {
                    withAnimation { draft.splitMode = .equal }
                }
            }
        }
        .buttonStyle(.glass)
        .controlSize(.small)
    }

    private var modeTitle: LocalizedStringKey {
        switch draft.splitMode {
        case .equal: "Split equally"
        case .exact: "Custom amounts"
        case .byItem: "By item"
        }
    }

    /// Shows the equal share until someone types; the first edit switches to Exact amounts, which
    /// starts from the equal shares.
    private func shareText(for share: AEShare) -> Binding<String> {
        Binding(
            get: {
                draft.splitMode == .exact
                    ? draft.exactTexts[share.id] ?? ""
                    : AEMoney.text(for: share.amount, fractionDigits: draft.fractionDigits)
            },
            set: { newValue in
                if draft.splitMode != .exact { draft.splitMode = .exact }
                draft.exactTexts[share.id] = newValue
            }
        )
    }
}

#Preview("Gannet · Add") {
    AEHomeHost { GannetEditor(draft: $0) }
}

#Preview("Gannet · Edit split") {
    AEDetailHost { GannetEditor(draft: .editSplitSample) }
}
#endif
