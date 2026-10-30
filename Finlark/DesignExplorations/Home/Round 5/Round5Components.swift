//
//  Round5Components.swift
//  Finlark
//
//  FIN-9 Round 5: pieces for the Topaz variants. Pending items come first, the plan leads with Slate's
//  pace sentence, and each variant tries a minimal spending-by-category chart (HOM-002). Following
//  the HIG for charts, each chart has one clear message, labels its data directly instead of relying
//  on color, and gives VoiceOver a label and value for every mark.
//

#if DEBUG
import SwiftUI
import Charts

// MARK: - Plan with the pace sentence

/// The plan (HOM-003) led by one sentence about the pace, as in Slate.
struct R5PlanPaceTile: View {
    let snapshot: ExplorationHomeSnapshot

    private var code: String { snapshot.currencyCode }

    var body: some View {
        R2Link(destination: .plan) {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Monthly Plan", symbol: "chart.bar.doc.horizontal.fill") { R2Chevron() }
                    if let plan = snapshot.plan {
                        Text(snapshot.r5PaceSentence(for: plan))
                            .font(.title3.weight(.semibold))
                        ExplorationStatusLabel(status: plan.status)
                            .font(.subheadline.weight(.semibold))
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        .padding(.vertical, 2)
                        Text("\(plan.totalSpent, format: .currency(code: code)) spent of \(plan.totalPlanned, format: .currency(code: code)) · \(snapshot.r3DaysLeft) days to go")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("You haven't set a plan yet. Planning a few categories shows where the month is heading.")
                            .font(.headline)
                    }
                }
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }
}

extension ExplorationHomeSnapshot {
    /// Slate's one-sentence read of the plan's pace ("At this pace you'll go €50.07 over plan.").
    func r5PaceSentence(for plan: ExplorationPlanSummary) -> LocalizedStringKey {
        // A-09: no pace estimate during the first 3 days of the month.
        guard dayOfMonth > 3 else {
            return "\(plan.totalRemaining, format: .currency(code: currencyCode)) left to spend this month."
        }
        switch plan.status {
        case .onTrack:
            return "You're on track, with \(plan.totalRemaining, format: .currency(code: currencyCode)) left to spend."
        case .atRisk:
            return "At this pace you'll go \(plan.totalProjected - plan.totalPlanned, format: .currency(code: currencyCode)) over plan."
        case .over:
            return "You're already \(plan.totalSpent - plan.totalPlanned, format: .currency(code: currencyCode)) over plan."
        }
    }
}

// MARK: - Summary pieces

struct R5BalanceHeader: View {
    let snapshot: ExplorationHomeSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Balance")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(snapshot.balance, format: .currency(code: snapshot.currencyCode))
                .font(.system(.title, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

struct R5MonthFigures: View {
    let snapshot: ExplorationHomeSnapshot

    private var code: String { snapshot.currencyCode }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) { figures }
            VStack(alignment: .leading, spacing: 8) { figures }
        }
    }

    @ViewBuilder
    private var figures: some View {
        R2Figure(title: "Income", value: snapshot.monthIncome, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        R2Figure(title: "Spending", value: snapshot.monthSpending, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        R2Figure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true,
                 font: .subheadline.weight(.semibold))
    }
}

extension ExplorationHomeSnapshot {
    /// Share of the month's spending, for chart captions.
    func r5Share(of amount: Decimal) -> Decimal {
        monthSpending > 0 ? amount / monthSpending : 0
    }
}

// MARK: - Pager

/// Pages that swipe inside a tile. Unlike Round 2's slider, pages are exactly as wide as the tile,
/// snap one page at a time and are clipped to the tile, so neighbors never show outside it.
/// At accessibility sizes the pages stack vertically.
struct R5Pager<Item: Identifiable, Page: View>: View {
    private let items: [Item]
    private let page: (Item) -> Page

    @State private var currentID: Item.ID?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(_ items: [Item], @ViewBuilder page: @escaping (Item) -> Page) {
        self.items = items
        self.page = page
    }

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(items) { item in
                    page(item)
                }
            }
        } else {
            VStack(spacing: 10) {
                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(items) { item in
                            page(item)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .containerRelativeFrame(.horizontal)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $currentID)
                .scrollIndicators(.hidden)

                if items.count > 1 {
                    R2PageDots(count: items.count, index: currentIndex, onGlass: false)
                }
            }
        }
    }

    private var currentIndex: Int {
        items.firstIndex { $0.id == currentID } ?? 0
    }
}

// MARK: - Minimal category charts (HOM-002)

/// The top categories as thin bars in one color on a shared scale, each with its name and amount
/// written above it. Nothing depends on color: every bar carries its own label.
struct R5RankBars: View {
    let snapshot: ExplorationHomeSnapshot
    var limit = 3

    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 6

    private var items: [ExplorationCategorySpending] {
        Array(snapshot.spendingByCategory.sorted { $0.amount > $1.amount }.prefix(limit))
    }

    var body: some View {
        let maxValue = items.map(\.amount.plotValue).max() ?? 0

        VStack(alignment: .leading, spacing: 10) {
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(item.category.name)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text(item.amount, format: .currency(code: snapshot.currencyCode))
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .font(.caption)

                    Chart {
                        BarMark(xStart: .value("Start", 0), xEnd: .value("Amount", item.amount.plotValue))
                            .foregroundStyle(Color.accentColor)
                            .cornerRadius(barHeight / 2)
                    }
                    .chartXScale(domain: 0...max(maxValue, 1))
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: barHeight)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(item.category.name))
                .accessibilityValue(Text(item.amount, format: .currency(code: snapshot.currencyCode)))
            }
        }
    }
}

/// One bar of the whole month where only the largest category is colored, plus one sentence that
/// names it. Focus plus context: the message is in the text, the bar shows the proportion.
struct R5FocusBar: View {
    let snapshot: ExplorationHomeSnapshot

    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 8

    private var sorted: [ExplorationCategorySpending] {
        snapshot.spendingByCategory.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        if let top = sorted.first {
            VStack(alignment: .leading, spacing: 8) {
                Text("**\(Text(top.category.name))** is \(snapshot.r5Share(of: top.amount), format: .percent.precision(.fractionLength(0))) of your spending")
                    .font(.subheadline)
                Chart(sorted) { item in
                    BarMark(x: .value("Amount", item.amount.plotValue))
                        .foregroundStyle(item.id == top.id ? Color.accentColor : Color.secondary.opacity(0.25))
                        .accessibilityLabel(Text(item.category.name))
                        .accessibilityValue(Text(item.amount, format: .currency(code: snapshot.currencyCode)))
                }
                .chartXScale(domain: 0...max(snapshot.monthSpending.plotValue, 1))
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: barHeight)
                .clipShape(.capsule)
            }
        }
    }
}

/// One bar of the whole month you can scrub: touching a segment colors it and names it above.
/// Untouched, it shows the largest category, so it reads without interaction. VoiceOver reads every
/// segment through the chart's own marks.
struct R5ScrubBar: View {
    let snapshot: ExplorationHomeSnapshot

    @State private var rawSelection: Double?
    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 14

    private var sorted: [ExplorationCategorySpending] {
        snapshot.spendingByCategory.sorted { $0.amount > $1.amount }
    }

    /// The segment under the finger. Segments stack in order, so walk the running total.
    private var selected: ExplorationCategorySpending? {
        guard let rawSelection else { return sorted.first }
        var runningTotal = 0.0
        for item in sorted {
            runningTotal += item.amount.plotValue
            if rawSelection <= runningTotal { return item }
        }
        return sorted.last
    }

    var body: some View {
        if let selected {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Image(systemName: selected.category.symbol)
                        .foregroundStyle(selected.category.color)
                        .accessibilityHidden(true)
                    Text(selected.category.name)
                        .fontWeight(.semibold)
                    Text(selected.amount, format: .currency(code: snapshot.currencyCode))
                        .monospacedDigit()
                    Text(snapshot.r5Share(of: selected.amount), format: .percent.precision(.fractionLength(0)))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                .font(.subheadline)
                .accessibilityHidden(true) // The chart marks carry the same information.

                Chart(sorted) { item in
                    BarMark(x: .value("Amount", item.amount.plotValue))
                        .foregroundStyle(item.id == selected.id ? item.category.color : Color.secondary.opacity(0.25))
                        .accessibilityLabel(Text(item.category.name))
                        .accessibilityValue(Text(item.amount, format: .currency(code: snapshot.currencyCode)))
                }
                .chartXScale(domain: 0...max(snapshot.monthSpending.plotValue, 1))
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .chartXSelection(value: $rawSelection)
                .frame(height: barHeight)
                .clipShape(.capsule)

                Text("Touch and drag the bar to see each category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
    }
}
#endif
