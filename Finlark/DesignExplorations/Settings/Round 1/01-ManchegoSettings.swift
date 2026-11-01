//
//  01-ManchegoSettings.swift
//  Finlark
//
//  FIN-9 Settings, Round 1 "Manchego": the system's own grouped list, like the Settings app. Sections in
//  SET-001's order, soft icons on every row, toggles and the IOU delay right in the list, and the rest
//  one push away. The baseline the other variants are measured against.
//

#if DEBUG
import SwiftUI

struct ManchegoSettings: View {
    @Bindable var settings: STSettings

    var body: some View {
        STScreen(settings: settings, scrolls: false) { actions in
            Form {
                Section("Account") {
                    Button(action: actions.editAccount) {
                        STRow(.account) {
                            Text(verbatim: settings.accountName)
                        }
                    }
                    .tint(.primary)
                    .accessibilityHint(Text("Edits the name and starting balance."))
                    LabeledContent("Starting balance") {
                        STText.startingBalance(settings)
                            .monospacedDigit()
                    }
                    NavigationLink(value: STRoute.currency) {
                        STRow(.currency, showsChevron: false) {
                            Text(verbatim: settings.currencyCode)
                        }
                    }
                }

                Section {
                    NavigationLink(value: STRoute.categories) {
                        STRow(.categories, showsChevron: false) {
                            Text(settings.activeCategoryCount, format: .number)
                        }
                    }
                    NavigationLink(value: STRoute.recurring) {
                        STRow(.recurring, showsChevron: false) {
                            Text(settings.recurring.templates.count, format: .number)
                        }
                    }
                } header: {
                    Text("Organize")
                }

                Section {
                    STNotificationControls(settings: settings)
                } header: {
                    Text("Notifications")
                }

                Section {
                    STAppLockControl(settings: settings, showsFootnote: false)
                } header: {
                    Text("Privacy")
                } footer: {
                    STAppLockFootnote(settings: settings)
                }

                Section {
                    STSyncLabel(settings: settings)
                } header: {
                    Text("iCloud")
                } footer: {
                    Text(settings.sync.explanation)
                }

                Section("About") {
                    STAboutRows()
                }

                Section {
                    Button(role: .destructive, action: actions.deleteAll) {
                        Label("Delete All Data", systemImage: "trash")
                    }
                } footer: {
                    Text("Deletes everything from this iPhone and from iCloud.")
                }
            }
            .scrollContentBackground(.hidden)
        }
    }
}

#Preview("Manchego") {
    STHost { ManchegoSettings(settings: $0) }
}

#Preview("Manchego · Needs attention") {
    STHost(settings: .needsAttention) { ManchegoSettings(settings: $0) }
}

#Preview("Manchego · Dark") {
    STHost { ManchegoSettings(settings: $0) }
        .preferredColorScheme(.dark)
}
#endif
