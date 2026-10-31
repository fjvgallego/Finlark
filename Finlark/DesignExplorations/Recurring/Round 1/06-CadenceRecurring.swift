//
//  06-CadenceRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Cadence": no glass tiles. A native inset grouped list, like Settings it's
//  reached from: what recurring adds up to each month, the pending items with swipe to confirm (right)
//  or skip (left), and the templates, with swipe to pause or resume. Tapping a pending item opens it
//  to change first.
//

#if DEBUG
import SwiftUI

struct CadenceRecurring: View {
    @Bindable var store: RCStore

    @State private var undo: RCUndo?
    @State private var reviewing: RCPending?

    var body: some View {
        Group {
            if store.templates.isEmpty {
                RCEmptyState(store: store)
            } else {
                list
                    .rcUndoToast($undo, store: store)
            }
        }
        .rcChrome(store: store)
        .sheet(item: $reviewing) { RCConfirmSheet(store: store, item: $0) }
    }

    private var list: some View {
        List {
            Section {
                RCMonthlyFigures(store: store)
            }

            let pending = store.pending
            Section {
                if pending.isEmpty {
                    Label("All caught up", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(.secondary)
                }
                ForEach(pending) { item in
                    Button { reviewing = item } label: {
                        RCPendingInfo(store: store, item: item)
                            .foregroundStyle(Color.primary)
                    }
                    .swipeActions(edge: .leading) {
                        Button("Confirm", systemImage: "checkmark") { undo = store.confirm(item) }
                            .tint(.green)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Skip", systemImage: "forward.end") { undo = store.skip(item) }
                            .tint(.gray)
                    }
                }
            } header: {
                Text("Pending")
            } footer: {
                if !pending.isEmpty {
                    Text("Swipe right to confirm or left to skip. Tap one to change it first.")
                }
            }

            templates("Active", store.active)
            templates("Paused", store.paused)
        }
        .listStyle(.insetGrouped)
    }

    @ViewBuilder
    private func templates(_ title: LocalizedStringKey, _ templates: [RCTemplate]) -> some View {
        if !templates.isEmpty {
            Section(title) {
                ForEach(templates) { template in
                    NavigationLink(value: RCRoute.template(template.id)) {
                        RCTemplateRow(store: store, template: template, showsChevron: false)
                    }
                    .swipeActions(edge: .trailing) {
                        Button(template.isPaused ? "Resume" : "Pause", systemImage: template.isPaused ? "play" : "pause") {
                            store.setPaused(!template.isPaused, for: template.id)
                        }
                        .tint(.indigo)
                    }
                }
            }
        }
    }
}

#Preview("Cadence") {
    RCHost { CadenceRecurring(store: $0) }
}

#Preview("Cadence · Caught up") {
    RCHost(store: .caughtUp) { CadenceRecurring(store: $0) }
}

#Preview("Cadence · Dark") {
    RCHost { CadenceRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
