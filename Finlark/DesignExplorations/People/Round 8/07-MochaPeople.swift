//
//  07-MochaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Mocha": each share's category icon sits in a ring that fills as it's paid
//  back, with what's left and, once part is paid, what it was. Settle All is a centered pill under the header instead of a
//  full-width bar, since the header already says the total.
//

#if DEBUG
import SwiftUI

struct MochaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if person.showsSettleAll {
                Button(action: actions.settleAll) {
                    Label("Settle All", systemImage: "checkmark.circle.fill")
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .accessibilityLabel(Text("Settle all, \(person.owed.formatted(.currency(code: store.code)))"))
                .padding(.bottom, 4)
            }
            if !person.openShares.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Open shares", symbol: "clock.fill")
                        ForEach(person.openShares) { share in
                            P5Row {
                                HStack(alignment: .center, spacing: 12) {
                                    MochaRing(share: share)
                                    VStack(alignment: .leading, spacing: 3) {
                                        P5ShareTitle(share: share, code: store.code, showsPaid: false)
                                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                                            Text(share.remaining, format: .currency(code: store.code))
                                                .font(.headline)
                                            if share.paid > 0 {
                                                Text("of \(share.share, format: .currency(code: store.code))")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                        .monospacedDigit()
                                        .padding(.top, 2)
                                    }
                                }
                            } controls: {
                                GenmaichaCheck(title: Text("Mark \(share.ticket) as paid")) { actions.markPaid(share) }
                            }
                            if share.id != person.openShares.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
}

/// The category symbol in a ring that fills with what's been paid back. Decorative: the share's
/// accessibility value says it in words.
private struct MochaRing: View {
    let share: PPShare

    @ScaledMetric private var size: CGFloat = 44
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: share.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: share.category.symbol)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(share.category.color)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
        }
    }
}

#Preview("Mocha") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { MochaPerson(store: $0, id: $1) }
}

#Preview("Mocha · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { MochaPerson(store: $0, id: $1) }
}

#Preview("Mocha · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { MochaPerson(store: $0, id: $1) }
}

#Preview("Mocha · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { MochaPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
