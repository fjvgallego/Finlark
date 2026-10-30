//
//  01-SumacPeople.swift
//  Finlark
//
//  FIN-9 People, Round 3 "Sumac": the check where it is on the list. Each open share ends with
//  Saffron's round check after its amount, the same place and look as on the people list, so "tap the
//  check to complete the repayment" means the same thing on both screens (SPL-006). Touch and hold a
//  share to record part of it (SPL-007).
//

#if DEBUG
import SwiftUI

struct SumacPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .glass

    var body: some View {
        P3PersonScreen(store: store, id: id, surface: surface) { share, actions in
            P3CheckLine {
                PPShareRow(share: share, code: store.code)
            } check: {
                P3CheckButton(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
            }
        }
    }
}

#Preview("Sumac") {
    PPHost { P3People(store: $0) } person: { SumacPerson(store: $0, id: $1) }
}

#Preview("Sumac · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { SumacPerson(store: $0, id: $1) }
}

#Preview("Sumac · No glass") {
    PPHost(opening: "marta") {
        P3People(store: $0, surface: .solid)
    } person: {
        SumacPerson(store: $0, id: $1, surface: .solid)
    }
}

#Preview("Sumac · Settled up") {
    PPHost(store: .settledUp) { P3People(store: $0) } person: { SumacPerson(store: $0, id: $1) }
}
#endif
