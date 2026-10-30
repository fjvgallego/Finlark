//
//  Round2Components.swift
//  Finlark
//
//  FIN-9 Round 2: building blocks shared by the Round 2 Home explorations. They combine the traits the
//  owner picked from Round 1: Glasshouse's glass tiles and backdrop, Mosaic's bento tiles, Carousel's
//  slider and Quiet's compact title. Every variation sits in the same tab shell, picked in Round 3:
//  a native tab bar whose bottom accessory holds quick add.
//

#if DEBUG
import SwiftUI

/// Where content tiles get their surface: glass (Glasshouse) or solid grouped backgrounds, which keeps
/// Liquid Glass on the controls layer only.
enum R2Surface {
    case glass
    case solid
}

extension EnvironmentValues {
    @Entry var r2Surface: R2Surface = .glass
}

/// The gap between tiles. Glass containers use a smaller spacing so neighboring tiles don't blend together.
let r2TileSpacing: CGFloat = 12
let r2GlassBlendSpacing: CGFloat = 4

struct R2Backdrop: View {
    @Environment(\.r2Surface) private var surface

    var body: some View {
        Group {
            switch surface {
            case .glass:
                LinearGradient(
                    colors: [Color.indigo.opacity(0.28), Color.teal.opacity(0.16), Color(.systemBackground)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .solid:
                Color(.systemGroupedBackground)
            }
        }
        .ignoresSafeArea()
    }
}

/// A bento tile. Fills the height of its grid row so tiles side by side line up.
struct R2Tile<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder let content: Content

    @Environment(\.r2Surface) private var surface

    var body: some View {
        let laidOut = content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        switch surface {
        case .glass:
            laidOut.glassEffect(.regular, in: .rect(cornerRadius: 24))
        case .solid:
            laidOut.background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 24))
        }
    }
}

/// A tile's small uppercase heading, with an optional trailing accessory.
struct R2TileHeader<Trailing: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            trailing
        }
    }
}

extension R2TileHeader where Trailing == EmptyView {
    init(title: LocalizedStringKey, symbol: String) {
        self.init(title: title, symbol: symbol) { EmptyView() }
    }
}

/// A chevron that marks a tile as tappable.
struct R2Chevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.tertiary)
            .accessibilityHidden(true)
    }
}

/// A horizontal, snapping slider of full-width pages with a glass page indicator (Carousel).
/// Pages share the height of the tallest one. At accessibility sizes the pages stack vertically instead.
struct R2Slider<Item: Identifiable, Page: View>: View {
    private let items: [Item]
    private let spacing: CGFloat
    private let margin: CGFloat
    private let indicatorOnGlass: Bool
    private let peeksNextPage: Bool
    private let page: (Item) -> Page

    @State private var currentID: Item.ID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - margin: horizontal inset around the pages. A non-zero margin lets the next page peek in.
    ///   - indicatorOnGlass: false when the slider already sits inside a glass tile, to avoid glass on glass.
    ///   - peeksNextPage: narrows each page so the edge of the next one shows, hinting that it scrolls.
    init(
        _ items: [Item],
        spacing: CGFloat = r2TileSpacing,
        margin: CGFloat = 16,
        indicatorOnGlass: Bool = true,
        peeksNextPage: Bool = false,
        @ViewBuilder page: @escaping (Item) -> Page
    ) {
        self.items = items
        self.spacing = spacing
        self.margin = margin
        self.indicatorOnGlass = indicatorOnGlass
        self.peeksNextPage = peeksNextPage
        self.page = page
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: spacing) {
                ForEach(items) { item in
                    page(item)
                }
            }
            .padding(.horizontal, margin)
        } else {
            VStack(spacing: 8) {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: spacing) {
                        ForEach(items) { item in
                            page(item)
                                .containerRelativeFrame(.horizontal, count: peeksNextPage ? 8 : 1, span: peeksNextPage ? 7 : 1, spacing: spacing)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $currentID)
                .scrollIndicators(.hidden)
                .scrollClipDisabled()
                .contentMargins(.horizontal, margin, for: .scrollContent)

                if items.count > 1 {
                    R2PageDots(count: items.count, index: currentIndex, onGlass: indicatorOnGlass)
                }
            }
        }
    }

    private var currentIndex: Int {
        items.firstIndex { $0.id == currentID } ?? 0
    }
}

struct R2PageDots: View {
    let count: Int
    let index: Int
    var onGlass = true

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { position in
                Capsule()
                    .fill(position == index ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                    .frame(width: position == index ? 16 : 6, height: 6)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(onGlass ? .regular : .identity, in: .capsule)
        .accessibilityHidden(true) // VoiceOver reaches every page by swiping.
    }
}

extension View {
    /// Quiet's compact title: "Home" stays small and inline instead of taking a large-title row.
    func r2CompactTitle() -> some View {
        navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Tab shell

/// The native tab bar shared by every Round 2 variation: Home, History and Settings. Quick add (HOM-007, TRX-001) lives in the bottom accessory above the tab bar on Home and
/// History (TRX-001), with Add expense first and an Income shortcut. When scrolling down, the tab bar
/// minimizes and the accessory moves inline next to it.
struct R2TabShell<Home: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    let model: ExplorationHomeModel
    private let home: Home

    @State private var selection: AppTab = .home
    @State private var router = R2TabRouter(tabDestinations: [.history])

    init(model: ExplorationHomeModel, @ViewBuilder home: () -> Home) {
        self.model = model
        self.home = home()
    }

    var body: some View {
        @Bindable var model = model

        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: AppTab.home) {
                NavigationStack {
                    home
                        .r2Destinations()
                }
            }
            Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                NavigationStack {
                    R2HistoryScreen(model: model)
                        .r2Destinations()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                NavigationStack {
                    R2SettingsScreen()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: selection == .home || selection == .history) {
            R2QuickAddAccessory(model: model)
        }
        .environment(router)
        .onChange(of: router.requested) { _, destination in
            guard destination != nil else { return }
            selection = .history
            router.requested = nil
        }
        .sheet(item: $model.addingType) { type in
            ExplorationAddSheet(type: type, currencyCode: model.snapshot.currencyCode)
        }
    }
}

/// Quick add in the tab view's bottom accessory: "Add expense" plus an Income shortcut, or a single
/// compact button when the accessory sits inline next to the minimized tab bar.
private struct R2QuickAddAccessory: View {
    let model: ExplorationHomeModel
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        if placement == .inline {
            Button {
                model.addingType = .expense
            } label: {
                Label("Add expense", systemImage: "plus")
            }
        } else {
            HStack(spacing: 0) {
                Button {
                    model.addingType = .expense
                } label: {
                    Label("Add expense", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                Divider()
                    .padding(.vertical, 8)
                Button {
                    model.addingType = .income
                } label: {
                    Label("Income", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: 140)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Routing

/// Lets Home's links switch tabs. Destinations in `tabDestinations` are tabs in the shell, so links to
/// them set `requested` (the shell switches tab) instead of pushing a screen.
@Observable
final class R2TabRouter {
    let tabDestinations: Set<ExplorationDestination>
    var requested: ExplorationDestination?

    init(tabDestinations: Set<ExplorationDestination>) {
        self.tabDestinations = tabDestinations
    }
}

/// Pushes the destination, or switches to its tab when the shell has one for it.
struct R2Link<Label: View>: View {
    let destination: ExplorationDestination
    @ViewBuilder let label: Label

    @Environment(R2TabRouter.self) private var router: R2TabRouter?

    var body: some View {
        if let router, router.tabDestinations.contains(destination) {
            Button {
                router.requested = destination
            } label: {
                label
            }
        } else {
            NavigationLink(value: destination) {
                label
            }
        }
    }
}

extension View {
    /// Placeholder pushes for destinations that aren't tabs. Apply inside each tab's NavigationStack.
    func r2Destinations() -> some View {
        navigationDestination(for: ExplorationDestination.self) { destination in
            ExplorationPlaceholderScreen(destination: destination)
        }
    }
}

// MARK: - History tab (mock of TRX-005)

/// A light mock of the History screen so the tab bar feels real, with search in notes (TRX-005).
struct R2HistoryScreen: View {
    let model: ExplorationHomeModel

    @State private var searchText = ""

    private var code: String { model.snapshot.currencyCode }

    private var days: [(day: Date, transactions: [ExplorationTransaction])] {
        let matching = model.snapshot.recentTransactions.filter { transaction in
            searchText.isEmpty || (transaction.note ?? "").localizedStandardContains(searchText)
        }
        let grouped = Dictionary(grouping: matching) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { (day: $0, transactions: grouped[$0] ?? []) }
    }

    var body: some View {
        List {
            Section {
                LabeledContent("Income") {
                    Text(model.snapshot.monthIncome, format: .currency(code: code))
                }
                LabeledContent("Spending") {
                    Text(model.snapshot.monthSpending, format: .currency(code: code))
                }
            } header: {
                Text(Date.now, format: .dateTime.month(.wide).year())
            }
            .monospacedDigit()

            ForEach(days, id: \.day) { day in
                Section {
                    ForEach(day.transactions) { transaction in
                        ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                    }
                } header: {
                    Text(day.day, format: .dateTime.weekday(.wide).day().month(.wide))
                }
            }
        }
        .overlay {
            if days.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: Text("Search notes"))
    }
}

// MARK: - Settings tab (mock of SET-001)

struct R2SettingsScreen: View {
    @State private var recurringNotifications = true
    @State private var iouNotifications = true
    @State private var appLock = false

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Name", value: "Main account")
                LabeledContent("Starting balance") {
                    Text(Decimal(1000), format: .currency(code: "EUR"))
                }
                LabeledContent("Home currency", value: "EUR")
            }
            Section {
                Label("Categories", systemImage: "square.grid.2x2")
                Label("Recurring", systemImage: "repeat")
            }
            Section("Notifications") {
                Toggle("Recurring due", isOn: $recurringNotifications)
                Toggle("IOU reminders", isOn: $iouNotifications)
            }
            Section("Security") {
                Toggle("App lock", isOn: $appLock)
            }
            Section("iCloud") {
                LabeledContent("Sync", value: String(localized: "Up to date"))
            }
            Section {
                Button("Delete all data", role: .destructive) {}
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Figures

/// An amount with a caption above it, used by the month figures in several variations.
struct R2Figure: View {
    let title: LocalizedStringKey
    let value: Decimal
    let code: String
    var signed = false
    var font: Font = .headline

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code).sign(strategy: signed ? .always() : .automatic))
                .font(font)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
