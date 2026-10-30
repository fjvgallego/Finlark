//
//  10-LindenDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Linden": no sheets for repayments. Record opens the row in place
//  with the amount already set to what's left, so saving it as is marks them paid and changing it
//  records part (SPL-006, SPL-007). Repayments are chips under the person. The view stays calm: Delete
//  only appears in edit mode, at the bottom of Dunlin's fields, as in Contacts and Calendar.
//

#if DEBUG
import SwiftUI

struct LindenDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var action: TDRepaymentAction?
    @State private var recordingID: AEPerson.ID?
    @State private var amountText = ""
    @State private var date = Date.now
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        TDScreen(record: record, editing: $editing, deletesInEditMode: true) {
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
                        ForEach(record.debts) { debt in
                            Divider()
                            row(debt)
                        }
                    }
                }
            }
        }
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
    }

    private func row(_ debt: TDDebt) -> some View {
        let isRecording = recordingID == debt.id

        return VStack(alignment: .leading, spacing: 10) {
            TDPersonLine(debt: debt, code: record.code) {
                if debt.remaining > 0, !isRecording {
                    Button("Record") { startRecording(debt) }
                        .font(.subheadline.weight(.semibold))
                        .buttonStyle(.glass)
                        .accessibilityLabel(Text("Record a repayment from \(debt.person.name)"))
                } else if debt.remaining == 0 {
                    Text(debt.share, format: .currency(code: record.code))
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }

            if !debt.repayments.isEmpty {
                TDRepaymentChips(debt: debt, record: record) { action = .edit($0) }
                    .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 0 : 40)
            }

            if isRecording {
                recorder(debt)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func recorder(_ debt: TDDebt) -> some View {
        let amount = AEMoney.parse(amountText) ?? 0
        let isTooMuch = amount > debt.remaining

        return VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Amount") {
                AEMoneyField(title: "Amount", text: $amountText, draft: record.saved)
            }
            DatePicker("Date", selection: $date, displayedComponents: .date)
            Group {
                if isTooMuch {
                    Label {
                        Text("Only \(debt.remaining, format: .currency(code: record.code)) is left.")
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                } else if amount == debt.remaining {
                    Text("Saves them as paid.")
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(debt.remaining - amount, format: .currency(code: record.code)) will still be left.")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption)

            HStack(spacing: 8) {
                Button("Cancel") { stopRecording() }
                    .buttonStyle(.glass)
                Spacer(minLength: 0)
                Button {
                    record.record(amount, from: debt.person, on: date)
                    stopRecording()
                } label: {
                    Label("Save", systemImage: "checkmark")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.glassProminent)
                .disabled(amount <= 0 || isTooMuch)
            }
        }
        .font(.subheadline)
        .padding(12)
        .background(.fill.quaternary, in: .rect(cornerRadius: 16, style: .continuous))
    }

    private func startRecording(_ debt: TDDebt) {
        amountText = AEMoney.text(for: debt.remaining, fractionDigits: record.saved.fractionDigits)
        date = .now
        withAnimation(reduceMotion ? nil : .snappy) { recordingID = debt.id }
    }

    private func stopRecording() {
        withAnimation(reduceMotion ? nil : .snappy) { recordingID = nil }
    }
}

#Preview("Linden · Split") {
    TDHost { LindenDetail(record: $0) }
}

#Preview("Linden · By item") {
    TDHost(opening: 1) { LindenDetail(record: $0) }
}
#endif
