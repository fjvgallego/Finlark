//
//  08-FugueRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Fugue": no separate pending list. Pending items sit under the template they
//  come from, in a soft inset with a round Skip and the round check, and those templates come first.
//  Expenses and income are apart, each with what it comes to a month. A ring around each icon fills as
//  the next date nears.
//

#if DEBUG
import SwiftUI

struct FugueRecurring: View {
    @Bindable var store: RCStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        RCScreen(store: store) { actions in
            group(.expense, title: "Expenses", symbol: "arrow.up.right", actions: actions)
            group(.income, title: "Income", symbol: "arrow.down.left", actions: actions)
            RCTemplateList(store: store, title: "Paused", symbol: "pause.fill", templates: store.paused)
        }
    }

    @ViewBuilder
    private func group(
        _ type: ExplorationTransactionType,
        title: LocalizedStringKey,
        symbol: String,
        actions: RCActions
    ) -> some View {
        // Templates with something pending first, then the soonest.
        let templates = store.active.filter { $0.type == type }
            .sorted { !store.pending(for: $0).isEmpty && store.pending(for: $1).isEmpty }
        if !templates.isEmpty {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    // At accessibility sizes the total moves under the heading, so the heading keeps its line.
                    R2TileHeader(title: title, symbol: symbol) {
                        if !dynamicTypeSize.isAccessibilitySize {
                            monthly(type)
                        }
                    }
                    if dynamicTypeSize.isAccessibilitySize {
                        monthly(type)
                    }
                    ForEach(templates) { template in
                        FugueRow(store: store, template: template, actions: actions)
                        if template.id != templates.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}

private extension FugueRecurring {
    func monthly(_ type: ExplorationTransactionType) -> some View {
        Text("\(store.monthlyTotal(type), format: .currency(code: store.code)) a month")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
}

private struct FugueRow: View {
    let store: RCStore
    let template: RCTemplate
    let actions: RCActions

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            NavigationLink(value: RCRoute.template(template.id)) {
                HStack(spacing: 12) {
                    FugueRing(store: store, template: template)
                    RCTemplateRow(store: store, template: template, showsIcon: false)
                }
            }
            .buttonStyle(.plain)

            ForEach(store.pending(for: template)) { item in
                P5Row {
                    Button { actions.review(item) } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Pending")
                                    .font(.subheadline.weight(.semibold))
                                RCFormat.due(item)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "clock.badge.exclamationmark.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
                } controls: {
                    RCQuickControls(store: store, item: item, actions: actions)
                        .controlSize(.small)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

/// The category icon in a ring that fills as the next date nears. Decorative: the row says the date.
private struct FugueRing: View {
    let store: RCStore
    let template: RCTemplate

    @ScaledMetric private var size: CGFloat = 44
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var progress: Double {
        guard let next = store.nextDate(for: template),
              let previous = Calendar.current.date(byAdding: template.frequency.component, value: -1, to: next)
        else { return 0 }
        let period = next.timeIntervalSince(previous)
        return period > 0 ? min(max(RCStore.today.timeIntervalSince(previous) / period, 0), 1) : 0
    }

    var body: some View {
        if !dynamicTypeSize.isAccessibilitySize {
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(template.category.color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: template.category.symbol)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(template.category.color)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)
        }
    }
}

#Preview("Fugue") {
    RCHost { FugueRecurring(store: $0) }
}

#Preview("Fugue · Caught up") {
    RCHost(store: .caughtUp) { FugueRecurring(store: $0) }
}

#Preview("Fugue · Dark") {
    RCHost { FugueRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
