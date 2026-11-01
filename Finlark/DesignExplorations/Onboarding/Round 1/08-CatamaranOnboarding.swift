//
//  08-CatamaranOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Catamaran": pages you can swipe. A welcome and the three questions are
//  side by side, each with a large soft icon, and a bar at the bottom holds the step dots and Next.
//  Swiping back to change an answer is natural, and the welcome reads as part of the flow rather than
//  a door in front of it.
//

#if DEBUG
import SwiftUI

struct CatamaranOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var page: OBStep
    @State private var choosingCurrency = false

    @FocusState private var amountFocused: Bool

    init(setup: OBSetup) {
        self.setup = setup
        _page = State(initialValue: min(setup.startStep, .appLock))
    }

    var body: some View {
        if setup.stage == .restoring {
            CatamaranRestoring(setup: setup)
        } else {
            TabView(selection: $page) {
                CatamaranPage(symbol: "bird.fill", color: .indigo, title: Text("Welcome to Finlark")) {
                    OBHighlights()
                }
                .tag(OBStep.welcome)

                CatamaranPage(symbol: STItem.currency.symbol, color: STItem.currency.color, title: Text(OBText.currencyQuestion)) {
                    Button {
                        choosingCurrency = true
                    } label: {
                        R2Tile(padding: 18) {
                            HStack {
                                OBCurrencyLabel(setup: setup)
                                Text("Change")
                                    .foregroundStyle(.tint)
                            }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Shows every currency."))
                    Text(OBText.currencyHint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .tag(OBStep.currency)

                CatamaranPage(symbol: "banknote.fill", color: .green, title: Text(OBText.balanceQuestion)) {
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 14) {
                            OBAmountField(setup: setup, focus: $amountFocused, baseSize: 40)
                            Divider()
                            OBOverdrawnToggle(setup: setup)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Text(OBText.balanceHint)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .tag(OBStep.balance)

                CatamaranPage(symbol: setup.lockSymbol, color: STItem.appLock.color, title: OBText.lockTitle(setup)) {
                    OBLockNote(setup: setup)
                }
                .tag(OBStep.appLock)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) {
                bar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            .background { R2Backdrop() }
            .animation(.smooth, value: page)
            .sheet(isPresented: $choosingCurrency) {
                OBCurrencySheet(setup: setup)
            }
            .onChange(of: page) { _, page in
                amountFocused = page == .balance
            }
        }
    }

    @ViewBuilder
    private var bar: some View {
        VStack(spacing: 16) {
            OBProgress(step: page.rawValue + 1, count: 4)
            if page == .appLock {
                OBLockActions(setup: setup, next: setup.finish)
            } else {
                OBPrimaryButton(page == .welcome ? "Get Started" : "Next") {
                    page = OBStep(rawValue: page.rawValue + 1) ?? .appLock
                }
            }
        }
    }
}

/// A page: a large soft icon, the title, and the page's content, scrolling at large text sizes.
private struct CatamaranPage<Content: View>: View {
    let symbol: String
    let color: Color
    let title: Text
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        LKCentered(alignment: .top) {
            VStack(alignment: .leading, spacing: 20) {
                if !dynamicTypeSize.isAccessibilitySize {
                    STIcon(symbol, color: color, size: 88)
                        .padding(.top, 24)
                }
                title
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                content
            }
        }
    }
}

private struct CatamaranRestoring: View {
    let setup: OBSetup

    var body: some View {
        LKCentered {
            OBRestoringContent()
        } bottom: {
            OBSecondaryButton(OBText.newUser, action: setup.continueAsNewUser)
        }
        .background { R2Backdrop() }
    }
}

#Preview("Catamaran") {
    OBHost { CatamaranOnboarding(setup: $0) }
}

#Preview("Catamaran · Currency") {
    OBHost(step: .currency) { CatamaranOnboarding(setup: $0) }
}

#Preview("Catamaran · App Lock") {
    OBHost(.touchID, step: .appLock) { CatamaranOnboarding(setup: $0) }
}

#Preview("Catamaran · No Passcode") {
    OBHost(.noPasscode, step: .appLock) { CatamaranOnboarding(setup: $0) }
}

#Preview("Catamaran · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { CatamaranOnboarding(setup: $0) }
}

#Preview("Catamaran · Dark") {
    OBHost(step: .balance) { CatamaranOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
