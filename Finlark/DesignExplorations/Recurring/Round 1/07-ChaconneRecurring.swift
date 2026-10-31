//
//  07-ChaconneRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Chaconne": every template is a small glass card in a two-column grid, with
//  its amount large, how often it repeats and when it's next. A card with something waiting says how
//  many. Above the grid, the pending items in compact rows with a round Skip and the round check. One
//  column at accessibility sizes.
//

#if DEBUG
import SwiftUI

struct ChaconneRecurring: View {
    @Bindable var store: RCStore

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        RCScreen(store: store) { actions in
            let pending = store.pending
            if !pending.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Pending", symbol: "clock.badge.exclamationmark.fill")
                        ForEach(pending) { item in
                            P5Row {
                                Button { actions.review(item) } label: {
                                    RCPendingInfo(store: store, item: item)
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
                            } controls: {
                                RCQuickControls(store: store, item: item, actions: actions)
                            }
                            if item.id != pending.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }

            RCSectionTitle(title: "All recurring", count: store.templates.count)
            let columns = Array(
                repeating: GridItem(.flexible(), spacing: r2TileSpacing, alignment: .top),
                count: dynamicTypeSize.isAccessibilitySize ? 1 : 2
            )
            LazyVGrid(columns: columns, spacing: r2TileSpacing) {
                ForEach(store.active + store.paused) { template in
                    NavigationLink(value: RCRoute.template(template.id)) {
                        ChaconneCard(store: store, template: template)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct ChaconneCard: View {
    let store: RCStore
    let template: RCTemplate

    var body: some View {
        let waiting = store.pending(for: template).count
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    ExplorationCategoryIcon(category: template.category)
                    Spacer(minLength: 4)
                    if waiting > 0 {
                        Label {
                            Text("\(waiting) pending")
                        } icon: {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                        }
                        .font(.caption.weight(.semibold))
                    }
                }
                Text(verbatim: template.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                RCFormat.amount(template, code: store.code)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                Group {
                    if template.isPaused {
                        RCPausedLabel()
                    } else {
                        Text(template.frequency.title)
                        if let next = store.nextDate(for: template) {
                            RCFormat.relative(next)
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Chaconne") {
    RCHost { ChaconneRecurring(store: $0) }
}

#Preview("Chaconne · Caught up") {
    RCHost(store: .caughtUp) { ChaconneRecurring(store: $0) }
}

#Preview("Chaconne · Dark") {
    RCHost { ChaconneRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
