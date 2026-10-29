//
//  BeaconHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Beacon": three tabs plus the iOS 26 search tab, which sits apart at the trailing
//  end of the tab bar and searches transaction notes (TRX-005). Quick add is in the navigation bar
//  of Home and Transactions.
//

#if DEBUG
import SwiftUI

struct BeaconHomeView: View {
    private enum AppTab: Hashable {
        case home
        case transactions
        case settings
        case search
    }

    @State private var model: ExplorationHomeModel
    @State private var selection: AppTab = .home
    @State private var router = R3TabRouter(tabDestinations: [.history])

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house", value: .home) {
                NavigationStack {
                    R3FacetHome(model: model)
                        .navigationTitle("Home")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) { R3AddMenuButton(model: model) }
                        }
                        .r3Destinations()
                }
            }
            Tab("Transactions", systemImage: "list.bullet.rectangle", value: .transactions) {
                NavigationStack {
                    R3TransactionsScreen(model: model, isSearchable: false)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) { R3AddMenuButton(model: model) }
                        }
                        .r3Destinations()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    R3SettingsScreen()
                }
            }
            Tab(value: .search, role: .search) {
                NavigationStack {
                    R3TransactionsScreen(model: model)
                        .navigationTitle("Search")
                        .r3Destinations()
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

#Preview("R3 Beacon") {
    BeaconHomeView()
}
#endif
