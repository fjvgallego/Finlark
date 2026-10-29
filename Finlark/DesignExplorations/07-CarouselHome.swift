//
//  07-CarouselHome.swift
//  Finlark
//
//  FIN-9 exploration 07 "Carousel": the summary cards (balance, month, plan, owed) page horizontally
//  at the top, with a page indicator. Pending items and recent transactions follow as a plain list.
//

#if DEBUG
import SwiftUI

struct CarouselHomeView: View {
    private enum Page: Hashable, CaseIterable {
        case balance
        case month
        case plan
        case owed
    }

    @State private var model: ExplorationHomeModel
    @State private var currentPage: Page? = .balance
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var chartSize: CGFloat = 120

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }
    private var pages: [Page] { Page.allCases.filter { $0 != .owed || snapshot.owedToYou > 0 } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    carousel
                    if !model.pendingItems.isEmpty {
                        listBlock(title: "Pending") {
                            ForEach(model.pendingItems) { item in
                                ExplorationPendingRow(
                                    item: item,
                                    currencyCode: code,
                                    onConfirm: { model.confirm(item) },
                                    onSkip: { model.skip(item) }
                                )
                                if item.id != model.pendingItems.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                    listBlock(title: "Recent") {
                        ForEach(snapshot.recentTransactions) { transaction in
                            ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                            Divider()
                        }
                        NavigationLink("See all in History", value: ExplorationDestination.history)
                    }
                }
                .padding(.bottom, 24)
            }
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

    // MARK: Carousel

    private var carousel: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(pages, id: \.self) { page in
                        card(for: page)
                            .containerRelativeFrame(.horizontal)
                            .id(page)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $currentPage)
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 20, for: .scrollContent)

            HStack(spacing: 8) {
                ForEach(pages, id: \.self) { page in
                    Circle()
                        .fill(page == currentPage ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
                        .frame(width: 7, height: 7)
                }
            }
            .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private func card(for page: Page) -> some View {
        switch page {
        case .balance:
            CarouselCard(symbol: "wallet.bifold.fill", title: "Balance", tint: .blue) {
                Text(snapshot.balance, format: .currency(code: code))
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                Text("Today, \(Date.now, format: .dateTime.day().month(.wide))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .month:
            CarouselCard(symbol: "calendar", title: "This month", tint: .purple) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
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
                    }
                    ExplorationSpendingDonut(spending: snapshot.spendingByCategory, currencyCode: code)
                        .frame(width: chartSize, height: chartSize)
                }
            }
        case .plan:
            NavigationLink(value: ExplorationDestination.plan) {
                CarouselCard(symbol: "chart.bar.doc.horizontal.fill", title: "Monthly Plan", tint: .orange) {
                    if let plan = snapshot.plan {
                        ExplorationStatusLabel(status: plan.status)
                            .font(.title3.weight(.semibold))
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        Text("\(plan.totalSpent, format: .currency(code: code)) of \(plan.totalPlanned, format: .currency(code: code)) · projected \(plan.totalProjected, format: .currency(code: code))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Plan what you'll spend in each category and track your pace.")
                            .font(.headline)
                    }
                }
            }
            .buttonStyle(.plain)
        case .owed:
            NavigationLink(value: ExplorationDestination.people) {
                CarouselCard(symbol: "person.2.fill", title: "Owed to you", tint: .teal) {
                    Text(snapshot.owedToYou, format: .currency(code: code))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("\(snapshot.owedPeopleCount) people")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private func listBlock<Content: View>(title: LocalizedStringKey, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.bold))
                .accessibilityAddTraits(.isHeader)
            content()
        }
        .padding(.horizontal, 20)
    }
}

private struct CarouselCard<Content: View>: View {
    let symbol: String
    let title: LocalizedStringKey
    let tint: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label {
                Text(title)
            } icon: {
                Image(systemName: symbol)
                    .foregroundStyle(tint)
            }
            .font(.subheadline.weight(.semibold))
            content
        }
        .monospacedDigit()
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(tint.opacity(0.12))
                .overlay {
                    RoundedRectangle(cornerRadius: 26).strokeBorder(tint.opacity(0.25), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("07 Carousel") {
    CarouselHomeView()
}
#endif
