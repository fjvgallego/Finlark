//
//  08-QuietHome.swift
//  Finlark
//
//  FIN-9 exploration 08 "Quiet": typographic and calm. Large light numerals, hairline dividers and a
//  monochrome palette. Color is reserved for plan status and actions.
//

#if DEBUG
import SwiftUI
import Charts

struct QuietHomeView: View {
    @State private var model: ExplorationHomeModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .largeTitle) private var heroSize: CGFloat = 54
    @ScaledMetric(relativeTo: .caption) private var stripHeight: CGFloat = 14

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    balance
                    QuietDivider()
                    month
                    QuietDivider()
                    plan
                    if snapshot.owedToYou > 0 {
                        QuietDivider()
                        owed
                    }
                    if !model.pendingItems.isEmpty {
                        QuietDivider()
                        pending
                    }
                    QuietDivider()
                    recent
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 96)
            }
            .animation(reduceMotion ? nil : .default, value: model.pendingItems.map(\.id))
            .safeAreaInset(edge: .bottom) {
                Button {
                    model.addingType = .expense
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)
                .padding(.bottom, 8)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .explorationScaffold(model)
        }
    }

    private var balance: some View {
        VStack(alignment: .leading, spacing: 4) {
            QuietCaption("Balance")
            Text(snapshot.balance, format: .currency(code: code))
                .font(.system(size: heroSize, weight: .thin, design: .default))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    private var month: some View {
        VStack(alignment: .leading, spacing: 14) {
            QuietCaption(Text(Date.now, format: .dateTime.month(.wide)))
            VStack(spacing: 8) {
                QuietLine("Income", value: snapshot.monthIncome, code: code)
                QuietLine("Spending", value: snapshot.monthSpending, code: code)
                QuietLine("Difference", value: snapshot.monthDifference, code: code, signed: true, emphasized: true)
            }

            // One stacked strip in shades of gray; the legend below names each band.
            Chart(Array(snapshot.spendingByCategory.enumerated()), id: \.element.id) { index, item in
                BarMark(x: .value("Amount", item.amount.plotValue))
                    .foregroundStyle(Color.primary.opacity(shade(index)))
                    .accessibilityLabel(Text(item.category.name))
                    .accessibilityValue(Text(item.amount, format: .currency(code: code)))
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: stripHeight)
            .clipShape(.capsule)

            VStack(spacing: 6) {
                ForEach(Array(snapshot.spendingByCategory.enumerated()), id: \.element.id) { index, item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.primary.opacity(shade(index)))
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                        Text(item.category.name)
                        Spacer(minLength: 8)
                        Text(item.amount, format: .currency(code: code))
                            .monospacedDigit()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityElement(children: .combine)
                }
            }
            .accessibilityHidden(true) // The chart above already exposes each category.
        }
    }

    private var plan: some View {
        NavigationLink(value: ExplorationDestination.plan) {
            VStack(alignment: .leading, spacing: 10) {
                QuietCaption("Monthly Plan")
                if let plan = snapshot.plan {
                    Text("\(plan.totalSpent, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code))")
                        .font(.title2.weight(.light))
                        .monospacedDigit()
                    ExplorationStatusLabel(status: plan.status)
                        .font(.subheadline)
                    Text("Projected \(plan.totalProjected, format: .currency(code: code)) by month end")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    Text("No plan yet. Set one up")
                        .font(.title3.weight(.light))
                        .foregroundStyle(.tint)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
    }

    private var owed: some View {
        NavigationLink(value: ExplorationDestination.people) {
            VStack(alignment: .leading, spacing: 6) {
                QuietCaption("Owed to you")
                Text(snapshot.owedToYou, format: .currency(code: code))
                    .font(.title2.weight(.light))
                    .monospacedDigit()
                Text("\(snapshot.owedPeopleCount) people")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
    }

    private var pending: some View {
        VStack(alignment: .leading, spacing: 16) {
            QuietCaption("Waiting for confirmation")
            ForEach(model.pendingItems) { item in
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.note)
                            ExplorationDueText(date: item.dueDate)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 8)
                        Text(item.type == .expense ? -item.amount : item.amount,
                             format: .currency(code: code).sign(strategy: .always()))
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)
                    HStack(spacing: 20) {
                        Button("Confirm") { model.confirm(item) }
                            .fontWeight(.semibold)
                            .accessibilityLabel(Text("Confirm \(item.note)"))
                        Button("Skip") { model.skip(item) }
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("Skip \(item.note)"))
                    }
                    .font(.subheadline)
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                QuietCaption("Recent")
                Spacer()
                NavigationLink("History", value: ExplorationDestination.history)
                    .font(.subheadline)
            }
            ForEach(snapshot.recentTransactions) { transaction in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(transaction.note ?? String(localized: transaction.category.name))
                        Group {
                            if let share = transaction.myShare {
                                Text("\(Text(transaction.category.name)) · Split, your share \(share, format: .currency(code: code))")
                            } else {
                                Text("\(Text(transaction.category.name)) · \(transaction.date, format: .dateTime.day().month())")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                    Text(transaction.signedAmount, format: .currency(code: code).sign(strategy: .always()))
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func shade(_ index: Int) -> Double {
        max(0.85 - Double(index) * 0.11, 0.15)
    }
}

private struct QuietCaption: View {
    private let text: Text

    init(_ key: LocalizedStringKey) {
        text = Text(key)
    }

    init(_ text: Text) {
        self.text = text
    }

    var body: some View {
        text
            .font(.footnote.weight(.medium))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.8)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct QuietLine: View {
    let title: LocalizedStringKey
    let value: Decimal
    let code: String
    var signed = false
    var emphasized = false

    init(_ title: LocalizedStringKey, value: Decimal, code: String, signed: Bool = false, emphasized: Bool = false) {
        self.title = title
        self.value = value
        self.code = code
        self.signed = signed
        self.emphasized = emphasized
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text(value, format: .currency(code: code).sign(strategy: signed ? .always() : .automatic))
                .fontWeight(emphasized ? .medium : .light)
                .monospacedDigit()
        }
        .font(.title3)
        .accessibilityElement(children: .combine)
    }
}

private struct QuietDivider: View {
    var body: some View {
        Rectangle()
            .fill(.separator)
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}

#Preview("08 Quiet") {
    QuietHomeView()
}
#endif
