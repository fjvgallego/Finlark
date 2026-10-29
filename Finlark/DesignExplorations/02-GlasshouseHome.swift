//
//  02-GlasshouseHome.swift
//  Finlark
//
//  FIN-9 exploration 02 "Glasshouse": Liquid Glass forward. Glass cards share one GlassEffectContainer
//  over a soft tinted backdrop, with a floating glass quick-add button.
//

#if DEBUG
import SwiftUI

struct GlasshouseHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var chartSize: CGFloat = 132
    @ScaledMetric private var addButtonSize: CGFloat = 60

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                GlassEffectContainer(spacing: 16) {
                    VStack(spacing: 16) {
                        balanceCard
                        if !model.pendingItems.isEmpty {
                            pendingCard
                        }
                        monthCard
                        planCard
                        if snapshot.owedToYou > 0 {
                            owedCard
                        }
                        recentCard
                    }
                    .padding(.horizontal)
                    .padding(.bottom, addButtonSize + 24)
                }
            }
            .background(backdrop)
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .overlay(alignment: .bottomTrailing) { addButton }
            .navigationTitle("Home")
            .explorationScaffold(model)
        }
    }

    private var backdrop: some View {
        LinearGradient(
            colors: [Color.indigo.opacity(0.28), Color.teal.opacity(0.16), Color(.systemBackground)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var addButton: some View {
        Button {
            model.addingType = .expense
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .frame(width: addButtonSize, height: addButtonSize)
        }
        .buttonStyle(.glassProminent)
        .buttonBorderShape(.circle)
        .accessibilityLabel(Text("Add transaction"))
        .padding(.trailing, 20)
        .padding(.bottom, 8)
    }

    private var balanceCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Label("Balance", systemImage: "wallet.bifold")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(snapshot.balance, format: .currency(code: code))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var pendingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Waiting for you", systemImage: "clock.badge.exclamationmark")
                    .font(.headline)
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
    }

    private var monthCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(Date.now, format: .dateTime.month(.wide))
                    .font(.headline)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 20) {
                        monthFigures
                        Spacer(minLength: 0)
                        donut
                    }
                    VStack(alignment: .leading, spacing: 16) {
                        monthFigures
                        donut
                    }
                }
            }
        }
    }

    private var monthFigures: some View {
        VStack(alignment: .leading, spacing: 10) {
            figure("Income", value: snapshot.monthIncome)
            figure("Spending", value: snapshot.monthSpending)
            figure("Difference", value: snapshot.monthDifference, signed: true)
        }
        .fixedSize()
    }

    private var donut: some View {
        ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
            .frame(width: chartSize, height: chartSize)
    }

    private func figure(_ title: LocalizedStringKey, value: Decimal, signed: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code).sign(strategy: signed ? .always() : .automatic))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var planCard: some View {
        NavigationLink(value: ExplorationDestination.plan) {
            GlassCard {
                if let plan = snapshot.plan {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Monthly Plan")
                                .font(.headline)
                            Spacer(minLength: 8)
                            ExplorationStatusLabel(status: plan.status)
                                .font(.subheadline.weight(.medium))
                        }
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        Text("\(plan.totalSpent, format: .currency(code: code)) spent of \(plan.totalPlanned, format: .currency(code: code)) · projected \(plan.totalProjected, format: .currency(code: code))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                } else {
                    Label("Create a Monthly Plan to see your pace", systemImage: "sparkles")
                        .font(.headline)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var owedCard: some View {
        NavigationLink(value: ExplorationDestination.people) {
            GlassCard {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.title2)
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
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.tertiary)
                        .accessibilityHidden(true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }

    private var recentCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Recent")
                        .font(.headline)
                    Spacer()
                    NavigationLink("History", value: ExplorationDestination.history)
                        .font(.subheadline.weight(.medium))
                }
                ForEach(snapshot.recentTransactions) { transaction in
                    ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                }
            }
        }
    }
}

private struct GlassCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}

#Preview("02 Glasshouse") {
    GlasshouseHomeView()
}
#endif
