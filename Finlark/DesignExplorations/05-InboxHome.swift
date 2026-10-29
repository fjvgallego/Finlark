//
//  05-InboxHome.swift
//  Finlark
//
//  FIN-9 exploration 05 "Inbox": attention first. Whatever needs action (pending items, money owed)
//  sits at the top, then the month summary and recent activity. The balance also rides in the
//  navigation subtitle, and quick add is a wide button in the bottom toolbar.
//

#if DEBUG
import SwiftUI

struct InboxHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 180

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }
    private var attentionCount: Int { model.pendingItems.count + (snapshot.owedToYou > 0 ? 1 : 0) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    attentionSection
                    summarySection
                    recentSection
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .navigationTitle("Home")
            .navigationSubtitle(Text("Balance \(snapshot.balance, format: .currency(code: code))"))
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        model.addingType = .expense
                    } label: {
                        Label("Add expense", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                }
            }
            .explorationScaffold(model)
        }
    }

    // MARK: Needs your attention

    private var attentionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Needs your attention")
                    .font(.title3.weight(.bold))
                if attentionCount > 0 {
                    Text(attentionCount, format: .number)
                        .font(.subheadline.weight(.bold).monospacedDigit())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red, in: .capsule)
                        .accessibilityLabel(Text("\(attentionCount) items"))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            if attentionCount == 0 {
                Label("You're all caught up", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
            }

            ForEach(model.pendingItems) { item in
                InboxItem(symbol: "repeat", tint: .orange, kind: "Recurring") {
                    ExplorationPendingRow(
                        item: item,
                        currencyCode: code,
                        onConfirm: { model.confirm(item) },
                        onSkip: { model.skip(item) }
                    )
                }
            }

            if snapshot.owedToYou > 0 {
                NavigationLink(value: ExplorationDestination.people) {
                    InboxItem(symbol: "person.2.fill", tint: .blue, kind: "Owed to you") {
                        HStack {
                            Text("\(snapshot.owedPeopleCount) people owe you \(snapshot.owedToYou, format: .currency(code: code))")
                                .font(.body.weight(.medium))
                                .monospacedDigit()
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: This month

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Date.now, format: .dateTime.month(.wide))
                .font(.title3.weight(.bold))
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: 14) {
                ViewThatFits(in: .horizontal) {
                    HStack { summaryFigures }
                    VStack(alignment: .leading, spacing: 10) { summaryFigures }
                }
                ExplorationSpendingBars(spending: snapshot.spendingByCategory, currencyCode: code)
                    .frame(height: chartHeight)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))

            NavigationLink(value: ExplorationDestination.plan) {
                planRow
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var summaryFigures: some View {
        InboxFigure(title: "Income", value: snapshot.monthIncome, code: code)
        Spacer(minLength: 8)
        InboxFigure(title: "Spending", value: snapshot.monthSpending, code: code)
        Spacer(minLength: 8)
        InboxFigure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true)
    }

    @ViewBuilder
    private var planRow: some View {
        if let plan = snapshot.plan {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Monthly Plan")
                        .font(.headline)
                    Spacer(minLength: 8)
                    ExplorationStatusLabel(status: plan.status)
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                ExplorationPlanBar(
                    spent: plan.totalSpent,
                    projected: plan.totalProjected,
                    planned: plan.totalPlanned,
                    tint: plan.status.tint
                )
                Text("\(plan.totalRemaining, format: .currency(code: code)) left · projected \(plan.totalProjected, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
        } else {
            Label("Plan your month to see how you're doing", systemImage: "chart.bar.doc.horizontal")
                .font(.headline)
        }
    }

    // MARK: Recent

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent")
                    .font(.title3.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                NavigationLink("See all", value: ExplorationDestination.history)
            }
            VStack(spacing: 14) {
                ForEach(snapshot.recentTransactions) { transaction in
                    ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        }
    }
}

private struct InboxItem<Content: View>: View {
    let symbol: String
    let tint: Color
    let kind: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(kind, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 18))
        .overlay(alignment: .leading) {
            UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18)
                .fill(tint)
                .frame(width: 5)
                .accessibilityHidden(true)
        }
    }
}

private struct InboxFigure: View {
    let title: LocalizedStringKey
    let value: Decimal
    let code: String
    var signed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code).sign(strategy: signed ? .always() : .automatic))
                .font(.headline)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("05 Inbox") {
    InboxHomeView()
}
#endif
