//
//  09-JuniperDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Juniper": one card per friend in a slider (Home's Carousel), each
//  a small page of its own: ring, status, figures, repayments and the two actions. The next card peeks
//  in so it reads as swipeable; at accessibility sizes they stack. Delete sits in the bottom toolbar,
//  as in Mail and Photos. Edit opens Dunlin as a sheet.
//

#if DEBUG
import SwiftUI

struct JuniperDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var action: TDRepaymentAction?
    @State private var isConfirmingDelete = false

    var body: some View {
        TDScreen(record: record, editing: $editing, editStyle: .sheet) {
            TDAmountTile(record: record)
            TDDetailsTile(record: record)
            if record.isSplit {
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
                    }
                }
                R2Slider(record.debts, margin: 0, peeksNextPage: record.debts.count > 1) { debt in
                    card(debt)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive) {
                    isConfirmingDelete = true
                } label: {
                    Label {
                        Text(record.saved.type.deleteTitle)
                    } icon: {
                        Image(systemName: "trash")
                    }
                }
                .tdDeleteConfirmation(record: record, isPresented: $isConfirmingDelete)
            }
        }
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
    }

    private func card(_ debt: TDDebt) -> some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 14) {
                TDPersonLine(debt: debt, code: record.code) {
                    TDProgressRing(debt: debt, size: 52)
                } trailing: {
                    EmptyView()
                }

                TDDebtFigures(debt: debt, code: record.code, spacing: 16)

                Divider()

                if debt.repayments.isEmpty {
                    Text("No repayments yet.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(debt.repayments) { repayment in
                        Button {
                            action = .edit(repayment)
                        } label: {
                            TDRepaymentLine(repayment: repayment, record: record)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(Text("Edit or delete this repayment"))
                    }
                }

                Spacer(minLength: 0)

                if debt.remaining > 0 {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { buttons(debt) }
                        VStack(alignment: .leading, spacing: 8) { buttons(debt) }
                    }
                }
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
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.glassProminent)
        Button {
            action = .record(debt.person)
        } label: {
            Label("Part", systemImage: "plus.circle")
        }
        .buttonStyle(.glass)
        .accessibilityLabel(Text("Record part of it"))
    }
}

#Preview("Juniper · Split") {
    TDHost { JuniperDetail(record: $0) }
}

#Preview("Juniper · Income") {
    TDHost(opening: 3) { JuniperDetail(record: $0) }
}
#endif
