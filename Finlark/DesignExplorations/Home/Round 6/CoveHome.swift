//
//  CoveHome.swift
//  Finlark
//
//  FIN-9 Round 6 "Cove": Mist with Jasper's rows. Income, Spending and Difference are labeled rows,
//  and the last row is Mist's focus bar. It expands in place to list every category, so there's
//  nothing to swipe.
//

#if DEBUG
import SwiftUI

struct CoveHomeView: View {
    @State private var model: ExplorationHomeModel
    @State private var debtors = R6Debtor.sample
    @State private var showsCategories = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }

    private var sorted: [ExplorationCategorySpending] {
        snapshot.spendingByCategory.sorted { $0.amount > $1.amount }
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
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 0) {
                R5BalanceHeader(snapshot: snapshot)
                    .padding(.bottom, 8)
                Divider()
                R6MonthRows(snapshot: snapshot)
                Divider()
                // A custom toggle instead of DisclosureGroup, whose label takes the tint and made the
                // sentence look like a link.
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) {
                        showsCategories.toggle()
                    }
                } label: {
                    HStack(alignment: .center, spacing: 12) {
                        R5FocusBar(snapshot: snapshot)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(showsCategories ? 180 : 0))
                            .accessibilityHidden(true)
                    }
                    .padding(.vertical, 10)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityValue(showsCategories ? Text("Expanded") : Text("Collapsed"))
                .accessibilityHint(Text("Shows every category"))

                if showsCategories {
                    let scale = sorted.first?.amount.plotValue ?? 0
                    VStack(spacing: 0) {
                        ForEach(sorted) { item in
                            Divider()
                            R6CategoryRow(item: item, snapshot: snapshot, scale: scale)
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

#Preview("R6 Cove") {
    CoveHomeView()
}
#endif
