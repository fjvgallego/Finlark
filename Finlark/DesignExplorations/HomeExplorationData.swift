//
//  HomeExplorationData.swift
//  Finlark
//
//  FIN-9: shared mock data and building blocks for the Home screen explorations.
//  Throwaway design code: not wired into the app, compiled in Debug only.
//

#if DEBUG
import SwiftUI
import Charts

// MARK: - Mock values

enum ExplorationTransactionType: String, CaseIterable, Identifiable {
    case expense
    case income

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        }
    }

    var addTitle: LocalizedStringResource {
        switch self {
        case .expense: "Add expense"
        case .income: "Add income"
        }
    }
}

struct ExplorationCategory: Identifiable {
    let id: String
    let name: LocalizedStringResource
    let symbol: String
    let color: Color

    // Icons and colors are proposals (Appendix A leaves them to UI design).
    static let groceries = ExplorationCategory(id: "groceries", name: "Groceries", symbol: "cart.fill", color: .green)
    static let dining = ExplorationCategory(id: "dining", name: "Dining", symbol: "fork.knife", color: .orange)
    static let transport = ExplorationCategory(id: "transport", name: "Transport", symbol: "tram.fill", color: .blue)
    static let fuel = ExplorationCategory(id: "fuel", name: "Fuel", symbol: "fuelpump.fill", color: .brown)
    static let housing = ExplorationCategory(id: "housing", name: "Housing", symbol: "house.fill", color: .indigo)
    static let health = ExplorationCategory(id: "health", name: "Health", symbol: "heart.fill", color: .pink)
    static let leisure = ExplorationCategory(id: "leisure", name: "Leisure", symbol: "theatermasks.fill", color: .purple)
    static let subscriptions = ExplorationCategory(
        id: "subscriptions", name: "Subscriptions", symbol: "tv.fill", color: .red
    )
    static let salary = ExplorationCategory(id: "salary", name: "Salary", symbol: "banknote.fill", color: .mint)
}

struct ExplorationCategorySpending: Identifiable {
    let category: ExplorationCategory
    let amount: Decimal

    var id: String { category.id }
}

/// Plan status per PLN-002. Always shown with its symbol and title, never by color alone (NFR-003).
enum ExplorationPlanStatus {
    case onTrack
    case atRisk
    case over

    init(planned: Decimal, spent: Decimal, projected: Decimal) {
        if spent > planned {
            self = .over
        } else if projected > planned {
            self = .atRisk
        } else {
            self = .onTrack
        }
    }

    var title: LocalizedStringResource {
        switch self {
        case .onTrack: "On track"
        case .atRisk: "At risk"
        case .over: "Over"
        }
    }

    var symbol: String {
        switch self {
        case .onTrack: "checkmark.circle.fill"
        case .atRisk: "exclamationmark.triangle.fill"
        case .over: "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .onTrack: .green
        case .atRisk: .orange
        case .over: .red
        }
    }
}

struct ExplorationCategoryPlan: Identifiable {
    let category: ExplorationCategory
    let planned: Decimal
    let spent: Decimal
    let projected: Decimal

    var id: String { category.id }
    var remaining: Decimal { planned - spent }
    var status: ExplorationPlanStatus { ExplorationPlanStatus(planned: planned, spent: spent, projected: projected) }
}

struct ExplorationPlanSummary {
    let categories: [ExplorationCategoryPlan]
    let unplannedSpent: Decimal
    let unplannedProjected: Decimal

    var totalPlanned: Decimal { categories.reduce(0) { $0 + $1.planned } }
    var totalSpent: Decimal { categories.reduce(unplannedSpent) { $0 + $1.spent } }
    var totalProjected: Decimal { categories.reduce(unplannedProjected) { $0 + $1.projected } }
    var totalRemaining: Decimal { totalPlanned - totalSpent }
    var status: ExplorationPlanStatus {
        ExplorationPlanStatus(planned: totalPlanned, spent: totalSpent, projected: totalProjected)
    }
}

struct ExplorationPendingItem: Identifiable {
    let id = UUID()
    let note: String
    let category: ExplorationCategory
    let type: ExplorationTransactionType
    let amount: Decimal
    let dueDate: Date
}

struct ExplorationTransaction: Identifiable {
    let id = UUID()
    let type: ExplorationTransactionType
    /// Full amount paid (ACC-001).
    let amount: Decimal
    /// The user's share; set only for split expenses.
    let myShare: Decimal?
    let category: ExplorationCategory
    let note: String?
    let date: Date

    var isSplit: Bool { myShare != nil }
    var signedAmount: Decimal { type == .expense ? -amount : amount }
}

struct ExplorationDailySpending: Identifiable {
    let day: Int
    let cumulative: Decimal

    var id: Int { day }
}

struct ExplorationHomeSnapshot {
    let currencyCode: String
    let balance: Decimal
    let monthIncome: Decimal
    let spendingByCategory: [ExplorationCategorySpending]
    let plan: ExplorationPlanSummary?
    let owedToYou: Decimal
    let owedPeopleCount: Int
    let pendingItems: [ExplorationPendingItem]
    let recentTransactions: [ExplorationTransaction]
    let dailySpending: [ExplorationDailySpending]
    let dayOfMonth: Int
    let daysInMonth: Int

    var monthSpending: Decimal { spendingByCategory.reduce(0) { $0 + $1.amount } }
    var monthDifference: Decimal { monthIncome - monthSpending }
}

extension ExplorationHomeSnapshot {
    /// A mid-month snapshot with every Home card visible. Numbers follow the examples in the v1 requirements.
    static let sample: ExplorationHomeSnapshot = {
        let dailyIncrements = [
            "762.40", "0", "18.20", "32.15", "0", "45.00", "27.98", "21.60", "0",
            "38.00", "24.75", "0", "48.30", "12.10", "0", "57.10", "52.10", "94.35",
        ]
        var running: Decimal = 0
        let daily = dailyIncrements.enumerated().map { index, increment in
            running += amount(increment)
            return ExplorationDailySpending(day: index + 1, cumulative: running)
        }

        return ExplorationHomeSnapshot(
            currencyCode: "EUR",
            balance: amount("2486.40"),
            monthIncome: amount("2150.00"),
            spendingByCategory: [
                .init(category: .housing, amount: amount("750.00")),
                .init(category: .groceries, amount: amount("212.35")),
                .init(category: .dining, amount: amount("96.50")),
                .init(category: .fuel, amount: amount("64.20")),
                .init(category: .leisure, amount: amount("45.00")),
                .init(category: .transport, amount: amount("38.00")),
                .init(category: .subscriptions, amount: amount("27.98")),
            ],
            plan: ExplorationPlanSummary(
                categories: [
                    .init(category: .housing, planned: amount("750"), spent: amount("750.00"), projected: amount("750.00")),
                    .init(category: .groceries, planned: amount("300"), spent: amount("212.35"), projected: amount("318.20")),
                    .init(category: .dining, planned: amount("80"), spent: amount("96.50"), projected: amount("140.00")),
                    .init(category: .fuel, planned: amount("100"), spent: amount("64.20"), projected: amount("96.00")),
                    .init(category: .leisure, planned: amount("200"), spent: amount("45.00"), projected: amount("80.00")),
                    .init(category: .subscriptions, planned: amount("45"), spent: amount("27.98"), projected: amount("40.97")),
                ],
                unplannedSpent: amount("38.00"),
                unplannedProjected: amount("99.90")
            ),
            owedToYou: amount("85.00"),
            owedPeopleCount: 2,
            pendingItems: [
                .init(note: "Netflix", category: .subscriptions, type: .expense, amount: amount("12.99"), dueDate: daysAgo(0)),
                .init(note: "Gym", category: .health, type: .expense, amount: amount("39.90"), dueDate: daysAgo(2)),
            ],
            recentTransactions: [
                .init(type: .expense, amount: amount("120.00"), myShare: amount("30.00"), category: .dining,
                      note: "Dinner at Casa Pepe", date: daysAgo(0)),
                .init(type: .expense, amount: amount("64.35"), myShare: nil, category: .groceries,
                      note: "Weekly shop", date: daysAgo(0)),
                .init(type: .expense, amount: amount("52.10"), myShare: nil, category: .fuel,
                      note: "Full tank", date: daysAgo(1)),
                .init(type: .expense, amount: amount("38.00"), myShare: nil, category: .transport,
                      note: "Monthly metro pass", date: daysAgo(8)),
                .init(type: .income, amount: amount("2150.00"), myShare: nil, category: .salary,
                      note: nil, date: daysAgo(17)),
            ],
            dailySpending: daily,
            dayOfMonth: 18,
            daysInMonth: 31
        )
    }()

    /// Parses from a string so mock amounts never pass through floating point (NFR-005).
    private static func amount(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    private static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
    }
}

extension Decimal {
    /// Swift Charts and progress bars plot `Double`. Use for drawing only, never for money math (NFR-005).
    var plotValue: Double { NSDecimalNumber(decimal: self).doubleValue }
}

// MARK: - Interaction state

enum ExplorationDestination: Hashable {
    case plan
    case people
    case history
}

@Observable
final class ExplorationHomeModel {
    let snapshot: ExplorationHomeSnapshot
    private(set) var pendingItems: [ExplorationPendingItem]
    var addingType: ExplorationTransactionType?
    /// The add screen to present instead of the stand-in, so the Add & edit explorations open from Home.
    @ObservationIgnored let addEditor: ((ExplorationTransactionType) -> AnyView)?

    init(snapshot: ExplorationHomeSnapshot, addEditor: ((ExplorationTransactionType) -> AnyView)? = nil) {
        self.snapshot = snapshot
        self.addEditor = addEditor
        pendingItems = snapshot.pendingItems
    }

    func confirm(_ item: ExplorationPendingItem) {
        pendingItems.removeAll { $0.id == item.id }
    }

    func skip(_ item: ExplorationPendingItem) {
        pendingItems.removeAll { $0.id == item.id }
    }
}

// MARK: - Placeholder destinations

struct ExplorationPlaceholderScreen: View {
    let destination: ExplorationDestination

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: symbol)
        } description: {
            Text("This screen isn't part of the Home exploration.")
        }
        .navigationTitle(title)
    }

    private var title: LocalizedStringResource {
        switch destination {
        case .plan: "Plan"
        case .people: "People"
        case .history: "History"
        }
    }

    private var symbol: String {
        switch destination {
        case .plan: "chart.bar.doc.horizontal"
        case .people: "person.2"
        case .history: "clock.arrow.circlepath"
        }
    }
}

/// Stand-in for TRX-001/TRX-002: opens on Expense with the amount focused, and lets the user switch to Income.
struct ExplorationAddSheet: View {
    @State var type: ExplorationTransactionType
    let currencyCode: String

    @State private var amount: Decimal?
    @FocusState private var isAmountFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Picker("Type", selection: $type) {
                    ForEach(ExplorationTransactionType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                TextField("Amount", value: $amount, format: .currency(code: currencyCode))
                    .keyboardType(.decimalPad)
                    .font(.largeTitle.weight(.semibold))
                    .focused($isAmountFocused)
            }
            .navigationTitle(Text(type.addTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", role: .confirm) { dismiss() }
                        .disabled((amount ?? 0) <= 0)
                }
            }
            .onAppear { isAmountFocused = true }
        }
    }
}

// MARK: - Shared building blocks

/// How icons and avatars are drawn: `solid` (white symbol on a filled circle, the system look) or
/// `soft` (symbol in the category color on a pale tint of it, in a rounded square).
enum ExplorationIconStyle {
    case solid
    case soft
}

extension EnvironmentValues {
    @Entry var explorationIconStyle: ExplorationIconStyle = .solid
}

/// How buttons are drawn: the system glass styles, or Liquid Glass tinted with a brand color in a
/// rounded rectangle with rounded type, so buttons stop looking like stock iOS.
enum ExplorationButtonLook {
    case system
    case brandGlass(Color)
}

enum ExplorationButtonRole {
    case primary
    case secondary
}

extension EnvironmentValues {
    @Entry var explorationButtonLook: ExplorationButtonLook = .system
}

extension View {
    /// Applies the button look from the environment for a primary or secondary action.
    func explorationButton(_ role: ExplorationButtonRole) -> some View {
        modifier(ExplorationButtonModifier(role: role))
    }
}

private struct ExplorationButtonModifier: ViewModifier {
    let role: ExplorationButtonRole
    @Environment(\.explorationButtonLook) private var look

    func body(content: Content) -> some View {
        switch (look, role) {
        case (.system, .primary):
            content.buttonStyle(.glassProminent)
        case (.system, .secondary):
            content.buttonStyle(.glass)
        case (.brandGlass(let tint), _):
            content.buttonStyle(ExplorationBrandGlassButtonStyle(tint: tint, isPrimary: role == .primary))
        }
    }
}

/// Interactive Liquid Glass, tinted with the brand color for primary actions and lightly for
/// secondary ones, in a continuous rounded rectangle.
struct ExplorationBrandGlassButtonStyle: ButtonStyle {
    let tint: Color
    let isPrimary: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(isPrimary ? Color.white : tint)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .glassEffect(
                isPrimary ? .regular.tint(tint).interactive() : .regular.tint(tint.opacity(0.12)).interactive(),
                in: .rect(cornerRadius: 14, style: .continuous)
            )
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
    }
}

struct ExplorationCategoryIcon: View {
    let category: ExplorationCategory
    @ScaledMetric private var size: CGFloat = 36
    @Environment(\.explorationIconStyle) private var style

    var body: some View {
        switch style {
        case .solid:
            Image(systemName: category.symbol)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(category.color.gradient, in: .circle)
                .accessibilityHidden(true)
        case .soft:
            Image(systemName: category.symbol)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(category.color)
                .frame(width: size, height: size)
                .background(category.color.opacity(0.16), in: .rect(cornerRadius: size * 0.3, style: .continuous))
                .accessibilityHidden(true)
        }
    }
}

struct ExplorationStatusLabel: View {
    let status: ExplorationPlanStatus

    var body: some View {
        Label {
            Text(status.title)
        } icon: {
            Image(systemName: status.symbol)
                .foregroundStyle(status.tint)
        }
    }
}

/// Spent (solid), projected (faded) and a marker at the planned amount.
struct ExplorationPlanBar: View {
    let spent: Decimal
    let projected: Decimal
    let planned: Decimal
    let tint: Color

    @ScaledMetric private var height: CGFloat = 8

    var body: some View {
        let scale = max(spent, projected, planned).plotValue
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule().fill(tint.opacity(0.35)).frame(width: width * fraction(projected, of: scale))
                Capsule().fill(tint).frame(width: width * fraction(spent, of: scale))
                Capsule()
                    .fill(.primary)
                    .frame(width: 2, height: height * 1.8)
                    .offset(x: width * fraction(planned, of: scale) - 1)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }

    private func fraction(_ value: Decimal, of scale: Double) -> CGFloat {
        guard scale > 0 else { return 0 }
        return CGFloat(min(max(value.plotValue / scale, 0), 1))
    }
}

struct ExplorationTransactionRow: View {
    let transaction: ExplorationTransaction
    let currencyCode: String

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
            : AnyLayout(HStackLayout(spacing: 12))

        layout {
            HStack(spacing: 12) {
                ExplorationCategoryIcon(category: transaction.category)
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.note ?? String(localized: transaction.category.name))
                        .font(.body)
                    Text(transaction.category.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let share = transaction.myShare {
                        Label {
                            Text("Split · your share \(share, format: .currency(code: currencyCode))")
                        } icon: {
                            Image(systemName: "person.2.fill")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 0)
            }
            Text(transaction.signedAmount, format: .currency(code: currencyCode).sign(strategy: .always()))
                .font(.body.monospacedDigit().weight(.medium))
        }
        .accessibilityElement(children: .combine)
    }
}

struct ExplorationDueText: View {
    let date: Date

    var body: some View {
        if Calendar.current.isDateInToday(date) {
            Text("Due today")
        } else {
            Text("Due \(date, format: .dateTime.day().month())")
        }
    }
}
#endif
