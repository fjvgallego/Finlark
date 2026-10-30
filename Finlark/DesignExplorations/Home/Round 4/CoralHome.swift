//
//  CoralHome.swift
//  Finlark
//
//  FIN-9 Round 4 "Coral": Ember with the categories section folded into the balance tile as a thin
//  split bar and a one-line legend. Everything else stays as in Ember. The baseline for this round.
//

#if DEBUG
import SwiftUI

struct CoralHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                Group {
                    R3SummaryTile(snapshot: snapshot) {
                        R4SpendingStrip(snapshot: snapshot)
                    }
                    R3PlanFiguresTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                }
                .padding(.horizontal)
                R3PendingSection(model: model)
                R3RecentSection(snapshot: snapshot)
            }
        }
    }
}

#Preview("R4 Coral") {
    CoralHomeView()
}
#endif
