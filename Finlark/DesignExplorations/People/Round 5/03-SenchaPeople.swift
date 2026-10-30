//
//  03-SenchaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 5 "Sencha": part payments in place. Each share has a "Part" button and the round
//  check. Part opens a strip right under the share with the likely answers, "Half" and "Other amount…",
//  so the common case (they paid half) is one more tap, with Undo (SPL-007). Settle All is an ink
//  button.
//

#if DEBUG
import SwiftUI

struct SenchaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    @State private var open: PPShare.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        P5PersonScreen(store: store, id: id) { share, actions in
            VStack(alignment: .leading, spacing: 10) {
                P5Row {
                    VStack(alignment: .leading, spacing: 3) {
                        P5ShareTitle(share: share, code: store.code)
                        Text("\(share.remaining, format: .currency(code: store.code)) left")
                            .font(.headline)
                            .monospacedDigit()
                            .padding(.top, 2)
                    }
                } controls: {
                    HStack(spacing: 8) {
                        Button {
                            withAnimation(reduceMotion ? nil : .snappy) {
                                open = open == share.id ? nil : share.id
                            }
                        } label: {
                            Text("Part")
                        }
                        .buttonStyle(P2ButtonStyle(kind: .outline, tint: .primary))
                        .accessibilityLabel(Text("Record part of \(share.ticket)"))
                        .accessibilityAddTraits(open == share.id ? .isSelected : [])
                        P3CheckButton(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
                    }
                }
                if open == share.id {
                    strip(share, actions: actions)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        } settle: { person, settleAll in
            Button(action: settleAll) {
                Label {
                    Text("Settle All · \(person.owed, format: .currency(code: store.code))")
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(P2ButtonStyle(kind: .ink, shape: .rounded, isLarge: true))
        }
    }

    /// Half of what's left (rounded down to the currency's minor unit), or any amount in the sheet.
    private func strip(_ share: PPShare, actions: P5ShareActions) -> some View {
        let half = AEMoney.rounded(share.remaining / 2, fractionDigits: AEMoney.fractionDigits(for: store.code))

        return ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { chips(half, actions: actions) }
            VStack(alignment: .leading, spacing: 8) { chips(half, actions: actions) }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func chips(_ half: Decimal, actions: P5ShareActions) -> some View {
        Text("They paid")
            .font(.subheadline)
            .foregroundStyle(.secondary)
        if half > 0 {
            Button {
                actions.record(half)
                open = nil
            } label: {
                Text("Half · \(half, format: .currency(code: store.code))")
                    .monospacedDigit()
            }
            .buttonStyle(P2ButtonStyle(kind: .filled))
        }
        Button("Other amount…") {
            actions.recordPart()
            open = nil
        }
        .buttonStyle(P2ButtonStyle(kind: .outline, tint: .primary))
    }
}

#Preview("Sencha") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { SenchaPerson(store: $0, id: $1) }
}

#Preview("Sencha · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { SenchaPerson(store: $0, id: $1) }
}

#Preview("Sencha · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { SenchaPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
