//
//  YawlOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding "Yawl": the brand all the way. Every step sits on Clove's gradient in
//  white, with glass controls, so onboarding, the lock screen and the app icon feel like one piece.
//  Steps slide in place under a row of white step dots, with a back button once you're past the
//  welcome. The currency list opens in a sheet. The owner's pick for onboarding: the starting balance
//  can be left empty (zero), and when iCloud data arrives after "Continue as New User", the person
//  chooses between it and this setup ("Yawl · iCloud Data Arrives").
//

#if DEBUG
import SwiftUI

struct YawlOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var step: OBStep
    @State private var movesForward = true
    @State private var choosingCurrency = false

    @FocusState private var amountFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(setup: OBSetup) {
        self.setup = setup
        _step = State(initialValue: min(setup.startStep, .appLock))
    }

    var body: some View {
        Group {
            if setup.stage == .restoring {
                restoring
            } else {
                ZStack {
                    page
                        .id(step)
                        .transition(transition)
                }
                .safeAreaInset(edge: .top) { topBar }
            }
        }
        .foregroundStyle(.white)
        .tint(.white)
        .environment(\.obPrimaryIsGlass, true)
        .background { OBBrandBackground() }
        .environment(\.colorScheme, .dark)
        .animation(.smooth(duration: 0.4), value: step)
        .sheet(isPresented: $choosingCurrency) {
            OBCurrencySheet(setup: setup)
        }
        .onChange(of: step) { _, step in
            amountFocused = step == .balance
        }
    }

    private var transition: AnyTransition {
        if reduceMotion { return .opacity }
        return .push(from: movesForward ? .trailing : .leading)
    }

    private func go(to next: OBStep) {
        movesForward = next > step
        step = next
    }

    @ViewBuilder
    private var topBar: some View {
        if step > .welcome {
            HStack {
                Button("Back", systemImage: "chevron.left") {
                    go(to: OBStep(rawValue: step.rawValue - 1) ?? .welcome)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
                Spacer()
                OBProgress(step: step.rawValue, count: 3)
                Spacer()
                // Balances the back button so the dots stay centered.
                Color.clear.frame(width: 44, height: 1)
            }
            .padding(.horizontal, 16)
        }
    }

    @ViewBuilder
    private var page: some View {
        switch step {
        case .welcome:
            LKCentered {
                VStack(spacing: 36) {
                    OBWordmark()
                    OBHighlights()
                }
            } bottom: {
                OBPrimaryButton("Get Started") { go(to: .currency) }
            }
        case .currency:
            LKCentered {
                VStack(spacing: 20) {
                    YawlHeading(symbol: "globe", title: Text(OBText.currencyQuestion), message: Text(OBText.currencyHint))
                    Button {
                        choosingCurrency = true
                    } label: {
                        HStack {
                            OBCurrencyLabel(setup: setup)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.footnote.weight(.semibold))
                                .accessibilityHidden(true)
                        }
                        .padding(16)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 24))
                    .accessibilityHint(Text("Shows every currency."))
                }
            } bottom: {
                OBPrimaryButton("Continue") { go(to: .balance) }
            }
        case .balance:
            LKCentered {
                VStack(spacing: 24) {
                    YawlHeading(symbol: "banknote.fill", title: Text(OBText.balanceQuestion), message: Text("Leave it empty to start from zero. You can correct it later in Settings."))
                    OBAmountField(setup: setup, focus: $amountFocused, baseSize: 52, tintsNegative: false)
                    OBOverdrawnToggle(setup: setup)
                        .tint(.green)
                        .padding(16)
                        .glassEffect(.regular, in: .rect(cornerRadius: 20))
                }
            } bottom: {
                OBPrimaryButton("Continue") { go(to: .appLock) }
            }
        default:
            LKCentered {
                VStack(spacing: 20) {
                    OBLockSymbol(setup: setup, size: 72)
                    OBText.lockTitle(setup)
                        .font(.title.bold())
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    OBLockNote(setup: setup)
                }
                .multilineTextAlignment(.center)
            } bottom: {
                OBLockActions(setup: setup, next: setup.finish)
            }
        }
    }

    private var restoring: some View {
        LKCentered {
            VStack(spacing: 32) {
                OBWordmark(birdSize: 44)
                OBRestoringContent()
            }
        } bottom: {
            VStack(spacing: 10) {
                OBSecondaryButton(OBText.newUser, action: setup.continueAsNewUser)
                // ONB-005: what was in iCloud isn't lost by starting over.
                Text("If your iCloud data arrives later, you choose which to keep.")
                    .font(.footnote)
                    .opacity(0.8)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct YawlHeading: View {
    let symbol: String
    let title: Text
    let message: Text

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .medium))
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .accessibilityHidden(true)
            title
                .font(.title.bold())
                .accessibilityAddTraits(.isHeader)
            message
                .font(.subheadline)
                .opacity(0.8)
        }
        .multilineTextAlignment(.center)
    }
}

#Preview("Yawl") {
    OBHost { YawlOnboarding(setup: $0) }
}

#Preview("Yawl · Balance") {
    OBHost(step: .balance) { YawlOnboarding(setup: $0) }
}

#Preview("Yawl · App Lock") {
    OBHost(step: .appLock) { YawlOnboarding(setup: $0) }
}

#Preview("Yawl · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { YawlOnboarding(setup: $0) }
}

#Preview("Yawl · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { YawlOnboarding(setup: $0) }
}

#Preview("Yawl · iCloud Data Arrives") {
    OBHost(.dataArrivesLater(after: .seconds(3)), step: .balance) { YawlOnboarding(setup: $0) }
}
#endif
