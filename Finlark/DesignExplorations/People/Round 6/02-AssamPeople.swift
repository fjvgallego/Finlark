//
//  02-AssamPeople.swift
//  Finlark
//
//  FIN-9 People, Round 6 "Assam": Sencha with one family of buttons. System bordered buttons. Settle All and Half are `.borderedProminent`, the rest `.bordered` with
//  its gray fill: the classic iOS look, flat and familiar.
//

#if DEBUG
import SwiftUI

struct AssamPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var opensPart = false

    var body: some View {
        P6SenchaPerson(store: store, id: id, look: .bordered, opensPart: opensPart)
    }
}

#Preview("Assam") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { AssamPerson(store: $0, id: $1) }
}

#Preview("Assam · Part open") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { AssamPerson(store: $0, id: $1, opensPart: true) }
}

#Preview("Assam · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { AssamPerson(store: $0, id: $1, opensPart: true) }
        .preferredColorScheme(.dark)
}
#endif
