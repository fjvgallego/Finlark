//
//  07-AspenDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Aspen": what still needs doing comes first. A "Still owe you"
//  tile lists only the people with something left, each with Mark as paid and Record part right
//  there; the split, who's paid and every repayment follow. Delete moves to a "…" menu in the toolbar
//  instead of the end of the screen. Edit is in place.
//

#if DEBUG
import SwiftUI

struct AspenDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var action: TDRepaymentAction?
    @State private var isConfirmingDelete = false

    var body: some View {
        TDScreen(record: record, editing: $editing) {
            TDAmountTile(record: record)
            if record.isSplit, !record.openDebts.isEmpty {
                openTile
            }
            TDDetailsTile(record: record)
            if record.isSplit {
                splitTile
            }
        }
        .toolbar {
            if editing == nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(role: .destructive) {
                            isConfirmingDelete = true
                        } label: {
                            Label {
                                Text(record.saved.type.deleteTitle)
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis")
                    }
                    .tdDeleteConfirmation(record: record, isPresented: $isConfirmingDelete)
                }
            }
        }
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
    }

    private var openTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 14) {
                R2TileHeader(title: "Still owe you", symbol: "clock.fill") {
                    Text(record.owedToYou, format: .currency(code: record.code))
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                }
                ForEach(record.openDebts) { debt in
                    if debt.id != record.openDebts.first?.id {
                        Divider()
                    }
                    openRow(debt)
                }
            }
        }
    }

    private func openRow(_ debt: TDDebt) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TDPersonLine(debt: debt, code: record.code, avatarSize: 36) {
                Text("\(debt.remaining, format: .currency(code: record.code)) left")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { buttons(debt) }
                VStack(alignment: .leading, spacing: 8) { buttons(debt) }
            }
        }
    }

    @ViewBuilder
    private func buttons(_ debt: TDDebt) -> some View {
        Button {
            action = .markPaid(debt.person)
        } label: {
            Label("Mark as paid", systemImage: "checkmark.circle.fill")
                .fontWeight(.semibold)
        }
        .buttonStyle(.glassProminent)

        Button {
            action = .record(debt.person)
        } label: {
            Label("Record part", systemImage: "plus.circle")
        }
        .buttonStyle(.glass)
    }

    private var splitTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 14) {
                R2TileHeader(title: "Split", symbol: "person.2.fill")
                TDSplitFigures(record: record)
                if record.saved.splitMode == .byItem {
                    Divider()
                    TDItemsList(draft: record.saved)
                }
                Divider()
                TDMyShareRow(record: record)
                ForEach(record.debts.filter { $0.status == .paid }) { debt in
                    TDPersonLine(debt: debt, code: record.code) {
                        Text(debt.share, format: .currency(code: record.code))
                            .fontWeight(.medium)
                            .monospacedDigit()
                    }
                }

                if !record.history.isEmpty {
                    Divider()
                    Text("Repayments")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(record.history) { repayment in
                        Button {
                            action = .edit(repayment)
                        } label: {
                            TDRepaymentLine(repayment: repayment, record: record, showsPerson: true)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(Text("Edit or delete this repayment"))
                    }
                }
            }
        }
    }
}

#Preview("Aspen · Split") {
    TDHost { AspenDetail(record: $0) }
}

#Preview("Aspen · No split") {
    TDHost(opening: 2) { AspenDetail(record: $0) }
}
#endif
