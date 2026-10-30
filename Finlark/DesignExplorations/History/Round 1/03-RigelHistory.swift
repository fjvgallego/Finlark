//
//  03-RigelHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Rigel": one month at a time, like a statement. A glass header steps between
//  months with arrows, or a swipe across it, and shows the month's income and spending with a bar
//  comparing them. The month's days follow in one tile, with day headings inside. Filter is a toolbar
//  menu.
//

#if DEBUG
import SwiftUI

struct RigelHistory: View {
    @Bindable var store: HYStore

    @State private var isGoingBack = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollView {
            VStack(spacing: r2TileSpacing) {
                if !store.records.isEmpty {
                    header
                    Group {
                        if store.results.isEmpty {
                            HYEmptyView(store: store)
                                .padding(.top, 24)
                        } else {
                            daysTile
                        }
                    }
                    .id(store.isSearching ? nil : store.month)
                    .transition(monthTransition)
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .overlay {
            if store.records.isEmpty {
                HYEmptyView(store: store)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                HYFilterMenu(store: store)
            }
        }
        .searchable(text: $store.searchText, prompt: Text("Search notes"))
    }

    private var monthTransition: AnyTransition {
        reduceMotion ? .opacity : .push(from: isGoingBack ? .leading : .trailing)
    }

    // MARK: Header

    private var header: some View {
        R2Tile(padding: 18) {
            VStack(spacing: 16) {
                if store.isSearching {
                    Text("Results")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .accessibilityAddTraits(.isHeader)
                } else {
                    stepper
                }
                HYTotalsRow(totals: store.totals, code: store.code, font: .title2.weight(.bold))
                    .fontDesign(.rounded)
                    .frame(maxWidth: .infinity, alignment: .leading)
                RigelBalanceBar(totals: store.totals)
                HYNarrowedNote(store: store)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard !store.isSearching, abs(value.translation.width) > abs(value.translation.height) else { return }
                    if value.translation.width < -40, store.canGoForward {
                        step(by: 1)
                    } else if value.translation.width > 40, store.canGoBack {
                        step(by: -1)
                    }
                }
        )
    }

    private var stepper: some View {
        HStack(spacing: 12) {
            Button("Previous month", systemImage: "chevron.left") { step(by: -1) }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .disabled(!store.canGoBack)

            VStack(spacing: 2) {
                if let month = store.month {
                    Text(month, format: .dateTime.month(.wide).year())
                        .font(.title3.weight(.semibold))
                }
                Text("\(store.results.count) transactions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: if store.canGoForward { step(by: 1) }
                case .decrement: if store.canGoBack { step(by: -1) }
                @unknown default: break
                }
            }

            Button("Next month", systemImage: "chevron.right") { step(by: 1) }
                .labelStyle(.iconOnly)
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .disabled(!store.canGoForward)
        }
    }

    private func step(by months: Int) {
        isGoingBack = months < 0
        withAnimation(reduceMotion ? nil : .smooth) { store.step(by: months) }
    }

    // MARK: Days

    private var daysTile: some View {
        R2Tile(padding: 14) {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(store.days) { day in
                    if day.id != store.days.first?.id {
                        Divider()
                            .padding(.vertical, 4)
                    }
                    HYDayHeader(day: day, code: store.code)
                    ForEach(day.records) { record in
                        NavigationLink(value: record) {
                            HYRow(record: record, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

/// Spending against income as one bar: the filled part is what was spent of what came in.
private struct RigelBalanceBar: View {
    let totals: HYTotals

    @ScaledMetric(relativeTo: .caption) private var height: CGFloat = 8

    private var fraction: Double {
        guard totals.income > 0 else { return totals.spending > 0 ? 1 : 0 }
        return min(totals.spending.plotValue / totals.income.plotValue, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { proxy in
                Capsule()
                    .fill(.fill.tertiary)
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(.tint)
                            .frame(width: proxy.size.width * fraction)
                    }
            }
            .frame(height: height)

            Group {
                if totals.income > 0 {
                    Text("Spent \(fraction, format: .percent.precision(.fractionLength(0))) of income")
                } else {
                    Text("No income yet")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Rigel") {
    HYHost { RigelHistory(store: $0) }
}

#Preview("Rigel · Empty") {
    HYHost(store: .empty) { RigelHistory(store: $0) }
}
#endif
