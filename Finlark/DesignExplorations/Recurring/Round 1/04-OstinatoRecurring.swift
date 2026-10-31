//
//  04-OstinatoRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Ostinato": Marsh's segmented control switches between what's pending and
//  every template, so each view stays short. Pending items are cards with People's wide Skip and
//  Confirm. A template opens straight in the editor, with Delete at its bottom; a long press offers
//  Pause and Delete too. No template screen.
//

#if DEBUG
import SwiftUI

struct OstinatoRecurring: View {
    private enum Panel: Hashable {
        case pending
        case all
    }

    @Bindable var store: RCStore

    @State private var panel: Panel = .pending
    @State private var editing: RCTemplate?
    @State private var deleting: RCTemplate?

    var body: some View {
        RCScreen(store: store) { actions in
            let pending = store.pending
            R6SegmentedControl(
                title: "Show",
                options: [(value: .pending, label: "Pending (\(pending.count))"), (value: .all, label: "All (\(store.templates.count))")],
                selection: $panel
            )
            .padding(.bottom, 4)

            switch panel {
            case .pending:
                if pending.isEmpty {
                    RCCaughtUp(store: store)
                }
                ForEach(pending) { item in
                    R2Tile(padding: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            Button { actions.review(item) } label: {
                                RCPendingInfo(store: store, item: item)
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
                            RCPendingButtons(store: store, item: item, actions: actions)
                        }
                    }
                }
            case .all:
                templates("Active", symbol: "repeat", store.active)
                templates("Paused", symbol: "pause.fill", store.paused)
            }
        }
        .sheet(item: $editing) { template in
            RCEditor(store: store, template: template) { store.delete(template.id) }
        }
        .rcDeleteDialog(
            isPresented: Binding { deleting != nil } set: { if !$0 { deleting = nil } },
            title: deleting?.title ?? ""
        ) {
            if let deleting { store.delete(deleting.id) }
        }
    }

    @ViewBuilder
    private func templates(_ title: LocalizedStringKey, symbol: String, _ templates: [RCTemplate]) -> some View {
        if !templates.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: title, symbol: symbol)
                    ForEach(templates) { template in
                        Button { editing = template } label: {
                            RCTemplateRow(store: store, template: template)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(Text("Opens it to edit."))
                        .contextMenu {
                            Button(template.isPaused ? "Resume" : "Pause", systemImage: template.isPaused ? "play" : "pause") {
                                store.setPaused(!template.isPaused, for: template.id)
                            }
                            Button("Delete Recurring", systemImage: "trash", role: .destructive) {
                                deleting = template
                            }
                        }
                        if template.id != templates.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

#Preview("Ostinato") {
    RCHost { OstinatoRecurring(store: $0) }
}

#Preview("Ostinato · Caught up") {
    RCHost(store: .caughtUp) { OstinatoRecurring(store: $0) }
}

#Preview("Ostinato · Dark") {
    RCHost { OstinatoRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
