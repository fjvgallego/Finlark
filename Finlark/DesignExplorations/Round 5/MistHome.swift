//
//  MistHome.swift
//  Finlark
//
//  FIN-9 Round 5 "Mist": Topaz's order (pending first) with a focus bar for categories: one thin bar
//  of the month where only the largest category is colored, and a sentence naming it ("Housing is 61%
//  of your spending"). The most minimal chart, with one clear message.
//

#if DEBUG
import SwiftUI

struct MistHomeView: View {
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
                            R5FocusBar(snapshot: snapshot)
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

#Preview("R5 Mist") {
    MistHomeView()
}
#endif
