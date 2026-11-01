//
//  01-EdamSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 2 "Edam": Gouda with the four most used categories as small icons under
//  Categories, so the row shows what's inside before it opens.
//

#if DEBUG
import SwiftUI

struct EdamSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        ST2Gouda(settings: settings, showsCategoryIcons: true)
    }
}

#Preview("Edam") {
    STHost { EdamSettings(settings: $0) }
}

#Preview("Edam · Fresh") {
    STHost(settings: .fresh) { EdamSettings(settings: $0) }
}

#Preview("Edam · Dark") {
    STHost { EdamSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
