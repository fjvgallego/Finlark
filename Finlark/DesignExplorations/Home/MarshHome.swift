//
//  MarshHome.swift
//  Finlark
//
//  FIN-9 Home "Marsh": a segmented control (Month | Categories) switches the view, which names both
//  views up front. The month view has a scrubbable category bar, and icons and avatars use the soft
//  style (tinted rounded squares) instead of the system look.
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
    @State private var debtors: [HMDebtor]
    @State private var selection: Panel = .month

    /// `addingType` opens the add screen right away, and `addEditor` replaces the stand-in add screen.
    /// `debtors` is empty for a Home with nobody owing money, such as right after onboarding.
    init(
        snapshot: ExplorationHomeSnapshot = .sample,
        debtors: [HMDebtor] = HMDebtor.sample,
        addingType: ExplorationTransactionType? = nil,
        addEditor: ((ExplorationTransactionType) -> AnyView)? = nil
    ) {
        let model = ExplorationHomeModel(snapshot: snapshot, addEditor: addEditor)
        model.addingType = addingType
        _model = State(initialValue: model)
        _debtors = State(initialValue: debtors)
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }

    private var topCategories: [ExplorationCategorySpending] {
        Array(snapshot.spendingByCategory.sorted { $0.amount > $1.amount }.prefix(4))
    }

    var body: some View {
        HMTabShell(model: model, quickAdd: .toolbarMenu) {
            HMHomeScroll(model: model) {
                HMOwedBar(debtors: $debtors, code: snapshot.currencyCode)
                    .padding(.horizontal)
                HMPendingSection(model: model)
                Group {
                    balanceTile
                    HMPlanTile(snapshot: snapshot)
                }
                .padding(.horizontal)
                HMRecentList(snapshot: snapshot)
            }
        }
        .environment(\.explorationIconStyle, .soft)
    }

    private var balanceTile: some View {
        HMTile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                HMBalanceHeader(snapshot: snapshot)
                HMSegmentedControl(
                    title: "Show",
                    options: Panel.allCases.map { (value: $0, label: $0.title) },
                    selection: $selection
                )

                switch selection {
                case .month:
                    VStack(spacing: 0) {
                        HMMonthRows(snapshot: snapshot)
                        Divider()
                        HMScrubBar(snapshot: snapshot)
                            .padding(.vertical, 10)
                    }
                case .categories:
                    VStack(spacing: 0) {
                        let scale = topCategories.first?.amount.plotValue ?? 0
                        ForEach(topCategories) { item in
                            HMCategoryRow(item: item, snapshot: snapshot, scale: scale)
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

#Preview("Marsh") {
    MarshHomeView()
}
#endif
