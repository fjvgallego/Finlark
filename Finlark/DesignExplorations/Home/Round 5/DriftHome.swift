//
//  DriftHome.swift
//  Finlark
//
//  FIN-9 Round 5 "Drift": Topaz with its swipeable month tile fixed. The balance stays put and the area
//  below swipes from the month figures (with the largest category) to the top three categories.
//  Pages are exactly as wide as the tile, snap one at a time and are clipped to it, and both pages
//  carry similar content so neither leaves an empty band.
//

#if DEBUG
import SwiftUI

struct DriftHomeView: View {
    private enum MonthPage: Identifiable, CaseIterable {
        case figures
        case categories

        var id: Self { self }
    }

    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                R3PendingSection(model: model)
                Group {
                    R2Tile(padding: 0) {
                        VStack(alignment: .leading, spacing: 14) {
                            R5BalanceHeader(snapshot: snapshot)
                                .padding([.horizontal, .top], 18)
                            Divider()
                                .padding(.horizontal, 18)
                            R5Pager(MonthPage.allCases) { page in
                                monthPage(page)
                                    .padding(.horizontal, 18)
                            }
                            .padding(.bottom, 12)
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

    @ViewBuilder
    private func monthPage(_ page: MonthPage) -> some View {
        switch page {
        case .figures:
            VStack(alignment: .leading, spacing: 14) {
                R5MonthFigures(snapshot: snapshot)
                R5FocusBar(snapshot: snapshot)
            }
        case .categories:
            R5RankBars(snapshot: snapshot)
        }
    }
}

#Preview("R5 Drift") {
    DriftHomeView()
}
#endif
