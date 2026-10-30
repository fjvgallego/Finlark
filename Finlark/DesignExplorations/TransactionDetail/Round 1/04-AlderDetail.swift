//
//  04-AlderDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Alder": friends are pills, like the people in Home's Owed to you
//  bar, and tapping one opens a popover to settle up, as Settle all does there: Mark as paid with a
//  date, or type part of it. Repayments get their own tile, newest first, with who paid; tap one to
//  edit or delete it. Edit turns the tiles into Dunlin's fields in place.
//

#if DEBUG
import SwiftUI

struct AlderDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var action: TDRepaymentAction?
    @State private var selectedID: AEPerson.ID?

    var body: some View {
        TDScreen(record: record, editing: $editing) {
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
                        AEFlowLayout(spacing: 8, lineSpacing: 8) {
                            ForEach(record.debts) { debt in
                                pill(debt)
                            }
                        }
                        Text("Tap someone to mark them paid or record part of it.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !record.history.isEmpty {
                    historyTile
                }
            }
            TDDeleteButton(record: record)
                .padding(.top, 12)
        }
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
    }

    private func pill(_ debt: TDDebt) -> some View {
        Button {
            selectedID = debt.id
        } label: {
            HStack(spacing: 8) {
                AEAvatar(person: debt.person, size: 28)
                VStack(alignment: .leading, spacing: 0) {
                    debt.person.displayName
                        .font(.subheadline.weight(.semibold))
                    HStack(spacing: 4) {
                        Image(systemName: debt.status.symbol)
                            .foregroundStyle(debt.status.tint)
                        if debt.remaining > 0 {
                            Text("\(debt.remaining, format: .currency(code: record.code)) left")
                        } else {
                            Text("Paid")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                }
            }
            .padding(.leading, 6)
            .padding(.trailing, 14)
            .padding(.vertical, 6)
            .background(debt.person.color.opacity(0.12), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(debt.person.displayName)
        .accessibilityValue(debt.statusText(code: record.code))
        .accessibilityHint(Text("Opens options to settle up"))
        .popover(isPresented: isPresented(debt)) {
            AlderSettlePopover(record: record, person: debt.person)
                .presentationCompactAdaptation(.popover)
        }
    }

    private func isPresented(_ debt: TDDebt) -> Binding<Bool> {
        Binding {
            selectedID == debt.id
        } set: { isPresented in
            if !isPresented { selectedID = nil }
        }
    }

    private var historyTile: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 10) {
                R2TileHeader(title: "Repayments", symbol: "arrow.uturn.backward")
                ForEach(record.history) { repayment in
                    Button {
                        action = .edit(repayment)
                    } label: {
                        TDRepaymentLine(repayment: repayment, record: record, showsPerson: true)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Edit", systemImage: "pencil") { action = .edit(repayment) }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            record.undo(repayment.id)
                        }
                    }
                    .accessibilityHint(Text("Edit or delete this repayment"))
                }
            }
        }
    }
}

/// Share, paid and left, then Mark as paid (with its date) or a typed part of it (SPL-006, SPL-007).
private struct AlderSettlePopover: View {
    let record: TDRecord
    let person: AEPerson

    @State private var date = Date.now
    @State private var partText = ""

    private var part: Decimal { AEMoney.parse(partText) ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                AEAvatar(person: person, size: 36)
                VStack(alignment: .leading, spacing: 0) {
                    person.displayName
                        .font(.headline)
                    if let debt = record.debt(for: person) {
                        TDStatusLabel(debt: debt, code: record.code)
                            .font(.subheadline)
                    }
                }
            }
            .accessibilityElement(children: .combine)

            if let debt = record.debt(for: person), debt.remaining > 0 {
                Divider()
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .font(.subheadline)

                Button {
                    record.markPaid(person, on: date)
                } label: {
                    Label("Mark as paid · \(debt.remaining, format: .currency(code: record.code))", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.glassProminent)

                HStack(spacing: 8) {
                    Text("Or part of it")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 4)
                    AEMoneyField(title: "Amount", text: $partText, draft: record.saved)
                    Button("Record") {
                        record.record(part, from: person, on: date)
                        partText = ""
                    }
                    .buttonStyle(.glass)
                    .disabled(part <= 0 || part > debt.remaining)
                }
                if part > debt.remaining {
                    Label {
                        Text("Only \(debt.remaining, format: .currency(code: record.code)) is left.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    .font(.caption)
                }
            } else {
                Text("Nothing left to pay on this split.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .frame(width: 320)
    }
}

#Preview("Alder · Split") {
    TDHost { AlderDetail(record: $0) }
}

#Preview("Alder · By item") {
    TDHost(opening: 1) { AlderDetail(record: $0) }
}
#endif
