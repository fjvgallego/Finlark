//
//  SettingsComponents.swift
//  Finlark
//
//  FIN-9 Settings: pieces shared by the Settings explorations (SET-001). Settings is Marsh's third tab,
//  so the host is Marsh's tab bar with Settings selected. It pushes the chosen Categories (Velvet) and
//  Recurring (Moderato) screens. Shared here: the screen around each variant (title, account editor,
//  delete-all flow), rows and controls, the screens a variant can push (account, currency,
//  notifications, app lock, iCloud, about), and the stand-in for onboarding after Delete All Data.
//  Marsh's look throughout: the tinted backdrop, glass tiles, soft icons, and the system's Liquid Glass
//  for actions.
//

#if DEBUG
import SwiftUI

// MARK: - Host

enum STRoute: Hashable {
    case categories
    case recurring
    case account
    case currency
    case notifications
    case security
    case sync
    case about
    case acknowledgements
}

/// What a preview opens once Settings appears.
enum STOpening {
    case accountEditor
    case deleteAll
}

extension EnvironmentValues {
    @Entry var stOpening: STOpening? = nil
}

/// Marsh's tab bar with Settings selected. After Delete All Data, onboarding's stand-in replaces it.
struct STHost<Root: View>: View {
    private enum AppTab: Hashable {
        case home
        case history
        case settings
    }

    @State private var settings: STSettings
    @State private var selection: AppTab = .settings
    @State private var path: [STRoute]
    private let opening: STOpening?
    private let root: (STSettings) -> Root

    init(
        settings: STSettings = .sample,
        path: [STRoute] = [],
        opening: STOpening? = nil,
        @ViewBuilder root: @escaping (STSettings) -> Root
    ) {
        _settings = State(initialValue: settings)
        _path = State(initialValue: path)
        self.opening = opening
        self.root = root
    }

    var body: some View {
        if settings.isErased {
            STOnboardingStandIn {
                path = []
                settings = .sample
            }
        } else {
            TabView(selection: $selection) {
                Tab("Home", systemImage: "house", value: AppTab.home) {
                    ContentUnavailableView {
                        Label("Home", systemImage: "house")
                    } description: {
                        Text("Marsh isn't part of the Settings exploration.")
                    }
                }
                Tab("History", systemImage: "clock.arrow.circlepath", value: AppTab.history) {
                    ContentUnavailableView {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text("Lyra isn't part of the Settings exploration.")
                    }
                }
                Tab("Settings", systemImage: "gearshape", value: AppTab.settings) {
                    NavigationStack(path: $path) {
                        root(settings)
                            .environment(\.stOpening, opening)
                            .navigationDestination(for: STRoute.self) { route in
                                STDestination(settings: settings, route: route)
                            }
                            .navigationDestination(for: RCRoute.self) { route in
                                switch route {
                                case .recurring: ModeratoRecurring(store: settings.recurring)
                                case .template(let id): RCTemplateScreen(store: settings.recurring, id: id)
                                }
                            }
                    }
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .environment(\.explorationIconStyle, .soft)
        }
    }
}

/// The screens Settings pushes. Categories and Recurring are the owner's picks.
private struct STDestination: View {
    let settings: STSettings
    let route: STRoute

    var body: some View {
        switch route {
        case .categories: VelvetCategories(store: settings.categories)
        case .recurring: ModeratoRecurring(store: settings.recurring)
        case .account: STAccountScreen(settings: settings)
        case .currency: STCurrencyScreen(settings: settings)
        case .notifications: STNotificationsScreen(settings: settings)
        case .security: STSecurityScreen(settings: settings)
        case .sync: STSyncScreen(settings: settings)
        case .about: STAboutScreen()
        case .acknowledgements: STAcknowledgementsScreen()
        }
    }
}

/// Delete All Data sends the app back to onboarding (SEC-003). Yawl isn't wired in here.
private struct STOnboardingStandIn: View {
    let restart: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Welcome to Finlark", systemImage: "sparkles")
        } description: {
            Text("All data was deleted, so Finlark starts over with onboarding. Onboarding isn't part of the Settings exploration.")
        } actions: {
            Button("Bring Back the Sample Data", action: restart)
                .buttonStyle(.glass)
        }
        .background { HMBackdrop() }
    }
}

// MARK: - Screen

/// What a variant's controls can do besides pushing a screen.
struct STActions {
    /// Opens the account editor: name and starting balance (ACC-002).
    let editAccount: () -> Void
    /// Starts Delete All Data (SEC-003).
    let deleteAll: () -> Void
}

/// The screen around a variant: a scroll view of its tiles, the inline title, the account editor and
/// the delete-all flow.
struct STScreen<Content: View>: View {
    let settings: STSettings
    /// False when the content brings its own scrolling container, such as a List.
    var scrolls = true
    @ViewBuilder let content: (STActions) -> Content

    @State private var editingAccount = false
    @State private var deleting = false
    @State private var didOpen = false
    @Environment(\.stOpening) private var opening

    var body: some View {
        let actions = STActions(
            editAccount: { editingAccount = true },
            deleteAll: { deleting = true }
        )

        Group {
            if scrolls {
                ScrollView {
                    VStack(spacing: hmTileSpacing) {
                        content(actions)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                content(actions)
            }
        }
        .background { HMBackdrop() }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $editingAccount) {
            STAccountSheet(settings: settings)
        }
        .sheet(isPresented: $deleting) {
            STDeleteSheet(settings: settings)
        }
        .onAppear {
            guard !didOpen else { return }
            didOpen = true
            switch opening {
            case .accountEditor: editingAccount = true
            case .deleteAll: deleting = true
            case nil: break
            }
        }
    }
}

/// A pushed screen: the backdrop, tiles in a scroll view, an inline title.
struct STPage<Content: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: hmTileSpacing) {
                content
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background { HMBackdrop() }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Rows

/// A soft icon: the symbol in its color on a tint of it, like the category icons.
struct STIcon: View {
    let symbol: String
    let color: Color
    @ScaledMetric private var size: CGFloat

    init(_ symbol: String, color: Color, size: CGFloat = 30) {
        self.symbol = symbol
        self.color = color
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.16), in: .rect(cornerRadius: size * 0.3, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Every setting's icon and color, so variants agree.
enum STItem {
    case account
    case currency
    case categories
    case recurring
    case notifications
    case appLock
    case sync
    case about
    case delete

    var symbol: String {
        switch self {
        case .account: "building.columns.fill"
        case .currency: "coloncurrencysign.circle.fill"
        case .categories: "square.grid.2x2.fill"
        case .recurring: "repeat"
        case .notifications: "bell.badge.fill"
        case .appLock: "lock.fill"
        case .sync: "icloud.fill"
        case .about: "info.circle.fill"
        case .delete: "trash.fill"
        }
    }

    var color: Color {
        switch self {
        case .account: .indigo
        case .currency: .green
        case .categories: .orange
        case .recurring: .purple
        case .notifications: .red
        case .appLock: .blue
        case .sync: .cyan
        case .about: .gray
        case .delete: .red
        }
    }

    var title: LocalizedStringKey {
        switch self {
        case .account: "Account"
        case .currency: "Home Currency"
        case .categories: "Categories"
        case .recurring: "Recurring"
        case .notifications: "Notifications"
        case .appLock: "App Lock"
        case .sync: "iCloud"
        case .about: "About"
        case .delete: "Delete All Data"
        }
    }
}

/// A row's content: icon, title with an optional subtitle, and a value on the trailing edge. At
/// accessibility sizes the value moves under the title so nothing truncates.
struct STRow<Value: View>: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color
    var subtitle: Text?
    var showsChevron = true
    @ViewBuilder var value: Value

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            if !dynamicTypeSize.isAccessibilitySize {
                STIcon(symbol, color: color)
            }
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
                : AnyLayout(HStackLayout(spacing: 8))
            layout {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                    if let subtitle {
                        subtitle
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if !dynamicTypeSize.isAccessibilitySize {
                    Spacer(minLength: 8)
                }
                value
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(dynamicTypeSize.isAccessibilitySize ? .leading : .trailing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if showsChevron {
                HMChevron()
            }
        }
        .padding(.vertical, 2)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

extension STRow where Value == EmptyView {
    init(title: LocalizedStringKey, symbol: String, color: Color, subtitle: Text? = nil, showsChevron: Bool = true) {
        self.init(title: title, symbol: symbol, color: color, subtitle: subtitle, showsChevron: showsChevron) {
            EmptyView()
        }
    }
}

extension STRow {
    init(_ item: STItem, subtitle: Text? = nil, showsChevron: Bool = true, @ViewBuilder value: () -> Value) {
        self.init(title: item.title, symbol: item.symbol, color: item.color, subtitle: subtitle, showsChevron: showsChevron, value: value)
    }
}

extension STRow where Value == EmptyView {
    init(_ item: STItem, subtitle: Text? = nil, showsChevron: Bool = true) {
        self.init(title: item.title, symbol: item.symbol, color: item.color, subtitle: subtitle, showsChevron: showsChevron) {
            EmptyView()
        }
    }
}

/// A row that pushes a screen, drawn plain so glass tiles keep their own look.
struct STLink<Label: View>: View {
    let route: STRoute
    @ViewBuilder let label: Label

    var body: some View {
        NavigationLink(value: route) {
            label
        }
        .buttonStyle(.plain)
    }
}

/// A toggle with a soft icon and an optional line under the title.
struct STToggle: View {
    let title: LocalizedStringKey
    let symbol: String
    let color: Color
    var subtitle: Text?
    @Binding var isOn: Bool

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 12) {
                if !dynamicTypeSize.isAccessibilitySize {
                    STIcon(symbol, color: color)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let subtitle {
                        subtitle
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Values

/// Shared wording for what rows show, so variants say the same thing.
enum STText {
    /// "Main account · €1,250.00"
    static func account(_ settings: STSettings) -> Text {
        Text("\(settings.accountName) · \(settings.startingBalance, format: .currency(code: settings.currencyCode))")
    }

    static func startingBalance(_ settings: STSettings) -> Text {
        Text(settings.startingBalance, format: .currency(code: settings.currencyCode))
    }

    /// "Euro (EUR)"
    static func currency(_ settings: STSettings) -> Text {
        Text(verbatim: "\(settings.currencyName) (\(settings.currencyCode))")
    }

    /// "12 categories"
    static func categories(_ settings: STSettings) -> Text {
        Text("^[\(settings.activeCategoryCount) category](inflect: true)")
    }

    /// "6 recurring" or "None yet"
    static func recurring(_ settings: STSettings) -> Text {
        let count = settings.recurring.templates.count
        return count == 0 ? Text("None yet") : Text("\(count) recurring")
    }

    /// "Rent · In 3 days"
    static func nextRecurring(_ settings: STSettings) -> Text? {
        guard let next = settings.nextRecurring else { return nil }
        return Text("\(next.template.title) · \(RCFormat.relative(next.date))")
    }

    /// "Both on", "1 of 2 on", "Off", or "Off in iOS Settings"
    static func notifications(_ settings: STSettings) -> Text {
        if settings.permission == .denied { return Text("Off in iOS Settings") }
        return switch settings.notificationsOnCount {
        case 2: Text("On")
        case 0: Text("Off")
        default: Text("\(settings.notificationsOnCount) of 2 on")
        }
    }

    /// "Face ID" or "Off"
    static func appLock(_ settings: STSettings) -> Text {
        settings.locksApp ? Text(settings.biometry.title) : Text("Off")
    }

    /// "After 7 days"
    static func iouDays(_ settings: STSettings) -> Text {
        Text("After ^[\(settings.iouReminderDays) day](inflect: true)")
    }

    /// When recurring notifications fire (NTF-001), shown in the user's time format.
    static var nineAM: Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: .now) ?? .now
    }

    static func version() -> Text {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return Text("Version \(version) (\(build))")
    }
}

/// The iCloud status with its icon, so it isn't color alone (SYN-002).
struct STSyncLabel: View {
    let settings: STSettings
    var showsLastSynced = true

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(settings.sync.title)
                if showsLastSynced, settings.sync == .upToDate {
                    Text("Synced \(settings.lastSynced, format: .relative(presentation: .named))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            Image(systemName: settings.sync.symbol)
                .foregroundStyle(settings.sync.color)
                .symbolRenderingMode(.hierarchical)
        }
    }
}

// MARK: - Controls

/// The two notification types and the IOU reminder delay (NTF-001, NTF-002, NTF-004).
struct STNotificationControls: View {
    @Bindable var settings: STSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            STPermissionNote(settings: settings)
            // Off while iOS doesn't allow them, so the switches don't promise what can't happen.
            VStack(alignment: .leading, spacing: 12) {
                STToggle(
                    title: "Recurring due",
                    symbol: "repeat",
                    color: STItem.recurring.color,
                    subtitle: Text("When a pending item is due, at \(STText.nineAM, format: .dateTime.hour().minute())."),
                    isOn: $settings.notifiesRecurringDue
                )
                Divider()
                STToggle(
                    title: "IOU reminders",
                    symbol: "person.2.fill",
                    color: .teal,
                    subtitle: Text("When a share is still unpaid."),
                    isOn: $settings.notifiesIOU
                )
                STIOUDaysStepper(settings: settings)
                    .disabled(!settings.notifiesIOU)
            }
            .disabled(settings.permission == .denied)
        }
    }
}

/// "After 7 days", 1–60 (NTF-002).
struct STIOUDaysStepper: View {
    @Bindable var settings: STSettings

    var body: some View {
        Stepper(value: $settings.iouReminderDays, in: STSettings.iouDayRange) {
            VStack(alignment: .leading, spacing: 2) {
                STText.iouDays(settings)
                    .monospacedDigit()
                Text("From the split's date")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(Text("IOU reminder delay"))
        .accessibilityValue(STText.iouDays(settings))
    }
}

/// What iOS allows: a way to iOS Settings when notifications are off there, a line on when Finlark asks
/// when it hasn't yet (NTF-004). Nothing when they're allowed.
struct STPermissionNote: View {
    let settings: STSettings

    @Environment(\.openURL) private var openURL

    var body: some View {
        switch settings.permission {
        case .allowed:
            EmptyView()
        case .notAsked:
            Label("Finlark asks to notify you the first time you add a recurring item or a split.", systemImage: "info.circle")
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Label("Notifications are off for Finlark in the Settings app.", systemImage: "bell.slash.fill")
                    .font(.subheadline.weight(.medium))
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        openURL(url)
                    }
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }
        }
    }
}

/// App lock with what it does (SEC-001, SEC-002, A-14). Without a device passcode the switch is off and
/// disabled, and a note says what to do. The note shows even where the footnote doesn't, and sits
/// outside the disabled switch so it isn't dimmed.
struct STAppLockControl: View {
    @Bindable var settings: STSettings
    var showsFootnote = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            STToggle(
                title: "App Lock",
                symbol: settings.biometry.symbol,
                color: STItem.appLock.color,
                subtitle: subtitle,
                isOn: Binding(
                    get: { settings.locksApp },
                    set: { settings.appLock = $0 }
                )
            )
            .disabled(!settings.hasDevicePasscode)
            if !settings.hasDevicePasscode || showsFootnote {
                STAppLockFootnote(settings: settings)
            }
        }
    }

    private var subtitle: Text {
        if settings.hasDevicePasscode {
            Text("Use \(Text(settings.biometry.title)) to open Finlark")
        } else {
            Text("Needs an iPhone passcode")
        }
    }
}

struct STAppLockFootnote: View {
    let settings: STSettings

    var body: some View {
        Group {
            if settings.hasDevicePasscode {
                Text("Finlark asks when you open it and after a minute away. Your passcode works too. In the app switcher, Finlark hides your data.")
            } else {
                Text("To use App Lock, set a passcode for your iPhone in the Settings app.")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

/// "Delete All Data" in red, with its icon (SEC-003).
struct STDeleteButton: View {
    let action: () -> Void

    var body: some View {
        Button(role: .destructive, action: action) {
            Label("Delete All Data", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glass)
        .controlSize(.large)
        .tint(.red)
    }
}

/// The privacy policy isn't published yet (NFR-007), so this is a stand-in address.
let stPrivacyPolicyURL = URL(string: "https://example.com/finlark/privacy")!

/// Version, privacy policy and acknowledgements, as rows.
struct STAboutRows: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            STRow(title: "Version", symbol: "app.badge.fill", color: .gray, showsChevron: false) {
                STText.version()
            }
            Divider()
            Link(destination: stPrivacyPolicyURL) {
                STRow(title: "Privacy Policy", symbol: "hand.raised.fill", color: .blue, showsChevron: false) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption.weight(.semibold))
                        .accessibilityHidden(true)
                }
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Opens in Safari."))
            Divider()
            STLink(route: .acknowledgements) {
                STRow(title: "Acknowledgements", symbol: "heart.fill", color: .pink)
            }
        }
    }
}

// MARK: - Account

/// Name and starting balance, edited as a draft and saved together (ACC-002).
struct STAccountSheet: View {
    let settings: STSettings

    @State private var name: String
    @State private var startingBalance: Decimal
    @Environment(\.dismiss) private var dismiss

    init(settings: STSettings) {
        self.settings = settings
        _name = State(initialValue: settings.accountName)
        _startingBalance = State(initialValue: settings.startingBalance)
    }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: hmTileSpacing) {
                    HMTile(padding: 18) {
                        STAccountFields(name: $name, startingBalance: $startingBalance, code: settings.currencyCode)
                    }
                    STStartingBalanceFootnote()
                }
                .padding()
            }
            .background { HMBackdrop() }
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        settings.accountName = trimmedName
                        settings.startingBalance = startingBalance
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// The two account fields. The starting balance can be zero or negative (ONB-002).
struct STAccountFields: View {
    @Binding var name: String
    @Binding var startingBalance: Decimal
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Account name", text: $name)
                    .font(.body.weight(.semibold))
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Text("Starting balance")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                TextField("Starting balance", value: $startingBalance, format: .currency(code: code))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    // Not the decimal pad: a starting balance can be negative.
                    .keyboardType(.numbersAndPunctuation)
                    .submitLabel(.done)
            }
        }
    }
}

struct STStartingBalanceFootnote: View {
    var body: some View {
        Text("Changing the starting balance recalculates your balance. No transactions change.")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}

/// The account fields edited in place, saved as they change, with the currency under them.
struct STAccountScreen: View {
    @Bindable var settings: STSettings

    var body: some View {
        STPage(title: "Account") {
            HMTile(padding: 18) {
                STAccountFields(name: $settings.accountName, startingBalance: $settings.startingBalance, code: settings.currencyCode)
            }
            STStartingBalanceFootnote()
            HMTile(padding: 18) {
                STLink(route: .currency) {
                    STRow(.currency) {
                        Text(verbatim: settings.currencyCode)
                    }
                }
            }
        }
    }
}

// MARK: - Currency

/// The home currency: a searchable list while there are no transactions, the reason it's fixed after (A-07).
struct STCurrencyScreen: View {
    @Bindable var settings: STSettings

    @State private var query = ""

    var body: some View {
        if settings.canChangeCurrency {
            List {
                Section {
                    ForEach(currencies, id: \.code) { currency in
                        Button {
                            settings.currencyCode = currency.code
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: currency.name)
                                    Text(verbatim: currency.code)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if currency.code == settings.currencyCode {
                                    Image(systemName: "checkmark")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.tint)
                                }
                            }
                            .contentShape(.rect)
                        }
                        .tint(.primary)
                        .accessibilityAddTraits(currency.code == settings.currencyCode ? .isSelected : [])
                    }
                } footer: {
                    Text("You can change it until you add your first transaction.")
                }
            }
            .scrollContentBackground(.hidden)
            .background { HMBackdrop() }
            .searchable(text: $query, prompt: "Search currencies")
            .navigationTitle("Home Currency")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            STPage(title: "Home Currency") {
                HMTile(padding: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            STIcon(STItem.currency.symbol, color: STItem.currency.color, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: settings.currencyName)
                                    .font(.headline)
                                Text(verbatim: settings.currencyCode)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Label {
                            Text("Every amount is in \(settings.currencyCode). It can't change once there are transactions, as Finlark doesn't convert between currencies yet.")
                        } icon: {
                            Image(systemName: "lock.fill")
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var currencies: [(code: String, name: String)] {
        // Common codes only: the full ISO list includes historical and fund codes nobody pays with.
        let all = Locale.commonISOCurrencyCodes.map { code in
            (code: code, name: Locale.current.localizedString(forCurrencyCode: code) ?? code)
        }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matching = trimmed.isEmpty ? all : all.filter {
            $0.name.localizedStandardContains(trimmed) || $0.code.localizedStandardContains(trimmed)
        }
        return matching.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

// MARK: - Pushed screens

struct STNotificationsScreen: View {
    let settings: STSettings

    var body: some View {
        STPage(title: "Notifications") {
            HMTile(padding: 18) {
                STNotificationControls(settings: settings)
            }
        }
    }
}

struct STSecurityScreen: View {
    let settings: STSettings

    var body: some View {
        STPage(title: "App Lock") {
            HMTile(padding: 18) {
                STAppLockControl(settings: settings)
            }
        }
    }
}

/// iCloud's status, what it means, and Delete All Data, as both are about where the data lives.
struct STSyncScreen: View {
    let settings: STSettings

    @State private var deleting = false

    var body: some View {
        STPage(title: "iCloud and Data") {
            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    STSyncLabel(settings: settings)
                        .font(.headline)
                    Text(settings.sync.explanation)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Deletes everything from this iPhone and from iCloud, so from your other devices too.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    STDeleteButton { deleting = true }
                }
            }
        }
        .sheet(isPresented: $deleting) {
            STDeleteSheet(settings: settings)
        }
    }
}

struct STAboutScreen: View {
    var body: some View {
        STPage(title: "About") {
            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Finlark")
                        .font(.title2.weight(.bold))
                    Text("Your data stays on your iPhone and in your iCloud. No accounts, no analytics, no tracking.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HMTile(padding: 18) {
                STAboutRows()
            }
        }
    }
}

/// Stand-in text: what the acknowledgements list isn't decided.
struct STAcknowledgementsScreen: View {
    var body: some View {
        STPage(title: "Acknowledgements") {
            HMTile(padding: 18) {
                Text("Finlark is built with Apple's frameworks only: SwiftUI, SwiftData, CloudKit and Swift Charts. Icons are SF Symbols.")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Delete all data

/// Two steps (SEC-003): this sheet says what goes, then a dialog asks once more before deleting.
struct STDeleteSheet: View {
    let settings: STSettings

    @State private var confirming = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: hmTileSpacing) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.red)
                            .accessibilityHidden(true)
                        Text("Delete all data?")
                            .font(.title2.weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                        Text("Everything goes from this iPhone and from iCloud, so from your other devices too. Finlark then starts over.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 4)

                    HMTile(padding: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            HMTileHeader(title: "What's deleted", symbol: "trash")
                            Label("^[\(settings.transactionCount) transaction](inflect: true)", systemImage: "list.bullet")
                            Label("^[\(settings.categories.categories.count) category](inflect: true)", systemImage: STItem.categories.symbol)
                            Label("^[\(settings.recurring.templates.count) recurring template](inflect: true)", systemImage: STItem.recurring.symbol)
                            Label("^[\(settings.peopleCount) person](inflect: true) and their splits", systemImage: "person.2.fill")
                            Label("Your account, your Monthly Plans and these settings", systemImage: STItem.account.symbol)
                        }
                        .font(.subheadline)
                    }

                    Button(role: .destructive) {
                        confirming = true
                    } label: {
                        Text("Delete All Data")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .controlSize(.large)
                    .confirmationDialog("Delete all data?", isPresented: $confirming, titleVisibility: .visible) {
                        Button("Delete Everything", role: .destructive) {
                            dismiss()
                            settings.eraseAllData()
                        }
                    } message: {
                        Text("This can't be undone.")
                    }
                }
                .padding()
            }
            .background { HMBackdrop() }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
            }
        }
    }
}

// MARK: - Tiles

/// A glass tile per group, controls inside them, Delete All Data alone at the end. The category icons
/// and the next recurring item are optional.
struct STSettingsTiles: View {
    @Bindable var settings: STSettings
    var showsCategoryIcons = false
    var showsNextRecurring = false

    var body: some View {
        STScreen(settings: settings) { actions in
            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HMTileHeader(title: "Account", symbol: STItem.account.symbol)
                    Button(action: actions.editAccount) {
                        STRow(.account, subtitle: STText.startingBalance(settings).monospacedDigit()) {
                            Text("Edit")
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Edits the name and starting balance."))
                    Divider()
                    STLink(route: .currency) {
                        STRow(.currency) {
                            Text(verbatim: settings.currencyCode)
                        }
                    }
                }
            }

            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HMTileHeader(title: "Organize", symbol: "tray.full.fill")
                    STLink(route: .categories) {
                        if showsCategoryIcons {
                            STCategoriesRow(settings: settings)
                        } else {
                            STRow(.categories) {
                                Text(settings.activeCategoryCount, format: .number)
                            }
                        }
                    }
                    Divider()
                    STLink(route: .recurring) {
                        STRow(.recurring, subtitle: showsNextRecurring ? STText.nextRecurring(settings) : nil) {
                            Text(settings.recurring.templates.count, format: .number)
                        }
                    }
                }
            }

            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HMTileHeader(title: "Notifications", symbol: STItem.notifications.symbol)
                    STNotificationControls(settings: settings)
                }
            }

            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HMTileHeader(title: "Privacy", symbol: "hand.raised.fill")
                    STAppLockControl(settings: settings)
                    Divider()
                    STSyncLabel(settings: settings)
                    Text(settings.sync.explanation)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            HMTile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    HMTileHeader(title: "About", symbol: STItem.about.symbol)
                    STAboutRows()
                }
            }

            STDeleteButton(action: actions.deleteAll)
                .padding(.top, 8)
        }
    }
}

/// Categories with the four most used ones under the title. At
/// accessibility sizes the icons step aside and "17 categories" goes under the title instead.
struct STCategoriesRow: View {
    let settings: STSettings

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: 12) {
            if !dynamicTypeSize.isAccessibilitySize {
                STIcon(STItem.categories.symbol, color: STItem.categories.color)
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(STItem.categories.title)
                if dynamicTypeSize.isAccessibilitySize {
                    STText.categories(settings)
                        .foregroundStyle(.secondary)
                } else {
                    HStack(spacing: 4) {
                        ForEach(settings.leadingCategories.prefix(4)) { category in
                            CTBadge(symbol: category.symbol, color: category.color, size: 22)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !dynamicTypeSize.isAccessibilitySize {
                Text(settings.activeCategoryCount, format: .number)
                    .foregroundStyle(.secondary)
            }
            HMChevron()
        }
        .padding(.vertical, 2)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}
#endif
