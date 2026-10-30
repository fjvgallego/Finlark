//
//  02-AnisePeople.swift
//  Finlark
//
//  FIN-9 People, Round 3 "Anise": the check where Ginger had its tick. Saffron's round check leads each
//  open share, in place of the category icon, so the shares read like a to-do list you tick off
//  (SPL-006). Touch and hold a share to record part of it (SPL-007).
//

#if DEBUG
import SwiftUI

struct AnisePerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .glass

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        P3PersonScreen(store: store, id: id, surface: surface) { share, actions in
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    PPShareRow(share: share, code: store.code)
                    P3CheckButton(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
                }
            } else {
                HStack(alignment: .top, spacing: 12) {
                    P3CheckButton(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
                    PPShareRow(share: share, code: store.code, showsIcon: false)
                }
            }
        }
    }
}

#Preview("Anise") {
    PPHost { P3People(store: $0) } person: { AnisePerson(store: $0, id: $1) }
}

#Preview("Anise · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { AnisePerson(store: $0, id: $1) }
}

#Preview("Anise · No glass") {
    PPHost(opening: "marta") {
        P3People(store: $0, surface: .solid)
    } person: {
        AnisePerson(store: $0, id: $1, surface: .solid)
    }
}
#endif
