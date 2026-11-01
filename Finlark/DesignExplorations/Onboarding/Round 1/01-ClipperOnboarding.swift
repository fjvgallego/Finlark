//
//  01-ClipperOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Clipper": the classic. A welcome on Clove's gradient, then one pushed
//  screen per question on Marsh's backdrop: a big question, a glass tile with the answer, Continue at
//  the bottom and the step dots on top. Back works as anywhere else in iOS. The last step opens Home.
//

#if DEBUG
import SwiftUI

struct ClipperOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var path: [OBStep]

    init(setup: OBSetup) {
        self.setup = setup
        _path = State(initialValue: [OBStep.currency, .balance, .appLock].filter { $0 <= setup.startStep })
    }

    var body: some View {
        if setup.stage == .restoring {
            ClipperRestoring(setup: setup)
        } else {
            NavigationStack(path: $path) {
                ClipperWelcome { path.append(.currency) }
                    .navigationDestination(for: OBStep.self) { step in
                        ClipperStep(setup: setup, step: step) { next(after: step) }
                    }
            }
        }
    }

    private func next(after step: OBStep) {
        switch step {
        case .currency: path.append(.balance)
        case .balance: path.append(.appLock)
        default: setup.finish()
        }
    }
}

private struct ClipperWelcome: View {
    let start: () -> Void

    var body: some View {
        LKCentered {
            VStack(spacing: 36) {
                OBWordmark()
                OBHighlights()
            }
            .foregroundStyle(.white)
        } bottom: {
            OBPrimaryButton("Get Started", action: start)
        }
        .tint(.white)
        .environment(\.obPrimaryIsGlass, true)
        .background { OBBrandBackground() }
        .environment(\.colorScheme, .dark)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

private struct ClipperStep: View {
    @Bindable var setup: OBSetup
    let step: OBStep
    let next: () -> Void

    @FocusState private var amountFocused: Bool

    var body: some View {
        LKCentered(alignment: .top) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    question
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    hint
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                answer
            }
        } bottom: {
            if step == .appLock {
                OBLockActions(setup: setup, next: next)
            } else {
                OBPrimaryButton("Continue", action: next)
            }
        }
        .background { R2Backdrop() }
        .toolbar {
            ToolbarItem(placement: .principal) {
                OBProgress(step: step.rawValue, count: 3)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if step == .balance { amountFocused = true }
        }
    }

    @ViewBuilder
    private var question: some View {
        switch step {
        case .currency: Text(OBText.currencyQuestion)
        case .balance: Text(OBText.balanceQuestion)
        default: OBText.lockTitle(setup)
        }
    }

    @ViewBuilder
    private var hint: some View {
        switch step {
        case .currency: Text(OBText.currencyHint)
        case .balance: Text(OBText.balanceHint)
        default: OBLockNote(setup: setup)
        }
    }

    @ViewBuilder
    private var answer: some View {
        switch step {
        case .currency:
            NavigationLink {
                OBCurrencyList(setup: setup)
            } label: {
                R2Tile(padding: 18) {
                    HStack {
                        OBCurrencyLabel(setup: setup)
                        Text("Change")
                            .foregroundStyle(.secondary)
                        R2Chevron()
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Shows every currency."))
        case .balance:
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    OBAmountField(setup: setup, focus: $amountFocused, baseSize: 44)
                    Divider()
                    OBOverdrawnToggle(setup: setup)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        default:
            OBLockSymbol(setup: setup)
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
        }
    }
}

private struct ClipperRestoring: View {
    let setup: OBSetup

    var body: some View {
        LKCentered {
            VStack(spacing: 32) {
                OBWordmark(birdSize: 44)
                OBRestoringContent()
            }
            .foregroundStyle(.white)
        } bottom: {
            OBSecondaryButton(OBText.newUser, action: setup.continueAsNewUser)
        }
        .tint(.white)
        .background { OBBrandBackground() }
        .environment(\.colorScheme, .dark)
    }
}

#Preview("Clipper") {
    OBHost { ClipperOnboarding(setup: $0) }
}

#Preview("Clipper · Balance") {
    OBHost(step: .balance) { ClipperOnboarding(setup: $0) }
}

#Preview("Clipper · App Lock") {
    OBHost(step: .appLock) { ClipperOnboarding(setup: $0) }
}

#Preview("Clipper · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { ClipperOnboarding(setup: $0) }
}

#Preview("Clipper · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { ClipperOnboarding(setup: $0) }
}

#Preview("Clipper · Dark") {
    OBHost(step: .currency) { ClipperOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
