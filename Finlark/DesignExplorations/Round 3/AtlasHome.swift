//
//  AtlasHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Atlas": five tabs (Home, Transactions, Plan, People, Settings), so every main area
//  is one tap away. Home's plan and owed tiles switch to their tabs instead of pushing a screen.
//  Quick add is in the navigation bar of Home and Transactions.
//

#if DEBUG
import SwiftUI

struct AtlasHomeView: View {
    private enum AppTab: Hashable {
        case home
        case transactions
        case plan
        case people
        case settings
    }

    @State private var model: ExplorationHomeModel
    @State private var selection: AppTab = .home
    @State private var router = R3TabRouter(tabDestinations: [.history, .plan, .people])

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
            Tab("Plan", systemImage: "chart.bar.doc.horizontal", value: .plan) {
                NavigationStack {
                    ExplorationPlaceholderScreen(destination: .plan)
                }
            }
            Tab("People", systemImage: "person.2", value: .people) {
                NavigationStack {
                    ExplorationPlaceholderScreen(destination: .people)
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
            guard let destination else { return }
            switch destination {
            case .history: selection = .transactions
            case .plan: selection = .plan
            case .people: selection = .people
            }
            router.requested = nil
        }
        .r3AddSheet(model)
    }
}

#Preview("R3 Atlas") {
    AtlasHomeView()
}
#endif
