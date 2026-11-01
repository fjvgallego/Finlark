//
//  03-MaasdamSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 2 "Maasdam": Gouda with both of Comté's touches: the category icons under
//  Categories and the next recurring item under Recurring.
//

#if DEBUG
import SwiftUI

struct MaasdamSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        ST2Gouda(settings: settings, showsCategoryIcons: true, showsNextRecurring: true)
    }
}

#Preview("Maasdam") {
    STHost { MaasdamSettings(settings: $0) }
}

#Preview("Maasdam · Fresh") {
    STHost(settings: .fresh) { MaasdamSettings(settings: $0) }
}

#Preview("Maasdam · Dark") {
    STHost { MaasdamSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
