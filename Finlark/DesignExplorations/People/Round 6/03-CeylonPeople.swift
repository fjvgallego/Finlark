//
//  03-CeylonPeople.swift
//  Finlark
//
//  FIN-9 People, Round 6 "Ceylon": Sencha with one family of buttons. System, as light as it gets. Only Settle All is a filled button; Part and Other amount are plain
//  tinted text, and the check is a round symbol, like Reminders.
//

#if DEBUG
import SwiftUI

struct CeylonPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var opensPart = false

    var body: some View {
        P6SenchaPerson(store: store, id: id, look: .minimal, opensPart: opensPart)
    }
}

#Preview("Ceylon") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { CeylonPerson(store: $0, id: $1) }
}

#Preview("Ceylon · Part open") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { CeylonPerson(store: $0, id: $1, opensPart: true) }
}

#Preview("Ceylon · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { CeylonPerson(store: $0, id: $1, opensPart: true) }
        .preferredColorScheme(.dark)
}
#endif
