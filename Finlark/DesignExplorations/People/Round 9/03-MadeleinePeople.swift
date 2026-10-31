//
//  03-MadeleinePeople.swift
//  Finlark
//
//  FIN-9 People, Round 9 "Madeleine": Settle All under the header, both share buttons in blue glass
//  as equals, and a bar under a partly paid share showing what came back.
//

#if DEBUG
import SwiftUI

struct MadeleinePerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P9PersonScreen(store: store, id: id, settlePlacement: .underHeader, settleLook: .fullWidth, buttonPair: .bothPrimary, showsProgress: true)
    }
}

#Preview("Madeleine") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { MadeleinePerson(store: $0, id: $1) }
}

#Preview("Madeleine · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { MadeleinePerson(store: $0, id: $1) }
}

#Preview("Madeleine · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { MadeleinePerson(store: $0, id: $1) }
}

#Preview("Madeleine · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { MadeleinePerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
