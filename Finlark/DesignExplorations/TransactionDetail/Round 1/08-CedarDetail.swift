//
//  08-CedarDetail.swift
//  Finlark
//
//  FIN-9 Transaction detail, Round 1 "Cedar": the split as a story, top to bottom. You paid, then each
//  repayment as it came in, and at the end who still owes what. Tap a repayment to edit or delete it.
//  A floating Record a repayment button asks who paid, then how much. Edit is in place.
//

#if DEBUG
import SwiftUI

struct CedarDetail: View {
    let record: TDRecord

    @State private var editing: AEDraft?
    @State private var action: TDRepaymentAction?
    @State private var isChoosingPerson = false

    /// Oldest first, as the story goes.
    private var repayments: [TDRepayment] { record.history.reversed() }

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
                    }
                }
                R2Tile {
                    VStack(alignment: .leading, spacing: 0) {
                        R2TileHeader(title: "Paying back", symbol: "arrow.uturn.backward")
                            .padding(.bottom, 14)
                        story
                    }
                }
            }
            TDDeleteButton(record: record)
                .padding(.top, 12)
        }
        .safeAreaInset(edge: .bottom) {
            if editing == nil, record.isSplit, !record.openDebts.isEmpty {
                Button {
                    isChoosingPerson = true
                } label: {
                    Label("Record a repayment", systemImage: "plus.circle.fill")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding(.bottom, 8)
                .confirmationDialog("Who paid you back?", isPresented: $isChoosingPerson, titleVisibility: .visible) {
                    ForEach(record.openDebts) { debt in
                        Button {
                            action = .record(debt.person)
                        } label: {
                            Text("\(debt.person.name) · \(debt.remaining, format: .currency(code: record.code)) left")
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .sheet(item: $action) { TDRepaymentSheet(record: record, action: $0) }
    }

    private var story: some View {
        VStack(alignment: .leading, spacing: 0) {
            node(symbol: "creditcard.fill", tint: .accentColor, isLast: false) {
                Text("You paid \(record.saved.total, format: .currency(code: record.code))")
                    .fontWeight(.semibold)
                Text("\(Text(record.saved.date, format: .dateTime.day().month())) · your share \(record.myShare, format: .currency(code: record.code))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(repayments) { repayment in
                node(symbol: "arrow.uturn.backward", tint: .green, isLast: false) {
                    Button {
                        action = .edit(repayment)
                    } label: {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                if let person = record.person(repayment.personID) {
                                    Text("\(person.displayName) paid you back \(repayment.amount, format: .currency(code: record.code))")
                                }
                                Text(repayment.date, format: .dateTime.day().month())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 8)
                            R2Chevron()
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(Text("Edit or delete this repayment"))
                }
            }

            if record.openDebts.isEmpty {
                node(symbol: "checkmark.seal.fill", tint: .green, isLast: true) {
                    Text("Everyone has paid you back")
                        .fontWeight(.semibold)
                }
            } else {
                node(symbol: "clock.fill", tint: .orange, isLast: true) {
                    Text("Still owed \(record.owedToYou, format: .currency(code: record.code))")
                        .fontWeight(.semibold)
                    ForEach(record.openDebts) { debt in
                        TDPersonLine(debt: debt, code: record.code, avatarSize: 24) {
                            Button("Mark as paid") {
                                action = .markPaid(debt.person)
                            }
                            .font(.subheadline.weight(.semibold))
                            .buttonStyle(.glass)
                            .accessibilityLabel(Text("Mark \(debt.person.name) as paid"))
                        }
                        .padding(.top, 6)
                    }
                }
            }
        }
        .font(.subheadline)
    }

    /// A step of the story: a dot, the line down to the next step, and what happened.
    private func node<Content: View>(
        symbol: String, tint: Color, isLast: Bool, @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: symbol)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(tint.opacity(0.16), in: .circle)
                if !isLast {
                    Rectangle()
                        .fill(.quaternary)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 4)
            .padding(.bottom, isLast ? 0 : 18)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Cedar · Split") {
    TDHost { CedarDetail(record: $0) }
}

#Preview("Cedar · By item") {
    TDHost(opening: 1) { CedarDetail(record: $0) }
}
#endif
