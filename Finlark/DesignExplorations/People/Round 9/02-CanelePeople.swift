//
//  02-CanelePeople.swift
//  Finlark
//
//  FIN-9 People, Round 9 "Canelé": Brioche with Settle All pinned above the tab bar, so it stays in
//  reach however many shares there are.
//

#if DEBUG
import SwiftUI

struct CanelePerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P9PersonScreen(store: store, id: id, settlePlacement: .pinned, settleLook: .fullWidth, buttonPair: .secondaryAndPrimary)
    }
}

#Preview("Canelé") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { CanelePerson(store: $0, id: $1) }
}

#Preview("Canelé · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { CanelePerson(store: $0, id: $1) }
}

#Preview("Canelé · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { CanelePerson(store: $0, id: $1) }
}

#Preview("Canelé · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { CanelePerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
