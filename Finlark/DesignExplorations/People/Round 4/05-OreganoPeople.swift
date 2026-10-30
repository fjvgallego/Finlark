//
//  05-OreganoPeople.swift
//  Finlark
//
//  FIN-9 People, Round 4 "Oregano": Settle All always in reach. It's a filled bar pinned above the tab
//  bar, so it stays put while the shares scroll. Each share's amount sits in a small capsule, and a
//  partly paid share gets a blue "Partly paid" chip next to its date instead of a sentence (PPL-003).
//

#if DEBUG
import SwiftUI

struct OreganoPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        P4PersonScreen(store: store, id: id, settleStyle: .pinned) { share in
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                : AnyLayout(HStackLayout(alignment: .top, spacing: 8))
            layout {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: share.ticket)
                        .font(.headline)
                    HStack(spacing: 6) {
                        Text(share.date, format: .dateTime.day().month())
                            .foregroundStyle(.secondary)
                        if share.paid > 0 {
                            Text("Partly paid")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tint)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.14), in: .capsule)
                        }
                    }
                    .font(.subheadline)
                }
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: 8)
                }
                Text(share.remaining, format: .currency(code: store.code))
                    .font(.headline)
                    .monospacedDigit()
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.fill.tertiary, in: .capsule)
            }
        }
    }
}

#Preview("Oregano") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { OreganoPerson(store: $0, id: $1) }
}

#Preview("Oregano · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { OreganoPerson(store: $0, id: $1) }
}

#Preview("Oregano · Dark") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { OreganoPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
