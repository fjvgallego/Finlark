//
//  10-DigestHome.swift
//  Finlark
//
//  FIN-9 exploration 10 "Digest": Home as plain-language sentences ("You've spent €1,234 of your
//  €1,475 plan"), each a friendly card with one clear action.
//

#if DEBUG
import SwiftUI

struct DigestHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var chartSize: CGFloat = 96

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    balanceCard
                    monthCard
                    planCard
                    if snapshot.owedToYou > 0 {
                        owedCard
                    }
                    if !model.pendingItems.isEmpty {
                        pendingCard
                    }
                    recentCard
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .navigationTitle("Home")
            .toolbar(.hidden, for: .navigationBar)
            .explorationScaffold(model)
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(greeting)
                .font(.largeTitle.weight(.bold))
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 12)
            Button {
                model.addingType = .expense
            } label: {
                Label("Log an expense", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            Button("or log income") {
                model.addingType = .income
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
        }
    }

    private var greeting: LocalizedStringKey {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: "Good morning"
        case 12..<20: "Good afternoon"
        default: "Good evening"
        }
    }

    // MARK: Cards

    private var balanceCard: some View {
        DigestCard(symbol: "wallet.bifold.fill", tint: .blue) {
            Text("You have **\(snapshot.balance, format: .currency(code: code))** in your account.")
        }
    }

    private var monthCard: some View {
        DigestCard(symbol: "calendar", tint: .purple) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(monthSentence)
                    if let top = snapshot.spendingByCategory.max(by: { $0.amount < $1.amount }) {
                        Text("Most of it went to \(Text(top.category.name).bold()).")
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
                    .frame(width: chartSize, height: chartSize)
            }
        }
    }

    private var monthSentence: LocalizedStringKey {
        let difference = snapshot.monthDifference
        if difference >= 0 {
            return "In \(Date.now, format: .dateTime.month(.wide)) you've earned **\(snapshot.monthIncome, format: .currency(code: code))** and spent **\(snapshot.monthSpending, format: .currency(code: code))**, so you're \(difference, format: .currency(code: code)) ahead."
        } else {
            return "In \(Date.now, format: .dateTime.month(.wide)) you've earned **\(snapshot.monthIncome, format: .currency(code: code))** and spent **\(snapshot.monthSpending, format: .currency(code: code))**, so you're \(-difference, format: .currency(code: code)) behind."
        }
    }

    private var planCard: some View {
        NavigationLink(value: ExplorationDestination.plan) {
            DigestCard(symbol: "chart.bar.doc.horizontal.fill", tint: .orange, actionTitle: "Open plan") {
                if let plan = snapshot.plan {
                    Text("You've spent **\(plan.totalSpent, format: .currency(code: code))** of your \(plan.totalPlanned, format: .currency(code: code)) plan. At this pace you'll reach \(plan.totalProjected, format: .currency(code: code)).")
                    ExplorationStatusLabel(status: plan.status)
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("You haven't set a Monthly Plan yet. Planning a few categories helps you see where the month is heading.")
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var owedCard: some View {
        NavigationLink(value: ExplorationDestination.people) {
            DigestCard(symbol: "person.2.fill", tint: .teal, actionTitle: "See who") {
                Text("\(snapshot.owedPeopleCount) people owe you **\(snapshot.owedToYou, format: .currency(code: code))**.")
            }
        }
        .buttonStyle(.plain)
    }

    private var pendingCard: some View {
        DigestCard(symbol: "repeat", tint: .pink) {
            Text("\(model.pendingItems.count) recurring items are waiting for you.")
            ForEach(model.pendingItems) { item in
                ExplorationPendingRow(
                    item: item,
                    currencyCode: code,
                    onConfirm: { model.confirm(item) },
                    onSkip: { model.skip(item) }
                )
                .padding(.top, 4)
            }
        }
    }

    private var recentCard: some View {
        DigestCard(symbol: "clock.fill", tint: .gray) {
            Text("Here's what you logged lately.")
            ForEach(snapshot.recentTransactions) { transaction in
                ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                    .padding(.top, 4)
            }
            NavigationLink(value: ExplorationDestination.history) {
                Text("See everything in History")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.top, 4)
        }
    }
}

private struct DigestCard<Content: View>: View {
    let symbol: String
    let tint: Color
    var actionTitle: LocalizedStringKey?
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(minWidth: 28)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 10) {
                content
                    .font(.body)
                if let actionTitle {
                    HStack(spacing: 4) {
                        Text(actionTitle)
                        Image(systemName: "chevron.right")
                            .accessibilityHidden(true)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                }
            }
        }
        .monospacedDigit()
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 22))
    }
}

#Preview("10 Digest") {
    DigestHomeView()
}
#endif
