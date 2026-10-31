//
//  05-PalmierPeople.swift
//  Finlark
//
//  FIN-9 People, Round 9 "Palmier": Settle All under the header as a centered pill, since the
//  header already says the total. Add Repayment in plain glass, Mark as Paid in blue glass, and the
//  progress bar on partly paid shares.
//

#if DEBUG
import SwiftUI

struct PalmierPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P9PersonScreen(store: store, id: id, settlePlacement: .underHeader, settleLook: .pill, buttonPair: .secondaryAndPrimary, showsProgress: true)
    }
}

#Preview("Palmier") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { PalmierPerson(store: $0, id: $1) }
}

#Preview("Palmier · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { PalmierPerson(store: $0, id: $1) }
}

#Preview("Palmier · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { PalmierPerson(store: $0, id: $1) }
}

#Preview("Palmier · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { PalmierPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
