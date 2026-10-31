//
//  06-MuslinCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Muslin": led by use. A plain header with this month's total, then the
//  categories used this month, most first, each with a bar against the biggest. The ones not used this
//  month sit apart with a nudge to archive what's no longer needed.
//

#if DEBUG
import SwiftUI

struct MuslinCategories: View {
    @Bindable var store: CTStore

    @State private var type: ExplorationTransactionType = .expense

    var body: some View {
        CTScreen(store: store, addType: type) { actions in
            let active = store.active(type).sorted { $0.thisMonth > $1.thisMonth }
            let used = active.filter { $0.thisMonth > 0 }
            let unused = active.filter { $0.thisMonth == 0 }

            CTTypeSwitch(selection: $type)
            MuslinHeader(store: store, type: type, used: used)

            if !used.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "This month", symbol: "calendar")
                        let largest = used.first?.thisMonth ?? 1
                        ForEach(used) { category in
                            Button { actions.edit(category) } label: {
                                MuslinRow(store: store, category: category, largest: largest)
                            }
                            .buttonStyle(.plain)
                            .ctArchiveMenu(category, actions: actions)
                        }
                    }
                }
            }

            if !unused.isEmpty {
                R2Tile(padding: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        R2TileHeader(title: "Not used this month", symbol: "moon.zzz.fill")
                        ForEach(unused) { category in
                            Button { actions.edit(category) } label: {
                                CTRow(category: category)
                            }
                            .buttonStyle(.plain)
                            .ctArchiveMenu(category, actions: actions)
                            if category.id != unused.last?.id {
                                Divider()
                            }
                        }
                        Text("Not using one any more? Archive it to keep the category picker short. Its transactions keep it.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            CTArchivedTile(categories: store.archived(type), actions: actions)
        }
    }
}

/// This month's total over the categories, plain.
private struct MuslinHeader: View {
    let store: CTStore
    let type: ExplorationTransactionType
    let used: [CTCategory]

    var body: some View {
        let total = used.reduce(Decimal(0)) { $0 + $1.thisMonth }
        VStack(spacing: 4) {
            Text(total, format: .currency(code: store.code))
                .font(.largeTitle.weight(.bold))
                .monospacedDigit()
            Group {
                if type == .expense {
                    Text("spent this month in ^[\(used.count) category](inflect: true)")
                } else {
                    Text("received this month in ^[\(used.count) category](inflect: true)")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }
}

/// Icon, name and amount, with a bar in the category's color under the text.
private struct MuslinRow: View {
    let store: CTStore
    let category: CTCategory
    let largest: Decimal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            P8CategoryIcon(category: category.icon)
            VStack(alignment: .leading, spacing: 6) {
                P8InfoAndAmount {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: category.name)
                            .font(.body.weight(.medium))
                        CTUsage.count(category)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } amount: {
                    Text(category.thisMonth, format: .currency(code: store.code))
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                }
                MuslinBar(fraction: fraction, tint: category.color.color)
            }
            R2Chevron()
                .padding(.top, 4)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }

    // Converted to Double for drawing only (NFR-005).
    private var fraction: Double {
        guard largest > 0 else { return 0 }
        return NSDecimalNumber(decimal: category.thisMonth / largest).doubleValue
    }
}

private struct MuslinBar: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        Capsule()
            .fill(.fill.tertiary)
            .frame(height: 6)
            .overlay(alignment: .leading) {
                GeometryReader { proxy in
                    Capsule()
                        .fill(tint.gradient)
                        .frame(width: max(proxy.size.width * fraction, 6))
                }
            }
            .accessibilityHidden(true)
    }
}

#Preview("Muslin") {
    CTHost { MuslinCategories(store: $0) }
}

#Preview("Muslin · Dark") {
    CTHost { MuslinCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
