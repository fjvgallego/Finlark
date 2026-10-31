//
//  07-CalicoCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Calico": edited in place. Tapping a category opens it right in the list,
//  with the name, a row of colors, a row of icons related to the current one (and All Icons for the
//  rest), the type, and Save. The + button opens a new one the same way at the top. No sheet to lose
//  your place in.
//

#if DEBUG
import SwiftUI

struct CalicoCategories: View {
    @Bindable var store: CTStore

    @State private var type: ExplorationTransactionType = .expense
    @State private var draft: CTDraft?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(store: CTStore, editing id: CTCategory.ID? = nil) {
        self.store = store
        _draft = State(initialValue: id.flatMap(store.category).map { CTDraft(editing: $0) })
    }

    var body: some View {
        CTScreen(store: store, addType: type, showsAddButton: false) { actions in
            CTTypeSwitch(selection: $type)
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(
                        title: type == .expense ? "Expense categories" : "Income categories",
                        symbol: "square.grid.2x2.fill"
                    )
                    if let draft, draft.isNew {
                        CalicoInlineEditor(store: store, draft: draft, actions: actions, close: close)
                        Divider()
                    }
                    let categories = store.active(type)
                    ForEach(categories) { category in
                        if let draft, draft.original?.id == category.id {
                            CalicoInlineEditor(store: store, draft: draft, actions: actions, close: close)
                        } else {
                            Button { open(category) } label: {
                                CTRow(category: category)
                            }
                            .buttonStyle(.plain)
                            .ctArchiveMenu(category, actions: actions)
                            .accessibilityHint(Text("Opens it here to edit."))
                        }
                        if category.id != categories.last?.id {
                            Divider()
                        }
                    }
                }
            }
            CTArchivedTile(categories: store.archived(type), actions: actions)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Add Category", systemImage: "plus") {
                    withAnimation(reduceMotion ? nil : .snappy) { draft = CTDraft(type: type) }
                }
            }
        }
        .onChange(of: type) { close() }
    }

    private func open(_ category: CTCategory) {
        withAnimation(reduceMotion ? nil : .snappy) { draft = CTDraft(editing: category) }
    }

    private func close() {
        withAnimation(reduceMotion ? nil : .snappy) { draft = nil }
    }
}

/// The category opened in place.
private struct CalicoInlineEditor: View {
    let store: CTStore
    @Bindable var draft: CTDraft
    let actions: CTActions
    let close: () -> Void

    @State private var showsAllIcons = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                if !dynamicTypeSize.isAccessibilitySize {
                    CTBadge(symbol: draft.symbol, color: draft.color, size: 44)
                }
                CTNameField(store: store, draft: draft)
            }
            CTColorPalette(selection: $draft.color, layout: .row)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(nearbySymbols) { symbol in
                        CTSymbolCell(symbol: symbol, color: draft.color, isSelected: draft.symbol == symbol.name) {
                            draft.symbol = symbol.name
                            draft.pickedSymbol = true
                        }
                    }
                    Button("All Icons") { showsAllIcons = true }
                        .buttonStyle(.glass)
                }
            }
            .scrollIndicators(.hidden)
            CTTypeControl(draft: draft)

            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 8))
                : AnyLayout(HStackLayout(spacing: 8))
            layout {
                Button { close() } label: {
                    Text("Cancel").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                Button {
                    store.save(draft.category)
                    close()
                } label: {
                    Text("Save").frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .disabled(draft.issue(in: store) != nil)
            }
            .controlSize(.large)

            if let original = draft.original {
                Button("Archive Category", systemImage: "archivebox") {
                    close()
                    actions.archive(original)
                }
                .buttonStyle(.borderless)
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity)
            }
        }
        .padding(14)
        .background(.fill.quaternary, in: .rect(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, -6)
        .sheet(isPresented: $showsAllIcons) {
            CalicoIconSheet(draft: draft)
        }
    }

    /// The current icon's group, so the row starts with related icons.
    private var nearbySymbols: [CTSymbol] {
        let group = CTSymbolGroup.all.first { $0.symbols.contains { $0.name == draft.symbol } }
        return (group ?? CTSymbolGroup.all[0]).symbols
    }
}

private struct CalicoIconSheet: View {
    @Bindable var draft: CTDraft
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                CTSymbolPicker(draft: draft)
                    .padding()
            }
            .navigationTitle("Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", role: .confirm) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview("Calico") {
    CTHost { CalicoCategories(store: $0) }
}

#Preview("Calico · Editing") {
    CTHost { CalicoCategories(store: $0, editing: "dining") }
}

#Preview("Calico · Dark") {
    CTHost { CalicoCategories(store: $0, editing: "dining") }
        .preferredColorScheme(.dark)
}
#endif
