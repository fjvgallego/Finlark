//
//  HavenHome.swift
//  Finlark
//
//  FIN-9 Round 5 "Haven": progressive disclosure. The spending figure carries a tiny bar split by
//  category, and one line says which categories dominate ("Housing, Groceries and Dining make up
//  86%"). Tapping that line opens a popover with the full breakdown, so Home stays quiet.
//

#if DEBUG
import SwiftUI
import Charts

struct HavenHomeView: View {
    @State private var model: ExplorationHomeModel
    @State private var showsBreakdown = false

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    private var sorted: [ExplorationCategorySpending] {
        snapshot.spendingByCategory.sorted { $0.amount > $1.amount }
    }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                R3PendingSection(model: model)
                Group {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            R5BalanceHeader(snapshot: snapshot)
                            Divider()
                            figures
                            breakdownButton
                        }
                    }
                    R5PlanPaceTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                }
                .padding(.horizontal)
                R4RecentList(snapshot: snapshot)
            }
        }
    }

    private var figures: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top) { figureContent }
            VStack(alignment: .leading, spacing: 8) { figureContent }
        }
    }

    @ViewBuilder
    private var figureContent: some View {
        R2Figure(title: "Income", value: snapshot.monthIncome, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        VStack(alignment: .leading, spacing: 4) {
            R2Figure(title: "Spending", value: snapshot.monthSpending, code: code, font: .subheadline.weight(.semibold))
            HavenMicroBar(spending: sorted, total: snapshot.monthSpending)
        }
        .fixedSize()
        Spacer(minLength: 8)
        R2Figure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true,
                 font: .subheadline.weight(.semibold))
    }

    private var breakdownButton: some View {
        let top = Array(sorted.prefix(3))
        let topTotal = top.reduce(Decimal(0)) { $0 + $1.amount }
        let names = top.map { String(localized: $0.category.name) }

        return Button {
            showsBreakdown = true
        } label: {
            HStack(spacing: 6) {
                Text("\(Text(names, format: .list(type: .and))) make up \(snapshot.r5Share(of: topTotal), format: .percent.precision(.fractionLength(0)))")
                    .multilineTextAlignment(.leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .accessibilityHidden(true)
            }
            .font(.subheadline)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.tint)
        .accessibilityHint(Text("Shows spending for every category"))
        .popover(isPresented: $showsBreakdown) {
            HavenBreakdown(snapshot: snapshot, spending: sorted)
                .presentationCompactAdaptation(.popover)
        }
    }
}

/// A tiny bar under the spending figure, split by category. Decorative: the line below it and the
/// breakdown name every category.
private struct HavenMicroBar: View {
    let spending: [ExplorationCategorySpending]
    let total: Decimal

    @ScaledMetric(relativeTo: .caption) private var height: CGFloat = 4

    var body: some View {
        Chart(spending) { item in
            BarMark(x: .value("Amount", item.amount.plotValue))
                .foregroundStyle(item.category.color)
        }
        .chartXScale(domain: 0...max(total.plotValue, 1))
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: height)
        .clipShape(.capsule)
        .accessibilityHidden(true)
    }
}

/// The full breakdown shown in the popover: every category, named, valued and with its share.
private struct HavenBreakdown: View {
    let snapshot: ExplorationHomeSnapshot
    let spending: [ExplorationCategorySpending]

    @ScaledMetric(relativeTo: .subheadline) private var rowHeight: CGFloat = 30

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by category")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(spending) { item in
                        HStack(spacing: 10) {
                            ExplorationCategoryIcon(category: item.category)
                            Text(item.category.name)
                            Spacer(minLength: 12)
                            Text(item.amount, format: .currency(code: snapshot.currencyCode))
                                .fontWeight(.medium)
                            Text(snapshot.r5Share(of: item.amount), format: .percent.precision(.fractionLength(0)))
                                .foregroundStyle(.secondary)
                                .frame(minWidth: 36, alignment: .trailing)
                        }
                        .font(.subheadline)
                        .monospacedDigit()
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .padding(20)
        .frame(minWidth: 320, idealHeight: rowHeight * CGFloat(spending.count + 3))
    }
}

#Preview("R5 Haven") {
    HavenHomeView()
}
#endif
