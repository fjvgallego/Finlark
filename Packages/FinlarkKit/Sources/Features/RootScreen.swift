import SwiftUI

/// The app's first screen. A placeholder until the tab bar and the router exist (ADR-0008).
public struct RootScreen: View {
    public init() {}

    public var body: some View {
        Text(verbatim: "Finlark")
            .font(.largeTitle)
    }
}

#Preview {
    RootScreen()
}
