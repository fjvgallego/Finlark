//
//  BrookHome.swift
//  Finlark
//
//  FIN-9 Round 6 "Brook": Mist with Flint's swipe. The balance stays put, and below it you swipe from
//  the month figures (with Mist's focus bar) to the top categories.
//

#if DEBUG
import SwiftUI

struct BrookHomeView: View {
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
            VStack(alignment: .leading, spacing: 14) {
                R5BalanceHeader(snapshot: snapshot)
                    .padding([.horizontal, .top], 18)
                Divider()
                    .padding(.horizontal, 18)
                R5Pager(Page.allCases) { page in
                    Group {
                        switch page {
                        case .month:
                            VStack(alignment: .leading, spacing: 14) {
                                R5MonthFigures(snapshot: snapshot)
                                R5FocusBar(snapshot: snapshot)
                            }
                        case .categories:
                            R5RankBars(snapshot: snapshot)
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .padding(.bottom, 12)
            }
        }
    }
}

#Preview("R6 Brook") {
    BrookHomeView()
}
#endif
