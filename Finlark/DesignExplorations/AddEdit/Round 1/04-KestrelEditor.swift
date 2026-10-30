//
//  04-KestrelEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Kestrel": Marsh's visual language carried into the editor. Glass tiles
//  over the same tinted backdrop: amount, a full category grid, details, and a split tile that grows
//  in place. When adding, a last tile previews what saving does to the balance and spending.
//

#if DEBUG
import SwiftUI

struct KestrelEditor: View {
    @State private var draft: AEDraft
    @FocusState private var isAmountFocused: Bool

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    amountTile
                    categoryTile
                    detailsTile
                    if draft.type == .expense {
                        splitTile
                    }
                    if draft.purpose == .add, draft.total > 0 {
                        R2Tile {
                            VStack(alignment: .leading, spacing: 10) {
                                R2TileHeader(title: "When you save", symbol: "sparkles")
                                AEImpactSummary(draft: draft)
                            }
                        }
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

    private var amountTile: some View {
        R2Tile(padding: 18) {
            VStack(spacing: 16) {
                AETypePicker(draft: draft)
                AEAmountField(draft: draft, focus: $isAmountFocused)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var categoryTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 10) {
                R2TileHeader(title: "Category", symbol: "square.grid.2x2.fill")
                AECategoryGrid(draft: draft)
            }
        }
    }

    private var detailsTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 0) {
                R2TileHeader(title: "Details", symbol: "text.alignleft")
                    .padding(.bottom, 6)
                DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                    .padding(.vertical, 6)
                Divider()
                TextField("Note", text: $draft.note, prompt: Text("Note (optional)"), axis: .vertical)
                    .padding(.vertical, 12)
            }
        }
    }

    private var splitTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: $draft.isSplit.animation()) {
                    Label("Split with friends", systemImage: "person.2.fill")
                        .font(.headline)
                }

                if draft.isSplit {
                    AEPeoplePicker(draft: draft)
                    AESplitModePicker(draft: draft)
                    Text(draft.splitMode.explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    if draft.splitMode == .byItem {
                        VStack(alignment: .leading, spacing: 10) {
                            AEItemRows(draft: draft, isCarded: true)
                        }
                    }
                    VStack(spacing: 12) {
                        AEShareRows(draft: draft)
                    }
                    AESplitFooter(draft: draft)
                } else {
                    Text("For an expense you paid that others owe you part of.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview("Kestrel · Add") {
    AEHomeHost { KestrelEditor(draft: $0) }
}

#Preview("Kestrel · Edit split") {
    AEDetailHost { KestrelEditor(draft: .editSplitSample) }
}
#endif
