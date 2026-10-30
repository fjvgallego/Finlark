//
//  TideHome.swift
//  Finlark
//
//  FIN-9 Round 6 "Tide": Marsh with buttons that keep Liquid Glass but drop the stock iOS look.
//  Glass is tinted with a brand color (indigo, from the backdrop) instead of system blue, buttons are
//  continuous rounded rectangles with rounded type, and Month | Categories is a custom switch with a
//  sliding pill. The toolbar "+", links and the tab bar selection take the same tint. Compare it side
//  by side with Marsh.
//

#if DEBUG
import SwiftUI

struct TideHomeView: View {
    private static let brand = Color.indigo

    private let snapshot: ExplorationHomeSnapshot

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        self.snapshot = snapshot
    }

    var body: some View {
        MarshHomeView(snapshot: snapshot)
            .environment(\.explorationButtonLook, .brandGlass(Self.brand))
            .tint(Self.brand)
    }
}

#Preview("R6 Tide") {
    TideHomeView()
}
#endif
