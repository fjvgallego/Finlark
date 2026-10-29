//
//  MarshHome.swift
//  Finlark
//
//  FIN-9 Round 6 "Marsh": like Fjord, but a segmented control (Month | Categories) switches the view
//  instead of a swipe. More discoverable than a gesture, and it names both views up front.
//  The month view uses Tern's scrubbable category bar, and icons and avatars use the soft style
//  (tinted rounded squares) instead of the system look.
//

#if DEBUG
import SwiftUI

struct MarshHomeView: View {
    private enum Panel: Hashable, CaseIterable {
        case month
        case categories

        var title: LocalizedStringKey {
            switch self {
            case .month: "Month"
            case .categories: "Categories"
            }
        }
    }

    @State private var model: ExplorationHomeModel
    @State private var debtors = R6Debtor.sample
    @State private var selection: Panel = .month

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
        .environment(\.explorationIconStyle, .soft)
    }

    private var balanceTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                R5BalanceHeader(snapshot: snapshot)
                R6SegmentedControl(
                    title: "Show",
                    options: Panel.allCases.map { (value: $0, label: $0.title) },
                    selection: $selection
                )

                switch selection {
                case .month:
                    VStack(spacing: 0) {
                        R6MonthRows(snapshot: snapshot)
                        Divider()
                        R5ScrubBar(snapshot: snapshot)
                            .padding(.vertical, 10)
                    }
                case .categories:
                    VStack(spacing: 0) {
                        let scale = topCategories.first?.amount.plotValue ?? 0
                        ForEach(topCategories) { item in
                            R6CategoryRow(item: item, snapshot: snapshot, scale: scale)
                            if item.id != topCategories.last?.id {
                                Divider()
                            }
                        }
                    }
                    .font(.subheadline)
                }
            }
        }
    }
}

#Preview("R6 Marsh") {
    MarshHomeView()
}
#endif
