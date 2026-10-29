//
//  PivotHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Pivot": an "Add" tab in the middle of the tab bar (Home, Transactions, Add, Settings).
//  Selecting it opens the add sheet and leaves you on the tab you were on. It's familiar from many
//  finance and social apps, but Apple's guidance says tabs should navigate, not perform actions.
//

#if DEBUG
import SwiftUI

struct PivotHomeView: View {
    private enum AppTab: Hashable {
        case home
        case transactions
        case add
        case settings
    }

    @State private var model: ExplorationHomeModel
    @State private var selection: AppTab = .home
    @State private var router = R3TabRouter(tabDestinations: [.history])

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    /// Selecting the Add tab opens the sheet instead of switching tabs.
    private var tabSelection: Binding<AppTab> {
        Binding {
            selection
        } set: { newValue in
            if newValue == .add {
                model.addingType = .expense
            } else {
                selection = newValue
            }
        }
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    R3FacetHome(model: model)
                        .navigationTitle("Home")
                        .navigationBarTitleDisplayMode(.inline)
                        .r3Destinations()
                }
            }
            Tab("Transactions", systemImage: "list.bullet.rectangle", value: .transactions) {
                NavigationStack {
                    R3TransactionsScreen(model: model)
                        .r3Destinations()
                }
            }
            Tab("Add", systemImage: "plus.circle.fill", value: .add) {
                Color.clear
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    R3SettingsScreen()
                }
            }
        }
        .environment(router)
        .onChange(of: router.requested) { _, destination in
            guard destination != nil else { return }
            selection = .transactions
            router.requested = nil
        }
        .r3AddSheet(model)
    }
}

#Preview("R3 Pivot") {
    PivotHomeView()
}
#endif
