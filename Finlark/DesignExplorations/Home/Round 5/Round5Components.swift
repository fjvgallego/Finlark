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

extension ExplorationHomeSnapshot {
    /// Share of the month's spending, for chart captions.
    func r5Share(of amount: Decimal) -> Decimal {
        monthSpending > 0 ? amount / monthSpending : 0
    }
}

// MARK: - Minimal category charts (HOM-002)

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
