//
//  SettingsModel.swift
//  Finlark
//
//  FIN-9 Settings: mock data for the Settings explorations (SET-001). One object holds what Settings
//  shows and changes: the account (ACC-002), the home currency (A-07), notifications (NTF-004), app lock
//  (SEC-001), the iCloud status (SYN-002) and the delete-all flow (SEC-003). It also owns the Categories
//  and Recurring stores, so their rows show live counts and the screens they push are the chosen ones.
//

#if DEBUG
import SwiftUI

/// What iCloud is doing, as Settings reports it (SYN-002).
enum STSyncStatus: CaseIterable, Identifiable {
    case upToDate
    case syncing
    case offline
    case signedOut

    var id: Self { self }

    var title: LocalizedStringKey {
        switch self {
        case .upToDate: "Up to date"
        case .syncing: "Syncing…"
        case .offline: "Waiting for a connection"
        case .signedOut: "Not signed in to iCloud"
        }
    }

    var symbol: String {
        switch self {
        case .upToDate: "checkmark.icloud.fill"
        case .syncing: "arrow.triangle.2.circlepath.icloud.fill"
        case .offline: "icloud.slash.fill"
        case .signedOut: "exclamationmark.icloud.fill"
        }
    }

    var color: Color {
        switch self {
        case .upToDate: .green
        case .syncing: .blue
        case .offline, .signedOut: .orange
        }
    }

    /// What it means for the data, in a sentence.
    var explanation: LocalizedStringKey {
        switch self {
        case .upToDate: "Your data is in your iCloud and on every iPhone signed in to it."
        case .syncing: "Sending and receiving changes. You can keep using Finlark."
        case .offline: "Finlark works fully without a connection. Changes sync when it's back."
        case .signedOut: "Finlark works fully on this iPhone. Sign in to iCloud in the Settings app to sync and keep a copy."
        }
    }

    var needsAttention: Bool { self == .signedOut }
}

/// The unlock method this iPhone has (SEC-001). Mocked: the real app asks LocalAuthentication.
enum STBiometry {
    case faceID
    case touchID
    case passcode

    var title: LocalizedStringKey {
        switch self {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .passcode: "Passcode"
        }
    }

    var symbol: String {
        switch self {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .passcode: "lock.fill"
        }
    }
}

/// Whether iOS lets Finlark notify. It's asked the first time it's needed, not at launch (NTF-004).
enum STNotificationPermission {
    case notAsked
    case allowed
    case denied
}

@Observable
final class STSettings {
    var accountName: String
    var startingBalance: Decimal
    var currencyCode: String
    /// While it's zero the home currency can change (A-07).
    var transactionCount: Int
    var peopleCount: Int

    var notifiesRecurringDue: Bool
    var notifiesIOU: Bool
    /// N in NTF-002: 1–60 days, 7 by default.
    var iouReminderDays: Int
    var permission: STNotificationPermission

    var appLock: Bool
    let biometry: STBiometry

    var sync: STSyncStatus
    var lastSynced: Date

    let categories: CTStore
    let recurring: RCStore

    /// Set by Delete All Data: the app goes back to onboarding (SEC-003).
    var isErased = false

    static let iouDayRange = 1...60

    init(
        accountName: String,
        startingBalance: Decimal,
        currencyCode: String,
        transactionCount: Int,
        peopleCount: Int,
        notifiesRecurringDue: Bool = true,
        notifiesIOU: Bool = true,
        iouReminderDays: Int = 7,
        permission: STNotificationPermission,
        appLock: Bool,
        biometry: STBiometry = .faceID,
        sync: STSyncStatus,
        lastSynced: Date = .now.addingTimeInterval(-120),
        categories: CTStore,
        recurring: RCStore
    ) {
        self.accountName = accountName
        self.startingBalance = startingBalance
        self.currencyCode = currencyCode
        self.transactionCount = transactionCount
        self.peopleCount = peopleCount
        self.notifiesRecurringDue = notifiesRecurringDue
        self.notifiesIOU = notifiesIOU
        self.iouReminderDays = iouReminderDays
        self.permission = permission
        self.appLock = appLock
        self.biometry = biometry
        self.sync = sync
        self.lastSynced = lastSynced
        self.categories = categories
        self.recurring = recurring
    }

    var canChangeCurrency: Bool { transactionCount == 0 }

    var activeCategoryCount: Int {
        categories.categories.filter { !$0.isArchived }.count
    }

    /// The categories a row can show as a preview: the most used first.
    var leadingCategories: [CTCategory] {
        categories.categories
            .filter { !$0.isArchived }
            .sorted { $0.transactionCount > $1.transactionCount }
    }

    var nextRecurring: (template: RCTemplate, date: Date)? {
        recurring.active
            .compactMap { template in recurring.nextDate(for: template).map { (template, $0) } }
            .min { $0.1 < $1.1 }
    }

    /// How many notification types are on, out of two.
    var notificationsOnCount: Int {
        [notifiesRecurringDue, notifiesIOU].filter { $0 }.count
    }

    var currencyName: String {
        Locale.current.localizedString(forCurrencyCode: currencyCode) ?? currencyCode
    }

    func eraseAllData() {
        isErased = true
    }
}

// MARK: - Samples

extension STSettings {
    /// A year in: transactions logged, so the currency is fixed, and everything set up.
    static var sample: STSettings {
        STSettings(
            accountName: String(localized: "Main account"),
            startingBalance: Decimal(string: "1250.00") ?? 0,
            currencyCode: "EUR",
            transactionCount: 248,
            peopleCount: 4,
            permission: .allowed,
            appLock: true,
            sync: .upToDate,
            categories: .sample,
            recurring: .sample
        )
    }

    /// Just after onboarding: no transactions, so the currency can still change, and nothing asked yet.
    static var fresh: STSettings {
        STSettings(
            accountName: String(localized: "Main account"),
            startingBalance: 0,
            currencyCode: Locale.current.currency?.identifier ?? "EUR",
            transactionCount: 0,
            peopleCount: 0,
            permission: .notAsked,
            appLock: false,
            sync: .syncing,
            categories: .fresh,
            recurring: .empty
        )
    }

    /// Things to fix: signed out of iCloud and notifications turned off in iOS.
    static var needsAttention: STSettings {
        let settings = sample
        settings.sync = .signedOut
        settings.permission = .denied
        settings.appLock = false
        return settings
    }
}
#endif
