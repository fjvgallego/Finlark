//
//  04-RooibosPeople.swift
//  Finlark
//
//  FIN-9 People, Round 5 "Rooibos": shares as ticket stubs. Each open share is its own glass ticket, the
//  amount large on the left, and a perforated stub on the right holding "Paid" and "Part" one above the
//  other (SPL-006, SPL-007). The shares add up underneath like a receipt, and Settle All closes it.
//

#if DEBUG
import SwiftUI

struct RooibosPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        P5PersonScreen(store: store, id: id, settlePlacement: .tileFooter, usesShareCards: true) { share, actions in
            R2Tile(padding: 0) {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                    : AnyLayout(HStackLayout(spacing: 0))
                layout {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(share.remaining, format: .currency(code: store.code))
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .monospacedDigit()
                        P5ShareTitle(share: share, code: store.code)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    RooibosPerforation(isVertical: !dynamicTypeSize.isAccessibilitySize)
                        .stroke(.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 5]))
                        .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 1.5,
                               height: dynamicTypeSize.isAccessibilitySize ? 1.5 : nil)
                        .padding(dynamicTypeSize.isAccessibilitySize ? .horizontal : .vertical, 12)
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Button(action: actions.markPaid) {
                            Label("Paid", systemImage: "checkmark")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(P2ButtonStyle(kind: .filled, shape: .rounded))
                        .accessibilityLabel(Text("Mark \(share.ticket) as paid"))
                        Button(action: actions.recordPart) {
                            Text("Part")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(P2ButtonStyle(kind: .outline, tint: .primary, shape: .rounded))
                        .accessibilityLabel(Text("Record part of \(share.ticket)"))
                    }
                    .padding(14)
                    .frame(width: dynamicTypeSize.isAccessibilitySize ? nil : 112)
                }
            }
        } settle: { person, settleAll in
            VStack(spacing: 12) {
                HStack {
                    Text("Total")
                    Spacer(minLength: 8)
                    Text(person.owed, format: .currency(code: store.code))
                        .monospacedDigit()
                }
                .font(.title3.weight(.bold))
                .padding(.horizontal, 4)
                .accessibilityElement(children: .combine)
                Button(action: settleAll) {
                    Label {
                    Text("Settle All · \(person.owed, format: .currency(code: store.code))")
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .frame(maxWidth: .infinity)
                }
                .buttonStyle(P2ButtonStyle(kind: .filled, shape: .rounded, isLarge: true))
            }
            .padding(.top, 4)
        }
    }
}

/// A dashed line between the ticket and its stub.
private struct RooibosPerforation: Shape {
    let isVertical: Bool

    func path(in rect: CGRect) -> Path {
        Path { path in
            if isVertical {
                path.move(to: CGPoint(x: rect.midX, y: rect.minY))
                path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            } else {
                path.move(to: CGPoint(x: rect.minX, y: rect.midY))
                path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            }
        }
    }
}

#Preview("Rooibos") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { RooibosPerson(store: $0, id: $1) }
}

#Preview("Rooibos · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { RooibosPerson(store: $0, id: $1) }
}

#Preview("Rooibos · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { RooibosPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
