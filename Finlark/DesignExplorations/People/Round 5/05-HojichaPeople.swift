//
//  05-HojichaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 5 "Hojicha": the amount is the part control. What's left sits in a pill with a
//  small pencil, and tapping it records a different amount, part of it (SPL-007); the round check next
//  to it records all of it (SPL-006). Two controls, and the one that changes the number is the number.
//  Settle All is an accent outline with text in the label color.
//

#if DEBUG
import SwiftUI

struct HojichaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P5PersonScreen(store: store, id: id) { share, actions in
            P5Row {
                P5ShareTitle(share: share, code: store.code)
            } controls: {
                HStack(spacing: 8) {
                    Button(action: actions.recordPart) {
                        HStack(spacing: 6) {
                            Text(share.remaining, format: .currency(code: store.code))
                                .monospacedDigit()
                            Image(systemName: "pencil")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .font(.headline)
                        .foregroundStyle(Color(uiColor: .label))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 36)
                        .background(.fill.tertiary, in: .capsule)
                        .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("\(share.remaining, format: .currency(code: store.code)) left"))
                    .accessibilityHint(Text("Records part of it"))
                    P3CheckButton(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
                }
            }
        } settle: { person, settleAll in
            Button(action: settleAll) {
                Label {
                    Text("Settle All · \(person.owed, format: .currency(code: store.code))")
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(P4OutlineButtonStyle())
        }
    }
}

#Preview("Hojicha") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { HojichaPerson(store: $0, id: $1) }
}

#Preview("Hojicha · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { HojichaPerson(store: $0, id: $1) }
}

#Preview("Hojicha · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { HojichaPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
