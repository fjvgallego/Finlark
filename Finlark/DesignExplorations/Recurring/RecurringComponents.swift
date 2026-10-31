//
//  RecurringComponents.swift
//  Finlark
//
//  FIN-9 Recurring: pieces shared by the Recurring explorations (REC-001…005). Recurring isn't a tab:
//  Settings links to it (SET-001), so the host is Marsh's tab bar with Recurring pushed on Settings.
//  Shared here: the screen around each variant (bar, add button, Undo toast, empty state), the
//  template editor, the confirm screen a pending item and its notification open (REC-003, NTF-001), and
//  the template screen. Marsh's look throughout: the tinted backdrop, glass tiles, soft icons, and the
//  system's blue Liquid Glass for actions.
//

#if DEBUG
import SwiftUI

// MARK: - Host

enum RCRoute: Hashable {
    case recurring
    case template(RCTemplate.ID)
}

/// Marsh's tab bar with Recurring pushed on Settings. `opensTemplate` also pushes the rent's screen.
struct RCHost<List: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    @State private var store: RCStore
    @State private var selection: AppTab = .settings
    @State private var path: [RCRoute]
    private let list: (RCStore) -> List

    init(store: RCStore = .sample, opensTemplate: Bool = false, @ViewBuilder list: @escaping (RCStore) -> List) {
        _store = State(initialValue: store)
        let template = opensTemplate ? store.templates.first.map { RCRoute.template($0.id) } : nil
        _path = State(initialValue: [.recurring] + (template.map { [$0] } ?? []))
        self.list = list
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                ContentUnavailableView {
                    Label("Home", systemImage: "house")
                } description: {
                    Text("Marsh isn't part of the Recurring exploration.")
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                ContentUnavailableView {
                    Label("History", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Lyra isn't part of the Recurring exploration.")
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack(path: $path) {
                    ContentUnavailableView {
                        Label("Settings", systemImage: "gearshape")
                    } description: {
                        Text("Settings isn't part of the Recurring exploration.")
                    } actions: {
                        NavigationLink("Open Recurring", value: RCRoute.recurring)
                            .buttonStyle(.glass)
                    }
                    .navigationTitle("Settings")
                    .navigationDestination(for: RCRoute.self) { route in
                        switch route {
                        case .recurring: list(store)
                        case .template(let id): RCTemplateScreen(store: store, id: id)
                        }
                    }
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(\.explorationIconStyle, .soft)
    }
}

// MARK: - Screen

/// What a variant's controls can do with a pending item.
struct RCActions {
    /// Confirms it as it is, with Undo (REC-003).
    let confirm: (RCPending) -> Void
    /// Skips it, with Undo (REC-004).
    let skip: (RCPending) -> Void
    /// Opens the confirm screen to change the amount, date or note first (REC-003).
    let review: (RCPending) -> Void
    /// Confirms every pending item, with Undo. Not in the requirements.
    let confirmAll: () -> Void
}

/// The screen around a variant: a scroll view of its tiles, a bar pinned above the tab bar if it has
/// one, the Undo toast, the confirm screen, and the empty state when there are no templates yet.
struct RCScreen<Content: View, Pinned: View>: View {
    @Bindable var store: RCStore
    @ViewBuilder let content: (RCActions) -> Content
    @ViewBuilder let pinned: (RCActions) -> Pinned

    @State private var undo: RCUndo?
    @State private var reviewing: RCPending?

    var body: some View {
        let actions = RCActions(
            confirm: { undo = store.confirm($0) },
            skip: { undo = store.skip($0) },
            review: { reviewing = $0 },
            confirmAll: { undo = store.confirmAll() }
        )

        Group {
            if store.templates.isEmpty {
                RCEmptyState(store: store)
            } else {
                ScrollView {
                    VStack(spacing: r2TileSpacing) {
                        content(actions)
                    }
                    .padding()
                }
                // The toast and the pinned bar share one inset, the toast above the bar.
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        RCUndoToastBar(undo: $undo, store: store)
                        pinned(actions)
                    }
                }
            }
        }
        .background { R2Backdrop() }
        .rcChrome(store: store)
        .sheet(item: $reviewing) { RCConfirmSheet(store: store, item: $0) }
    }
}

extension RCScreen where Pinned == EmptyView {
    init(store: RCStore, @ViewBuilder content: @escaping (RCActions) -> Content) {
        self.init(store: store, content: content) { _ in EmptyView() }
    }
}

/// "Recurring", inline, with an add button (REC-001).
struct RCChrome: ViewModifier {
    let store: RCStore

    @State private var isAdding = false

    func body(content: Content) -> some View {
        content
            .navigationTitle("Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add Recurring", systemImage: "plus") { isAdding = true }
                }
            }
            .sheet(isPresented: $isAdding) {
                RCEditor(store: store)
            }
    }
}

extension View {
    func rcChrome(store: RCStore) -> some View {
        modifier(RCChrome(store: store))
    }

    func rcUndoToast(_ undo: Binding<RCUndo?>, store: RCStore) -> some View {
        safeAreaInset(edge: .bottom) {
            RCUndoToastBar(undo: undo, store: store)
        }
    }
}

/// No templates yet, with Add Recurring in blue glass.
struct RCEmptyState: View {
    let store: RCStore

    @State private var isAdding = false

    var body: some View {
        ContentUnavailableView {
            Label("No Recurring Yet", systemImage: "repeat")
        } description: {
            Text("Add your rent, subscriptions or salary once. When each one is due, Finlark asks you to confirm it before it counts.")
        } actions: {
            Button("Add Recurring", systemImage: "plus") { isAdding = true }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
        }
        .sheet(isPresented: $isAdding) {
            RCEditor(store: store)
        }
    }
}

/// People's Undo toast for confirming and skipping in one tap, for the bottom safe area inset, above
/// the tab bar. In an overlay on the scroll view it showed at the top, behind the bar's buttons.
struct RCUndoToastBar: View {
    @Binding var undo: RCUndo?
    let store: RCStore

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            if let undo {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                    Text(verbatim: undo.message)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Button("Undo") {
                        store.undo(undo)
                        self.undo = nil
                    }
                    .buttonStyle(P2ButtonStyle(kind: .tinted))
                }
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: .capsule)
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                .task(id: undo) {
                    AccessibilityNotification.Announcement(undo.message).post()
                    try? await Task.sleep(for: .seconds(5))
                    if !Task.isCancelled { self.undo = nil }
                }
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: undo)
    }
}

// MARK: - Text

enum RCFormat {
    /// "Every Monday", "Every month on day 29", "Every year on 12 March".
    static func schedule(_ frequency: RCFrequency, start: Date) -> Text {
        switch frequency {
        case .weekly:
            Text("Every \(start, format: .dateTime.weekday(.wide))")
        case .monthly:
            Text("Every month on day \(Calendar.current.component(.day, from: start))")
        case .yearly:
            Text("Every year on \(start, format: .dateTime.day().month(.wide))")
        }
    }

    static func schedule(_ template: RCTemplate) -> Text {
        schedule(template.frequency, start: template.startDate)
    }

    /// "Today", "Tomorrow", "In 3 days", "2 days ago".
    static func relative(_ date: Date) -> Text {
        let days = Calendar.current.dateComponents([.day], from: RCStore.today, to: date).day ?? 0
        return switch days {
        case 0: Text("Today")
        case 1: Text("Tomorrow")
        case -1: Text("Yesterday")
        case 2...: Text("In ^[\(days) day](inflect: true)")
        default: Text("^[\(-days) day](inflect: true) ago")
        }
    }

    /// "Due today" or "Due 29 Oct".
    static func due(_ item: RCPending) -> Text {
        item.isDueToday ? Text("Due today") : Text("Due \(item.date, format: .dateTime.day().month())")
    }

    static func day(_ date: Date) -> Text {
        Text(date, format: .dateTime.day().month())
    }

    /// "−€750.00" or "+€2,150.00".
    static func amount(_ template: RCTemplate, code: String) -> Text {
        Text(template.signedAmount, format: .currency(code: code).sign(strategy: .always()))
    }
}

/// "Paused", with its icon so it isn't color alone.
struct RCPausedLabel: View {
    var body: some View {
        Label("Paused", systemImage: "pause.circle.fill")
            .foregroundStyle(.secondary)
    }
}

// MARK: - Rows

/// A template: icon, title and schedule leading; amount and next date trailing. At accessibility
/// sizes the trailing part moves under it and the icon goes.
struct RCTemplateRow: View {
    let store: RCStore
    let template: RCTemplate
    var showsIcon = true
    var showsChevron = true

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            if showsIcon {
                P8CategoryIcon(category: template.category)
            }
            P8InfoAndAmount {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: template.title)
                        .font(.body.weight(.semibold))
                    RCFormat.schedule(template)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } amount: {
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
                    RCFormat.amount(template, code: store.code)
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                    Group {
                        if template.isPaused {
                            RCPausedLabel()
                        } else if let next = store.nextDate(for: template) {
                            RCFormat.relative(next)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            if showsChevron {
                R2Chevron()
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

/// A pending item's icon, title, due date and amount.
struct RCPendingInfo: View {
    let store: RCStore
    let item: RCPending

    var body: some View {
        if let template = store.template(item.templateID) {
            HStack(alignment: .top, spacing: 12) {
                P8CategoryIcon(category: template.category)
                P8InfoAndAmount {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: template.title)
                            .font(.body.weight(.semibold))
                        RCFormat.due(item)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } amount: {
                    RCFormat.amount(template, code: store.code)
                        .font(.headline)
                        .monospacedDigit()
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// Skip and Confirm, wide, side by side, or stacked at accessibility sizes. People's Financier pair:
/// the one that posts in blue glass.
struct RCPendingButtons: View {
    let store: RCStore
    let item: RCPending
    let actions: RCActions

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let title = store.template(item.templateID)?.title ?? ""
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 10))
        layout {
            Button { actions.skip(item) } label: {
                Label("Skip", systemImage: "forward.end")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .accessibilityLabel(Text("Skip \(title)"))
            Button { actions.confirm(item) } label: {
                Label("Confirm", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .accessibilityLabel(Text("Confirm \(title)"))
        }
        .lineLimit(1)
    }
}

/// A round Skip next to People's round check, for compact rows.
struct RCQuickControls: View {
    let store: RCStore
    let item: RCPending
    let actions: RCActions

    var body: some View {
        let title = store.template(item.templateID)?.title ?? ""
        HStack(spacing: 8) {
            Button { actions.skip(item) } label: {
                Label {
                    Text("Skip \(title)")
                } icon: {
                    Image(systemName: "forward.end")
                }
                .labelStyle(.iconOnly)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            GenmaichaCheck(title: Text("Confirm \(title)")) { actions.confirm(item) }
        }
    }
}

/// A heading over cards that aren't in one tile, with a count.
struct RCSectionTitle: View {
    let title: LocalizedStringKey
    var count: Int?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(title)
                .font(.headline)
            if let count {
                Text(count, format: .number)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// Templates in one tile, each opening its screen.
struct RCTemplateList: View {
    let store: RCStore
    let title: LocalizedStringKey
    var symbol = "repeat"
    let templates: [RCTemplate]
    var showsIcon = true

    var body: some View {
        if !templates.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: title, symbol: symbol)
                    ForEach(templates) { template in
                        NavigationLink(value: RCRoute.template(template.id)) {
                            RCTemplateRow(store: store, template: template, showsIcon: showsIcon)
                        }
                        .buttonStyle(.plain)
                        if template.id != templates.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

/// Nothing pending, and when the next one is due.
struct RCCaughtUp: View {
    let store: RCStore

    var body: some View {
        R2Tile(padding: 18) {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("All caught up")
                        .font(.headline)
                    if let next = store.upcoming(days: 366).first, let template = store.template(next.templateID) {
                        Text("Next: \(template.title) on \(next.date, format: .dateTime.weekday(.wide).day().month())")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
}

/// What the active templates come to in an average month.
struct RCMonthlyFigures: View {
    let store: RCStore

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 24) { figures }
            VStack(alignment: .leading, spacing: 10) { figures }
        }
    }

    @ViewBuilder
    private var figures: some View {
        R2Figure(title: "Out each month", value: store.monthlyTotal(.expense), code: store.code)
        R2Figure(title: "In each month", value: store.monthlyTotal(.income), code: store.code)
    }
}

// MARK: - Template editor (REC-001, REC-005)

/// Dunlin's tiles for a template: type and amount, category, note, and how it repeats. Editing says
/// that changes apply from the next occurrence on.
struct RCEditor: View {
    let store: RCStore
    private let original: RCTemplate?
    /// Shows Delete at the bottom, for variants without a template screen.
    private let onDelete: (() -> Void)?

    @State private var draft: AEDraft
    @State private var frequency: RCFrequency
    @State private var hasEnd: Bool
    @State private var endDate: Date
    @State private var isConfirmingDelete = false
    @FocusState private var isAmountFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(store: RCStore, template: RCTemplate? = nil, onDelete: (() -> Void)? = nil) {
        self.store = store
        original = template
        self.onDelete = onDelete
        _draft = State(initialValue: AEDraft(
            purpose: template == nil ? .add : .edit,
            type: template?.type ?? .expense,
            amount: template?.amount ?? 0,
            date: template?.startDate ?? RCStore.today,
            categoryID: template?.category.id,
            note: template?.note ?? "",
            currencyCode: store.code
        ))
        _frequency = State(initialValue: template?.frequency ?? .monthly)
        _hasEnd = State(initialValue: template?.endDate != nil)
        let nextYear = Calendar.current.date(byAdding: .year, value: 1, to: RCStore.today) ?? RCStore.today
        _endDate = State(initialValue: template?.endDate ?? nextYear)
    }

    private var startDay: Int { Calendar.current.component(.day, from: draft.date) }

    var body: some View {
        NavigationStack {
            ScrollView {
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
                            DunlinCategoryPicker(draft: draft)
                        }
                    }
                    R2Tile {
                        VStack(alignment: .leading, spacing: 6) {
                            R2TileHeader(title: "Note", symbol: "text.alignleft")
                            TextField("Note", text: $draft.note, prompt: Text("Rent, Netflix, Salary…"), axis: .vertical)
                                .padding(.vertical, 6)
                        }
                    }
                    repeatsTile
                    if original != nil {
                        Text("Changes apply from the next time it's due. Transactions it already created stay as they are.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    if let original, let onDelete {
                        Button(role: .destructive) { isConfirmingDelete = true } label: {
                            Label("Delete Recurring", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        .controlSize(.large)
                        .rcDeleteDialog(isPresented: $isConfirmingDelete, title: original.title) {
                            dismiss()
                            onDelete()
                        }
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background { R2Backdrop() }
            .navigationTitle(original == nil ? "New Recurring" : "Edit Recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        save()
                        dismiss()
                    }
                    .disabled(!draft.canSave)
                }
            }
            .environment(\.explorationIconStyle, .soft)
            .onAppear { isAmountFocused = original == nil }
        }
    }

    private var repeatsTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Repeats", symbol: "repeat")
                R6SegmentedControl(
                    title: "Frequency",
                    options: RCFrequency.allCases.map { (value: $0, label: $0.title) },
                    selection: $frequency
                )
                DatePicker("Starts", selection: $draft.date, displayedComponents: .date)
                Divider()
                Toggle("End Date", isOn: $hasEnd.animation())
                if hasEnd {
                    DatePicker("Ends", selection: $endDate, in: draft.date..., displayedComponents: .date)
                }
                VStack(alignment: .leading, spacing: 4) {
                    RCFormat.schedule(frequency, start: draft.date)
                    if frequency == .monthly, startDay >= 29 {
                        Text("In shorter months, on the last day.")
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    private func save() {
        guard let amount = draft.amount, let category = draft.category else { return }
        var template = original ?? RCTemplate(amount: amount, category: category, note: draft.note, startDate: draft.date)
        template.type = draft.type
        template.amount = amount
        template.category = category
        template.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        template.frequency = frequency
        template.startDate = Calendar.current.startOfDay(for: draft.date)
        template.endDate = hasEnd ? Calendar.current.startOfDay(for: endDate) : nil
        store.save(template)
    }
}

extension View {
    /// Asks before deleting, and says the transactions it created stay (REC-005).
    func rcDeleteDialog(isPresented: Binding<Bool>, title: String, delete: @escaping () -> Void) -> some View {
        confirmationDialog(Text("Delete \(title)?"), isPresented: isPresented, titleVisibility: .visible) {
            Button("Delete Recurring", role: .destructive, action: delete)
        } message: {
            Text("No more pending items will appear. The transactions it already created stay in History.")
        }
    }
}

// MARK: - Confirm screen (REC-003, NTF-001)

/// A pending item with its amount, date and note ready to change before confirming. The recurring-due
/// notification opens this too. Skip sits next to Confirm.
struct RCConfirmSheet: View {
    let store: RCStore
    let item: RCPending

    @State private var draft: AEDraft
    @FocusState private var isAmountFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(store: RCStore, item: RCPending) {
        self.store = store
        self.item = item
        let template = store.template(item.templateID)
        _draft = State(initialValue: AEDraft(
            purpose: .edit,
            type: template?.type ?? .expense,
            amount: template?.amount ?? 0,
            date: item.date,
            categoryID: template?.category.id,
            note: template?.note ?? "",
            currencyCode: store.code
        ))
    }

    var body: some View {
        NavigationStack {
            if let template = store.template(item.templateID) {
                ScrollView {
                    VStack(spacing: r2TileSpacing) {
                        R2Tile(padding: 18) {
                            VStack(spacing: 16) {
                                HStack(spacing: 12) {
                                    P8CategoryIcon(category: template.category)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verbatim: template.title)
                                            .font(.headline)
                                        RCFormat.due(item)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    .accessibilityElement(children: .combine)
                                    Spacer(minLength: 0)
                                }
                                AEAmountField(draft: draft, focus: $isAmountFocused)
                                    .frame(maxWidth: .infinity)
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
                        Text("It counts toward your balance and spending once you confirm it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    buttons(template)
                }
                .background { R2Backdrop() }
                .navigationTitle("Confirm")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                    }
                }
            }
        }
        .environment(\.explorationIconStyle, .soft)
    }

    private func buttons(_ template: RCTemplate) -> some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 10))
        return layout {
            Button {
                store.skip(item)
                dismiss()
            } label: {
                Label("Skip", systemImage: "forward.end")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            Button {
                store.confirm(item, amount: draft.amount, date: draft.date)
                dismiss()
            } label: {
                Label("Confirm", systemImage: "checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled((draft.amount ?? 0) <= 0)
        }
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - Template screen (REC-005)

/// One template: what it is and how it repeats, its pending items, the next dates, what past ones came
/// to, and Pause and Delete. Edit opens the editor.
struct RCTemplateScreen: View {
    @Bindable var store: RCStore
    let id: RCTemplate.ID

    @State private var isEditing = false
    @State private var isConfirmingDelete = false
    @State private var reviewing: RCPending?
    @State private var undo: RCUndo?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if let template = store.template(id) {
            let actions = RCActions(
                confirm: { undo = store.confirm($0) },
                skip: { undo = store.skip($0) },
                review: { reviewing = $0 },
                confirmAll: {}
            )

            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    header(template)
                    pendingTile(template, actions: actions)
                    upcomingTile(template)
                    historyTile(template)
                    VStack(spacing: 10) {
                        Button {
                            store.setPaused(!template.isPaused, for: template.id)
                        } label: {
                            Group {
                                if template.isPaused {
                                    Label("Resume", systemImage: "play.fill")
                                } else {
                                    Label("Pause", systemImage: "pause.fill")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        Button(role: .destructive) { isConfirmingDelete = true } label: {
                            Label("Delete Recurring", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                    }
                    .controlSize(.large)
                    .padding(.top, 8)
                }
                .padding()
            }
            .rcUndoToast($undo, store: store)
            .background { R2Backdrop() }
            .navigationTitle(Text(verbatim: template.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { isEditing = true }
                }
            }
            .sheet(isPresented: $isEditing) { RCEditor(store: store, template: template) }
            .sheet(item: $reviewing) { RCConfirmSheet(store: store, item: $0) }
            .rcDeleteDialog(isPresented: $isConfirmingDelete, title: template.title) {
                dismiss()
                store.delete(template.id)
            }
        }
    }

    /// Plain, not on glass, like the person screen's header.
    private func header(_ template: RCTemplate) -> some View {
        VStack(spacing: 8) {
            ExplorationCategoryIcon(category: template.category)
                .scaleEffect(1.3)
                .padding(.bottom, 6)
            RCFormat.amount(template, code: store.code)
                .font(.largeTitle.weight(.bold))
                .monospacedDigit()
            VStack(spacing: 2) {
                RCFormat.schedule(template)
                if let end = template.endDate {
                    Text("Until \(end, format: .dateTime.day().month().year())")
                }
                if template.isPaused {
                    RCPausedLabel()
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func pendingTile(_ template: RCTemplate, actions: RCActions) -> some View {
        let items = store.pending(for: template)
        if !items.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    R2TileHeader(title: "Pending", symbol: "clock.badge.exclamationmark.fill")
                    ForEach(items) { item in
                        VStack(alignment: .leading, spacing: 12) {
                            Button { actions.review(item) } label: {
                                RCPendingInfo(store: store, item: item)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
                            RCPendingButtons(store: store, item: item, actions: actions)
                        }
                        if item.id != items.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func upcomingTile(_ template: RCTemplate) -> some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Coming up", symbol: "calendar")
                if template.isPaused {
                    Text("Paused. Nothing becomes pending until you resume it.")
                        .foregroundStyle(.secondary)
                } else {
                    let dates = template.upcoming(after: RCStore.today, count: 3)
                    if dates.isEmpty {
                        Text("It has ended. Nothing else is coming up.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(dates, id: \.self) { date in
                        HStack {
                            RCFormat.day(date)
                            Spacer(minLength: 8)
                            RCFormat.relative(date)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func historyTile(_ template: RCTemplate) -> some View {
        let history = store.history(for: template).prefix(6)
        if !history.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Earlier", symbol: "clock.arrow.circlepath")
                    ForEach(history) { outcome in
                        HStack {
                            RCFormat.day(outcome.occurrence)
                            Spacer(minLength: 8)
                            switch outcome.kind {
                            case .confirmed(let amount, _):
                                Label {
                                    Text(amount, format: .currency(code: store.code))
                                        .monospacedDigit()
                                } icon: {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                                .accessibilityLabel(Text("Confirmed, \(amount.formatted(.currency(code: store.code)))"))
                            case .skipped:
                                Label {
                                    Text("Skipped")
                                } icon: {
                                    Image(systemName: "forward.end.circle.fill")
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}

#Preview("Recurring · Empty") {
    RCHost(store: .empty) { RCScreen(store: $0) { _ in EmptyView() } }
}

#Preview("Recurring · Template") {
    RCHost(opensTemplate: true) { RCScreen(store: $0) { _ in EmptyView() } }
}
#endif
