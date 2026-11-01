//
//  05-SchoonerOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Schooner": one decision per screen, with big targets. The currency is a
//  guess to confirm ("Use Euro"), the balance is typed on Finlark's own keypad (as in Add & edit) with
//  a plus-minus key, and App Lock is one big choice. A last "You're all set" screen shows what was
//  made, including the categories, before Home opens.
//

#if DEBUG
import SwiftUI

struct SchoonerOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var step: OBStep
    @State private var choosingCurrency = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(setup: OBSetup) {
        self.setup = setup
        _step = State(initialValue: max(setup.startStep, .currency))
    }

    var body: some View {
        Group {
            if setup.stage == .restoring {
                restoring
            } else {
                page
                    .id(step)
                    .transition(reduceMotion ? .opacity : .asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            }
        }
        .background { R2Backdrop() }
        .animation(.smooth(duration: 0.4), value: step)
        .sheet(isPresented: $choosingCurrency) {
            OBCurrencySheet(setup: setup)
        }
    }

    @ViewBuilder
    private var page: some View {
        switch step {
        case .welcome, .currency:
            LKCentered {
                VStack(spacing: 24) {
                    SchoonerTitle(text: Text("Your currency"))
                    VStack(spacing: 12) {
                        Text(verbatim: setup.currencySymbol)
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundStyle(.tint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                            .accessibilityHidden(true)
                        Text(verbatim: setup.currencyName)
                            .font(.title2.bold())
                        Text(verbatim: setup.currencyCode)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    Text(OBText.currencyHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
            } bottom: {
                VStack(spacing: 10) {
                    OBPrimaryButton(text: Text("Use \(setup.currencyName)")) { step = .balance }
                    OBSecondaryButton("Choose Another") { choosingCurrency = true }
                }
            }
        case .balance:
            VStack(spacing: 16) {
                SchoonerBack { step = .currency }
                // The keypad keeps its place, so at accessibility sizes the question and the amount
                // scroll above it.
                if dynamicTypeSize.isAccessibilitySize {
                    ScrollView {
                        balanceHeader
                    }
                } else {
                    Spacer(minLength: 0)
                    balanceHeader
                    Spacer(minLength: 0)
                }
                AEKeypad(text: $setup.balanceText, fractionDigits: setup.fractionDigits)
                OBPrimaryButton("Continue") { step = .appLock }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        case .appLock:
            LKCentered {
                VStack(spacing: 20) {
                    OBLockSymbol(setup: setup, size: 88)
                    SchoonerTitle(text: OBText.lockTitle(setup))
                    OBLockNote(setup: setup)
                }
                .multilineTextAlignment(.center)
            } bottom: {
                OBLockActions(setup: setup) { step = .done }
            }
            .safeAreaInset(edge: .top) {
                SchoonerBack { step = .balance }
                    .padding(.horizontal, 24)
            }
        case .done:
            LKCentered {
                VStack(spacing: 24) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .accessibilityHidden(true)
                    SchoonerTitle(text: Text("You're all set"))
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 12) {
                            SchoonerFact(symbol: STItem.account.symbol, title: Text(verbatim: setup.accountName)) {
                                Text(setup.startingBalance, format: .currency(code: setup.currencyCode))
                                    .monospacedDigit()
                            }
                            Divider()
                            SchoonerFact(symbol: setup.biometry.symbol, title: Text("App Lock")) {
                                if setup.appLock {
                                    Text("On")
                                } else {
                                    Text("Off")
                                }
                            }
                            Divider()
                            SchoonerFact(symbol: STItem.categories.symbol, title: Text("Categories")) {
                                Text(setup.categories.count, format: .number)
                            }
                            OBCategoryIcons(setup: setup, size: 26)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                }
                .multilineTextAlignment(.center)
            } bottom: {
                OBPrimaryButton("Open Finlark", action: setup.finish)
            }
        }
    }

    private var balanceHeader: some View {
        VStack(spacing: 16) {
            SchoonerTitle(text: Text(OBText.balanceQuestion))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            OBAmountText(setup: setup, baseSize: 60)
            OBSignButton(setup: setup)
        }
        .frame(maxWidth: .infinity)
    }

    private var restoring: some View {
        LKCentered {
            OBRestoringContent()
        } bottom: {
            OBSecondaryButton(OBText.newUser, action: setup.continueAsNewUser)
        }
    }
}

private struct SchoonerTitle: View {
    let text: Text

    var body: some View {
        text
            .font(.largeTitle.bold())
            .accessibilityAddTraits(.isHeader)
    }
}

private struct SchoonerBack: View {
    let action: () -> Void

    var body: some View {
        HStack {
            Button("Back", systemImage: "chevron.left", action: action)
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
            Spacer()
        }
    }
}

private struct SchoonerFact<Value: View>: View {
    let symbol: String
    let title: Text
    @ViewBuilder let value: Value

    var body: some View {
        HStack(spacing: 12) {
            STIcon(symbol, color: .indigo)
            title
                .frame(maxWidth: .infinity, alignment: .leading)
            value
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Schooner") {
    OBHost { SchoonerOnboarding(setup: $0) }
}

#Preview("Schooner · Balance") {
    OBHost(step: .balance) { SchoonerOnboarding(setup: $0) }
}

#Preview("Schooner · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { SchoonerOnboarding(setup: $0) }
}

#Preview("Schooner · All Set") {
    OBHost(step: .done) { SchoonerOnboarding(setup: $0) }
}

#Preview("Schooner · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { SchoonerOnboarding(setup: $0) }
}

#Preview("Schooner · Dark") {
    OBHost(step: .appLock) { SchoonerOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
