//
//  01-BriochePeople.swift
//  Finlark
//
//  FIN-9 People, Round 9 "Brioche": Settle All under the header as a full-width bar with the total.
//  Under each share, Add Repayment in plain glass and Mark as Paid in blue glass, so the full
//  repayment leads.
//

#if DEBUG
import SwiftUI

struct BriochePerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P9PersonScreen(store: store, id: id, settlePlacement: .underHeader, settleLook: .fullWidth, buttonPair: .secondaryAndPrimary)
    }
}

#Preview("Brioche") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { BriochePerson(store: $0, id: $1) }
}

#Preview("Brioche · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { BriochePerson(store: $0, id: $1) }
}

#Preview("Brioche · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { BriochePerson(store: $0, id: $1) }
}

#Preview("Brioche · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { BriochePerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
