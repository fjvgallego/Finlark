//
//  TernHome.swift
//  Finlark
//
//  FIN-9 Round 5 "Tern": Topaz's order (pending first) with a bar you can scrub: touching a segment
//  colors it and names its category, amount and share. Untouched, it shows the largest category, so
//  it reads without any interaction.
//

#if DEBUG
import SwiftUI

struct TernHomeView: View {
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
                            R5ScrubBar(snapshot: snapshot)
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

#Preview("R5 Tern") {
    TernHomeView()
}
#endif
