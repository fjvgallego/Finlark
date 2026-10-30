//
//  PeopleRound6Components.swift
//  Finlark
//
//  FIN-9 People, Round 6: the owner picked Sencha from Round 5 and asked for other button styles,
//  native ones included. Sencha's layout and behavior stay as they are: each share has Part and the
//  round check, Part opens a strip with Half and Other amount, Settle All sits under the header, and
//  Undo follows every one-tap action (SPL-006…008). Only the look of those five buttons changes, through
//  `P6Look`.
//

#if DEBUG
import SwiftUI

// MARK: - Looks

/// A family of button styles for Sencha's five buttons.
enum P6Look {
    /// System Liquid Glass: `.glassProminent` and `.glass`.
    case glass
    /// System bordered: `.borderedProminent` and `.bordered`.
    case bordered
    /// System, as light as it gets: a prominent Settle All, everything else plain tinted text and symbols.
    case minimal
    /// Custom, black and white: ink fills and label-colored outlines.
    case mono
    /// Custom, soft: neutral gray pills with label-colored text, a filled accent check.
    case soft
    /// Custom tinted glass in the accent color.
    case brandGlass
    /// Custom, tactile: raised buttons with a highlight and a shadow that presses in.
    case tactile
}

/// Which of Sencha's buttons is being styled.
enum P6Role {
    case settleAll
    case part
    case check
    /// "Half · 12,50 €" in the strip.
    case chipPrimary
    /// "Other amount…" in the strip.
    case chipSecondary

    var isPrimary: Bool { self == .settleAll || self == .chipPrimary }
}

extension View {
    func p6Button(_ look: P6Look, _ role: P6Role) -> some View {
        modifier(P6ButtonLook(look: look, role: role))
    }
}

private struct P6ButtonLook: ViewModifier {
    let look: P6Look
    let role: P6Role

    func body(content: Content) -> some View {
        switch look {
        case .glass:
            if role.isPrimary {
                native(content.buttonStyle(.glassProminent))
            } else {
                native(content.buttonStyle(.glass))
            }
        case .bordered:
            if role.isPrimary {
                native(content.buttonStyle(.borderedProminent))
            } else {
                native(content.buttonStyle(.bordered))
            }
        case .minimal:
            if role == .settleAll {
                native(content.buttonStyle(.borderedProminent))
            } else {
                content.buttonStyle(.borderless)
            }
        case .mono:
            switch role {
            case .settleAll: content.buttonStyle(P2ButtonStyle(kind: .ink, shape: .rounded, isLarge: true))
            case .chipPrimary: content.buttonStyle(P2ButtonStyle(kind: .ink))
            case .check: content.buttonStyle(P2IconButtonStyle(kind: .ink))
            case .part, .chipSecondary: content.buttonStyle(P2ButtonStyle(kind: .outline, tint: .primary))
            }
        case .soft:
            switch role {
            case .settleAll: content.buttonStyle(P4StrongTintButtonStyle())
            case .chipPrimary: content.buttonStyle(P2ButtonStyle(kind: .filled))
            case .check: content.buttonStyle(P2IconButtonStyle(kind: .filled))
            case .part, .chipSecondary: content.buttonStyle(P6NeutralButtonStyle())
            }
        case .brandGlass:
            if role.isPrimary || role == .check {
                content.buttonStyle(ExplorationBrandGlassButtonStyle(tint: .accentColor, isPrimary: true))
            } else {
                // Accent text on accent-tinted glass is too faint, so secondary buttons use label text.
                content.buttonStyle(P6ClearGlassButtonStyle())
            }
        case .tactile:
            content.buttonStyle(P6TactileButtonStyle(isPrimary: role.isPrimary || role == .check, isLarge: role == .settleAll, isRound: role == .check))
        }
    }

    /// System styles: Settle All is large, the check is round, and the rest are small capsules.
    private func native(_ content: some View) -> some View {
        content
            .controlSize(role == .settleAll ? .large : .regular)
            .buttonBorderShape(role == .check ? .circle : .capsule)
    }
}

/// A neutral gray pill with label-colored text, for the secondary buttons of the soft look.
struct P6NeutralButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(Color(uiColor: .label))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(minHeight: 36)
            .background(.fill.tertiary, in: .capsule)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Untinted interactive glass with label-colored text, for the brand glass look's secondary buttons.
struct P6ClearGlassButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(Color(uiColor: .label))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 14, style: .continuous))
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.2), value: configuration.isPressed)
    }
}

/// Raised buttons: a top highlight and a soft shadow that shrinks as the button is pressed in.
struct P6TactileButtonStyle: ButtonStyle {
    var isPrimary: Bool
    var isLarge = false
    var isRound = false

    @ScaledMetric private var roundSize: CGFloat = 38
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed
        let shape = isRound
            ? AnyShape(Circle())
            : AnyShape(RoundedRectangle(cornerRadius: isLarge ? 16 : 12, style: .continuous))

        configuration.label
            .labelStyle(isRound ? AnyLabelStyle(.iconOnly) : AnyLabelStyle(.titleAndIcon))
            .font(isLarge ? .headline : .subheadline.weight(.semibold))
            .fontDesign(.rounded)
            .foregroundStyle(isPrimary ? Color.white : Color(uiColor: .label))
            .padding(.horizontal, isRound ? 0 : (isLarge ? 20 : 14))
            .padding(.vertical, isRound ? 0 : (isLarge ? 14 : 8))
            .frame(width: isRound ? roundSize : nil, height: isRound ? roundSize : nil)
            .frame(minHeight: isRound ? nil : (isLarge ? 52 : 36))
            .background {
                shape.fill(isPrimary ? AnyShapeStyle(Color.accentColor.gradient) : AnyShapeStyle(Color(uiColor: .secondarySystemBackground)))
                    .overlay {
                        shape.stroke(
                            LinearGradient(colors: [.white.opacity(isPrimary ? 0.45 : 0.9), .clear], startPoint: .top, endPoint: .bottom),
                            lineWidth: 1
                        )
                    }
                    .shadow(color: .black.opacity(pressed ? 0.08 : 0.2), radius: pressed ? 1 : 4, y: pressed ? 1 : 3)
            }
            .contentShape(shape)
            .offset(y: pressed && !reduceMotion ? 1.5 : 0)
            .animation(reduceMotion ? nil : .snappy(duration: 0.15), value: pressed)
    }
}

/// Lets a style pick a label style at run time.
struct AnyLabelStyle: LabelStyle {
    private let make: (Configuration) -> AnyView

    init(_ style: some LabelStyle) {
        make = { AnyView(style.makeBody(configuration: $0)) }
    }

    func makeBody(configuration: Configuration) -> some View {
        make(configuration)
    }
}

// MARK: - Sencha

/// Sencha's person screen with the given look. `opensPart` opens the strip on the first partly paid
/// share (or the first share), for previews.
struct P6SenchaPerson: View {
    @Bindable var store: PPStore
    let id: PPPerson.ID
    let look: P6Look
    var opensPart = false

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
                        .p6Button(look, .part)
                        .accessibilityLabel(Text("Record part of \(share.ticket)"))
                        .accessibilityAddTraits(open == share.id ? .isSelected : [])
                        check(share, actions: actions)
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
            .p6Button(look, .settleAll)
        }
        .onAppear {
            guard opensPart, open == nil, let person = store.person(id) else { return }
            open = (person.openShares.first { $0.paid > 0 } ?? person.openShares.first)?.id
        }
    }

    @ViewBuilder
    private func check(_ share: PPShare, actions: P5ShareActions) -> some View {
        let title = Text("Mark \(share.ticket) as paid")

        if look == .minimal {
            // Plain, like Reminders' round button, but filled with a check.
            Button(action: actions.markPaid) {
                Label {
                    title
                } icon: {
                    Image(systemName: "checkmark.circle")
                }
                .labelStyle(.iconOnly)
                .font(.title)
                .frame(minWidth: 44, minHeight: 44)
            }
            .p6Button(look, .check)
        } else {
            Button(action: actions.markPaid) {
                Label {
                    title
                } icon: {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                }
                .labelStyle(.iconOnly)
            }
            .p6Button(look, .check)
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
            .p6Button(look, .chipPrimary)
        }
        Button("Other amount…") {
            actions.recordPart()
            open = nil
        }
        .p6Button(look, .chipSecondary)
    }
}
#endif
