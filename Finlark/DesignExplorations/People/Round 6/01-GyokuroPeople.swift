//
//  01-GyokuroPeople.swift
//  Finlark
//
//  FIN-9 People, Round 6 "Gyokuro": Sencha with one family of buttons. System Liquid Glass. Settle All and Half are `.glassProminent`, Part, the check and Other amount are
//  `.glass`: the look iOS 26 gives every app, nothing custom.
//

#if DEBUG
import SwiftUI

struct GyokuroPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var opensPart = false

    var body: some View {
        P6SenchaPerson(store: store, id: id, look: .glass, opensPart: opensPart)
    }
}

#Preview("Gyokuro") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { GyokuroPerson(store: $0, id: $1) }
}

#Preview("Gyokuro · Part open") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { GyokuroPerson(store: $0, id: $1, opensPart: true) }
}

#Preview("Gyokuro · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { GyokuroPerson(store: $0, id: $1, opensPart: true) }
        .preferredColorScheme(.dark)
}
#endif
