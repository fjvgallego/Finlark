//
//  FlintHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Flint": quick add sits on Home itself, as two large buttons right under the
//  balance, so adding is the first thing you see. History keeps a "+" in its navigation bar.
//  The month tile slides from the figures to a labeled category chart, keeping Facet's compact look.
//

#if DEBUG
import SwiftUI

struct FlintHomeView: View {
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
    private var code: String { snapshot.currencyCode }

    var body: some View {
        R3TabShell(model: model, quickAdd: .homeButtons) {
            R3HomeScroll(model: model) {
                Group {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Balance")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                    .textCase(.uppercase)
                                Text(snapshot.balance, format: .currency(code: code))
                                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            R3HomeAddButtons(model: model)
                        }
                    }
                }
                .padding(.horizontal)

                R2Slider(MonthPage.allCases) { page in
                    monthPage(page)
                }

                Group {
                    R3PlanFiguresTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                }
                .padding(.horizontal)
                R3PendingSection(model: model)
                R3RecentSection(snapshot: snapshot)
            }
        }
    }

    @ViewBuilder
    private func monthPage(_ page: MonthPage) -> some View {
        switch page {
        case .figures:
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    R2TileHeader(title: "This month", symbol: "calendar")
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top) { monthFigures }
                        VStack(alignment: .leading, spacing: 10) { monthFigures }
                    }
                    Label("Swipe for spending by category", systemImage: "chevron.right.2")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
        case .categories:
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    R2TileHeader(title: "Spending by category", symbol: "chart.bar.fill")
                    R3LabeledBars(spending: snapshot.r3TopSpending(limit: 3), code: code)
                }
            }
        }
    }

    @ViewBuilder
    private var monthFigures: some View {
        R2Figure(title: "Income", value: snapshot.monthIncome, code: code)
        Spacer(minLength: 8)
        R2Figure(title: "Spending", value: snapshot.monthSpending, code: code)
        Spacer(minLength: 8)
        R2Figure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true)
    }
}

#Preview("R3 Flint") {
    FlintHomeView()
}
#endif
