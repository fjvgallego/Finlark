//
//  06-DoryOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Dory": you see what you're making. A card at the top shows the account
//  as Home will show it, and it updates as you answer: the currency, the balance as you type it, the
//  lock. The question for each step sits under it. It ties every answer to the result, so the starting
//  balance reads as "my balance", not an abstract number.
//

#if DEBUG
import SwiftUI

struct DoryOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var step: OBStep
    @State private var choosingCurrency = false

    @FocusState private var amountFocused: Bool

    init(setup: OBSetup) {
        self.setup = setup
        _step = State(initialValue: min(max(setup.startStep, .currency), .appLock))
    }

    var body: some View {
        if setup.stage == .restoring {
            DoryRestoring(setup: setup)
        } else {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        DoryPreview(setup: setup, step: step)
                        question
                            .id(step)
                            .transition(.opacity)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom) {
                    actions
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
                .background { R2Backdrop() }
                .navigationTitle("Your Account")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if step > .currency {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Back", systemImage: "chevron.left") {
                                step = OBStep(rawValue: step.rawValue - 1) ?? .currency
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        OBProgress(step: step.rawValue, count: 3)
                            .padding(.horizontal, 8)
                    }
                }
                .animation(.smooth(duration: 0.35), value: step)
                .sheet(isPresented: $choosingCurrency) {
                    OBCurrencySheet(setup: setup)
                }
                .onChange(of: step) { _, step in
                    amountFocused = step == .balance
                }
                .onAppear {
                    amountFocused = step == .balance
                }
            }
        }
    }

    @ViewBuilder
    private var question: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch step {
            case .currency:
                Text(OBText.currencyQuestion)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(OBText.currencyHint)
                    .foregroundStyle(.secondary)
            case .balance:
                Text(OBText.balanceQuestion)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        OBAmountField(setup: setup, focus: $amountFocused, baseSize: 36)
                        Divider()
                        OBOverdrawnToggle(setup: setup)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            default:
                OBText.lockTitle(setup)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                OBLockNote(setup: setup)
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch step {
        case .currency:
            VStack(spacing: 10) {
                OBPrimaryButton(text: Text("Use \(setup.currencyName)")) { step = .balance }
                OBSecondaryButton("Choose Another") { choosingCurrency = true }
            }
        case .balance:
            OBPrimaryButton("Continue") { step = .appLock }
        default:
            OBLockActions(setup: setup, next: setup.finish)
        }
    }
}

/// The account as Home will show it. The part the current step sets is highlighted.
private struct DoryPreview: View {
    let setup: OBSetup
    let step: OBStep

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label {
                        Text(verbatim: setup.accountName)
                    } icon: {
                        Image(systemName: STItem.account.symbol)
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    Spacer()
                    if setup.appLock {
                        Image(systemName: "lock.fill")
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("App Lock on"))
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Text(setup.startingBalance, format: .currency(code: setup.currencyCode))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .contentTransition(.numericText())
                        .animation(.smooth, value: setup.balanceText)
                        .padding(4)
                        .background(highlight(.balance), in: .rect(cornerRadius: 10))
                }
                let chips = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
                    : AnyLayout(HStackLayout(spacing: 8))
                chips {
                    DoryChip(isHighlighted: step == .currency) {
                        Text(verbatim: "\(setup.currencySymbol) \(setup.currencyCode)")
                    }
                    DoryChip(isHighlighted: step == .appLock) {
                        Label {
                            if setup.appLock {
                                Text("Locked")
                            } else {
                                Text("Not locked")
                            }
                        } icon: {
                            Image(systemName: setup.appLock ? "lock.fill" : "lock.open")
                        }
                    }
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private func highlight(_ part: OBStep) -> Color {
        step == part ? Color.accentColor.opacity(0.14) : .clear
    }
}

private struct DoryChip<Content: View>: View {
    let isHighlighted: Bool
    @ViewBuilder let content: Content

    var body: some View {
        content
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isHighlighted ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12), in: .capsule)
            .foregroundStyle(isHighlighted ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
    }
}

private struct DoryRestoring: View {
    let setup: OBSetup

    var body: some View {
        LKCentered {
            R2Tile(padding: 24) {
                OBRestoringContent()
                    .frame(maxWidth: .infinity)
            }
            .fixedSize(horizontal: false, vertical: true)
        } bottom: {
            OBSecondaryButton(OBText.newUser, action: setup.continueAsNewUser)
        }
        .background { R2Backdrop() }
    }
}

#Preview("Dory") {
    OBHost { DoryOnboarding(setup: $0) }
}

#Preview("Dory · Balance") {
    OBHost(step: .balance) { DoryOnboarding(setup: $0) }
}

#Preview("Dory · App Lock") {
    OBHost(step: .appLock) { DoryOnboarding(setup: $0) }
}

#Preview("Dory · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { DoryOnboarding(setup: $0) }
}

#Preview("Dory · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { DoryOnboarding(setup: $0) }
}

#Preview("Dory · Dark") {
    OBHost(step: .balance) { DoryOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
