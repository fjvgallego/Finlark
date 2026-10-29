//
//  FjordHome.swift
//  Finlark
//
//  FIN-9 Round 6 "Fjord": Flint's swipe and Jasper's rows together. The balance stays put, and below
//  it you swipe between two lists of labeled rows: the month (with Mist's focus bar) and the top
//  categories, each with an inline bar, amount and share.
//

#if DEBUG
import SwiftUI

struct FjordHomeView: View {
    private enum Page: Identifiable, CaseIterable {
        case month
        case categories

        var id: Self { self }
    }

    @State private var model: ExplorationHomeModel
    @State private var debtors = R6Debtor.sample

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }

    private var topCategories: [ExplorationCategorySpending] {
        Array(snapshot.spendingByCategory.sorted { $0.amount > $1.amount }.prefix(4))
    }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                R6OwedBar(debtors: $debtors, code: snapshot.currencyCode)
                    .padding(.horizontal)
                R3PendingSection(model: model)
                Group {
                    balanceTile
                    R6PlanTile(snapshot: snapshot)
                }
                .padding(.horizontal)
                R4RecentList(snapshot: snapshot)
            }
        }
    }

    private var balanceTile: some View {
        R2Tile(padding: 0) {
            VStack(alignment: .leading, spacing: 6) {
                R5BalanceHeader(snapshot: snapshot)
                    .padding([.horizontal, .top], 18)
                R5Pager(Page.allCases) { page in
                    Group {
                        switch page {
                        case .month:
                            VStack(spacing: 0) {
                                Divider()
                                R6MonthRows(snapshot: snapshot)
                                Divider()
                                R5FocusBar(snapshot: snapshot)
                                    .padding(.vertical, 10)
                            }
                        case .categories:
                            VStack(spacing: 0) {
                                let scale = topCategories.first?.amount.plotValue ?? 0
                                ForEach(topCategories) { item in
                                    Divider()
                                    R6CategoryRow(item: item, snapshot: snapshot, scale: scale, verticalPadding: 12)
                                }
                            }
                            .font(.subheadline)
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 12)
            }
        }
    }
}

#Preview("R6 Fjord") {
    FjordHomeView()
}
#endif
