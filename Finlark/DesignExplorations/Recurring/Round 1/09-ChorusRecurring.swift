//
//  09-ChorusRecurring.swift
//  Finlark
//
//  FIN-9 Recurring, Round 1 "Chorus": one timeline. What's waiting to be confirmed sits above a Today
//  marker, with Skip and Confirm; the next 30 days run below it. The templates themselves fold away in
//  a tile at the end, since the timeline already shows what's coming.
//

#if DEBUG
import SwiftUI

struct ChorusRecurring: View {
    @Bindable var store: RCStore

    @State private var showsAll = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RCScreen(store: store) { actions in
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 0) {
                    let pending = store.pending
                    if !pending.isEmpty {
                        R2TileHeader(title: "To confirm", symbol: "clock.badge.exclamationmark.fill")
                            .padding(.bottom, 12)
                        ForEach(pending) { item in
                            ChorusNode(symbol: "exclamationmark.circle.fill", tint: .orange) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Button { actions.review(item) } label: {
                                        RCPendingInfo(store: store, item: item)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityHint(Text("Opens it to change the amount, date or note before confirming."))
                                    RCPendingButtons(store: store, item: item, actions: actions)
                                        .controlSize(.small)
                                }
                            }
                        }
                    }
                    ChorusNode(symbol: "smallcircle.filled.circle.fill", tint: .accentColor) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("Today")
                                .font(.headline)
                            Text(RCStore.today, format: .dateTime.weekday(.wide).day().month())
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                    }
                    let upcoming = store.upcoming(days: 30)
                    ForEach(upcoming) { item in
                        if let template = store.template(item.templateID) {
                            ChorusNode(symbol: "circle", tint: .secondary, isLast: item.id == upcoming.last?.id) {
                                P8InfoAndAmount {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(verbatim: template.title)
                                            .font(.body.weight(.semibold))
                                        Text("\(RCFormat.relative(item.date)) · \(RCFormat.day(item.date))")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                } amount: {
                                    RCFormat.amount(template, code: store.code)
                                        .monospacedDigit()
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
            }

            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Button {
                        withAnimation(reduceMotion ? nil : .snappy) { showsAll.toggle() }
                    } label: {
                        HStack {
                            Label("All recurring", systemImage: "repeat")
                                .font(.headline)
                            Text(store.templates.count, format: .number)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.down")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .rotationEffect(.degrees(showsAll ? 180 : 0))
                                .accessibilityHidden(true)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(showsAll ? Text("Expanded") : Text("Collapsed"))

                    if showsAll {
                        let templates = store.active + store.paused
                        ForEach(templates) { template in
                            Divider()
                            NavigationLink(value: RCRoute.template(template.id)) {
                                RCTemplateRow(store: store, template: template)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

/// A point on the timeline: a symbol on the line, its content beside it.
private struct ChorusNode<Content: View>: View {
    let symbol: String
    let tint: Color
    var isLast = false
    @ViewBuilder let content: Content

    @ScaledMetric private var railWidth: CGFloat = 18

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Image(systemName: symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(tint)
                if !isLast {
                    Capsule()
                        .fill(.quaternary)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: railWidth)
            .accessibilityHidden(true)
            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, isLast ? 0 : 18)
        }
    }
}

#Preview("Chorus") {
    RCHost { ChorusRecurring(store: $0) }
}

#Preview("Chorus · Caught up") {
    RCHost(store: .caughtUp) { ChorusRecurring(store: $0) }
}

#Preview("Chorus · Dark") {
    RCHost { ChorusRecurring(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
