//
//  Round6Components.swift
//  Finlark
//
//  FIN-9 Round 6: pieces for the Mist variants. Owed to you becomes a thin bar at the very top that
//  expands into a row of people, and tapping one opens a popover to settle what they owe. The plan
//  combines Slate's pace sentence with Coral's labeled figures and bar. Builds on Rounds 2 to 5.
//

#if DEBUG
import SwiftUI
import Charts

// MARK: - Mock debtors

/// A person with open shares (PPL-003), mocked so Settle all (SPL-008) can be tried from Home.
struct R6Debtor: Identifiable {
    struct OpenShare: Identifiable {
        let id = UUID()
        let ticket: String
        let date: Date
        let remaining: Decimal
    }

    let id = UUID()
    let name: String
    let shares: [OpenShare]

    var total: Decimal { shares.reduce(0) { $0 + $1.remaining } }
    var initial: String { String(name.prefix(1)) }

    /// Matches the sample snapshot: €85.00 owed by 2 people.
    static let sample: [R6Debtor] = [
        R6Debtor(name: "Marta", shares: [
            OpenShare(ticket: "Dinner at Casa Pepe", date: .now, remaining: 30),
            OpenShare(ticket: "Cinema", date: Calendar.current.date(byAdding: .day, value: -6, to: .now) ?? .now,
                      remaining: 25),
        ]),
        R6Debtor(name: "Luis", shares: [
            OpenShare(ticket: "Dinner at Casa Pepe", date: .now, remaining: 30),
        ]),
    ]
}

// MARK: - Owed to you bar (HOM-004)

/// A thin, collapsed bar at the top of Home. Expanded, it shows a row of people who owe you; tapping
/// one opens a popover to settle everything they owe. Hidden when nothing is owed.
struct R6OwedBar: View {
    @Binding var debtors: [R6Debtor]
    let code: String

    @State private var isExpanded = false
    @State private var selectedID: R6Debtor.ID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var total: Decimal { debtors.reduce(0) { $0 + $1.total } }

    var body: some View {
        if !debtors.isEmpty {
            R2Tile(padding: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    if isExpanded {
                        Divider()
                            .padding(.horizontal, 16)
                        people
                    }
                }
            }
        }
    }

    private var header: some View {
        Button {
            withAnimation(reduceMotion ? nil : .snappy) {
                isExpanded.toggle()
            }
        } label: {
            HStack(spacing: 10) {
                // Multicolor keeps the black exclamation mark, so the yellow symbol stays legible
                // on light backgrounds.
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.multicolor)
                    .accessibilityHidden(true)
                Text("Owed to you")
                    .fontWeight(.semibold)
                Text("\(debtors.count) people")
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Text(total, format: .currency(code: code))
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    .accessibilityHidden(true)
            }
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
        .accessibilityHint(Text("Shows who owes you"))
    }

    private var people: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(debtors) { debtor in
                    personChip(debtor)
                }
                // HOM-004: People stays one tap away.
                R2Link(destination: .people) {
                    Label("People", systemImage: "chevron.right")
                        .labelStyle(R6TrailingIconLabelStyle())
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .scrollIndicators(.hidden)
    }

    private func personChip(_ debtor: R6Debtor) -> some View {
        Button {
            selectedID = debtor.id
        } label: {
            HStack(spacing: 8) {
                R6Avatar(initial: debtor.initial)
                VStack(alignment: .leading, spacing: 0) {
                    Text(debtor.name)
                        .font(.subheadline.weight(.semibold))
                    Text(debtor.total, format: .currency(code: code))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
            .background(.fill.tertiary, in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Opens options to settle up"))
        .popover(isPresented: isPresented(debtor)) {
            R6SettlePopover(debtor: debtor, code: code) {
                selectedID = nil
                withAnimation(reduceMotion ? nil : .snappy) {
                    debtors.removeAll { $0.id == debtor.id }
                }
            }
            .presentationCompactAdaptation(.popover)
        }
    }

    private func isPresented(_ debtor: R6Debtor) -> Binding<Bool> {
        Binding {
            selectedID == debtor.id
        } set: { isPresented in
            if !isPresented { selectedID = nil }
        }
    }
}

/// What a person owes, share by share, with one confirming action: Settle all (SPL-008).
private struct R6SettlePopover: View {
    let debtor: R6Debtor
    let code: String
    let onSettle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                R6Avatar(initial: debtor.initial)
                VStack(alignment: .leading, spacing: 0) {
                    Text(debtor.name)
                        .font(.headline)
                    Text("Owes you \(debtor.total, format: .currency(code: code))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)

            Divider()

            ForEach(debtor.shares) { share in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(share.ticket)
                        Text(share.date, format: .dateTime.day().month())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 12)
                    Text(share.remaining, format: .currency(code: code))
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }

            Button(action: onSettle) {
                Label("Settle all · \(debtor.total, format: .currency(code: code))", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.glassProminent)

            Text("Records a repayment for each open share, dated today.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 300)
    }
}

private struct R6Avatar: View {
    let initial: String
    @ScaledMetric private var size: CGFloat = 30

    var body: some View {
        Text(initial)
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Color.accentColor.gradient, in: .circle)
            .accessibilityHidden(true)
    }
}

private struct R6TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.title
            configuration.icon
                .font(.caption.weight(.bold))
        }
    }
}

// MARK: - Plan (HOM-003)

/// Slate's pace sentence over Coral's labeled figures and bar.
struct R6PlanTile: View {
    let snapshot: ExplorationHomeSnapshot

    private var code: String { snapshot.currencyCode }

    var body: some View {
        R2Link(destination: .plan) {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 14) {
                    R2TileHeader(title: "Monthly Plan", symbol: "chart.bar.doc.horizontal.fill") { R2Chevron() }
                    if let plan = snapshot.plan {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(snapshot.r5PaceSentence(for: plan))
                                .font(.title3.weight(.semibold))
                            ExplorationStatusLabel(status: plan.status)
                                .font(.subheadline.weight(.semibold))
                        }
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top) { figures(plan) }
                            VStack(alignment: .leading, spacing: 10) { figures(plan) }
                        }
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        .padding(.vertical, 2)
                        HStack {
                            R3RemainingText(planned: plan.totalPlanned, spent: plan.totalSpent, code: code)
                            Spacer(minLength: 8)
                            Text("\(snapshot.r3DaysLeft) days to go")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    } else {
                        R3PlanInvite()
                    }
                }
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func figures(_ plan: ExplorationPlanSummary) -> some View {
        R3PlanFigure(title: "Spent", value: plan.totalSpent, code: code, swatch: .spent(plan.status.tint))
        Spacer(minLength: 8)
        R3PlanFigure(title: "Projected", value: plan.totalProjected, code: code, swatch: .projected(plan.status.tint))
        Spacer(minLength: 8)
        R3PlanFigure(title: "Planned", value: plan.totalPlanned, code: code, swatch: .planned)
    }
}

// MARK: - Jasper-style rows

/// A label and a value on one row, as in Jasper.
struct R6Row<Value: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder let value: Value

    init(_ title: LocalizedStringKey, @ViewBuilder value: () -> Value) {
        self.title = title
        self.value = value()
    }

    var body: some View {
        LabeledContent {
            value
                .foregroundStyle(.primary)
                .monospacedDigit()
        } label: {
            Text(title)
        }
        .padding(.vertical, 10)
    }
}

/// Income, Spending and Difference as labeled rows with dividers.
struct R6MonthRows: View {
    let snapshot: ExplorationHomeSnapshot

    private var code: String { snapshot.currencyCode }

    var body: some View {
        VStack(spacing: 0) {
            R6Row("Income") { Text(snapshot.monthIncome, format: .currency(code: code)) }
            Divider()
            R6Row("Spending") { Text(snapshot.monthSpending, format: .currency(code: code)) }
            Divider()
            R6Row("Difference") {
                Text(snapshot.monthDifference, format: .currency(code: code).sign(strategy: .always()))
                    .fontWeight(.semibold)
            }
        }
    }
}

/// One category as a row: icon, name, an inline bar on a shared scale, amount and share.
/// The amount column has a fixed width so every bar starts at the same x.
struct R6CategoryRow: View {
    let item: ExplorationCategorySpending
    let snapshot: ExplorationHomeSnapshot
    let scale: Double
    var verticalPadding: CGFloat = 9

    @ScaledMetric(relativeTo: .caption) private var barWidth: CGFloat = 56
    @ScaledMetric(relativeTo: .caption) private var barHeight: CGFloat = 6
    @ScaledMetric(relativeTo: .subheadline) private var amountWidth: CGFloat = 84

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.category.symbol)
                .foregroundStyle(item.category.color)
                .frame(minWidth: 22)
                .accessibilityHidden(true)
            Text(item.category.name)
            Spacer(minLength: 8)
            Chart {
                BarMark(xStart: .value("Start", 0), xEnd: .value("Amount", item.amount.plotValue))
                    .foregroundStyle(item.category.color)
                    .cornerRadius(barHeight / 2)
            }
            .chartXScale(domain: 0...max(scale, 1))
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(width: barWidth, height: barHeight)
            .accessibilityHidden(true)
            Text(item.amount, format: .currency(code: snapshot.currencyCode))
                .fontWeight(.medium)
                .monospacedDigit()
                .frame(minWidth: amountWidth, alignment: .trailing)
            Text(snapshot.r5Share(of: item.amount), format: .percent.precision(.fractionLength(0)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .frame(minWidth: 32, alignment: .trailing)
        }
        .padding(.vertical, verticalPadding)
        .accessibilityElement(children: .combine)
    }
}
#endif
