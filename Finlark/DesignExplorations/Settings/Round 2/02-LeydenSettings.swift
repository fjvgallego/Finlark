//
//  02-LeydenSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 2 "Leyden": Gouda with the next recurring item under Recurring
//  ("Veggie box · In 3 days"), so what's coming next is one glance away.
//

#if DEBUG
import SwiftUI

struct LeydenSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        ST2Gouda(settings: settings, showsNextRecurring: true)
    }
}

#Preview("Leyden") {
    STHost { LeydenSettings(settings: $0) }
}

#Preview("Leyden · Fresh") {
    STHost(settings: .fresh) { LeydenSettings(settings: $0) }
}

#Preview("Leyden · No Passcode") {
    STHost(settings: .noPasscode) { LeydenSettings(settings: $0) }
}

#Preview("Leyden · Dark") {
    STHost { LeydenSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
