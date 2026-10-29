//
//  PebbleHome.swift
//  Finlark
//
//  FIN-9 Round 5 "Pebble": Topaz's order (pending first) with the top three categories as thin
//  single-color bars, named above and valued at the end, directly under the month figures. Nothing
//  depends on color.
//

#if DEBUG
import SwiftUI

struct PebbleHomeView: View {
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
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            R5BalanceHeader(snapshot: snapshot)
                            Divider()
                            R5MonthFigures(snapshot: snapshot)
                            R5RankBars(snapshot: snapshot)
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
}

#Preview("R5 Pebble") {
    PebbleHomeView()
}
#endif
