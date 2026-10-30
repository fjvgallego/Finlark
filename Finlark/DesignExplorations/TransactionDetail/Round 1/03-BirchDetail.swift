//
//  03-BirchDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Birch": the split tile stays short, one line per friend with a
//  ring that fills as they pay. Tapping someone opens their own sheet: the ring large, their
//  repayments as a list you can swipe (Edit, Delete), and Mark as paid and Record part at the bottom.
//  Edit turns the tiles into Dunlin's fields in place.
//

#if DEBUG
import SwiftUI

struct BirchDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var selected: AEPerson?

    var body: some View {
        TDScreen(record: record, editing: $editing) {
            TDAmountTile(record: record)
            TDDetailsTile(record: record)
            if record.isSplit {
                R2Tile {
                    VStack(alignment: .leading, spacing: 12) {
                        R2TileHeader(title: "Split", symbol: "person.2.fill")
                        TDSplitFigures(record: record)
                        if record.saved.splitMode == .byItem {
                            Divider()
                            TDItemsList(draft: record.saved)
                        }
                        Divider()
                        TDMyShareRow(record: record)
                        ForEach(record.debts) { debt in
                            Divider()
                            row(debt)
                        }
                    }
                }
            }
            TDDeleteButton(record: record)
                .padding(.top, 12)
        }
        .sheet(item: $selected) { person in
            BirchPersonSheet(record: record, person: person)
        }
    }

    private func row(_ debt: TDDebt) -> some View {
        Button {
            selected = debt.person
        } label: {
            HStack(spacing: 10) {
                TDPersonLine(debt: debt, code: record.code) {
                    TDProgressRing(debt: debt, size: 36)
                } trailing: {
                    Text(debt.share, format: .currency(code: record.code))
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                R2Chevron()
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Shows their repayments"))
    }
}

/// One friend on this split: progress, repayments and the two actions.
private struct BirchPersonSheet: View {
    let record: TDRecord
    let person: AEPerson

    @State private var action: TDRepaymentAction?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let debt = record.debt(for: person) {
                    Section {
                        VStack(spacing: 10) {
                            TDProgressRing(debt: debt, size: 84)
                            TDStatusLabel(debt: debt, code: record.code)
                                .font(.headline)
                            TDDebtFigures(debt: debt, code: record.code, spacing: 24)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }

                    Section {
                        if debt.repayments.isEmpty {
                            Text("No repayments yet.")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(debt.repayments) { repayment in
                            Button {
                                action = .edit(repayment)
                            } label: {
                                TDRepaymentLine(repayment: repayment, record: record)
                                    .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) {
                                    record.undo(repayment.id)
                                }
                                Button("Edit", systemImage: "pencil") {
                                    action = .edit(repayment)
                                }
                            }
                        }
                    } header: {
                        Text("Repayments")
                    } footer: {
                        if !debt.repayments.isEmpty {
                            Text("Swipe a repayment to delete it, or tap it to change the amount or date.")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if let debt = record.debt(for: person), debt.remaining > 0 {
                    HStack(spacing: 10) {
                        Button {
                            action = .record(person)
                        } label: {
                            Label("Record part", systemImage: "plus.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glass)
                        Button {
                            action = .markPaid(person)
                        } label: {
                            Label("Mark as paid", systemImage: "checkmark.circle.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                    }
                    .controlSize(.large)
                    .padding()
                }
            }
            .navigationTitle(Text(verbatim: person.name))
            .navigationSubtitle(record.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", role: .confirm) { dismiss() }
                }
            }
            .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
        }
        .presentationDetents([.fraction(0.75), .large])
        .environment(\.explorationIconStyle, .soft)
    }
}

#Preview("Birch · Split") {
    TDHost { BirchDetail(record: $0) }
}

#Preview("Birch · By item") {
    TDHost(opening: 1) { BirchDetail(record: $0) }
}
#endif
