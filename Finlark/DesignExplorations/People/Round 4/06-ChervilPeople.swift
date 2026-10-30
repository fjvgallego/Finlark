//
//  06-ChervilPeople.swift
//  Finlark
//
//  FIN-9 People, Round 4 "Chervil": closest to Anise. Settle All keeps its tinted look but with a
//  stronger tint and text in the label color, so it reads in both appearances. A share is two lines,
//  ticket and date, with what's left trailing; a partly paid share shows "of 30,00 €" under its amount
//  instead of a status line (PPL-003).
//

#if DEBUG
import SwiftUI

struct ChervilPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        P4PersonScreen(store: store, id: id, settleStyle: .strongTint) { share in
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 8))
            layout {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: share.ticket)
                        .font(.headline)
                    Text(share.date, format: .dateTime.weekday().day().month())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: 8)
                }
                VStack(alignment: dynamicTypeSize.isAccessibilitySize ? .leading : .trailing, spacing: 2) {
                    Text(share.remaining, format: .currency(code: store.code))
                        .font(.headline)
                    if share.paid > 0 {
                        Text("of \(share.share, format: .currency(code: store.code))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .monospacedDigit()
            }
        }
    }
}

#Preview("Chervil") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { ChervilPerson(store: $0, id: $1) }
}

#Preview("Chervil · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { ChervilPerson(store: $0, id: $1) }
}

#Preview("Chervil · Dark") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { ChervilPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
