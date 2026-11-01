//
//  03-KetchOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Ketch": a conversation. Finlark asks one question at a time, and each
//  answer stays on screen as a line you can tap to change ("Currency: Euro"). The current question is
//  a glass card at the end, with its buttons at the bottom. Friendly, and it shows what you've already
//  set without a summary screen.
//

#if DEBUG
import SwiftUI

struct KetchOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var current: OBStep
    @State private var choosingCurrency = false

    @FocusState private var amountFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(setup: OBSetup) {
        self.setup = setup
        _current = State(initialValue: max(setup.startStep, .currency))
    }

    private var steps: [OBStep] { [.currency, .balance, .appLock] }

    var body: some View {
        if setup.stage == .restoring {
            KetchRestoring(setup: setup)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    greeting
                    ForEach(steps.filter { $0 < current }, id: \.self) { step in
                        KetchAnswer(setup: setup, step: step) { current = step }
                    }
                    card
                        .id(current)
                        .transition(reduceMotion ? .opacity : .move(edge: .bottom).combined(with: .opacity))
                }
                .padding()
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                actions
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            .background { R2Backdrop() }
            .animation(.smooth(duration: 0.35), value: current)
            .sheet(isPresented: $choosingCurrency) {
                OBCurrencySheet(setup: setup)
            }
            .onChange(of: current) { _, step in
                amountFocused = step == .balance
            }
        }
    }

    private var greeting: some View {
        HStack(alignment: .top, spacing: 12) {
            LKMark(size: 40)
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome to Finlark")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Three quick questions and you're ready.")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    private var card: some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    switch current {
                    case .currency: Text(OBText.currencyQuestion)
                    case .balance: Text(OBText.balanceQuestion)
                    default: OBText.lockTitle(setup)
                    }
                }
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)

                switch current {
                case .currency:
                    OBCurrencyLabel(setup: setup)
                    Text(OBText.currencyHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                case .balance:
                    OBAmountField(setup: setup, focus: $amountFocused, baseSize: 44)
                    Divider()
                    OBOverdrawnToggle(setup: setup)
                    Text(OBText.balanceHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                default:
                    HStack(alignment: .top, spacing: 16) {
                        OBLockSymbol(setup: setup, size: 44)
                        OBLockNote(setup: setup)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch current {
        case .currency:
            VStack(spacing: 10) {
                OBPrimaryButton(text: Text("Use \(setup.currencyName)")) { current = .balance }
                OBSecondaryButton("Choose Another") { choosingCurrency = true }
            }
        case .balance:
            OBPrimaryButton("Continue") { current = .appLock }
        default:
            OBLockActions(setup: setup, next: setup.finish)
        }
    }
}

/// An answered question, as a line that opens it again.
private struct KetchAnswer: View {
    let setup: OBSetup
    let step: OBStep
    let change: () -> Void

    var body: some View {
        Button(action: change) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    value
                        .font(.body.weight(.semibold))
                        .monospacedDigit()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text("Change")
                    .font(.subheadline)
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Asks again."))
    }

    @ViewBuilder
    private var title: some View {
        switch step {
        case .currency: Text("Currency")
        default: Text("Starting balance")
        }
    }

    @ViewBuilder
    private var value: some View {
        switch step {
        case .currency: Text(verbatim: "\(setup.currencyName) (\(setup.currencyCode))")
        default: Text(setup.startingBalance, format: .currency(code: setup.currencyCode))
        }
    }
}

private struct KetchRestoring: View {
    let setup: OBSetup

    var body: some View {
        LKCentered {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    LKMark(size: 40)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back")
                            .font(.title2.bold())
                            .accessibilityAddTraits(.isHeader)
                        Text("Your iCloud already has Finlark data.")
                            .foregroundStyle(.secondary)
                    }
                }
                R2Tile(padding: 24) {
                    OBRestoringContent()
                        .frame(maxWidth: .infinity)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        } bottom: {
            OBSecondaryButton(OBText.newUser, action: setup.continueAsNewUser)
        }
        .background { R2Backdrop() }
    }
}

#Preview("Ketch") {
    OBHost { KetchOnboarding(setup: $0) }
}

#Preview("Ketch · App Lock") {
    OBHost(step: .appLock) { KetchOnboarding(setup: $0) }
}

#Preview("Ketch · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { KetchOnboarding(setup: $0) }
}

#Preview("Ketch · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { KetchOnboarding(setup: $0) }
}

#Preview("Ketch · Dark") {
    OBHost(step: .balance) { KetchOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
