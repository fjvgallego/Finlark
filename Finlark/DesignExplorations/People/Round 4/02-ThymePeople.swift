//
//  02-ThymePeople.swift
//  Finlark
//
//  FIN-9 People, Round 4 "Thyme": the check shows progress. Settle All is an ink button (the label color,
//  inverted), the highest contrast there is. The round check carries a ring that fills with what's been
//  paid back, so a partly paid share shows it without an extra line of text, and the row is just the
//  ticket, its date and what's left (PPL-003, SPL-006).
//

#if DEBUG
import SwiftUI

struct ThymePerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P4PersonScreen(store: store, id: id, settleStyle: .ink) { share, actions in
            ThymeRingCheck(share: share, action: actions.markPaid)
        } content: { share in
            VStack(alignment: .leading, spacing: 4) {
                P4TitleLine(share: share, code: store.code)
                if share.paid > 0 {
                    Text("\(share.date, format: .dateTime.day().month()) · \(share.paid, format: .currency(code: store.code)) of \(share.share, format: .currency(code: store.code)) paid")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    Text(share.date, format: .dateTime.weekday().day().month())
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Saffron's round check with a ring around it for what's been paid back. The ring is decorative.
private struct ThymeRingCheck: View {
    let share: PPShare
    let action: () -> Void

    @ScaledMetric private var size: CGFloat = 40
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.14))
                Circle()
                    .trim(from: 0, to: share.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .padding(1.5)
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: size, height: size)
            .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Mark \(share.ticket) as paid"))
    }
}

#Preview("Thyme") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { ThymePerson(store: $0, id: $1) }
}

#Preview("Thyme · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { ThymePerson(store: $0, id: $1) }
}

#Preview("Thyme · Dark") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { ThymePerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
