//
//  09-MonsoonPlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Monsoon": the projection explained. What's left to spend leads, large. Each
//  category is a short row, and tapping it opens its sum: spent so far, plus the pace estimate, plus
//  recurring expenses still due, equals the projection, against the planned amount (PLN-003). The
//  number stops being a black box.
//

#if DEBUG
import SwiftUI

struct MonsoonPlan: View {
    @Bindable var store: PLStore

    @State private var expanded: Set<String>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// `expanded` opens those categories' sums from the start.
    init(store: PLStore, expanded: Set<String> = []) {
        self.store = store
        _expanded = State(initialValue: expanded)
    }

    private var code: String { store.code }

    var body: some View {
        let report = store.report

        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if report.hasPlan {
                    hero(report)
                    R2Tile(padding: 18) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(report.entries) { entry in
                                row(entry)
                                if entry.id != report.entries.last?.id {
                                    Divider().padding(.vertical, 10)
                                }
                            }
                        }
                    }
                } else {
                    PLInvite(store: store)
                }
                PLUnplannedTile(report: report, code: code)
                if report.hasPlan {
                    PLFootnote(report: report, code: code)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .plChrome(store: store)
    }

    private func hero(_ report: PLReport) -> some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 10) {
                if report.spent > report.planned {
                    Text("Over plan by")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(report.spent - report.planned, format: .currency(code: code))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                } else {
                    Text("Left to spend")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(report.remaining, format: .currency(code: code))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                }
                Text("of \(report.planned, format: .currency(code: code)) planned")
                    .foregroundStyle(.secondary)
                PLBar.Total(report: report)
                    .padding(.vertical, 4)
                HStack {
                    if let status = report.status {
                        PLStatusLabel(status: status)
                            .font(.subheadline.weight(.semibold))
                    }
                    Spacer(minLength: 8)
                    if report.isCurrent {
                        Text("\(report.daysLeft) days to go")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }

    private func row(_ entry: PLEntry) -> some View {
        let isExpanded = expanded.contains(entry.id)

        return VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation(reduceMotion ? nil : .snappy) {
                    if isExpanded { expanded.remove(entry.id) } else { expanded.insert(entry.id) }
                }
            } label: {
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: 6))
                    : AnyLayout(HStackLayout(spacing: 12))
                layout {
                    ExplorationCategoryIcon(category: entry.category)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.category.name)
                            .font(.headline)
                        if let status = entry.status {
                            PLStatusLabel(status: status)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if !dynamicTypeSize.isAccessibilitySize {
                        Spacer(minLength: 8)
                    }
                    if let planned = entry.planned {
                        R3RemainingText(planned: planned, spent: entry.spent, code: code)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                    }
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text("Shows how the projection adds up"))
            .accessibilityAddTraits(isExpanded ? .isSelected : [])

            if isExpanded {
                breakdown(entry)
                    .transition(.opacity)
            }
        }
    }

    /// Spent + pace + recurring due = projected, then the planned amount (PLN-003).
    private func breakdown(_ entry: PLEntry) -> some View {
        VStack(spacing: 8) {
            line("Spent so far", entry.spent, sign: nil)
            if let projected = entry.projected {
                if let pace = entry.pace {
                    line("At your pace, to month end", pace, sign: "+")
                } else {
                    HStack {
                        Text("Pace estimate")
                        Spacer()
                        Text("From day 4")
                    }
                    .foregroundStyle(.secondary)
                }
                line("Recurring still due", entry.recurringDue, sign: "+")
                Divider()
                line("Projected", projected, sign: "=")
                    .fontWeight(.semibold)
            }
            line("Planned", entry.planned ?? 0, sign: nil)
                .foregroundStyle(.secondary)
            PLBar(entry: entry)
                .padding(.top, 4)
        }
        .font(.subheadline)
        .monospacedDigit()
        .padding(14)
        .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func line(_ title: LocalizedStringKey, _ value: Decimal, sign: String?) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 8)
            if let sign {
                Text(verbatim: sign)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            Text(value, format: .currency(code: code))
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Monsoon") {
    PLHost { MonsoonPlan(store: $0, expanded: ["fuel"]) }
}

#Preview("Monsoon · Last month") {
    PLHost(store: .lastMonth) { MonsoonPlan(store: $0) }
}

#Preview("Monsoon · Early month") {
    PLHost(store: .earlyMonth) { MonsoonPlan(store: $0, expanded: ["bills"]) }
}

#Preview("Monsoon · No plan") {
    PLHost(store: .noPlan) { MonsoonPlan(store: $0) }
}
#endif
