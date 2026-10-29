//
//  01-LedgerHome.swift
//  Finlark
//
//  FIN-9 exploration 01 "Ledger": pure system design. An inset-grouped list with native sections,
//  a large title and a prominent glass add button in the toolbar. The baseline to compare against.
//

#if DEBUG
import SwiftUI

struct LedgerHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var chartHeight: CGFloat = 200

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        NavigationStack {
            List {
                balanceSection
                pendingSection
                monthSection
                planSection
                owedSection
                recentSection
            }
            .listStyle(.insetGrouped)
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .navigationTitle("Home")
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

    private var balanceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(snapshot.balance, format: .currency(code: code))
                    .font(.largeTitle.bold())
                    .monospacedDigit()
            }
            .padding(.vertical, 4)
            .accessibilityElement(children: .combine)
        }
    }

    @ViewBuilder
    private var pendingSection: some View {
        if !model.pendingItems.isEmpty {
            Section("Pending") {
                ForEach(model.pendingItems) { item in
                    ExplorationPendingRow(
                        item: item,
                        currencyCode: code,
                        onConfirm: { model.confirm(item) },
                        onSkip: { model.skip(item) }
                    )
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var monthSection: some View {
        Section {
            LabeledContent("Income") {
                Text(snapshot.monthIncome, format: .currency(code: code))
            }
            LabeledContent("Spending") {
                Text(snapshot.monthSpending, format: .currency(code: code))
            }
            LabeledContent("Difference") {
                Text(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))
                    .fontWeight(.semibold)
            }
            ExplorationSpendingBars(spending: snapshot.spendingByCategory, currencyCode: code)
                .frame(height: chartHeight)
                .padding(.vertical, 8)
        } header: {
            Text(Date.now, format: .dateTime.month(.wide))
        }
        .monospacedDigit()
    }

    private var planSection: some View {
        Section("Monthly Plan") {
            if let plan = snapshot.plan {
                NavigationLink(value: ExplorationDestination.plan) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("\(plan.totalSpent, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code))")
                                .font(.headline)
                            Spacer(minLength: 8)
                            ExplorationStatusLabel(status: plan.status)
                                .font(.subheadline)
                        }
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: .accentColor
                        )
                        Text("Projected \(plan.totalProjected, format: .currency(code: code))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .monospacedDigit()
                    .padding(.vertical, 4)
                    .accessibilityElement(children: .combine)
                }
            } else {
                NavigationLink(value: ExplorationDestination.plan) {
                    Label("Set up your Monthly Plan", systemImage: "chart.bar.doc.horizontal")
                }
            }
        }
    }

    @ViewBuilder
    private var owedSection: some View {
        if snapshot.owedToYou > 0 {
            Section {
                NavigationLink(value: ExplorationDestination.people) {
                    LabeledContent {
                        Text(snapshot.owedToYou, format: .currency(code: code))
                            .monospacedDigit()
                    } label: {
                        Label {
                            Text("Owed to you")
                            Text("\(snapshot.owedPeopleCount) people")
                        } icon: {
                            Image(systemName: "person.2.fill")
                        }
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        Section("Recent") {
            ForEach(snapshot.recentTransactions) { transaction in
                ExplorationTransactionRow(transaction: transaction, currencyCode: code)
            }
            NavigationLink("See all in History", value: ExplorationDestination.history)
        }
    }
}

#Preview("01 Ledger") {
    LedgerHomeView()
}
#endif
