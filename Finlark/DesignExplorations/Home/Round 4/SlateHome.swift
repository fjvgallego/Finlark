//
//  SlateHome.swift
//  Finlark
//
//  FIN-9 Round 4 "Slate": every tile leads with one plain sentence that says what matters
//  ("At this pace you'll go €50.07 over plan"), with the details underneath. Recent transactions are
//  grouped under Today, Yesterday and earlier dates.
//

#if DEBUG
import SwiftUI

struct SlateHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                Group {
                    balanceTile
                    planTile
                    if snapshot.owedToYou > 0 {
                        owedTile
                    }
                }
                .padding(.horizontal)
                R3PendingSection(model: model)
                recentSection
            }
        }
    }

    // MARK: Tiles

    private var balanceTile: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.balance, format: .currency(code: code))
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .monospacedDigit()
                    Text("in your account")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
                Divider()
                Text(monthSentence)
                    .font(.body)
                    .monospacedDigit()
                R4SpendingStrip(snapshot: snapshot)
            }
        }
    }

    private var monthSentence: LocalizedStringKey {
        let difference = snapshot.monthDifference
        if difference >= 0 {
            return "You're **\(difference, format: .currency(code: code)) ahead** this month: \(snapshot.monthIncome, format: .currency(code: code)) in, \(snapshot.monthSpending, format: .currency(code: code)) out."
        } else {
            return "You're **\(-difference, format: .currency(code: code)) behind** this month: \(snapshot.monthIncome, format: .currency(code: code)) in, \(snapshot.monthSpending, format: .currency(code: code)) out."
        }
    }

    private var planTile: some View {
        R2Link(destination: .plan) {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    R2TileHeader(title: "Monthly Plan", symbol: "chart.bar.doc.horizontal.fill") { R2Chevron() }
                    if let plan = snapshot.plan {
                        Text(planSentence(plan))
                            .font(.title3.weight(.semibold))
                        ExplorationStatusLabel(status: plan.status)
                            .font(.subheadline.weight(.semibold))
                        ExplorationPlanBar(
                            spent: plan.totalSpent,
                            projected: plan.totalProjected,
                            planned: plan.totalPlanned,
                            tint: plan.status.tint
                        )
                        Text("\(plan.totalSpent, format: .currency(code: code)) spent of \(plan.totalPlanned, format: .currency(code: code)) · \(snapshot.r3DaysLeft) days to go")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("You haven't set a plan yet. Planning a few categories shows where the month is heading.")
                            .font(.headline)
                    }
                }
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }

    private func planSentence(_ plan: ExplorationPlanSummary) -> LocalizedStringKey {
        switch plan.status {
        case .onTrack:
            "You're on track, with \(plan.totalRemaining, format: .currency(code: code)) left to spend."
        case .atRisk:
            "At this pace you'll go \(plan.totalProjected - plan.totalPlanned, format: .currency(code: code)) over plan."
        case .over:
            "You're already \(plan.totalSpent - plan.totalPlanned, format: .currency(code: code)) over plan."
        }
    }

    private var owedTile: some View {
        R2Link(destination: .people) {
            R2Tile(padding: 18) {
                HStack(spacing: 12) {
                    Text("\(snapshot.owedPeopleCount) people owe you **\(snapshot.owedToYou, format: .currency(code: code))**.")
                        .font(.body)
                        .monospacedDigit()
                    Spacer(minLength: 8)
                    R2Chevron()
                }
                .accessibilityElement(children: .combine)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Recent

    private var recentDays: [(day: Date, transactions: [ExplorationTransaction])] {
        let grouped = Dictionary(grouping: snapshot.recentTransactions) { Calendar.current.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { (day: $0, transactions: grouped[$0] ?? []) }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: r2TileSpacing) {
            R3SectionHeader(title: "Recent") {
                R2Link(destination: .history) { Text("History") }
                    .font(.subheadline.weight(.semibold))
            }
            R2Tile(padding: 16) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(recentDays, id: \.day) { day in
                        VStack(alignment: .leading, spacing: 10) {
                            dayTitle(day.day)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(.uppercase)
                                .accessibilityAddTraits(.isHeader)
                            ForEach(day.transactions) { transaction in
                                ExplorationTransactionRow(transaction: transaction, currencyCode: code)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func dayTitle(_ day: Date) -> Text {
        if Calendar.current.isDateInToday(day) {
            Text("Today")
        } else if Calendar.current.isDateInYesterday(day) {
            Text("Yesterday")
        } else {
            Text(day, format: .dateTime.weekday(.wide).day().month(.wide))
        }
    }
}

#Preview("R4 Slate") {
    SlateHomeView()
}
#endif
