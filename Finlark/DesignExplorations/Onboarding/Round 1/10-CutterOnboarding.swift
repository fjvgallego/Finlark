//
//  10-CutterOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Cutter": two screens, keyboard first. The first asks for the balance with
//  the keyboard already up, and the currency is a button right next to the amount, since they're read
//  together ("€1,250"). The second asks about App Lock. Plain type on the system background, no tiles:
//  the quickest look, and the least to read.
//

#if DEBUG
import SwiftUI

struct CutterOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var asksLock: Bool
    @State private var choosingCurrency = false

    @FocusState private var amountFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(setup: OBSetup) {
        self.setup = setup
        _asksLock = State(initialValue: setup.startStep >= .appLock)
    }

    var body: some View {
        Group {
            if setup.stage == .restoring {
                restoring
            } else if asksLock {
                lock
                    .transition(reduceMotion ? .opacity : .move(edge: .trailing))
            } else {
                balance
                    .transition(reduceMotion ? .opacity : .move(edge: .leading))
            }
        }
        .background(Color(.systemBackground))
        .animation(.smooth(duration: 0.35), value: asksLock)
        .sheet(isPresented: $choosingCurrency) {
            OBCurrencySheet(setup: setup)
        }
    }

    private var balance: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label {
                    Text(verbatim: "Finlark")
                        .font(.headline)
                } icon: {
                    Image(systemName: "bird.fill")
                }
                .foregroundStyle(.indigo)
                .padding(.top, 24)

                Text(OBText.balanceQuestion)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)

                OBAmountField(setup: setup, focus: $amountFocused, baseSize: 56)

                HStack(spacing: 8) {
                    Button {
                        choosingCurrency = true
                    } label: {
                        Label {
                            Text(verbatim: setup.currencyCode)
                        } icon: {
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .labelStyle(CutterTrailingIcon())
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(Text("Currency"))
                    .accessibilityValue(Text(verbatim: setup.currencyName))
                    OBSignButton(setup: setup)
                }

                Text("Every amount uses \(setup.currencyName). Your balance starts here, and you can correct it later in Settings.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDismissesKeyboard(.never)
        .safeAreaInset(edge: .bottom) {
            OBPrimaryButton("Continue") { asksLock = true }
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
        }
        .onAppear { amountFocused = true }
    }

    private var lock: some View {
        LKCentered(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 20) {
                Button("Back", systemImage: "chevron.left") { asksLock = false }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.glass)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .padding(.top, 8)
                OBText.lockTitle(setup)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                OBLockNote(setup: setup)
                    .font(.body)
            }
        } bottom: {
            OBLockActions(setup: setup, next: setup.finish)
        }
    }

    private var restoring: some View {
        LKCentered(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 20) {
                Label {
                    Text(verbatim: "Finlark")
                        .font(.headline)
                } icon: {
                    Image(systemName: "bird.fill")
                }
                .foregroundStyle(.indigo)
                .padding(.top, 24)
                Text(OBText.restoringTitle)
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(OBText.restoringMessage)
                    .foregroundStyle(.secondary)
                ProgressView()
            }
        } bottom: {
            OBSecondaryButton(OBText.newUser, action: setup.continueAsNewUser)
        }
    }
}

private struct CutterTrailingIcon: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
                .font(.caption.weight(.semibold))
        }
    }
}

#Preview("Cutter") {
    OBHost { CutterOnboarding(setup: $0) }
}

#Preview("Cutter · App Lock") {
    OBHost(step: .appLock) { CutterOnboarding(setup: $0) }
}

#Preview("Cutter · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { CutterOnboarding(setup: $0) }
}

#Preview("Cutter · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { CutterOnboarding(setup: $0) }
}

#Preview("Cutter · Dark") {
    OBHost { CutterOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
