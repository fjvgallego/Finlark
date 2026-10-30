//
//  01-MatchaPeople.swift
//  Finlark
//
//  FIN-9 People, Round 5 "Matcha": one split control. Under each share's amount sits a single capsule cut
//  in two: "Part" on a neutral half and "Paid" on a filled half, so both choices are visible and read
//  as one decision about that share (SPL-006, SPL-007). Settle All is a filled accent button.
//

#if DEBUG
import SwiftUI

struct MatchaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P5PersonScreen(store: store, id: id) { share, actions in
            P5Row {
                P5ShareTitle(share: share, code: store.code)
            } controls: {
                VStack(alignment: .trailing, spacing: 8) {
                    Text(share.remaining, format: .currency(code: store.code))
                        .font(.headline)
                        .monospacedDigit()
                    MatchaSplitControl(share: share, actions: actions)
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
            .buttonStyle(P2ButtonStyle(kind: .filled, shape: .rounded, isLarge: true))
        }
    }
}

/// "Part | ✓ Paid" as one capsule: a neutral half with label-colored text and a filled accent half.
private struct MatchaSplitControl: View {
    let share: PPShare
    let actions: P5ShareActions

    var body: some View {
        HStack(spacing: 0) {
            Button(action: actions.recordPart) {
                Text("Part")
                    .foregroundStyle(Color(uiColor: .label))
                    .padding(.horizontal, 14)
                    .frame(maxHeight: .infinity)
                    .background(.fill.secondary)
            }
            .accessibilityLabel(Text("Record part of \(share.ticket)"))
            Button(action: actions.markPaid) {
                Label("Paid", systemImage: "checkmark")
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(maxHeight: .infinity)
                    .background(Color.accentColor.gradient)
            }
            .accessibilityLabel(Text("Mark \(share.ticket) as paid"))
        }
        .buttonStyle(.plain)
        .font(.subheadline.weight(.semibold))
        .fontDesign(.rounded)
        .frame(minHeight: 36)
        .fixedSize()
        .clipShape(.capsule)
    }
}

#Preview("Matcha") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { MatchaPerson(store: $0, id: $1) }
}

#Preview("Matcha · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { MatchaPerson(store: $0, id: $1) }
}

#Preview("Matcha · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { MatchaPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
