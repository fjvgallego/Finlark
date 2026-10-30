//
//  05-KukichaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 6 "Kukicha": Sencha with one family of buttons. Custom, soft. Part and Other amount are neutral gray pills with label-colored text, the check is a
//  filled accent circle, and Settle All a strong accent tint.
//

#if DEBUG
import SwiftUI

struct KukichaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var opensPart = false

    var body: some View {
        P6SenchaPerson(store: store, id: id, look: .soft, opensPart: opensPart)
    }
}

#Preview("Kukicha") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { KukichaPerson(store: $0, id: $1) }
}

#Preview("Kukicha · Part open") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { KukichaPerson(store: $0, id: $1, opensPart: true) }
}

#Preview("Kukicha · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { KukichaPerson(store: $0, id: $1, opensPart: true) }
        .preferredColorScheme(.dark)
}
#endif
