//
//  09-BrigOnboarding.swift
//  Finlark
//
//  FIN-9 Onboarding, Round 1 "Brig": a checklist. One screen lists what Finlark needs, each with its
//  current answer and whether it's done, optional or ready. Tapping one opens a small sheet for it.
//  The currency starts done (the device's), the starting balance waits for you, App Lock is optional,
//  and the categories are listed as ready. Start is there once the balance is set.
//

#if DEBUG
import SwiftUI

struct BrigOnboarding: View {
    @Bindable var setup: OBSetup
    @State private var editing: OBStep?
    @State private var hasSetBalance: Bool

    init(setup: OBSetup) {
        self.setup = setup
        _hasSetBalance = State(initialValue: setup.startStep > .balance)
        _editing = State(initialValue: setup.startStep == .balance || setup.startStep == .appLock ? setup.startStep : nil)
    }

    var body: some View {
        if setup.stage == .restoring {
            BrigRestoring(setup: setup)
        } else {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: r2TileSpacing) {
                        VStack(alignment: .leading, spacing: 6) {
                            LKMark(size: 48)
                                .padding(.bottom, 6)
                            Text("Set Up Finlark")
                                .font(.largeTitle.bold())
                                .accessibilityAddTraits(.isHeader)
                            Text("Finlark needs two things to start. The rest is ready or up to you.")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 12)

                        BrigItem(symbol: STItem.currency.symbol, color: STItem.currency.color, title: Text("Currency"), status: .done, action: { editing = .currency }) {
                            Text(verbatim: "\(setup.currencyName) (\(setup.currencyCode))")
                        }
                        BrigItem(symbol: "banknote.fill", color: .green, title: Text("Starting Balance"), status: hasSetBalance ? .done : .todo, action: { editing = .balance }) {
                            if hasSetBalance {
                                Text(setup.startingBalance, format: .currency(code: setup.currencyCode))
                                    .monospacedDigit()
                            } else {
                                Text("How much is in your account now")
                            }
                        }
                        BrigItem(symbol: setup.lockSymbol, color: STItem.appLock.color, title: Text("App Lock"), status: lockStatus, action: { editing = .appLock }) {
                            if !setup.hasDevicePasscode {
                                Text("Needs an iPhone passcode")
                            } else if setup.appLock {
                                Text("On with \(Text(setup.biometry.title))")
                            } else {
                                Text("Off")
                            }
                        }
                        BrigItem(symbol: STItem.categories.symbol, color: STItem.categories.color, title: Text("Categories"), status: .ready) {
                            Text("^[\(setup.categories.count) category](inflect: true), ready to use")
                        }
                    }
                    .padding()
                }
                .safeAreaInset(edge: .bottom) {
                    OBPrimaryButton("Start Using Finlark", action: setup.finish)
                        .disabled(!hasSetBalance)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                }
                .background { R2Backdrop() }
                .sheet(item: $editing) { step in
                    BrigSheet(setup: setup, step: step) {
                        if step == .balance { hasSetBalance = true }
                        editing = nil
                    }
                }
            }
        }
    }

    private var lockStatus: BrigStatus {
        if !setup.hasDevicePasscode { return .unavailable }
        return setup.appLock ? .done : .optional
    }
}

private enum BrigStatus {
    case todo
    case done
    case optional
    case ready
    case unavailable

    var title: LocalizedStringKey {
        switch self {
        case .todo: "To do"
        case .done: "Done"
        case .optional: "Optional"
        case .ready: "Ready"
        case .unavailable: "Unavailable"
        }
    }

    var symbol: String {
        switch self {
        case .todo: "circle"
        case .done, .ready: "checkmark.circle.fill"
        case .optional: "circle.dashed"
        case .unavailable: "minus.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .todo: .orange
        case .done, .ready: .green
        case .optional, .unavailable: .secondary
        }
    }
}

/// A checklist row: icon, title, answer, and its status as a symbol and a word.
private struct BrigItem<Value: View>: View {
    let symbol: String
    let color: Color
    let title: Text
    let status: BrigStatus
    /// Nil for a row that's only information.
    let action: (() -> Void)?
    let value: Value

    init(symbol: String, color: Color, title: Text, status: BrigStatus, action: (() -> Void)? = nil, @ViewBuilder value: () -> Value) {
        self.symbol = symbol
        self.color = color
        self.title = title
        self.status = status
        self.action = action
        self.value = value()
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if let action {
            Button(action: action) { tile }
                .buttonStyle(.plain)
        } else {
            tile
        }
    }

    private var tile: some View {
        R2Tile(padding: 16) {
            HStack(spacing: 14) {
                if !dynamicTypeSize.isAccessibilitySize {
                    STIcon(symbol, color: color, size: 40)
                }
                VStack(alignment: .leading, spacing: 2) {
                    title
                        .font(.body.weight(.semibold))
                    value
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Label(status.title, systemImage: status.symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(status.color)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if action != nil {
                    R2Chevron()
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(.rect(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }
}

/// One item's editor in a sheet.
private struct BrigSheet: View {
    @Bindable var setup: OBSetup
    let step: OBStep
    let done: () -> Void

    @FocusState private var amountFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        switch step {
        case .currency:
            OBCurrencySheet(setup: setup)
        case .balance:
            NavigationStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text(OBText.balanceQuestion)
                        .font(.title2.bold())
                    OBAmountField(setup: setup, focus: $amountFocused, baseSize: 44)
                    OBOverdrawnToggle(setup: setup)
                    Text(OBText.balanceHint)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(24)
                .navigationTitle("Starting Balance")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark", role: .confirm, action: done)
                    }
                }
                .onAppear { amountFocused = true }
            }
            .presentationDetents([.medium])
        default:
            VStack(spacing: 20) {
                OBLockSymbol(setup: setup, size: 56)
                OBText.lockTitle(setup)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                OBLockNote(setup: setup)
                OBLockActions(setup: setup, next: done)
            }
            .multilineTextAlignment(.center)
            .padding(24)
            .presentationDetents([.medium])
        }
    }
}

private struct BrigRestoring: View {
    let setup: OBSetup

    var body: some View {
        LKCentered {
            VStack(spacing: 24) {
                LKMark(size: 48)
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

#Preview("Brig") {
    OBHost { BrigOnboarding(setup: $0) }
}

#Preview("Brig · Balance") {
    OBHost(step: .balance) { BrigOnboarding(setup: $0) }
}

#Preview("Brig · App Lock") {
    OBHost(step: .appLock) { BrigOnboarding(setup: $0) }
}

#Preview("Brig · No Passcode") {
    OBHost(.noPasscode, step: .done) { BrigOnboarding(setup: $0) }
}

#Preview("Brig · Restoring") {
    OBHost(.restoring(arrivesAfter: .seconds(5))) { BrigOnboarding(setup: $0) }
}

#Preview("Brig · Dark") {
    OBHost { BrigOnboarding(setup: $0) }
        .preferredColorScheme(.dark)
}
#endif
