//
//  CategoriesComponents.swift
//  Finlark
//
//  FIN-9 Categories: pieces shared by the Categories explorations (CAT-001…003). Categories isn't a tab:
//  Settings links to it (SET-001), so the host is Marsh's tab bar with Categories pushed on Settings.
//  Shared here: the screen around each variant (bar, add button, editor, archive flow), the editor and
//  its parts (name, type, color, icon), rows, the archived tile, and the sheet that asks for a
//  replacement when the category being archived is used by recurring templates (CAT-003). Marsh's look
//  throughout: the tinted backdrop, glass tiles, soft icons, and the system's Liquid Glass for actions.
//

#if DEBUG
import SwiftUI

// MARK: - Host

enum CTRoute: Hashable {
    case categories
}

/// What a preview opens once the screen appears.
enum CTOpening {
    case editor(CTEditorTarget)
    case archive(CTCategory.ID)
}

extension EnvironmentValues {
    @Entry var ctOpening: CTOpening? = nil
}

/// Marsh's tab bar with Categories pushed on Settings.
struct CTHost<Screen: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    @State private var store: CTStore
    @State private var selection: AppTab = .settings
    @State private var path: [CTRoute] = [.categories]
    private let opening: CTOpening?
    private let screen: (CTStore) -> Screen

    init(store: CTStore = .sample, opening: CTOpening? = nil, @ViewBuilder screen: @escaping (CTStore) -> Screen) {
        _store = State(initialValue: store)
        self.opening = opening
        self.screen = screen
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                ContentUnavailableView {
                    Label("Home", systemImage: "house")
                } description: {
                    Text("Marsh isn't part of the Categories exploration.")
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                ContentUnavailableView {
                    Label("History", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Lyra isn't part of the Categories exploration.")
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack(path: $path) {
                    ContentUnavailableView {
                        Label("Settings", systemImage: "gearshape")
                    } description: {
                        Text("Settings isn't part of the Categories exploration.")
                    } actions: {
                        NavigationLink("Open Categories", value: CTRoute.categories)
                            .buttonStyle(.glass)
                    }
                    .navigationTitle("Settings")
                    .navigationDestination(for: CTRoute.self) { _ in
                        screen(store)
                            .environment(\.ctOpening, opening)
                    }
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(\.explorationIconStyle, .soft)
    }
}

// MARK: - Screen

/// What a variant's controls can do.
struct CTActions {
    /// Opens the editor for a new category of a type (CAT-001).
    let add: (ExplorationTransactionType) -> Void
    /// Opens the editor for a new category with its name already typed.
    let addNamed: (ExplorationTransactionType, String) -> Void
    /// Opens the editor (CAT-002).
    let edit: (CTCategory) -> Void
    /// Archives it: asks first, or asks for replacements when recurring templates use it (CAT-003).
    let archive: (CTCategory) -> Void
    /// Brings it back, unless an active category of its type has its name now (CAT-003).
    let unarchive: (CTCategory) -> Void
}

enum CTEditorTarget: Identifiable, Hashable {
    case new(ExplorationTransactionType, name: String)
    case edit(CTCategory.ID)

    var id: String {
        switch self {
        case .new(let type, _): "new-\(type.rawValue)"
        case .edit(let id): id
        }
    }
}

/// An alert for something that can't be done yet, with a way forward when there is one.
private struct CTBlock: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    var rename: CTCategory?
}

/// The screen around a variant: a scroll view of its tiles, the inline title and add button, the editor,
/// and the archive flow.
struct CTScreen<Content: View>: View {
    @Bindable var store: CTStore
    /// The type the add button starts a new category with.
    var addType: ExplorationTransactionType = .expense
    /// False when the content brings its own scrolling container, such as a List.
    var scrolls = true
    var showsAddButton = true
    @ViewBuilder let content: (CTActions) -> Content

    @State private var editing: CTEditorTarget?
    /// Runs once the editor has gone, so a dialog or sheet it leads to can present.
    @State private var afterEditor: (() -> Void)?
    @State private var confirmingArchive: CTCategory?
    @State private var replacing: CTCategory?
    @State private var block: CTBlock?
    @State private var didOpen = false
    @Environment(\.ctOpening) private var opening
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let actions = CTActions(
            add: { editing = .new($0, name: "") },
            addNamed: { editing = .new($0, name: $1) },
            edit: { editing = .edit($0.id) },
            archive: archive,
            unarchive: unarchive
        )

        Group {
            if scrolls {
                ScrollView {
                    VStack(spacing: hmTileSpacing) {
                        content(actions)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                content(actions)
            }
        }
        .background { HMBackdrop() }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsAddButton {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Category", systemImage: "plus") { editing = .new(addType, name: "") }
                }
            }
        }
        .sheet(item: $editing, onDismiss: {
            afterEditor?()
            afterEditor = nil
        }) { target in
            CTEditorSheet(
                store: store,
                target: target,
                onArchive: { category in afterEditor = { archive(category) } },
                onUnarchive: { category in afterEditor = { unarchive(category) } }
            )
        }
        .sheet(item: $replacing) { CTReplacementSheet(store: store, category: $0) }
        .confirmationDialog(
            Text("Archive “\(confirmingArchive?.name ?? "")”?"),
            isPresented: Binding(get: { confirmingArchive != nil }, set: { if !$0 { confirmingArchive = nil } }),
            titleVisibility: .visible,
            presenting: confirmingArchive
        ) { category in
            Button("Archive") {
                withAnimation(reduceMotion ? nil : .snappy) { store.archive(category.id) }
            }
        } message: { category in
            CTArchiveMessage(category: category)
        }
        .alert(
            block?.title ?? Text(""),
            isPresented: Binding(get: { block != nil }, set: { if !$0 { block = nil } }),
            presenting: block
        ) { block in
            if let category = block.rename {
                Button("Rename") { editing = .edit(category.id) }
                Button("Cancel", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: { block in
            block.message
        }
        .task {
            guard !didOpen, let opening else { return }
            didOpen = true
            switch opening {
            case .editor(let target): editing = target
            case .archive(let id): if let category = store.category(id) { archive(category) }
            }
        }
    }

    private func archive(_ category: CTCategory) {
        if store.isLastActive(category) {
            block = CTBlock(
                title: category.type == .expense
                    ? Text("Keep One Expense Category")
                    : Text("Keep One Income Category"),
                message: Text("Every transaction needs a category. Add another one before archiving “\(category.name)”.")
            )
        } else if !store.templates(using: category.id).isEmpty {
            replacing = category
        } else {
            confirmingArchive = category
        }
    }

    private func unarchive(_ category: CTCategory) {
        var issue: CTNameIssue?
        withAnimation(reduceMotion ? nil : .snappy) {
            issue = store.unarchive(category.id)
        }
        if let message = issue?.message {
            block = CTBlock(
                title: Text("Rename It First"),
                message: Text("\(message) Rename one of them, then unarchive “\(category.name)”."),
                rename: category
            )
        }
    }
}

/// What archiving does, for the confirmation (CAT-003). Income has no Plan.
struct CTArchiveMessage: View {
    let category: CTCategory

    var body: some View {
        let count = category.transactionCount
        switch (category.type, count) {
        case (.expense, 0):
            Text("It won't show when you add an expense or in the Plan editor. You can unarchive it at any time.")
        case (.expense, _):
            Text("It won't show when you add an expense or in the Plan editor. ^[\(count) transaction](inflect: true) and your stats will still show it, and you can unarchive it at any time.")
        case (.income, 0):
            Text("It won't show when you add income. You can unarchive it at any time.")
        case (.income, _):
            Text("It won't show when you add income. ^[\(count) transaction](inflect: true) and your stats will still show it, and you can unarchive it at any time.")
        }
    }
}

/// "Expenses" or "Income", for variants that show one type at a time.
struct CTTypeSwitch: View {
    @Binding var selection: ExplorationTransactionType

    var body: some View {
        HMSegmentedControl(
            title: "Type",
            options: [(value: .expense, label: "Expenses"), (value: .income, label: "Income")],
            selection: $selection
        )
    }
}

// MARK: - Text

enum CTUsage {
    /// "142 transactions" or "Not used yet".
    static func count(_ category: CTCategory) -> Text {
        category.transactionCount == 0
            ? Text("Not used yet")
            : Text("^[\(category.transactionCount) transaction](inflect: true)")
    }

    /// "€312.40 this month", or what was received for income.
    static func thisMonth(_ category: CTCategory, code: String) -> Text {
        let amount = category.thisMonth.formatted(.currency(code: code))
        return category.type == .expense
            ? Text("\(amount) spent this month")
            : Text("\(amount) received this month")
    }
}

// MARK: - Icon

/// A category's icon at any size, in the soft look: the symbol in its color on a pale tint of it.
struct CTBadge: View {
    let symbol: String
    let color: CTColor
    @ScaledMetric private var size: CGFloat

    init(symbol: String, color: CTColor, size: CGFloat = 36) {
        self.symbol = symbol
        self.color = color
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.44, weight: .semibold))
            .foregroundStyle(color.color)
            .frame(width: size, height: size)
            .background(color.color.opacity(0.16), in: .rect(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - Rows

extension View {
    /// Edit and Archive (or Unarchive) on long press, and as VoiceOver actions.
    func ctArchiveMenu(_ category: CTCategory, actions: CTActions) -> some View {
        contextMenu {
            Button("Edit", systemImage: "pencil") { actions.edit(category) }
            if category.isArchived {
                Button("Unarchive", systemImage: "tray.and.arrow.up") { actions.unarchive(category) }
            } else {
                Button("Archive", systemImage: "archivebox") { actions.archive(category) }
            }
        }
        .accessibilityAction(named: category.isArchived ? Text("Unarchive") : Text("Archive")) {
            category.isArchived ? actions.unarchive(category) : actions.archive(category)
        }
    }
}

/// A search field for the tiles, since `searchable` only lives in the navigation bar.
struct CTSearchField: View {
    @Binding var text: String
    let prompt: LocalizedStringKey

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(prompt, text: $text)
                .autocorrectionDisabled()
                .submitLabel(.search)
            if !text.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") { text = "" }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.fill.tertiary, in: .capsule)
    }
}

// MARK: - Editor

/// The category being added or edited.
@Observable
final class CTDraft {
    let original: CTCategory?
    let id: CTCategory.ID
    var name: String
    var type: ExplorationTransactionType
    var symbol: String
    var color: CTColor
    /// Set once an icon is picked by hand, so suggestions stop replacing it.
    var pickedSymbol: Bool

    init(type: ExplorationTransactionType, name: String = "") {
        original = nil
        id = UUID().uuidString
        self.name = name
        self.type = type
        symbol = CTSymbolGroup.suggestions(for: name).first?.name ?? "tag.fill"
        color = .blue
        pickedSymbol = false
    }

    init(editing category: CTCategory) {
        original = category
        id = category.id
        name = category.name
        type = category.type
        symbol = category.symbol
        color = category.color
        pickedSymbol = true
    }

    var isNew: Bool { original == nil }

    /// Its type is fixed once it has transactions (CAT-002).
    var canChangeType: Bool { original?.canChangeType ?? true }

    /// Archived categories only need a name: uniqueness is among active ones (CAT-001).
    func issue(in store: CTStore) -> CTNameIssue? {
        if original?.isArchived == true {
            return name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .empty : nil
        }
        return store.nameIssue(name, type: type, excluding: original?.id)
    }

    var category: CTCategory {
        var category = original ?? CTCategory(id: id, name: name, type: type, symbol: symbol, color: color)
        category.name = name
        category.type = type
        category.symbol = symbol
        category.color = color
        return category
    }

    var icon: ExplorationCategory { category.icon }
}

/// The editor sheet: a tile for each part, then what the change does, and Archive.
struct CTEditorSheet: View {
    let store: CTStore
    let onArchive: (CTCategory) -> Void
    let onUnarchive: (CTCategory) -> Void

    @State private var draft: CTDraft
    @Environment(\.dismiss) private var dismiss

    init(
        store: CTStore,
        target: CTEditorTarget,
        onArchive: @escaping (CTCategory) -> Void,
        onUnarchive: @escaping (CTCategory) -> Void
    ) {
        self.store = store
        self.onArchive = onArchive
        self.onUnarchive = onUnarchive
        let draft: CTDraft = switch target {
        case .new(let type, let name): CTDraft(type: type, name: name)
        case .edit(let id): store.category(id).map { CTDraft(editing: $0) } ?? CTDraft(type: .expense)
        }
        _draft = State(initialValue: draft)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: hmTileSpacing) {
                    CTTilesEditor(store: store, draft: draft)
                    footer
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background { HMBackdrop() }
            .navigationTitle(draft.isNew ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        store.save(draft.category)
                        dismiss()
                    }
                    .disabled(draft.issue(in: store) != nil)
                }
            }
            .environment(\.explorationIconStyle, .soft)
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private var footer: some View {
        if let original = draft.original {
            if original.transactionCount > 0 {
                Text("^[\(original.transactionCount) transaction](inflect: true) will show the new name, icon and color.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            // Archiving keeps the changes made here: they're saved first when they're valid.
            Button {
                if draft.issue(in: store) == nil {
                    store.save(draft.category)
                }
                original.isArchived ? onUnarchive(original) : onArchive(original)
                dismiss()
            } label: {
                Group {
                    if original.isArchived {
                        Label("Unarchive Category", systemImage: "tray.and.arrow.up")
                    } else {
                        Label("Archive Category", systemImage: "archivebox")
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
    }
}

/// Tiles: a preview with the name, then type, color and icon.
struct CTTilesEditor: View {
    let store: CTStore
    @Bindable var draft: CTDraft

    var body: some View {
        HMTile(padding: 18) {
            VStack(spacing: 14) {
                CTBadge(symbol: draft.symbol, color: draft.color, size: 72)
                    .frame(maxWidth: .infinity)
                CTNameField(store: store, draft: draft, isProminent: true)
            }
        }
        HMTile {
            VStack(alignment: .leading, spacing: 12) {
                HMTileHeader(title: "Type", symbol: "arrow.up.arrow.down")
                CTTypeControl(draft: draft)
            }
        }
        HMTile {
            VStack(alignment: .leading, spacing: 12) {
                HMTileHeader(title: "Color", symbol: "paintpalette.fill")
                CTColorPalette(selection: $draft.color)
            }
        }
        HMTile {
            VStack(alignment: .leading, spacing: 12) {
                HMTileHeader(title: "Icon", symbol: "square.grid.2x2.fill")
                CTSymbolPicker(draft: draft)
            }
        }
    }
}

/// The name, and why it can't be saved when it clashes (CAT-001).
struct CTNameField: View {
    let store: CTStore
    @Bindable var draft: CTDraft
    var isProminent = false

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: isProminent ? .center : .leading, spacing: 6) {
            TextField("Name", text: $draft.name, prompt: Text("Name"))
                .font(isProminent ? .title2.weight(.bold) : .body.weight(.medium))
                .multilineTextAlignment(isProminent ? .center : .leading)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($isFocused)
                .padding(.vertical, 6)
            if let message = draft.issue(in: store)?.message {
                Label {
                    message
                } icon: {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                }
                .font(.footnote)
                .multilineTextAlignment(isProminent ? .center : .leading)
            }
        }
        .onAppear { isFocused = draft.isNew && draft.name.isEmpty }
    }
}

/// Expense or income, fixed once it has transactions (CAT-002).
struct CTTypeControl: View {
    @Bindable var draft: CTDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HMSegmentedControl(
                title: "Type",
                options: [(value: .expense, label: "Expense"), (value: .income, label: "Income")],
                selection: $draft.type
            )
            .disabled(!draft.canChangeType)
            if !draft.canChangeType {
                Text("It has transactions, so its type can't change.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

/// The colors as round swatches, the picked one with a check so it isn't color alone.
struct CTColorPalette: View {
    enum Layout {
        case grid
        case row
    }

    @Binding var selection: CTColor
    var layout: Layout = .grid

    @ScaledMetric private var size: CGFloat = 34

    var body: some View {
        switch layout {
        case .grid:
            LazyVGrid(columns: [GridItem(.adaptive(minimum: size + 8), spacing: 8)], spacing: 10) {
                swatches
            }
        case .row:
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    swatches
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var swatches: some View {
        ForEach(CTColor.allCases) { color in
            let isSelected = color == selection
            Button { selection = color } label: {
                Circle()
                    .fill(color.color.gradient)
                    .frame(width: size, height: size)
                    .overlay {
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.system(size: size * 0.4, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(3)
                    .overlay {
                        Circle().strokeBorder(isSelected ? color.color : .clear, lineWidth: 2)
                    }
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(color.name))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        }
    }
}

/// Every icon, grouped, with a search field.
struct CTSymbolPicker: View {
    @Bindable var draft: CTDraft
    var showsSearch = true

    @State private var query = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if showsSearch {
                CTSearchField(text: $query, prompt: "Search icons")
            }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                ForEach(CTSymbolGroup.all) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityAddTraits(.isHeader)
                        CTSymbolGrid(draft: draft, symbols: group.symbols)
                    }
                }
            } else {
                let results = CTSymbolGroup.allSymbols.filter { $0.matches(trimmed) }
                if results.isEmpty {
                    Text("No icons match “\(trimmed)”.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    CTSymbolGrid(draft: draft, symbols: results)
                }
            }
        }
    }
}

struct CTSymbolGrid: View {
    @Bindable var draft: CTDraft
    let symbols: [CTSymbol]

    @ScaledMetric private var cell: CGFloat = 44

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: cell), spacing: 8)], spacing: 8) {
            ForEach(symbols) { symbol in
                CTSymbolCell(symbol: symbol, color: draft.color, isSelected: draft.symbol == symbol.name) {
                    draft.symbol = symbol.name
                    draft.pickedSymbol = true
                }
            }
        }
    }
}

/// An icon to pick. The picked one fills with the category's color and its symbol turns white.
struct CTSymbolCell: View {
    let symbol: CTSymbol
    let color: CTColor
    let isSelected: Bool
    let action: () -> Void

    @ScaledMetric private var size: CGFloat = 44

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol.name)
                .font(.system(size: size * 0.4, weight: .semibold))
                .foregroundStyle(isSelected ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                .frame(width: size, height: size)
                .background(
                    isSelected ? AnyShapeStyle(color.color.gradient) : AnyShapeStyle(.fill.tertiary),
                    in: .rect(cornerRadius: size * 0.3, style: .continuous)
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(symbol.label))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Replacement (CAT-003)

/// The recurring templates that use a category being archived, each with a category to move to.
struct CTReplacementSheet: View {
    let store: CTStore
    let category: CTCategory

    @State private var choices: [CTTemplateUse.ID: CTCategory.ID] = [:]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let uses = store.templates(using: category.id)
        let options = store.active(category.type).filter { $0.id != category.id }

        NavigationStack {
            ScrollView {
                VStack(spacing: hmTileSpacing) {
                    VStack(spacing: 10) {
                        CTBadge(symbol: category.symbol, color: category.color, size: 56)
                        Group {
                            if uses.count == 1 {
                                Text("A recurring item uses “\(category.name)”. Choose a category for it from now on.")
                            } else {
                                Text("These recurring items use “\(category.name)”. Choose a category for each from now on.")
                            }
                        }
                        .font(.body)
                        .multilineTextAlignment(.center)
                        Text("Transactions they already created keep “\(category.name)”.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)

                    HMTile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            HMTileHeader(title: "Recurring", symbol: "repeat")
                            ForEach(uses) { use in
                                let layout = dynamicTypeSize.isAccessibilitySize
                                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                                    : AnyLayout(HStackLayout(spacing: 8))
                                layout {
                                    Text(verbatim: use.title)
                                        .font(.body.weight(.semibold))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Picker(selection: choice(for: use)) {
                                        Text("Choose").tag(String?.none)
                                        ForEach(options) { option in
                                            Label {
                                                Text(verbatim: option.name)
                                            } icon: {
                                                Image(systemName: option.symbol)
                                            }
                                            .tag(Optional(option.id))
                                        }
                                    } label: {
                                        Text(verbatim: use.title)
                                    }
                                    .pickerStyle(.menu)
                                }
                                if use.id != uses.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .background { HMBackdrop() }
            .navigationTitle("Archive Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Archive") {
                        withAnimation(reduceMotion ? nil : .snappy) {
                            store.archive(category.id, replacements: choices)
                        }
                        dismiss()
                    }
                    .disabled(uses.contains { choices[$0.id] == nil })
                }
            }
        }
    }

    private func choice(for use: CTTemplateUse) -> Binding<CTCategory.ID?> {
        Binding(get: { choices[use.id] }, set: { choices[use.id] = $0 })
    }
}

#Preview("Categories · Archive with recurring") {
    CTHost(opening: .archive("subscriptions")) { VelvetCategories(store: $0) }
}
#endif
