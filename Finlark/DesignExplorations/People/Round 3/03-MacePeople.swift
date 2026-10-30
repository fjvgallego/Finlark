//
//  03-MacePeople.swift
//  Finlark
//
//  FIN-9 People, Round 3 "Mace": Sumac, with part payments in sight. The round check still completes a
//  share in one tap (SPL-006), and a small "Record part…" link sits under each share, so part payments
//  don't depend on finding the touch-and-hold menu (SPL-007).
//

#if DEBUG
import SwiftUI

struct MacePerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    var surface: R2Surface = .glass

    var body: some View {
        P3PersonScreen(
            store: store,
            id: id,
            surface: surface,
            hint: "Check a share when it's paid back."
        ) { share, actions in
            VStack(alignment: .leading, spacing: 6) {
                P3CheckLine {
                    PPShareRow(share: share, code: store.code)
                } check: {
                    P3CheckButton(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
                }
                Button("Record part…", action: actions.recordPart)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
                    .buttonStyle(.plain)
                    .padding(.leading, 48)
                    .frame(minHeight: 32)
                    .accessibilityLabel(Text("Record part of \(share.ticket)"))
            }
        }
    }
}

#Preview("Mace") {
    PPHost { P3People(store: $0) } person: { MacePerson(store: $0, id: $1) }
}

#Preview("Mace · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { MacePerson(store: $0, id: $1) }
}

#Preview("Mace · No glass") {
    PPHost(opening: "marta") {
        P3People(store: $0, surface: .solid)
    } person: {
        MacePerson(store: $0, id: $1, surface: .solid)
    }
}
#endif
