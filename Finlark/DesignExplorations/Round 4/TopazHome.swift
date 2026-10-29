//
//  TopazHome.swift
//  Finlark
//
//  FIN-9 Round 4 "Topaz": what needs action comes first. Pending items lead the screen, then a balance
//  tile you can swipe from the month figures to the top categories, then the plan and owed. Recent
//  transactions close the screen as a plain list.
//

#if DEBUG
import SwiftUI

struct TopazHomeView: View {
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
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                R3PendingSection(model: model)
                Group {
                    summaryTile
                    R3PlanFiguresTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                }
                .padding(.horizontal)
                R4RecentList(snapshot: snapshot)
            }
        }
    }

    private var summaryTile: some View {
        R2Tile(padding: 0) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(snapshot.balance, format: .currency(code: code))
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                .padding([.horizontal, .top], 18)

                Divider()
                    .padding(.horizontal, 18)

                R2Slider(MonthPage.allCases, spacing: 0, margin: 18, indicatorOnGlass: false) { page in
                    monthPage(page)
                }
                .padding(.bottom, 10)
            }
        }
    }

    @ViewBuilder
    private func monthPage(_ page: MonthPage) -> some View {
        switch page {
        case .figures:
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) { monthFigures }
                VStack(alignment: .leading, spacing: 8) { monthFigures }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .categories:
            VStack(alignment: .leading, spacing: 6) {
                Text("Top categories")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                R3LabeledBars(spending: snapshot.r3TopSpending(limit: 2), code: code)
            }
        }
    }

    @ViewBuilder
    private var monthFigures: some View {
        R2Figure(title: "Income", value: snapshot.monthIncome, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        R2Figure(title: "Spending", value: snapshot.monthSpending, code: code, font: .subheadline.weight(.semibold))
        Spacer(minLength: 8)
        R2Figure(title: "Difference", value: snapshot.monthDifference, code: code, signed: true,
                 font: .subheadline.weight(.semibold))
    }
}

#Preview("R4 Topaz") {
    TopazHomeView()
}
#endif
