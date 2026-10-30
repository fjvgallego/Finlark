//
//  OnyxHome.swift
//  Finlark
//
//  FIN-9 Round 4 "Onyx": the balance and the month live directly on the backdrop, without a tile:
//  a large balance, the month figures as glass pills and the thin category bar under them. Tiles start
//  with the plan, so the top of Home reads like a header.
//

#if DEBUG
import SwiftUI

struct OnyxHomeView: View {
    @State private var model: ExplorationHomeModel

    init(snapshot: ExplorationHomeSnapshot = .sample) {
        _model = State(initialValue: ExplorationHomeModel(snapshot: snapshot))
    }

    private var snapshot: ExplorationHomeSnapshot { model.snapshot }
    private var code: String { snapshot.currencyCode }

    var body: some View {
        R3TabShell(model: model, quickAdd: .toolbarMenu) {
            R3HomeScroll(model: model) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Balance")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(snapshot.balance, format: .currency(code: code))
                            .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                            .monospacedDigit()
                    }
                    .accessibilityElement(children: .combine)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { pills }
                        VStack(alignment: .leading, spacing: 8) { pills }
                    }

                    R4SpendingStrip(snapshot: snapshot)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)

                Group {
                    R3PlanFiguresTile(snapshot: snapshot)
                    R3OwedRow(snapshot: snapshot)
                }
                .padding(.horizontal)
                R3PendingSection(model: model)
                R3RecentSection(snapshot: snapshot)
            }
        }
    }

    @ViewBuilder
    private var pills: some View {
        OnyxPill(title: "Income", symbol: "arrow.down.left", value: snapshot.monthIncome, code: code)
        OnyxPill(title: "Spending", symbol: "arrow.up.right", value: snapshot.monthSpending, code: code)
        OnyxPill(title: "Difference", symbol: "plusminus", value: snapshot.monthDifference, code: code, signed: true)
    }
}

private struct OnyxPill: View {
    let title: LocalizedStringKey
    let symbol: String
    let value: Decimal
    let code: String
    var signed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label(title, systemImage: symbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code).sign(strategy: signed ? .always() : .automatic))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }
}

#Preview("R4 Onyx") {
    OnyxHomeView()
}
#endif
