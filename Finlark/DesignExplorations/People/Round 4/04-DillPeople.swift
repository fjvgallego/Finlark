//
//  04-DillPeople.swift
//  Finlark
//
//  FIN-9 People, Round 4 "Dill": each share on its own card. Settle All moves into the Open shares
//  heading as a small filled pill, right where the shares it settles are. Every share sits on a soft
//  inset card instead of rows with dividers: ticket and what's left, the date, and for a partly paid
//  share, Share / Paid figures (PPL-003).
//

#if DEBUG
import SwiftUI

struct DillPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P4PersonScreen(store: store, id: id, settleStyle: .inHeading, usesShareCards: true) { share in
            VStack(alignment: .leading, spacing: 4) {
                P4TitleLine(share: share, code: store.code)
                Text(share.date, format: .dateTime.weekday().day().month())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if share.paid > 0 {
                    HStack(spacing: 16) {
                        TDFigure(title: "Share", value: share.share, code: store.code)
                        TDFigure(title: "Paid", value: share.paid, code: store.code)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

#Preview("Dill") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { DillPerson(store: $0, id: $1) }
}

#Preview("Dill · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { DillPerson(store: $0, id: $1) }
}

#Preview("Dill · Dark") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { DillPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
