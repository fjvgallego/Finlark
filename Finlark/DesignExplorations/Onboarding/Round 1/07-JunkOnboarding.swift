//
//  07-JunkOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Junk": set up inside the app. Home is already there, empty, and the
//  questions come in a sheet over it that can't be swiped away. Home's balance changes behind the
//  sheet as you answer, and when you're done the sheet goes down and you're on Home. No separate
//  onboarding world to leave. It feels light, but the sheet leaves less room for each question.
//

#if DEBUG
import SwiftUI

struct JunkOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var isPresented = true
    @State private var path: [OBStep]
    @State private var detent: PresentationDetent = .medium

    init(setup: OBSetup) {
        self.setup = setup
        _path = State(initialValue: [OBStep.balance, .appLock].filter { $0 <= setup.startStep })
    }

    var body: some View {
        Group {
            if setup.stage == .restoring {
                R2Backdrop()
            } else {
                // Rebuilt as the answers change, so the balance behind the sheet is live.
                MarshHomeView(snapshot: setup.homeSnapshot, debtors: [])
                    .id("\(setup.currencyCode) \(setup.balanceText) \(setup.isOverdrawn)")
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .sheet(isPresented: $isPresented, onDismiss: finish) {
            sheet
                .presentationDetents([.medium, .large], selection: $detent)
                .presentationBackgroundInteraction(.disabled)
                .interactiveDismissDisabled()
        }
    }

    /// The sheet also goes away when the iCloud data arrives and Home replaces this view.
    private func finish() {
        if setup.stage == .setup {
            setup.finish()
        }
    }

    @ViewBuilder
    private var sheet: some View {
        if setup.stage == .restoring {
            VStack(spacing: 24) {
                OBRestoringContent()
                OBSecondaryButton(OBText.newUser, action: setup.continueAsNewUser)
            }
            .padding(24)
        } else {
            NavigationStack(path: $path) {
                JunkStep(setup: setup, step: .currency, detent: $detent) { path.append(.balance) }
                    .navigationDestination(for: OBStep.self) { step in
                        JunkStep(setup: setup, step: step, detent: $detent) {
                            if step == .balance {
                                path.append(.appLock)
                            } else {
                                isPresented = false
                            }
                        }
                    }
            }
        }
    }
}

private struct JunkStep: View {
    @Bindable var setup: OBSetup
    let step: OBStep
    @Binding var detent: PresentationDetent
    let next: () -> Void

    @FocusState private var amountFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch step {
                case .currency:
                    NavigationLink {
                        OBCurrencyList(setup: setup)
                            .onAppear { detent = .large }
                            .onDisappear { detent = .medium }
                    } label: {
                        HStack {
                            OBCurrencyLabel(setup: setup)
                            R2Chevron()
                        }
                        .padding(16)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 20))
                    .accessibilityHint(Text("Shows every currency."))
                    Text(OBText.currencyHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                case .balance:
                    OBAmountField(setup: setup, focus: $amountFocused, baseSize: 40)
                    OBOverdrawnToggle(setup: setup)
                    Text(OBText.balanceHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                default:
                    HStack(alignment: .top, spacing: 16) {
                        OBLockSymbol(setup: setup, size: 40)
                        OBLockNote(setup: setup)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .safeAreaInset(edge: .bottom) {
            Group {
                if step == .appLock {
                    OBLockActions(setup: setup, next: next)
                } else {
                    OBPrimaryButton("Continue", action: next)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                OBProgress(step: step.rawValue, count: 3)
                    .padding(.horizontal, 8)
            }
        }
        .onAppear {
            if step == .balance { amountFocused = true }
        }
    }

    private var title: Text {
        switch step {
        case .currency: Text("Your Currency")
        case .balance: Text("Starting Balance")
        default: OBText.lockTitle(setup)
        }
    }
}

#Preview("Junk") {
    OBHost { JunkOnboarding(setup: $0) }
}

#Preview("Junk · Balance") {
    OBHost(step: .balance) { JunkOnboarding(setup: $0) }
}

#Preview("Junk · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { JunkOnboarding(setup: $0) }
}

#Preview("Junk · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { JunkOnboarding(setup: $0) }
}

#Preview("Junk · Dark") {
    OBHost(step: .appLock) { JunkOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
