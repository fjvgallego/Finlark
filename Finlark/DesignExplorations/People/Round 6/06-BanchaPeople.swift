//
//  06-BanchaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 6 "Bancha": Sencha with one family of buttons. Custom tinted glass. Settle All, Half and the check are glass tinted with the accent; Part and
//  Other amount are clear glass with label-colored text.
//

#if DEBUG
import SwiftUI

struct BanchaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var opensPart = false

    var body: some View {
        P6SenchaPerson(store: store, id: id, look: .brandGlass, opensPart: opensPart)
    }
}

#Preview("Bancha") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { BanchaPerson(store: $0, id: $1) }
}

#Preview("Bancha · Part open") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { BanchaPerson(store: $0, id: $1, opensPart: true) }
}

#Preview("Bancha · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { BanchaPerson(store: $0, id: $1, opensPart: true) }
        .preferredColorScheme(.dark)
}
#endif
