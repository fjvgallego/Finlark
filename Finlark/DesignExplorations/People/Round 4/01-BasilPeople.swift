//
//  01-BasilPeople.swift
//  Finlark
//
//  FIN-9 People, Round 4 "Basil": the simplest fix. Settle All becomes a filled accent button with white
//  text. Each share drops "Pending" and "left": the ticket and what's left share one line, the date sits
//  under it, and only a partly paid share adds "20,00 € of 30,00 € paid" with a thin bar (PPL-003).
//  VoiceOver still reads the status.
//

#if DEBUG
import SwiftUI

struct BasilPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P4PersonScreen(store: store, id: id, settleStyle: .filled) { share in
            VStack(alignment: .leading, spacing: 4) {
                P4TitleLine(share: share, code: store.code)
                Text(share.date, format: .dateTime.weekday().day().month())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if share.paid > 0 {
                    P4PaidLine(share: share, code: store.code)
                    PPProgressBar(share: share, color: .accentColor)
                        .padding(.top, 2)
                }
            }
        }
    }
}

#Preview("Basil") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { BasilPerson(store: $0, id: $1) }
}

#Preview("Basil · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { BasilPerson(store: $0, id: $1) }
}

#Preview("Basil · Dark") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { BasilPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
