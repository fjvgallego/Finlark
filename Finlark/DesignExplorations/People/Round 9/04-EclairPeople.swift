//
//  04-EclairPeople.swift
//  Finlark
//
//  FIN-9 People, Round 9 "Éclair": Madeleine with Settle All pinned above the tab bar.
//

#if DEBUG
import SwiftUI

struct EclairPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P9PersonScreen(store: store, id: id, settlePlacement: .pinned, settleLook: .fullWidth, buttonPair: .bothPrimary, showsProgress: true)
    }
}

#Preview("Éclair") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { EclairPerson(store: $0, id: $1) }
}

#Preview("Éclair · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { EclairPerson(store: $0, id: $1) }
}

#Preview("Éclair · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { EclairPerson(store: $0, id: $1) }
}

#Preview("Éclair · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { EclairPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
