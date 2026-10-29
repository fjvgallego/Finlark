//
//  DockHome.swift
//  Finlark
//
//  FIN-9 Round 3 "Dock": three tabs, with quick add in the tab view's bottom accessory, the glass bar
//  that sits just above the tab bar. It shows "Add expense" plus an Income shortcut, and stays on Home
//  and Transactions only. The tab bar minimizes when scrolling down, and the accessory moves inline
//  next to it with a compact add button.
//

#if DEBUG
import SwiftUI

struct DockHomeView: View {
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
                        .r3Destinations()
                }
            }
            Tab("Transactions", systemImage: "list.bullet.rectangle", value: .transactions) {
                NavigationStack {
                    R3TransactionsScreen(model: model)
                        .r3Destinations()
                }
            }
            Tab("Settings", systemImage: "gearshape", value: .settings) {
                NavigationStack {
                    R3SettingsScreen()
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory(isEnabled: selection != .settings) {
            DockQuickAdd(model: model)
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

private struct DockQuickAdd: View {
    let model: ExplorationHomeModel
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        if placement == .inline {
            Button {
                model.addingType = .expense
            } label: {
                Label("Add expense", systemImage: "plus")
            }
        } else {
            HStack(spacing: 0) {
                Button {
                    model.addingType = .expense
                } label: {
                    Label("Add expense", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                Divider()
                    .padding(.vertical, 8)
                Button {
                    model.addingType = .income
                } label: {
                    Label("Income", systemImage: "arrow.down.circle")
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: 140)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview("R3 Dock") {
    DockHomeView()
}
#endif
