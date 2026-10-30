//
//  06-DarjeelingPeople.swift
//  Finlark
//
//  FIN-9 People, Round 5 "Darjeeling": two labeled round buttons. Each share ends with a half-filled
//  circle for part (SPL-007) and Saffron's check for paid (SPL-006), each with its word under it, so
//  neither is a guess. Settle All keeps Anise's tinted look, with a stronger tint and label-colored text.
//

#if DEBUG
import SwiftUI

struct DarjeelingPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID

    var body: some View {
        P5PersonScreen(store: store, id: id) { share, actions in
            P5Row {
                VStack(alignment: .leading, spacing: 3) {
                    P5ShareTitle(share: share, code: store.code)
                    Text("\(share.remaining, format: .currency(code: store.code)) left")
                        .font(.headline)
                        .monospacedDigit()
                        .padding(.top, 2)
                }
            } controls: {
                HStack(alignment: .top, spacing: 12) {
                    DarjeelingButton(title: "Part", symbol: "circle.lefthalf.filled", label: Text("Record part of \(share.ticket)"), action: actions.recordPart)
                    DarjeelingButton(title: "Paid", symbol: "checkmark", label: Text("Mark \(share.ticket) as paid"), action: actions.markPaid)
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
            .buttonStyle(P4StrongTintButtonStyle())
        }
    }
}

/// A round tinted button with its word under it.
private struct DarjeelingButton: View {
    let title: LocalizedStringKey
    let symbol: String
    let label: Text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Label(title, systemImage: symbol)
                    .labelStyle(.iconOnly)
                    .modifier(DarjeelingCircle())
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(uiColor: .label))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Saffron's tinted circle, as a modifier so it can sit inside a plain button with a caption.
private struct DarjeelingCircle: ViewModifier {
    @ScaledMetric private var size: CGFloat = 36

    func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: size, height: size)
            .background(Color.accentColor.opacity(0.14), in: .circle)
    }
}

#Preview("Darjeeling") {
    PPHost(opening: "marta") { P3People(store: $0) } person: { DarjeelingPerson(store: $0, id: $1) }
}

#Preview("Darjeeling · Luis") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { DarjeelingPerson(store: $0, id: $1) }
}

#Preview("Darjeeling · Dark") {
    PPHost(opening: "luis") { P3People(store: $0) } person: { DarjeelingPerson(store: $0, id: $1) }
        .preferredColorScheme(.dark)
}
#endif
