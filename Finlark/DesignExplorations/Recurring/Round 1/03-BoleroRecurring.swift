//
//  03-BoleroRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Bolero": pending items stay out of the list. A glass bar pinned above the
//  tab bar says how many wait and what they add up to, and Review goes through them one at a time:
//  Skip, Confirm, or change it first. The review also offers Confirm All, which the requirements don't
//  have. The templates are grouped by how often they repeat.
//

#if DEBUG
import SwiftUI

struct BoleroRecurring: View {
    @Bindable var store: RCStore

    @State private var isReviewing = false

    var body: some View {
        RCScreen(store: store) { _ in
            if store.pending.isEmpty {
                RCCaughtUp(store: store)
            }
            ForEach(RCFrequency.allCases) { frequency in
                RCTemplateList(
                    store: store,
                    title: frequency.title,
                    symbol: "repeat",
                    templates: store.active.filter { $0.frequency == frequency }
                )
            }
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        } pinned: { _ in
            if !store.pending.isEmpty {
                BoleroBar(store: store) { isReviewing = true }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $isReviewing) {
            BoleroReview(store: store)
        }
    }
}

/// People's Financier bar: the count and total leading, Review trailing.
private struct BoleroBar: View {
    let store: RCStore
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(spacing: 12))
        layout {
            VStack(alignment: .leading, spacing: 0) {
                Text("^[\(store.pending.count) item](inflect: true) to confirm")
                    .font(.headline)
                Text(store.pendingTotal, format: .currency(code: store.code).sign(strategy: .always()))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .accessibilityElement(children: .combine)
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            Button(action: action) {
                Label("Review", systemImage: "checklist")
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 20)
        .padding(.trailing, 8)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
    }
}

/// One pending item at a time, oldest first, as a large card.
private struct BoleroReview: View {
    let store: RCStore

    @State private var total: Int
    @State private var editing: RCPending?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(store: RCStore) {
        self.store = store
        _total = State(initialValue: store.pending.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let item = store.pending.first, let template = store.template(item.templateID) {
                    ScrollView {
                        VStack(spacing: 20) {
                            let done = total - store.pending.count
                            VStack(spacing: 6) {
                                ProgressView(value: Double(done), total: Double(max(total, 1)))
                                Text("\(done + 1) of \(total)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            .accessibilityElement(children: .combine)
                            card(item, template)
                        }
                        .padding()
                    }
                    .safeAreaInset(edge: .bottom) {
                        buttons(item)
                    }
                } else {
                    ContentUnavailableView {
                        Label("All Caught Up", systemImage: "checkmark.seal")
                    } description: {
                        Text("Every pending item is confirmed or skipped.")
                    } actions: {
                        Button("Done") { dismiss() }
                            .buttonStyle(.glassProminent)
                            .controlSize(.large)
                    }
                }
            }
            .background { R2Backdrop() }
            .navigationTitle("Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                if store.pending.count > 1 {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Confirm All") { _ = store.confirmAll() }
                    }
                }
            }
            .sheet(item: $editing) { RCConfirmSheet(store: store, item: $0) }
        }
        .environment(\.explorationIconStyle, .soft)
    }

    private func card(_ item: RCPending, _ template: RCTemplate) -> some View {
        R2Tile(padding: 24) {
            VStack(spacing: 10) {
                ExplorationCategoryIcon(category: template.category)
                    .scaleEffect(1.4)
                    .padding(.vertical, 8)
                Text(verbatim: template.title)
                    .font(.title2.weight(.semibold))
                RCFormat.amount(template, code: store.code)
                    .font(.largeTitle.weight(.bold))
                    .monospacedDigit()
                VStack(spacing: 2) {
                    RCFormat.due(item)
                    RCFormat.schedule(template)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }

    private func buttons(_ item: RCPending) -> some View {
        VStack(spacing: 10) {
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: 10))
                : AnyLayout(HStackLayout(spacing: 10))
            layout {
                Button { store.skip(item) } label: {
                    Label("Skip", systemImage: "forward.end")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                Button { store.confirm(item) } label: {
                    Label("Confirm", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
            Button("Change Before Confirming", systemImage: "pencil") { editing = item }
                .buttonStyle(.borderless)
        }
        .controlSize(.large)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

#Preview("Bolero") {
    RCHost { BoleroRecurring(store: $0) }
}

#Preview("Bolero · Caught up") {
    RCHost(store: .caughtUp) { BoleroRecurring(store: $0) }
}

#Preview("Bolero · Dark") {
    RCHost { BoleroRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
