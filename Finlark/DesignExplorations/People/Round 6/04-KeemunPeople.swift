//
//  04-KeemunPeople.swift
//  Finlark
//
//  FIN-9 People, Round 6 "Keemun": Sencha with one family of buttons. Custom, black and white. Ink fills for Settle All, Half and the check, label-colored outlines for
//  Part and Other amount: full contrast, no accent color in the buttons.
//

#if DEBUG
import SwiftUI

struct KeemunPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var opensPart = false

    var body: some View {
        P6SenchaPerson(store: store, id: id, look: .mono, opensPart: opensPart)
    }
}

#Preview("Keemun") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { KeemunPerson(store: $0, id: $1) }
}

#Preview("Keemun · Part open") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { KeemunPerson(store: $0, id: $1, opensPart: true) }
}

#Preview("Keemun · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { KeemunPerson(store: $0, id: $1, opensPart: true) }
        .preferredColorScheme(.dark)
}
#endif
