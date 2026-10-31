//
//  06-FinancierPeople.swift
//  Finlark
//
//  FIN-9 People, Round 9 "Financier": Settle All pinned in a glass bar that also says what's open
//  and across how many shares, so the total stays visible while scrolling. Add Repayment in plain
//  glass, Mark as Paid in blue glass.
//

#if DEBUG
import SwiftUI

struct FinancierPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P9PersonScreen(store: store, id: id, settlePlacement: .pinned, settleLook: .summaryBar, buttonPair: .secondaryAndPrimary)
    }
}

#Preview("Financier") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { FinancierPerson(store: $0, id: $1) }
}

#Preview("Financier · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { FinancierPerson(store: $0, id: $1) }
}

#Preview("Financier · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { FinancierPerson(store: $0, id: $1) }
}

#Preview("Financier · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { FinancierPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
