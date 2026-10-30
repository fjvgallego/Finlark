//
//  PlanComponents.swift
//  Finlark
//
//  FIN-9 Plan: pieces shared by the Plan explorations (PLN-001…003). Plan isn't a tab: Home's plan card
//  opens it (HOM-003), so the host is Marsh's tab bar with Plan pushed on Home. The bar shows "Monthly
//  Plan" with the month under it, the title's menu picks a past month, and Edit opens the plan editor.
//  Marsh's look throughout: the tinted backdrop, glass tiles, soft icons, system glass buttons.
//

#if DEBUG
import SwiftUI

// MARK: - Host

/// Marsh's tab bar with Plan pushed on Home, as tapping Home's plan card does.
struct PLHost<Plan: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    private enum Route: Hashable {
        case plan
    }

    @State private var store: PLStore
    @State private var selection: AppTab = .home
    @State private var path: [Route] = [.plan]
    private let plan: (PLStore) -> Plan

    init(store: PLStore = .sample, @ViewBuilder plan: @escaping (PLStore) -> Plan) {
        _store = State(initialValue: store)
        self.plan = plan
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack(path: $path) {
                    ContentUnavailableView {
                        Label("Home", systemImage: "house")
                    } description: {
                        Text("Marsh isn't part of the Plan exploration.")
                    } actions: {
                        NavigationLink("Open Plan", value: Route.plan)
                            .buttonStyle(.glass)
                    }
                    .navigationTitle("Home")
                    .navigationDestination(for: Route.self) { _ in plan(store) }
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                ContentUnavailableView {
                    Label("History", systemImage: "clock.arrow.circlepath")
                } description: {
                    Text("Lyra isn't part of the Plan exploration.")
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    R2SettingsScreen()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(\.explorationIconStyle, .soft)
    }
}

// MARK: - Bar

/// "Monthly Plan" with the month under it; the title's menu picks the month (PLN-002), and Edit opens
/// the plan editor (PLN-001). Past months are read-only, so Edit only shows on the current month.
struct PLChrome: ViewModifier {
    @Bindable var store: PLStore
    /// Off for variants with their own way to edit.
    var showsEdit = true

    @State private var isEditing = false

    func body(content: Content) -> some View {
        content
            .navigationTitle("Monthly Plan")
            .navigationSubtitle(PLFormat.month(store.month))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarTitleMenu {
                PLMonthPicker(store: store)
            }
            .toolbar {
                if showsEdit, store.isCurrentMonth, store.hasPlan {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") { isEditing = true }
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                PLEditor(store: store)
            }
    }
}

extension View {
    func plChrome(store: PLStore, showsEdit: Bool = true) -> some View {
        modifier(PLChrome(store: store, showsEdit: showsEdit))
    }
}

/// This month and the past months with spending, newest first.
struct PLMonthPicker: View {
    @Bindable var store: PLStore

    var body: some View {
        Picker("Month", selection: $store.month) {
            ForEach(store.months, id: \.self) { month in
                PLFormat.month(month).tag(month)
            }
        }
    }
}

enum PLFormat {
    /// "October 2026".
    static func month(_ date: Date) -> Text {
        Text(date, format: .dateTime.month(.wide).year())
    }

    /// "Oct".
    static func shortMonth(_ date: Date) -> Text {
        Text(date, format: .dateTime.month(.abbreviated))
    }
}

// MARK: - Status and figures

struct PLStatusLabel: View {
    let status: PLStatus

    var body: some View {
        Label {
            Text(status.title)
        } icon: {
            Image(systemName: status.symbol)
                .foregroundStyle(status.tint)
        }
    }
}

/// The plan in one sentence, from Slate and Marsh's plan tile.
struct PLPaceSentence: View {
    let report: PLReport
    let code: String

    var body: some View {
        if !report.isCurrent {
            if report.spent > report.planned {
                Text("You went \(report.spent - report.planned, format: .currency(code: code)) over plan.")
            } else {
                Text("You spent \(report.remaining, format: .currency(code: code)) less than planned.")
            }
        } else if !report.showsPace {
            // A-09: no pace estimate during the first 3 days.
            Text("\(report.remaining, format: .currency(code: code)) left to spend this month.")
        } else if let projected = report.projected {
            switch report.status {
            case .over:
                Text("You're already \(report.spent - report.planned, format: .currency(code: code)) over plan.")
            case .atRisk:
                Text("At this pace you'll go \(projected - report.planned, format: .currency(code: code)) over plan.")
            default:
                Text("You're on track, with \(report.remaining, format: .currency(code: code)) left to spend.")
            }
        }
    }
}

/// Spent, Projected (this month only) and Planned with their bar swatches, side by side when they fit.
struct PLFigures: View {
    let spent: Decimal
    let projected: Decimal?
    let planned: Decimal
    let tint: Color
    let code: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) { figures(spacer: true) }
            VStack(alignment: .leading, spacing: 10) { figures(spacer: false) }
        }
    }

    @ViewBuilder
    private func figures(spacer: Bool) -> some View {
        R3PlanFigure(title: "Spent", value: spent, code: code, swatch: .spent(tint))
        if let projected {
            if spacer { Spacer(minLength: 8) }
            R3PlanFigure(title: "Projected", value: projected, code: code, swatch: .projected(tint))
        }
        if spacer { Spacer(minLength: 8) }
        R3PlanFigure(title: "Planned", value: planned, code: code, swatch: .planned)
    }
}

extension PLFigures {
    init(report: PLReport, code: String) {
        self.init(
            spent: report.spent,
            projected: report.projected,
            planned: report.planned,
            tint: report.status?.tint ?? .accentColor,
            code: code
        )
    }
}

/// Spent, the projection faded behind it and a mark at the planned amount (Marsh's plan bar).
struct PLBar: View {
    let entry: PLEntry

    var body: some View {
        ExplorationPlanBar(
            spent: entry.spent,
            projected: entry.projectedOrSpent,
            planned: entry.planned ?? 0,
            tint: entry.status?.tint ?? .secondary
        )
    }
}

extension PLBar {
    /// The whole plan's bar.
    struct Total: View {
        let report: PLReport

        var body: some View {
            ExplorationPlanBar(
                spent: report.spent,
                projected: report.projected ?? report.spent,
                planned: report.planned,
                tint: report.status?.tint ?? .secondary
            )
        }
    }
}

/// "€127.60 left · €296.91 projected", or "Spent €750.00" in a finished month.
struct PLEntryDetail: View {
    let entry: PLEntry
    let code: String

    var body: some View {
        if let planned = entry.planned {
            if let projected = entry.projected {
                Text("\(remainingText(planned)) · \(projected, format: .currency(code: code)) projected")
            } else {
                Text("\(entry.spent, format: .currency(code: code)) of \(planned, format: .currency(code: code))")
            }
        } else {
            Text("Unplanned")
        }
    }

    private func remainingText(_ planned: Decimal) -> Text {
        if entry.spent > planned {
            Text("\(entry.spent - planned, format: .currency(code: code)) over")
        } else {
            Text("\(planned - entry.spent, format: .currency(code: code)) left")
        }
    }
}

/// What projections are made of, or that a past month is read-only (PLN-002, PLN-003, A-09).
struct PLFootnote: View {
    let report: PLReport
    let code: String

    var body: some View {
        Group {
            if !report.isCurrent {
                Label("Past months show the plan they had and can't be changed.", systemImage: "lock")
            } else if !report.showsPace {
                Label(
                    "The pace estimate starts on day 4. Until then, projections are what's spent plus recurring expenses still due.",
                    systemImage: "calendar.badge.clock"
                )
            } else if report.recurringDue > 0 {
                Label(
                    "Projections follow your pace so far and include \(report.recurringDue, format: .currency(code: code)) of recurring expenses still due.",
                    systemImage: "arrow.triangle.2.circlepath"
                )
            } else {
                Label("Projections follow your pace so far.", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Rows

/// A planned category: icon, name and status, then the bar and what's left (PLN-002).
struct PLEntryRow: View {
    let entry: PLEntry
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ExplorationCategoryIcon(category: entry.category)
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.category.name)
                        .font(.headline)
                    PLEntryDetail(entry: entry, code: code)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                if let status = entry.status {
                    PLStatusBadge(status: status)
                        .font(.subheadline.weight(.semibold))
                }
            }
            PLBar(entry: entry)
        }
        .monospacedDigit()
        .accessibilityElement(children: .combine)
    }
}

/// The status icon alone at default sizes, which keeps rows short; VoiceOver still reads the title.
/// At accessibility sizes the title shows too.
struct PLStatusBadge: View {
    let status: PLStatus

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            PLStatusLabel(status: status)
        } else {
            Image(systemName: status.symbol)
                .foregroundStyle(status.tint)
                .accessibilityLabel(Text(status.title))
        }
    }
}

/// Spending in categories without a plan, one row each (PLN-002).
struct PLUnplannedRow: View {
    let entry: PLEntry
    let code: String

    var body: some View {
        HStack(spacing: 12) {
            ExplorationCategoryIcon(category: entry.category)
            Text(entry.category.name)
            Spacer(minLength: 8)
            Text(entry.spent, format: .currency(code: code))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

/// A tile with every unplanned category and their total, or nothing when there are none.
struct PLUnplannedTile: View {
    let report: PLReport
    let code: String

    var body: some View {
        if !report.unplanned.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Unplanned", symbol: "questionmark.square.dashed") {
                        Text(report.unplannedSpent, format: .currency(code: code))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    ForEach(report.unplanned) { entry in
                        PLUnplannedRow(entry: entry, code: code)
                    }
                }
            }
        }
    }
}

// MARK: - No plan

/// No plan for this month (HOM-003): on the current month it invites the user to set one up.
struct PLInvite: View {
    let store: PLStore

    @State private var isEditing = false

    var body: some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.title)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                if store.isCurrentMonth {
                    Text("Set up your Monthly Plan")
                        .font(.title3.weight(.bold))
                    Text("Plan how much you'll spend per category and see early whether you'll stay within it.")
                        .foregroundStyle(.secondary)
                    Button("Set Up Plan") { isEditing = true }
                        .buttonStyle(.glassProminent)
                        .padding(.top, 4)
                } else {
                    Text("No plan this month")
                        .font(.title3.weight(.bold))
                    Text("You hadn't set a plan yet, so all spending was unplanned.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            PLEditor(store: store)
        }
    }
}

// MARK: - Editor

/// Sets, changes or clears a planned amount per active expense category (PLN-001). An empty field
/// means no plan. Changes apply from this month onward; past months keep theirs (A-08).
struct PLEditor: View {
    let store: PLStore

    @Environment(\.dismiss) private var dismiss
    @State private var texts: [String: String] = [:]

    private var fractionDigits: Int { AEMoney.fractionDigits(for: store.code) }

    private var total: Decimal {
        texts.values.reduce(0) { $0 + (AEMoney.parse($1) ?? 0) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    LabeledContent("Total planned") {
                        Text(total, format: .currency(code: store.code))
                            .font(.headline)
                            .monospacedDigit()
                    }
                }

                Section {
                    ForEach(store.activeCategories) { category in
                        HStack(spacing: 12) {
                            ExplorationCategoryIcon(category: category)
                            Text(category.name)
                            Spacer(minLength: 8)
                            PLAmountField(title: category.name, text: binding(for: category), code: store.code)
                        }
                    }
                } header: {
                    Text("Planned per month")
                } footer: {
                    Text("Leave a category empty to keep it unplanned. Changes apply from \(PLFormat.month(PLStore.currentMonth)) onward; earlier months keep the amounts they had.")
                }
            }
            .navigationTitle("Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        store.replacePlan(with: texts.compactMapValues { AEMoney.parse($0) })
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            texts = store.plan.mapValues { AEMoney.text(for: $0, fractionDigits: fractionDigits) }
        }
    }

    private func binding(for category: ExplorationCategory) -> Binding<String> {
        Binding {
            texts[category.id] ?? ""
        } set: {
            texts[category.id] = $0
        }
    }
}

/// A small amount field typed as text and parsed to `Decimal` (NFR-005). Empty reads "No plan".
struct PLAmountField: View {
    let title: LocalizedStringResource
    @Binding var text: String
    let code: String

    var body: some View {
        let affix = AEMoney.affix(for: code)

        HStack(spacing: 2) {
            if affix.isLeading, !text.isEmpty { Text(verbatim: affix.symbol).foregroundStyle(.secondary) }
            TextField(String(localized: title), text: $text, prompt: Text("No plan"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .fixedSize()
            if !affix.isLeading, !text.isEmpty { Text(verbatim: affix.symbol).foregroundStyle(.secondary) }
        }
        .monospacedDigit()
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.fill.tertiary, in: .rect(cornerRadius: 10, style: .continuous))
        .onChange(of: text) { _, newValue in
            let clean = AEMoney.sanitize(newValue, fractionDigits: AEMoney.fractionDigits(for: code))
            if clean != newValue { text = clean }
        }
    }
}

#Preview("Plan editor") {
    PLEditor(store: .sample)
        .environment(\.explorationIconStyle, .soft)
}
#endif
