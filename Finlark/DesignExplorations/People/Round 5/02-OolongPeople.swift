//
//  02-OolongPeople.swift
//  Finlark
//
//  FIN-9 People, Round 5 "Oolong": drag what came back. Each share has a bar of what's been paid back;
//  drag along it to record part (the amount follows your finger, in whole units, and Undo follows), or
//  tap the round check to record all that's left (SPL-006, SPL-007). Settle All is a track you slide,
//  so settling everyone's shares at once is deliberate.
//

#if DEBUG
import SwiftUI

struct OolongPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P5PersonScreen(store: store, id: id) { share, actions in
            VStack(alignment: .leading, spacing: 10) {
                P5Row {
                    P5ShareTitle(share: share, code: store.code, showsPaid: false)
                } controls: {
                    HStack(spacing: 10) {
                        Text(share.remaining, format: .currency(code: store.code))
                            .font(.headline)
                            .monospacedDigit()
                        P3CheckButton(title: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
                    }
                }
                OolongPaybackBar(share: share, code: store.code, actions: actions)
            }
        } settle: { person, settleAll in
            P5SlideToSettle(
                title: Text("Slide to settle all · \(person.owed, format: .currency(code: store.code))"),
                action: settleAll
            )
        }
    }
}

/// What's been paid back, as a bar you can drag to record more. Whole units only, never past what's
/// left (A-04). VoiceOver opens the repayment sheet instead of dragging.
private struct OolongPaybackBar: View {
    let share: PPShare
    let code: String
    let actions: P5ShareActions

    @State private var dragged: Decimal?
    @ScaledMetric private var height: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let paid = share.paid.plotValue
                let total = max(share.share.plotValue, 0.01)
                let extra = (dragged ?? 0).plotValue

                ZStack(alignment: .leading) {
                    Capsule().fill(.fill.tertiary)
                    Capsule()
                        .fill(Color.accentColor.opacity(0.45))
                        .frame(width: width * min((paid + extra) / total, 1))
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: width * min(paid / total, 1))
                }
                .frame(height: height)
                .frame(maxHeight: .infinity)
                .contentShape(.rect)
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { value in
                            let fraction = min(max(value.location.x / width, 0), 1)
                            let wanted = (fraction * total - paid).rounded()
                            let amount = min(Decimal(max(wanted, 0)), share.remaining)
                            dragged = amount > 0 ? amount : nil
                        }
                        .onEnded { _ in
                            if let dragged { actions.record(dragged) }
                            dragged = nil
                        }
                )
            }
            .frame(height: 28)

            Group {
                if let dragged {
                    Text("Record \(dragged, format: .currency(code: code))")
                        .foregroundStyle(.tint)
                        .fontWeight(.semibold)
                } else if share.paid > 0 {
                    Text("\(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code)) paid · drag to add")
                        .foregroundStyle(.secondary)
                } else {
                    Text("Drag to record part")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.footnote)
            .monospacedDigit()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Paid back so far"))
        .accessibilityValue(Text("\(share.paid, format: .currency(code: code)) of \(share.share, format: .currency(code: code))"))
        .accessibilityAction(named: Text("Record part"), actions.recordPart)
    }
}

#Preview("Oolong") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { OolongPerson(store: $0, id: $1) }
}

#Preview("Oolong · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { OolongPerson(store: $0, id: $1) }
}

#Preview("Oolong · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { OolongPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
