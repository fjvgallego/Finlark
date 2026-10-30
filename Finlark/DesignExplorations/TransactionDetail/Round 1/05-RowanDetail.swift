//
//  05-RowanDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Rowan": the split as a ring. Your share is grey, each friend's
//  share is their color, solid for what they've paid and faded for what's left, and the middle says
//  what's still owed. Each row has a one-tap Mark paid button, dated today, with an Undo bar in case it was
//  a slip; touch and hold a row for a partial repayment or another date. Edit is in place.
//

#if DEBUG
import SwiftUI
import Charts

struct RowanDetail: View {
    private struct Undo: Equatable {
        let repaymentID: TDRepayment.ID
        let name: String
    }

    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var action: TDRepaymentAction?
    @State private var undo: Undo?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        TDScreen(record: record, editing: $editing) {
            TDAmountTile(record: record)
            TDDetailsTile(record: record)
            if record.isSplit {
                R2Tile {
                    VStack(alignment: .leading, spacing: 14) {
                        R2TileHeader(title: "Split", symbol: "person.2.fill")
                        RowanRing(record: record)
                            .frame(maxWidth: .infinity)
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
                        Text("Touch and hold someone to record part of it or pick another date.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            TDDeleteButton(record: record)
                .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            if let undo, editing == nil {
                undoBar(undo)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .task(id: undo) {
            guard undo != nil else { return }
            try? await Task.sleep(for: .seconds(5))
            withAnimation(reduceMotion ? nil : .snappy) { undo = nil }
        }
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
        .sensoryFeedback(.success, trigger: undo?.repaymentID)
    }

    private func row(_ debt: TDDebt) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TDPersonLine(debt: debt, code: record.code) {
                if debt.remaining > 0 {
                    Button {
                        markPaid(debt)
                    } label: {
                        Label("Mark paid", systemImage: "checkmark")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(Text("Mark \(debt.person.name) as paid"))
                } else {
                    Text(debt.share, format: .currency(code: record.code))
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
            }

            if !debt.repayments.isEmpty {
                TDRepaymentChips(debt: debt, record: record) { action = .edit($0) }
                    .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 0 : 40)
            }
        }
        .contentShape(.rect)
        .contextMenu {
            if debt.remaining > 0 {
                Button("Record part of it", systemImage: "plus.circle") { action = .record(debt.person) }
                Button("Mark as paid on another day", systemImage: "calendar") { action = .markPaid(debt.person) }
            }
        }
        .accessibilityActions {
            if debt.remaining > 0 {
                Button("Record part of it") { action = .record(debt.person) }
                Button("Mark as paid on another day") { action = .markPaid(debt.person) }
            }
        }
    }

    private func markPaid(_ debt: TDDebt) {
        withAnimation(reduceMotion ? nil : .snappy) {
            record.markPaid(debt.person)
            if let repayment = record.repayments.last {
                undo = Undo(repaymentID: repayment.id, name: debt.person.name)
            }
        }
    }

    private func undoBar(_ undo: Undo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .accessibilityHidden(true)
            Text("\(undo.name) marked as paid today")
                .font(.subheadline.weight(.medium))
            Spacer(minLength: 8)
            Button("Undo") {
                withAnimation(reduceMotion ? nil : .snappy) {
                    record.undo(undo.repaymentID)
                    self.undo = nil
                }
            }
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

/// Your share and each friend's share around a ring, with what's still owed in the middle.
private struct RowanRing: View {
    private struct Segment: Identifiable {
        let id: String
        let value: Decimal
        let color: Color
    }

    let record: TDRecord

    @ScaledMetric private var size: CGFloat = 170

    private var segments: [Segment] {
        var segments = [Segment(id: "me", value: record.myShare, color: .gray.opacity(0.35))]
        for debt in record.debts {
            segments.append(Segment(id: "\(debt.id)-paid", value: debt.paid, color: debt.person.color))
            segments.append(Segment(id: "\(debt.id)-left", value: debt.remaining, color: debt.person.color.opacity(0.28)))
        }
        return segments.filter { $0.value > 0 }
    }

    var body: some View {
        Chart(segments) { segment in
            SectorMark(
                angle: .value("Amount", segment.value.plotValue),
                innerRadius: .ratio(0.66),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(segment.color)
        }
        .chartLegend(.hidden)
        .chartBackground { _ in
            VStack(spacing: 0) {
                Text(record.owedToYou, format: .currency(code: record.code))
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                Text("still owed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: min(size, 240), height: min(size, 240))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Owed to you"))
        .accessibilityValue(Text("\(record.owedToYou.formatted(.currency(code: record.code))) of \(record.debts.reduce(0) { $0 + $1.share }.formatted(.currency(code: record.code)))"))
    }
}

#Preview("Rowan · Split") {
    TDHost { RowanDetail(record: $0) }
}

#Preview("Rowan · By item") {
    TDHost(opening: 1) { RowanDetail(record: $0) }
}
#endif
