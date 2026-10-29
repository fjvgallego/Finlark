//
//  LumenHome.swift
//  Finlark
//
//  FIN-9 Round 2 "Lumen": Prism's layout with Liquid Glass kept on the controls layer only, as Apple's
//  guidance describes. Content tiles sit on solid grouped backgrounds, and glass is used for the
//  navigation bar, the floating add button and the page indicator. Compare it side by side
//  with Prism to choose between glass content and glass controls.
//

#if DEBUG
import SwiftUI

struct LumenHomeView: View {
    private let snapshot: ExplorationHomeSnapshot

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        self.snapshot = snapshot
    }

    var body: some View {
        PrismHomeView(snapshot: snapshot)
            .environment(\.r2Surface, .solid)
    }
}

#Preview("R2 Lumen") {
    LumenHomeView()
}
#endif
