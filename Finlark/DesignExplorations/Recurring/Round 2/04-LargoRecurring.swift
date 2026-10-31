//
//  04-LargoRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 2 "Largo": the header lays out the month as three figures side by side, Out,
//  In and the Difference, like Home's month. Each pending card is large and centered, one item filling
//  it, with its place in the queue ("1 of 4") at the top.
//

#if DEBUG
import SwiftUI

struct LargoRecurring: View {
    @Bindable var store: RCStore

    var body: some View {
        RCScreen(store: store) { actions in
            LargoHeader(store: store)
            let pending = store.pending
            if pending.isEmpty {
                RCCaughtUp(store: store)
            } else {
                RC2PendingTitle(store: store)
                RC2Slider(items: Array(pending.enumerated()).map { LargoPage(index: $0.offset, item: $0.element) }) { page in
                    LargoCard(store: store, page: page, count: pending.count, actions: actions)
                }
            }
            RCTemplateList(store: store, title: "All recurring", templates: store.active)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }
}

/// Out, In and Difference for an average month, plain, side by side, or stacked at accessibility sizes.
private struct LargoHeader: View {
    let store: RCStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let out = store.monthlyTotal(.expense)
        let income = store.monthlyTotal(.income)
        VStack(alignment: .leading, spacing: 10) {
            Text("Each month")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) { figures(out: out, income: income, spacers: false) }
            } else {
                HStack(alignment: .top, spacing: 8) { figures(out: out, income: income, spacers: true) }
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func figures(out: Decimal, income: Decimal, spacers: Bool) -> some View {
        R2Figure(title: "Out", value: out, code: store.code, font: .title3.weight(.bold))
        if spacers { Spacer(minLength: 0) }
        R2Figure(title: "In", value: income, code: store.code, font: .title3.weight(.bold))
        if spacers { Spacer(minLength: 0) }
        R2Figure(title: "Difference", value: income - out, code: store.code, signed: true, font: .title3.weight(.bold))
    }
}

private struct LargoPage: Identifiable {
    let index: Int
    let item: RCPending

    var id: String { item.id }
}

/// One pending item, centered, with its place in the queue.
private struct LargoCard: View {
    let store: RCStore
    let page: LargoPage
    let count: Int
    let actions: RCActions

    var body: some View {
        if let template = store.template(page.item.templateID) {
            R2Tile(padding: 18) {
                VStack(spacing: 8) {
                    Text("\(page.index + 1) of \(count)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    RC2ReviewButton(item: page.item, actions: actions) {
                        VStack(spacing: 6) {
                            P8CategoryIcon(category: template.category)
                            Text(verbatim: template.title)
                                .font(.headline)
                            RCFormat.amount(template, code: store.code)
                                .font(.title.weight(.bold))
                                .monospacedDigit()
                            RCFormat.due(page.item)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                    }
                    Spacer(minLength: 4)
                    RCPendingButtons(store: store, item: page.item, actions: actions)
                }
            }
        }
    }
}

#Preview("Largo") {
    RCHost { LargoRecurring(store: $0) }
}

#Preview("Largo · Caught up") {
    RCHost(store: .caughtUp) { LargoRecurring(store: $0) }
}

#Preview("Largo · Dark") {
    RCHost { LargoRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
