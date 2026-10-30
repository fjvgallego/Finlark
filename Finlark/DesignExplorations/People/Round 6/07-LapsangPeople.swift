//
//  07-LapsangPeople.swift
//  Finlark
//
//  FIN-9 People, Round 6 "Lapsang": Sencha with one family of buttons. Custom, tactile. Raised buttons with a top highlight and a shadow that presses in when tapped:
//  accent for Settle All, Half and the check, light for Part and Other amount.
//

#if DEBUG
import SwiftUI

struct LapsangPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var opensPart = false

    var body: some View {
        P6SenchaPerson(store: store, id: id, look: .tactile, opensPart: opensPart)
    }
}

#Preview("Lapsang") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { LapsangPerson(store: $0, id: $1) }
}

#Preview("Lapsang · Part open") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { LapsangPerson(store: $0, id: $1, opensPart: true) }
}

#Preview("Lapsang · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { LapsangPerson(store: $0, id: $1, opensPart: true) }
        .preferredColorScheme(.dark)
}
#endif
