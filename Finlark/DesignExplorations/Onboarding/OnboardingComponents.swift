//
//  OnboardingComponents.swift
//  Finlark
//
//  FIN-9 Onboarding: pieces shared by the onboarding explorations (ONB-001…005). Each variant takes a
//  new user through the home currency, the starting balance and App Lock, and shows its own take on
//  "Restoring from iCloud…" for a returning one. The host runs the rest: the mocked iCloud restore,
//  the mocked Face ID prompt when App Lock is turned on, and Marsh once onboarding is done, with the
//  new account's balance and nothing else yet. The default categories (Appendix A) are made on finish
//  (ONB-004), so variants can show them but not change them.
//

#if DEBUG
import SwiftUI

// MARK: - Model

/// Where the app is: restoring from iCloud, setting up, or on Home.
enum OBStage {
    case restoring
    case setup
    /// Onboarding is done: Home with the new account.
    case finished
    /// The iCloud data arrived: Home with it, and no onboarding (ONB-005).
    case restored
}

/// The steps a variant can open on, so a preview can start part way through. Variants that merge steps
/// open on the screen that holds the step.
enum OBStep: Int, Comparable {
    case welcome
    case currency
    case balance
    case appLock
    case done

    static func < (lhs: OBStep, rhs: OBStep) -> Bool { lhs.rawValue < rhs.rawValue }
}

extension OBStep: Identifiable {
    var id: Self { self }
}

enum OBScenario {
    case newUser
    case touchID
    /// An iPhone without a passcode: App Lock can't be turned on (ONB-003, SEC-001).
    case noPasscode
    /// iCloud already has Finlark data. It arrives after the delay, or never, so a preview can stay on
    /// the restoring screen.
    case restoring(arrivesAfter: Duration?)
    /// Someone continued as a new user while restoring, and the iCloud data arrives after the delay,
    /// so they choose which to keep (ONB-005).
    case dataArrivesLater(after: Duration)
}

@Observable
final class OBSetup {
    var stage: OBStage
    let startStep: OBStep

    /// Starts as the device locale's currency (ONB-001).
    private(set) var currencyCode: String
    /// The starting balance as typed, without its sign, so it never passes through floating point
    /// (NFR-005). Empty means zero.
    var balanceText = ""
    /// The starting balance can be negative (ONB-002).
    var isOverdrawn = false

    var appLock = false
    let biometry: STBiometry
    /// Mocked: the real app asks LocalAuthentication.
    let hasDevicePasscode: Bool
    /// The system's Face ID prompt is up while App Lock is turned on.
    private(set) var isConfirmingLock = false

    /// The iCloud data arrived after "Continue as New User": keep it or this setup (ONB-005).
    var isChoosingData = false
    /// Keeping this setup replaces the iCloud data everywhere, so it's confirmed first.
    var isConfirmingReplace = false

    let restoreDelay: Duration?

    init(scenario: OBScenario, startStep: OBStep = .welcome) {
        self.startStep = startStep
        currencyCode = Self.deviceCurrencyCode
        switch scenario {
        case .newUser:
            stage = .setup
            biometry = .faceID
            hasDevicePasscode = true
            restoreDelay = nil
        case .touchID:
            stage = .setup
            biometry = .touchID
            hasDevicePasscode = true
            restoreDelay = nil
        case .noPasscode:
            stage = .setup
            biometry = .passcode
            hasDevicePasscode = false
            restoreDelay = nil
        case .restoring(let delay):
            stage = .restoring
            biometry = .faceID
            hasDevicePasscode = true
            restoreDelay = delay
        case .dataArrivesLater(let delay):
            stage = .setup
            biometry = .faceID
            hasDevicePasscode = true
            restoreDelay = delay
        }
    }

    static var deviceCurrencyCode: String { Locale.current.currency?.identifier ?? "EUR" }

    var fractionDigits: Int { AEMoney.fractionDigits(for: currencyCode) }

    var startingBalance: Decimal {
        let amount = AEMoney.parse(balanceText) ?? 0
        return isOverdrawn ? -amount : amount
    }

    var currencyName: String {
        Locale.current.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
    }

    var currencySymbol: String { AEMoney.affix(for: currencyCode).symbol }

    /// Face ID, Touch ID or the passcode lock, crossed out when the iPhone has no passcode.
    var lockSymbol: String { hasDevicePasscode ? biometry.symbol : "lock.slash.fill" }

    /// The account onboarding creates (ONB-002). It can be renamed in Settings (ACC-002).
    var accountName: String { String(localized: "Main account") }

    /// The default categories onboarding creates (ONB-004, Appendix A).
    var categories: [CTCategory] { CTStore.fresh.categories }

    func chooseCurrency(_ code: String) {
        currencyCode = code
        // A currency with fewer decimals, like JPY, trims what was typed.
        balanceText = AEMoney.sanitize(balanceText, fractionDigits: fractionDigits)
    }

    /// Mocked: the real app asks for Face ID once, which also shows iOS's permission alert the first
    /// time, and turns App Lock on only if that passes.
    func turnOnLock(then next: @escaping () -> Void = {}) {
        guard hasDevicePasscode, !isConfirmingLock else { return }
        isConfirmingLock = true
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            isConfirmingLock = false
            appLock = true
            try? await Task.sleep(for: .seconds(0.3))
            next()
        }
    }

    /// For switches: on asks Face ID first, off is immediate.
    var lockBinding: Binding<Bool> {
        Binding(
            get: { self.appLock },
            set: { isOn in
                if isOn {
                    self.turnOnLock()
                } else {
                    self.appLock = false
                }
            }
        )
    }

    func continueAsNewUser() {
        stage = .setup
    }

    /// Mocked: the real app learns this from CloudKit. While restoring, Home opens with the data. After
    /// "Continue as New User", the person chooses which to keep.
    func iCloudDataArrived() {
        switch stage {
        case .restoring: stage = .restored
        case .setup, .finished: isChoosingData = true
        case .restored: break
        }
    }

    func useICloudData() {
        stage = .restored
    }

    func finish() {
        stage = .finished
    }

    /// Home right after onboarding: the starting balance and nothing else yet.
    var homeSnapshot: ExplorationHomeSnapshot {
        let calendar = Calendar.current
        return ExplorationHomeSnapshot(
            currencyCode: currencyCode,
            balance: startingBalance,
            monthIncome: 0,
            spendingByCategory: [],
            plan: nil,
            owedToYou: 0,
            owedPeopleCount: 0,
            pendingItems: [],
            recentTransactions: [],
            dailySpending: [],
            dayOfMonth: calendar.component(.day, from: .now),
            daysInMonth: calendar.range(of: .day, in: .month, for: .now)?.count ?? 30
        )
    }
}

// MARK: - Host

/// Runs a variant: its restoring screen and steps, then Marsh. The Face ID prompt stand-in shows over
/// everything while App Lock is turned on, and the choice between the iCloud data and this setup shows
/// as system alerts wherever the person is when the data arrives (ONB-005).
struct OBHost<Flow: View>: View {
    @State private var setup: OBSetup
    private let flow: (OBSetup) -> Flow

    init(_ scenario: OBScenario = .newUser, step: OBStep = .welcome, @ViewBuilder flow: @escaping (OBSetup) -> Flow) {
        _setup = State(initialValue: OBSetup(scenario: scenario, startStep: step))
        self.flow = flow
    }

    var body: some View {
        ZStack {
            switch setup.stage {
            case .restoring, .setup:
                flow(setup)
            case .finished:
                MarshHomeView(snapshot: setup.homeSnapshot, debtors: [])
                    .transition(.opacity)
            case .restored:
                MarshHomeView()
                    .transition(.opacity)
            }
        }
        .overlay {
            if setup.isConfirmingLock {
                LKSystemPromptStandIn(biometry: setup.biometry)
            }
        }
        .animation(.smooth(duration: 0.4), value: setup.stage)
        .animation(.smooth(duration: 0.25), value: setup.isConfirmingLock)
        .alert("Your iCloud Data Is Here", isPresented: $setup.isChoosingData) {
            Button("Use iCloud Data", action: setup.useICloudData)
            Button("Keep This Setup") { setup.isConfirmingReplace = true }
        } message: {
            Text("Use the Finlark data from your iCloud instead of what you set up on this iPhone, or keep this setup and replace the data in iCloud.")
        }
        .alert("Replace Your iCloud Data?", isPresented: $setup.isConfirmingReplace) {
            // Mocked: the real app deletes the iCloud data and uploads this setup.
            Button("Replace", role: .destructive) {}
            Button("Cancel", role: .cancel) { setup.isChoosingData = true }
        } message: {
            Text("This deletes the Finlark data in your iCloud and on your other devices, and saves this setup instead. It can't be undone.")
        }
        .task {
            guard let delay = setup.restoreDelay else { return }
            try? await Task.sleep(for: delay)
            setup.iCloudDataArrived()
        }
    }
}

// MARK: - Brand

/// Clove's gradient, so onboarding and the lock screen are the same front door.
struct OBBrandBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.indigo, Color.indigo.mix(with: .teal, by: 0.4).mix(with: .black, by: 0.2)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

/// The bird and the wordmark, as on Clove. The bird is decoration and stops growing past the largest
/// standard text size.
struct OBWordmark: View {
    var birdSize: CGFloat = 68

    var body: some View {
        VStack(spacing: 12) {
            OBBird(size: birdSize)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Text(verbatim: "Finlark")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .accessibilityAddTraits(.isHeader)
        }
    }
}

private struct OBBird: View {
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat) {
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        Image(systemName: "bird.fill")
            .font(.system(size: size, weight: .semibold))
            .accessibilityHidden(true)
    }
}

/// What Finlark is about, in three lines (vision): spending apart from balance, splits, privacy.
struct OBHighlights: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OBHighlight(
                symbol: "chart.pie.fill",
                title: "What you spend",
                text: "Your share of a split is spending. The rest is money friends owe you."
            )
            OBHighlight(
                symbol: "person.2.fill",
                title: "Who owes you",
                text: "Split a bill and see each repayment come back to your balance."
            )
            OBHighlight(
                symbol: "lock.shield.fill",
                title: "Yours alone",
                text: "Your data stays on your iPhone and in your iCloud. No accounts, no tracking."
            )
        }
    }
}

private struct OBHighlight: View {
    let symbol: String
    let title: LocalizedStringKey
    let text: LocalizedStringKey

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 14) {
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: symbol)
                    .font(.title2)
                    .frame(width: 32)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.subheadline)
                    .opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Buttons and progress

extension EnvironmentValues {
    /// On the brand gradient the main button is clear glass, as Clove's unlock button is: a prominent
    /// button in the gradient's own blue would disappear.
    @Entry var obPrimaryIsGlass = false
}

/// The step's main action, full width.
struct OBPrimaryButton: View {
    let title: Text
    var systemImage: String?
    let action: () -> Void

    @Environment(\.obPrimaryIsGlass) private var isGlass

    init(_ title: LocalizedStringKey, systemImage: String? = nil, action: @escaping () -> Void) {
        self.init(text: Text(title), systemImage: systemImage, action: action)
    }

    init(text: Text, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = text
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        let button = Button(action: action) {
            Group {
                if let systemImage {
                    Label { title } icon: { Image(systemName: systemImage) }
                } else {
                    title
                }
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)

        if isGlass {
            button
                .buttonStyle(.glass)
                .fontWeight(.semibold)
        } else {
            button.buttonStyle(.glassProminent)
        }
    }
}

/// A quieter action under the main one, like "Not Now".
struct OBSecondaryButton: View {
    let title: LocalizedStringKey
    let action: () -> Void

    init(_ title: LocalizedStringKey, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(title, action: action)
            .buttonStyle(.glass)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
    }
}

/// Step dots as short bars. VoiceOver hears "Step 2 of 3".
struct OBProgress: View {
    let step: Int
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1...count, id: \.self) { index in
                Capsule()
                    .fill(index <= step ? AnyShapeStyle(.tint) : AnyShapeStyle(.fill.secondary))
                    .frame(width: index == step ? 22 : 8, height: 8)
            }
        }
        .animation(.smooth, value: step)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(step) of \(count)"))
    }
}

// MARK: - Restoring (ONB-005)

enum OBText {
    static let restoringTitle: LocalizedStringKey = "Restoring from iCloud…"
    static let restoringMessage: LocalizedStringKey = "Your Finlark data is on its way from iCloud. Home opens as soon as it's here."
    static let newUser: LocalizedStringKey = "Continue as New User"
    static let balanceQuestion: LocalizedStringKey = "How much is in your account now?"
    static let balanceHint: LocalizedStringKey = "Your balance starts here. You can correct it later in Settings."
    static let currencyQuestion: LocalizedStringKey = "Which currency do you use?"
    static let currencyHint: LocalizedStringKey = "Every amount in Finlark uses it. You can change it until you add your first transaction."
    static let lockQuestion: LocalizedStringKey = "Lock Finlark?"
    static let categoriesReady: LocalizedStringKey = "Categories are ready to use. You can change them any time in Settings."

    /// Without a device passcode there's nothing to lock with, so the title says what's missing.
    static func lockTitle(_ setup: OBSetup) -> Text {
        if setup.hasDevicePasscode {
            Text("Lock Finlark with \(Text(setup.biometry.title))")
        } else {
            Text("App Lock needs an iPhone passcode")
        }
    }

    static func turnOn(_ biometry: STBiometry) -> Text {
        Text("Turn On \(Text(biometry.title))")
    }
}

/// The cloud, the title, the message and a spinner. Variants place it and add "Continue as New User".
struct OBRestoringContent: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            OBRestoringSymbol(reduceMotion: reduceMotion)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            Text(OBText.restoringTitle)
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text(OBText.restoringMessage)
                .font(.body)
                .foregroundStyle(.secondary)
            ProgressView()
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
    }
}

private struct OBRestoringSymbol: View {
    let reduceMotion: Bool
    @ScaledMetric private var size: CGFloat = 56

    var body: some View {
        Image(systemName: "icloud.and.arrow.down.fill")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(.tint)
            .symbolEffect(.pulse, isActive: !reduceMotion)
            .accessibilityHidden(true)
    }
}

// MARK: - Currency (ONB-001)

/// The currency's symbol, name and code.
struct OBCurrencyLabel: View {
    let setup: OBSetup
    @ScaledMetric private var symbolSize: CGFloat = 44

    var body: some View {
        HStack(spacing: 14) {
            Text(verbatim: setup.currencySymbol)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(.tint)
                .frame(width: symbolSize, height: symbolSize)
                .background(.tint.opacity(0.14), in: .rect(cornerRadius: symbolSize * 0.3, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: setup.currencyName)
                    .font(.headline)
                Text(verbatim: setup.currencyCode)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Every common ISO 4217 currency, searchable, with the device's currency suggested first (ONB-001).
/// Picking one goes back.
struct OBCurrencyList: View {
    let setup: OBSetup

    @State private var query = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            if query.isEmpty {
                Section("Suggested") {
                    row(code: OBSetup.deviceCurrencyCode)
                }
            }
            Section(query.isEmpty ? "All Currencies" : "Results") {
                ForEach(currencies, id: \.self) { code in
                    row(code: code)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background { R2Backdrop() }
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search currencies")
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(code: String) -> some View {
        let isSelected = code == setup.currencyCode
        return Button {
            setup.chooseCurrency(code)
            dismiss()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: Self.name(code))
                    Text(verbatim: "\(code) · \(AEMoney.affix(for: code).symbol)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .tint(.primary)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private static func name(_ code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    private var currencies: [String] {
        // Common codes only: the full ISO list includes historical and fund codes nobody pays with.
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = Locale.commonISOCurrencyCodes.filter { code in
            trimmed.isEmpty || code.localizedStandardContains(trimmed) || Self.name(code).localizedStandardContains(trimmed)
        }
        return matching.sorted { Self.name($0).localizedStandardCompare(Self.name($1)) == .orderedAscending }
    }
}

/// The list in a sheet of its own, for variants that don't push.
struct OBCurrencySheet: View {
    let setup: OBSetup
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            OBCurrencyList(setup: setup)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                    }
                }
        }
    }
}

// MARK: - Starting balance (ONB-002)

/// The big amount, typed with the decimal pad, with a minus sign in front when it's overdrawn.
struct OBAmountField: View {
    @Bindable var setup: OBSetup
    var focus: FocusState<Bool>.Binding
    var baseSize: CGFloat = 52
    /// Red when overdrawn. Off on the brand gradient, where red doesn't have the contrast.
    var tintsNegative = true

    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1

    var body: some View {
        let affix = AEMoney.affix(for: setup.currencyCode)
        let size = min(baseSize * scale, baseSize * 1.5)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if setup.isOverdrawn {
                Text(verbatim: "−")
                    .accessibilityHidden(true)
            }
            if affix.isLeading { symbol(affix.symbol, size: size) }
            TextField("Starting balance", text: $setup.balanceText, prompt: Text(verbatim: "0"))
                .keyboardType(.decimalPad)
                .focused(focus)
                .fixedSize()
                .accessibilityValue(Text(setup.startingBalance, format: .currency(code: setup.currencyCode)))
            if !affix.isLeading { symbol(affix.symbol, size: size) }
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .monospacedDigit()
        .foregroundStyle(tintsNegative && setup.isOverdrawn ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
        .onChange(of: setup.balanceText) { _, newValue in
            let clean = AEMoney.sanitize(newValue, fractionDigits: setup.fractionDigits)
            if clean != newValue { setup.balanceText = clean }
        }
    }

    private func symbol(_ symbol: String, size: CGFloat) -> some View {
        Text(verbatim: symbol)
            .font(.system(size: size * 0.6, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
}

/// Whether the account is below zero. A switch, since the decimal pad has no minus key.
struct OBOverdrawnToggle: View {
    @Bindable var setup: OBSetup

    var body: some View {
        Toggle(isOn: $setup.isOverdrawn) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Overdrawn")
                Text("The account is below zero")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - App lock (ONB-003)

/// What App Lock does, or why it can't be turned on without a device passcode (SEC-001).
struct OBLockNote: View {
    let setup: OBSetup

    var body: some View {
        Group {
            if setup.hasDevicePasscode {
                Text("Finlark asks when you open it and after a minute away. Your passcode works too. You can change this any time in Settings.")
            } else {
                Text("To use App Lock, set a passcode for your iPhone in the Settings app. You can turn it on later in Finlark's Settings.")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

/// The big Face ID, Touch ID or lock glyph, crossed out when there's no passcode.
struct OBLockSymbol: View {
    let setup: OBSetup
    var size: CGFloat = 64

    var body: some View {
        OBLockGlyph(symbol: setup.lockSymbol, isOn: setup.appLock, size: size)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct OBLockGlyph: View {
    let symbol: String
    let isOn: Bool
    @ScaledMetric private var size: CGFloat

    init(symbol: String, isOn: Bool, size: CGFloat) {
        self.symbol = symbol
        self.isOn = isOn
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: .light))
            .foregroundStyle(.tint)
            .overlay(alignment: .bottomTrailing) {
                if isOn {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size * 0.38, weight: .semibold))
                        .foregroundStyle(.white, .green)
                        .offset(x: size * 0.12, y: size * 0.08)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .accessibilityHidden(true)
    }
}

/// Turn On or Not Now, Continue once it's on, or just Continue without a passcode. Turning it on asks
/// Face ID once, then moves on.
struct OBLockActions: View {
    @Bindable var setup: OBSetup
    let next: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            if !setup.hasDevicePasscode {
                OBPrimaryButton("Continue", action: next)
            } else if setup.appLock {
                OBPrimaryButton("Continue", action: next)
                OBSecondaryButton("Turn Off") { setup.appLock = false }
            } else {
                OBPrimaryButton(text: OBText.turnOn(setup.biometry), systemImage: setup.biometry.symbol) {
                    setup.turnOnLock(then: next)
                }
                OBSecondaryButton("Not Now", action: next)
            }
        }
    }
}
#endif
