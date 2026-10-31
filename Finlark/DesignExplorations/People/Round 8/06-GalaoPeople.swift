//
//  06-GalaoPeople.swift
//  Finlark
//
//  FIN-9 People, Round 8 "Galão": the open shares grouped by when they happened, This week and
//  Earlier, like a statement. The tile ends on a receipt-style total line, with Settle All next to the
//  total it settles.
//

#if DEBUG
import SwiftUI

struct GalaoPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P8PersonScreen(store: store, id: id) { person, actions in
            if !person.openShares.isEmpty {
                let recent = person.openShares.filter { $0.age < 7 }
                let earlier = person.openShares.filter { $0.age >= 7 }

                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Open shares", symbol: "clock.fill")
                        GalaoGroup(title: "This week", shares: recent, code: store.code, actions: actions)
                        GalaoGroup(title: "Earlier", shares: earlier, code: store.code, actions: actions)
                        if person.showsSettleAll {
                            GalaoTotal(person: person, code: store.code, action: actions.settleAll)
                        }
                    }
                }
            }
        }
    }
}

private struct GalaoGroup: View {
    let title: LocalizedStringKey
    let shares: [PPShare]
    let code: String
    let actions: P8Actions

    var body: some View {
        if !shares.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(shares) { share in
                    P5Row {
                        P8InfoAndAmount {
                            P5ShareTitle(share: share, code: code)
                        } amount: {
                            Text(share.remaining, format: .currency(code: code))
                                .font(.headline)
                                .monospacedDigit()
                        }
                    } controls: {
                        GenmaichaCheck(title: Text("Mark \(share.ticket) as paid")) { actions.markPaid(share) }
                    }
                }
            }
        }
    }
}

/// A dashed rule, then the total and Settle All, like the foot of a receipt.
private struct GalaoTotal: View {
    let person: PPPerson
    let code: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Line()
                .stroke(.tertiary, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(height: 1)
                .accessibilityHidden(true)
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
                : AnyLayout(HStackLayout(spacing: 12))
            layout {
                HStack(alignment: .firstTextBaseline) {
                    Text("Total")
                        .font(.headline)
                    Spacer(minLength: 8)
                    Text(person.owed, format: .currency(code: code))
                        .font(.title3.weight(.bold))
                        .fontDesign(.rounded)
                        .monospacedDigit()
                }
                .accessibilityElement(children: .combine)
                P8CompactSettleButton(person: person, code: code, action: action)
            }
        }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { path in
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

#Preview("Galão") {
    PPHost(opening: "marta") { GenmaichaPeople(store: $0) } person: { GalaoPerson(store: $0, id: $1) }
}

#Preview("Galão · Luis") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { GalaoPerson(store: $0, id: $1) }
}

#Preview("Galão · Ana") {
    PPHost(opening: "ana") { GenmaichaPeople(store: $0) } person: { GalaoPerson(store: $0, id: $1) }
}

#Preview("Galão · Dark") {
    PPHost(opening: "luis") { GenmaichaPeople(store: $0) } person: { GalaoPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
