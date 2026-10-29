//
//  AnchorHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Anchor": Facet in a three-tab bar (Home, Transactions, Settings). Quick add is a
//  prominent glass button in the navigation bar of Home and Transactions, the two screens TRX-001
//  names. The most standard option.
//

#if DEBUG
import SwiftUI

struct AnchorHomeView: View {
    private enum AppTab: Hashable {
        case home
        case transactions
        case settings
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
                    R3TransactionsScreen(model: model)
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

#Preview("R3 Anchor") {
    AnchorHomeView()
}
#endif
