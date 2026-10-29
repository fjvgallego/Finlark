//
//  03-PulseHome.swift
//  Finlark
//
//  FIN-9 exploration 03 "Pulse": a hero balance above a ring gauge that shows plan spent (solid),
//  projected (faded) against planned, with compact cards below.
//

#if DEBUG
import SwiftUI

struct PulseHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 190
    @ScaledMetric private var ringSize: CGFloat = 210

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    monthTiles
                    if !model.pendingItems.isEmpty {
                        PulseCard(title: "Pending") {
                            ForEach(model.pendingItems) { item in
                                ExplorationPendingRow(
                                    item: item,
                                    currencyCode: code,
                                    onConfirm: { model.confirm(item) },
                                    onSkip: { model.skip(item) }
                                )
                            }
                        }
                    }
                    if snapshot.owedToYou > 0 {
                        owedCard
                    }
                    PulseCard(title: "Spending by category") {
                        ExplorationSpendingBars(spending: snapshot.spendingByCategory, currencyCode: code)
                            .frame(height: chartHeight)
                    }
                    PulseCard(title: "Recent") {
                        ForEach(snapshot.recentTransactions) { transaction in
                            ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                        }
                        NavigationLink(value: ExplorationDestination.history) {
                            Label("See all in History", systemImage: "arrow.right")
                                .labelStyle(TrailingIconLabelStyle())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Add transaction", systemImage: "plus") {
                        model.addingType = .expense
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .explorationScaffold(model)
        }
    }

    private var hero: some View {
        VStack(spacing: 18) {
            VStack(spacing: 4) {
                Text("Balance")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(snapshot.balance, format: .currency(code: code))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)

            NavigationLink(value: ExplorationDestination.plan) {
                if let plan = snapshot.plan {
                    planRing(plan)
                } else {
                    Label("Create a Monthly Plan", systemImage: "plus.circle")
                        .font(.headline)
                        .padding()
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
    }

    @ViewBuilder
    private func planRing(_ plan: ExplorationPlanSummary) -> some View {
        let ringCaption = VStack(spacing: 4) {
            Text("\(plan.totalSpent, format: .currency(code: code))")
                .font(.title2.weight(.semibold))
            Text("of \(plan.totalPlanned, format: .currency(code: code))")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            ExplorationStatusLabel(status: plan.status)
                .font(.subheadline.weight(.medium))
                .padding(.top, 4)
        }
        .monospacedDigit()
        .multilineTextAlignment(.center)

        let ring = ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 18)
            Circle()
                .trim(from: 0, to: fraction(plan.totalProjected, of: plan.totalPlanned))
                .stroke(plan.status.tint.opacity(0.35), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Circle()
                .trim(from: 0, to: fraction(plan.totalSpent, of: plan.totalPlanned))
                .stroke(plan.status.tint, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)

        VStack(spacing: 10) {
            // Text moves out of the ring at accessibility sizes so it never truncates.
            if dynamicTypeSize.isAccessibilitySize {
                ring.frame(width: 120, height: 120)
                ringCaption
            } else {
                ZStack {
                    ring
                    ringCaption.padding(36)
                }
                .frame(width: ringSize, height: ringSize)
            }
            Text("Projected \(plan.totalProjected, format: .currency(code: code)) by month end")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Monthly Plan"))
        .accessibilityValue(Text("\(plan.totalSpent, format: .currency(code: code)) spent of \(plan.totalPlanned, format: .currency(code: code)), projected \(plan.totalProjected, format: .currency(code: code)), \(Text(plan.status.title))"))
    }

    private var monthTiles: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { monthTileContent }
            VStack(spacing: 12) { monthTileContent }
        }
    }

    @ViewBuilder
    private var monthTileContent: some View {
        PulseTile(title: "Income", symbol: "arrow.down.left", value: snapshot.monthIncome, code: code)
        PulseTile(title: "Spending", symbol: "arrow.up.right", value: snapshot.monthSpending, code: code)
        PulseTile(title: "Difference", symbol: "plusminus", value: snapshot.monthDifference, code: code, signed: true)
    }

    private var owedCard: some View {
        NavigationLink(value: ExplorationDestination.people) {
            HStack(spacing: 12) {
                Image(systemName: "person.2.wave.2.fill")
                    .font(.title3)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Owed to you")
                        .font(.headline)
                    Text("\(snapshot.owedPeopleCount) people")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Text(snapshot.owedToYou, format: .currency(code: code))
                    .font(.headline)
                    .monospacedDigit()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
    }

    private func fraction(_ value: Decimal, of total: Decimal) -> CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(min(max(value.plotValue / total.plotValue, 0), 1))
    }
}

private struct PulseTile: View {
    let title: LocalizedStringKey
    let symbol: String
    let value: Decimal
    let code: String
    var signed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code).sign(strategy: signed ? .always() : .automatic))
                .font(.headline)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

private struct PulseCard<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
        }
        .font(.subheadline.weight(.medium))
    }
}

#Preview("03 Pulse") {
    PulseHomeView()
}
#endif
