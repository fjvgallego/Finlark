//
//  AddEditRound2Components.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2: Kestrel, the owner's pick, as a shell. Amount, details and the "When you
//  save" tile stay as they are; each variant swaps in its own category control and split control.
//

#if DEBUG
import SwiftUI

// MARK: - Kestrel shell

struct AE2KestrelShell<CategoryControl: View, SplitControl: View>: View {
    @Bindable var draft: AEDraft
    /// Runs before Save dismisses.
    var onSave: (() -> Void)?
    @ViewBuilder var category: CategoryControl
    /// Shown in the split tile while the split is on.
    @ViewBuilder var split: SplitControl

    var body: some View {
        NavigationStack {
            ScrollView {
                AE2KestrelTiles(draft: draft) { category } split: { split }
                    .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background { R2Backdrop() }
            .aeEditorChrome(draft, onSave: onSave)
        }
    }
}

/// The shell's tiles without the screen around them, so the transaction detail can switch into them
/// in place when editing.
struct AE2KestrelTiles<CategoryControl: View, SplitControl: View>: View {
    @Bindable var draft: AEDraft
    @ViewBuilder var category: CategoryControl
    @ViewBuilder var split: SplitControl

    @FocusState private var isAmountFocused: Bool

    var body: some View {
        VStack(spacing: r2TileSpacing) {
            R2Tile(padding: 18) {
                VStack(spacing: 16) {
                    AETypePicker(draft: draft)
                    AEAmountField(draft: draft, focus: $isAmountFocused)
                        .frame(maxWidth: .infinity)
                }
            }

            R2Tile {
                VStack(alignment: .leading, spacing: 10) {
                    R2TileHeader(title: "Category", symbol: "square.grid.2x2.fill")
                    category
                }
            }

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

            if draft.type == .expense {
                R2Tile {
                    VStack(alignment: .leading, spacing: 14) {
                        Toggle(isOn: $draft.isSplit.animation()) {
                            Label("Split with friends", systemImage: "person.2.fill")
                                .font(.headline)
                        }
                        if draft.isSplit {
                            split
                        } else {
                            Text("For an expense you paid that others owe you part of.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
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
        .onAppear { isAmountFocused = draft.purpose == .add }
    }
}
#endif
