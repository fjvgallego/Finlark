//
//  03-SagePeople.swift
//  Finlark
//
//  FIN-9 People, Round 4 "Sage": how long it's been. Settle All is an accent outline with text in the
//  label color, so the words keep full contrast. Each share says when it happened in plain words
//  ("6 days ago") with its category, and a partly paid share adds a small "Partly paid" note with what
//  came back (PPL-003).
//

#if DEBUG
import SwiftUI

struct SagePerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P4PersonScreen(store: store, id: id, settleStyle: .outline) { share in
            VStack(alignment: .leading, spacing: 4) {
                P4TitleLine(share: share, code: store.code)
                Text("\(Text(share.category.name)) · \(share.date, format: .relative(presentation: .named))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if share.paid > 0 {
                    Label {
                        Text("Partly paid, \(share.paid, format: .currency(code: store.code)) back so far")
                    } icon: {
                        Image(systemName: "circle.lefthalf.filled")
                            .foregroundStyle(.tint)
                    }
                    .font(.subheadline)
                    .monospacedDigit()
                }
            }
        }
    }
}

#Preview("Sage") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { SagePerson(store: $0, id: $1) }
}

#Preview("Sage · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { SagePerson(store: $0, id: $1) }
}

#Preview("Sage · Dark") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { SagePerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
