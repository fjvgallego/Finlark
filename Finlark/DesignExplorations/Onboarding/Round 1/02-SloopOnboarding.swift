//
//  02-SloopOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Sloop": one screen. Every question is a glass tile on Marsh's backdrop,
//  already answered with a sensible default: the device's currency, a zero balance, App Lock off. The
//  categories that come with Finlark sit at the end. Change what you like and start. The fastest way
//  in, and everything is in view at once.
//

#if DEBUG
import SwiftUI

struct SloopOnboarding: View {
    @Bindable var setup: OBSetup

    @FocusState private var amountFocused: Bool

    var body: some View {
        if setup.stage == .restoring {
            SloopRestoring(setup: setup)
        } else {
            NavigationStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: r2TileSpacing) {
                            header
                            currencyTile
                            balanceTile
                            lockTile
                                .id(OBStep.appLock)
                            categoriesTile
                        }
                        .padding()
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onAppear {
                        if setup.startStep >= .appLock {
                            proxy.scrollTo(OBStep.appLock, anchor: .center)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    OBPrimaryButton("Start Using Finlark", action: setup.finish)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
                .background { R2Backdrop() }
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        Button("Done", systemImage: "checkmark") { amountFocused = false }
                    }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            LKMark(size: 56)
            Text("Set Up Finlark")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text("Check these three, and you're in.")
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var currencyTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Currency", symbol: STItem.currency.symbol)
                NavigationLink {
                    OBCurrencyList(setup: setup)
                } label: {
                    HStack {
                        OBCurrencyLabel(setup: setup)
                        R2Chevron()
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Shows every currency."))
                Text(OBText.currencyHint)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var balanceTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Starting Balance", symbol: "banknote.fill")
                Text(OBText.balanceQuestion)
                    .font(.headline)
                OBAmountField(setup: setup, focus: $amountFocused, baseSize: 40)
                Divider()
                OBOverdrawnToggle(setup: setup)
            }
        }
    }

    private var lockTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Privacy", symbol: "hand.raised.fill")
                OBLockToggle(setup: setup)
                OBLockNote(setup: setup)
                    .font(.footnote)
            }
        }
    }

    private var categoriesTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                R2TileHeader(title: "Categories", symbol: STItem.categories.symbol)
                OBCategoryIcons(setup: setup, size: 30)
                Text(OBText.categoriesReady)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SloopRestoring: View {
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

#Preview("Sloop") {
    OBHost { SloopOnboarding(setup: $0) }
}

#Preview("Sloop · App Lock") {
    OBHost(step: .appLock) { SloopOnboarding(setup: $0) }
}

#Preview("Sloop · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { SloopOnboarding(setup: $0) }
}

#Preview("Sloop · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { SloopOnboarding(setup: $0) }
}

#Preview("Sloop · Dark") {
    OBHost { SloopOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
