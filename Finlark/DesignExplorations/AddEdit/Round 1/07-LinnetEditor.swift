//
//  07-LinnetEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 1 "Linnet": the transaction as a paper ticket. The note is its title,
//  date and category sit under it, and the amount is the ticket's total. Splitting turns the ticket
//  into what you'd hold at the table: lines with who had them (By item), or a line per person with
//  dot leaders, and "Your share" and "Owed to you" at the bottom.
//

#if DEBUG
import SwiftUI

struct LinnetEditor: View {
    @State private var draft: AEDraft
    @FocusState private var isAmountFocused: Bool

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    private var code: String { draft.currencyCode }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    AETypePicker(draft: draft)
                    ticket
                    if draft.type == .expense {
                        Button {
                            withAnimation { draft.isSplit.toggle() }
                        } label: {
                            Label(
                                draft.isSplit ? LocalizedStringKey("Don't split this ticket") : "Split this ticket",
                                systemImage: draft.isSplit ? "person.crop.circle.badge.minus" : "person.2"
                            )
                        }
                        .buttonStyle(.glass)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .aeEditorChrome(draft)
        }
        .onAppear { isAmountFocused = draft.purpose == .add }
    }

    private var ticket: some View {
        VStack(alignment: .leading, spacing: 14) {
            TextField("Note", text: $draft.note, prompt: Text("What was it?"), axis: .vertical)
                .font(.title3.weight(.semibold))

            HStack {
                AEDateMenu(draft: draft) {
                    Label { AEDateText(date: draft.date) } icon: { Image(systemName: "calendar") }
                }
                Spacer()
                Menu {
                    Picker("Category", selection: $draft.categoryID) {
                        ForEach(draft.type.categories) { category in
                            Label {
                                Text(category.name)
                            } icon: {
                                Image(systemName: category.symbol)
                            }
                            .tag(Optional(category.id))
                        }
                    }
                } label: {
                    AECategoryLabel(category: draft.category)
                }
                .accessibilityLabel(Text("Category"))
            }
            .font(.subheadline.weight(.medium))

            LinnetPerforation()

            if draft.isSplit {
                splitLines
            } else {
                totalLine
            }
        }
        .padding(20)
        .padding(.bottom, 10)
        .background {
            LinnetTicketShape()
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        }
    }

    private var totalLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Total")
                .font(.headline)
            Spacer(minLength: 12)
            AEAmountField(draft: draft, focus: $isAmountFocused, baseSize: 34)
        }
    }

    @ViewBuilder
    private var splitLines: some View {
        AESplitModePicker(draft: draft)

        if draft.splitMode == .byItem {
            AEItemRows(draft: draft)
            LinnetPerforation()
            LinnetLeaderLine(title: Text("Total"), amount: draft.total, code: code)
                .font(.headline)
        } else {
            totalLine
        }

        Text("With")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
        AEPeoplePicker(draft: draft)

        LinnetPerforation()

        ForEach(draft.shares) { share in
            if draft.splitMode == .exact {
                AEShareRow(share: share, currencyCode: code) {
                    AEMoneyField(title: "Share", text: draft.exactText(for: share.person), draft: draft)
                }
            } else {
                LinnetLeaderLine(title: share.person.displayName, amount: share.amount, code: code)
            }
        }

        LinnetPerforation()

        VStack(spacing: 6) {
            LinnetLeaderLine(title: Text("Your share"), amount: draft.myShare, code: code)
                .font(.headline)
            LinnetLeaderLine(title: Text("Owed to you"), amount: draft.owedToYou, code: code)
                .foregroundStyle(.secondary)
        }
        AESplitFooter(draft: draft)
    }
}

/// A name and an amount joined by dot leaders, as on a printed receipt.
private struct LinnetLeaderLine: View {
    let title: Text
    let amount: Decimal
    let code: String

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            title
            LinnetDots()
                .stroke(.tertiary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 5]))
                .frame(height: 2)
                .alignmentGuide(.lastTextBaseline) { $0[.bottom] }
                .accessibilityHidden(true)
            Text(amount, format: .currency(code: code))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct LinnetDots: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        }
    }
}

/// A dashed tear line across the ticket.
private struct LinnetPerforation: View {
    var body: some View {
        LinnetDots()
            .stroke(.quaternary, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// Rounded top corners and a zigzag bottom edge, like a torn-off receipt.
private struct LinnetTicketShape: Shape {
    var radius: CGFloat = 18
    var tooth: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        Path { path in
            let bottom = rect.maxY - tooth
            path.move(to: CGPoint(x: rect.minX, y: bottom))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(
                center: CGPoint(x: rect.minX + radius, y: rect.minY + radius), radius: radius,
                startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(
                center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius), radius: radius,
                startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: bottom))

            let teeth = max(Int(rect.width / (tooth * 2)), 1)
            let step = rect.width / CGFloat(teeth)
            for index in (0..<teeth).reversed() {
                let x = rect.minX + CGFloat(index) * step
                path.addLine(to: CGPoint(x: x + step / 2, y: rect.maxY))
                path.addLine(to: CGPoint(x: x, y: bottom))
            }
            path.closeSubpath()
        }
    }
}

#Preview("Linnet · Add") {
    AEHomeHost { LinnetEditor(draft: $0) }
}

#Preview("Linnet · Edit by item") {
    AEDetailHost { LinnetEditor(draft: .editByItemSample) }
}
#endif
