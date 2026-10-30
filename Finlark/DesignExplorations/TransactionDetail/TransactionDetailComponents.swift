//
//  TransactionDetailComponents.swift
//  Finlark
//
//  FIN-9 Transaction detail: pieces shared by the detail explorations. View mode shows Dunlin's tiles
//  read-only with the split detail (SPL-005); Edit switches the screen into Dunlin itself, in place or
//  as a sheet. Marsh's look throughout: glass tiles, soft icons, system glass buttons.
//

#if DEBUG
import SwiftUI

// MARK: - Host

/// Opens a detail from a stand-in for History (TRX-005), as tapping a row would. Back returns to the
/// list, where every sample can be opened, and a deleted transaction disappears from it.
struct TDHost<Detail: View>: View {
    @State private var records: [TDRecord]
    @State private var path: [TDRecord]
    private let detail: (TDRecord) -> Detail

    /// `opening` is the sample pushed right away: 0 the equal dinner, 1 the By item pizzeria,
    /// 2 groceries without a split, 3 an income.
    init(opening: Int? = 0, @ViewBuilder detail: @escaping (TDRecord) -> Detail) {
        let records = TDRecord.samples
        _records = State(initialValue: records)
        _path = State(initialValue: opening.map { [records[$0]] } ?? [])
        self.detail = detail
    }

    var body: some View {
        NavigationStack(path: $path) {
            List(records.filter { !$0.isDeleted }) { record in
                NavigationLink(value: record) {
                    TDHistoryRow(record: record)
                }
            }
            .navigationTitle("History")
            .navigationDestination(for: TDRecord.self) { detail($0) }
        }
        .environment(\.explorationIconStyle, .soft)
    }
}

/// A History row: amount paid and, for splits, the user's share (TRX-005).
struct TDHistoryRow: View {
    let record: TDRecord

    var body: some View {
        HStack(spacing: 12) {
            if let category = record.saved.category {
                ExplorationCategoryIcon(category: category)
            }
            VStack(alignment: .leading, spacing: 2) {
                record.title
                AEDateText(date: record.saved.date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.signedAmount, format: .currency(code: record.code).sign(strategy: .always()))
                    .fontWeight(.medium)
                if record.isSplit {
                    Label {
                        Text("Your share \(record.myShare, format: .currency(code: record.code))")
                    } icon: {
                        Image(systemName: "person.2.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Screen (view and edit modes)

enum TDEditStyle {
    /// The tiles turn into Dunlin's fields on the same screen, with Cancel and Save, like Contacts.
    case inPlace
    /// Dunlin opens as a sheet over the detail.
    case sheet
}

/// The detail screen: view-mode tiles, and Dunlin for editing. Variants own `editing` so they can add
/// toolbar items that only show in view mode.
struct TDScreen<Content: View>: View {
    let record: TDRecord
    @Binding var editing: AEDraft?
    var editStyle: TDEditStyle = .inPlace
    /// Puts Delete at the bottom of the editor instead of in the view-mode content, as Contacts does.
    var deletesInEditMode = false
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isEditingInPlace: Bool { editStyle == .inPlace && editing != nil }

    var body: some View {
        ScrollView {
            Group {
                if let editing, editStyle == .inPlace {
                    VStack(spacing: r2TileSpacing) {
                        AE2KestrelTiles(draft: editing) {
                            DunlinCategoryPicker(draft: editing)
                        } split: {
                            DunlinSplitEditor(draft: editing)
                        }
                        if deletesInEditMode {
                            TDDeleteButton(record: record)
                                .padding(.top, 12)
                        }
                    }
                    .transition(.opacity)
                } else {
                    VStack(spacing: r2TileSpacing) {
                        content
                    }
                    .transition(.opacity)
                }
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .background { R2Backdrop() }
        .navigationTitle(isEditingInPlace ? Text(editing?.title ?? record.saved.type.editTitle) : Text(record.saved.type.title))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isEditingInPlace)
        .toolbar {
            if isEditingInPlace, let editing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { finish() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        record.save(editing)
                        finish()
                    }
                    .disabled(!editing.canSave)
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { start() }
                }
            }
        }
        .sheet(isPresented: isEditingInSheet) {
            if let editing {
                DunlinEditor(draft: editing) { record.save(editing) }
            }
        }
        .environment(\.explorationIconStyle, .soft)
    }

    private var isEditingInSheet: Binding<Bool> {
        Binding {
            editStyle == .sheet && editing != nil
        } set: { isPresented in
            if !isPresented { editing = nil }
        }
    }

    private func start() {
        withAnimation(editStyle == .inPlace && !reduceMotion ? .smooth : nil) {
            editing = record.editingDraft()
        }
    }

    private func finish() {
        withAnimation(reduceMotion ? nil : .smooth) { editing = nil }
    }
}

// MARK: - Read-only tiles

/// Dunlin's amount tile, read-only: the type, the full amount paid and, for splits, the user's share.
struct TDAmountTile: View {
    let record: TDRecord

    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 46

    var body: some View {
        R2Tile(padding: 18) {
            VStack(spacing: 6) {
                Label {
                    Text(record.saved.type.title)
                } icon: {
                    Image(systemName: record.saved.type.symbol)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

                Text(record.saved.total, format: .currency(code: record.code))
                    .font(.system(size: min(size, 70), weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if record.isSplit {
                    Text("Your share \(record.myShare, format: .currency(code: record.code))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .combine)
        }
    }
}

/// Category, date and note as labeled rows (TRX-006).
struct TDDetailsTile: View {
    let record: TDRecord

    var body: some View {
        R2Tile {
            VStack(alignment: .leading, spacing: 0) {
                R2TileHeader(title: "Details", symbol: "text.alignleft")
                    .padding(.bottom, 4)
                TDField("Category") {
                    AECategoryLabel(category: record.saved.category)
                }
                Divider()
                TDField("Date") {
                    Text(record.saved.date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                }
                if !record.saved.note.isEmpty {
                    Divider()
                    TDField("Note") {
                        Text(verbatim: record.saved.note)
                    }
                }
            }
        }
    }
}

struct TDField<Value: View>: View {
    let title: LocalizedStringKey
    @ViewBuilder var value: Value

    init(_ title: LocalizedStringKey, @ViewBuilder value: () -> Value) {
        self.title = title
        self.value = value()
    }

    var body: some View {
        LabeledContent {
            value
                .multilineTextAlignment(.trailing)
        } label: {
            Text(title)
        }
        .padding(.vertical, 10)
    }
}

/// Total paid, the user's share, what's still owed, and the mode (SPL-005).
struct TDSplitFigures: View {
    let record: TDRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 16) { figures }
                VStack(alignment: .leading, spacing: 10) { figures }
            }
            Label {
                record.saved.splitSummary
            } icon: {
                Image(systemName: record.saved.splitMode.symbol)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var figures: some View {
        TDFigure(title: "Total paid", value: record.saved.total, code: record.code)
        TDFigure(title: "Your share", value: record.myShare, code: record.code)
        TDFigure(title: "Owed to you", value: record.owedToYou, code: record.code)
    }
}

struct TDFigure: View {
    let title: LocalizedStringKey
    let value: Decimal
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

/// One person's share, paid so far and what's left, side by side, or stacked when they don't fit.
struct TDDebtFigures: View {
    let debt: TDDebt
    let code: String
    var spacing: CGFloat = 16

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: spacing) { figures }
            VStack(alignment: .leading, spacing: 8) { figures }
        }
    }

    @ViewBuilder
    private var figures: some View {
        TDFigure(title: "Share", value: debt.share, code: code)
        TDFigure(title: "Paid", value: debt.paid, code: code)
        TDFigure(title: "Left", value: debt.remaining, code: code)
    }
}

/// By item lines, read-only: name, who had it, and the amount (SPL-004).
struct TDItemsList: View {
    let draft: AEDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(draft.items) { item in
                let people = draft.everyone.filter { item.assignees.contains($0.id) }
                let amount = AEMoney.parse(item.amountText) ?? 0
                HStack(spacing: 8) {
                    item.name.isEmpty ? Text("Item") : Text(verbatim: item.name)
                    Spacer(minLength: 8)
                    HStack(spacing: 2) {
                        ForEach(people) { AEAvatar(person: $0, size: 20) }
                    }
                    Text(amount, format: .currency(code: draft.currencyCode))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(itemLabel(item, people: people, amount: amount))
            }
        }
    }

    private func itemLabel(_ item: AESplitItem, people: [AEPerson], amount: Decimal) -> Text {
        let name = item.name.isEmpty ? String(localized: "Item") : item.name
        let names = people.map { $0.isMe ? String(localized: "You") : $0.name }.formatted(.list(type: .and))
        let price = amount.formatted(.currency(code: draft.currencyCode))
        return people.isEmpty
            ? Text("\(name), \(price), yours")
            : Text("\(name), \(price), had by \(names)")
    }
}

/// The user's own share, which counts as spending (SPL-001).
struct TDMyShareRow: View {
    let record: TDRecord

    var body: some View {
        AEShareRow(share: AEShare(person: .me, amount: record.myShare, repaid: 0), currencyCode: record.code)
    }
}

// MARK: - Status (SPL-005)

extension TDDebt {
    /// *Pending*, *Partially paid X of Y* or *Paid*.
    func statusText(code: String) -> Text {
        switch status {
        case .pending:
            Text("Pending")
        case .partiallyPaid:
            Text("Partially paid \(paid, format: .currency(code: code)) of \(share, format: .currency(code: code))")
        case .paid:
            Text("Paid")
        }
    }
}

struct TDStatusLabel: View {
    let debt: TDDebt
    let code: String

    var body: some View {
        Label {
            debt.statusText(code: code)
        } icon: {
            Image(systemName: debt.status.symbol)
                .foregroundStyle(debt.status.tint)
        }
    }
}

/// A friend's avatar (or another leading view), name and status, with something trailing: an amount
/// or a button. At accessibility sizes the leading view goes and the trailing part moves under the
/// name, so nothing is squeezed into a narrow column.
struct TDPersonLine<Leading: View, Trailing: View>: View {
    let debt: TDDebt
    let code: String
    @ViewBuilder var leading: Leading
    @ViewBuilder var trailing: Trailing

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                identity
                    .frame(maxWidth: .infinity, alignment: .leading)
                trailing
            }
        } else {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    leading
                    identity
                    Spacer(minLength: 8)
                }
                .accessibilityElement(children: .combine)
                trailing
            }
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 2) {
            debt.person.displayName
                .fontWeight(.medium)
            TDStatusLabel(debt: debt, code: code)
                .font(.caption)
        }
        .accessibilityElement(children: .combine)
    }
}

extension TDPersonLine where Leading == AEAvatar {
    init(debt: TDDebt, code: String, avatarSize: CGFloat = 30, @ViewBuilder trailing: () -> Trailing) {
        self.init(debt: debt, code: code) {
            AEAvatar(person: debt.person, size: avatarSize)
        } trailing: {
            trailing()
        }
    }
}

/// How much of the share is paid, in the person's color. Decorative: the status says it in words.
struct TDProgressBar: View {
    let debt: TDDebt

    @ScaledMetric private var height: CGFloat = 6

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary)
                Capsule()
                    .fill(debt.person.color)
                    .frame(width: proxy.size.width * debt.progress)
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

/// A ring that fills as the share is paid, with a check when it's done. Decorative.
struct TDProgressRing: View {
    let debt: TDDebt
    var size: CGFloat = 44

    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        let side = size * min(scale, 1.5)
        ZStack {
            Circle().stroke(.quaternary, lineWidth: side * 0.11)
            Circle()
                .trim(from: 0, to: debt.progress)
                .stroke(debt.person.color, style: StrokeStyle(lineWidth: side * 0.11, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if debt.status == .paid {
                Image(systemName: "checkmark")
                    .font(.system(size: side * 0.36, weight: .bold))
                    .foregroundStyle(debt.person.color)
            } else {
                Text(verbatim: debt.person.initial)
                    .font(.system(size: side * 0.38, weight: .bold, design: .rounded))
                    .foregroundStyle(debt.person.color)
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

/// A repayment as a line: amount and date, and optionally who paid it.
struct TDRepaymentLine: View {
    let repayment: TDRepayment
    let record: TDRecord
    var showsPerson = false

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(spacing: 8))
        layout {
            if showsPerson, let person = record.person(repayment.personID) {
                AEAvatar(person: person, size: 22)
                person.displayName
            } else {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
            }
            Text(repayment.amount, format: .currency(code: record.code))
                .fontWeight(.medium)
                .monospacedDigit()
            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 8)
            }
            AEDateText(date: repayment.date)
                .foregroundStyle(.secondary)
        }
        .font(.subheadline)
        .accessibilityElement(children: .combine)
    }
}

/// A person's repayments as small chips (amount and date) that scroll sideways. Tapping one edits it.
struct TDRepaymentChips: View {
    let debt: TDDebt
    let record: TDRecord
    let onEdit: (TDRepayment) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(debt.repayments) { repayment in
                    Button {
                        onEdit(repayment)
                    } label: {
                        Text("\(repayment.amount, format: .currency(code: record.code)) · \(repayment.date, format: .dateTime.day().month())")
                            .font(.caption.weight(.medium))
                            .monospacedDigit()
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.fill.tertiary, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Repayment of \(repayment.amount.formatted(.currency(code: record.code))) on \(repayment.date.formatted(.dateTime.day().month()))"))
                    .accessibilityHint(Text("Edit or delete this repayment"))
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Repayment sheet (SPL-006, SPL-007, SPL-009)

enum TDRepaymentAction: Identifiable {
    case markPaid(AEPerson)
    case record(AEPerson)
    case edit(TDRepayment)

    var id: String {
        switch self {
        case .markPaid(let person): "paid-\(person.id)"
        case .record(let person): "record-\(person.id)"
        case .edit(let repayment): "edit-\(repayment.id)"
        }
    }
}

/// Mark as paid (the whole remaining amount), record part of it, or edit a repayment. The date
/// defaults to today and can be changed (SPL-006). The amount can't go over what's left (A-04).
struct TDRepaymentSheet: View {
    let record: TDRecord
    let action: TDRepaymentAction

    @State private var amountText: String
    @State private var date: Date
    @State private var isConfirmingUndo = false
    @Environment(\.dismiss) private var dismiss

    init(record: TDRecord, action: TDRepaymentAction) {
        self.record = record
        self.action = action
        let digits = record.saved.fractionDigits
        switch action {
        case .markPaid(let person):
            _amountText = State(initialValue: AEMoney.text(for: record.maximum(for: person.id), fractionDigits: digits))
            _date = State(initialValue: .now)
        case .record:
            _amountText = State(initialValue: "")
            _date = State(initialValue: .now)
        case .edit(let repayment):
            _amountText = State(initialValue: AEMoney.text(for: repayment.amount, fractionDigits: digits))
            _date = State(initialValue: repayment.date)
        }
    }

    private var personID: AEPerson.ID {
        switch action {
        case .markPaid(let person), .record(let person): person.id
        case .edit(let repayment): repayment.personID
        }
    }

    private var repaymentID: TDRepayment.ID? {
        if case .edit(let repayment) = action { return repayment.id }
        return nil
    }

    private var person: AEPerson? { record.person(personID) }
    private var maximum: Decimal { record.maximum(for: personID, editing: repaymentID) }
    private var amount: Decimal { AEMoney.parse(amountText) ?? 0 }
    private var isTooMuch: Bool { amount > maximum }
    private var canSave: Bool { amount > 0 && !isTooMuch }

    private var title: LocalizedStringKey {
        switch action {
        case .markPaid: "Mark as paid"
        case .record: "Record a repayment"
        case .edit: "Edit repayment"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                if let person, let debt = record.debt(for: person) {
                    Section {
                        HStack(spacing: 12) {
                            AEAvatar(person: person, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                person.displayName
                                    .font(.headline)
                                TDStatusLabel(debt: debt, code: record.code)
                                    .font(.subheadline)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                Section {
                    LabeledContent("Amount") {
                        if case .markPaid = action {
                            Text(maximum, format: .currency(code: record.code))
                                .monospacedDigit()
                        } else {
                            AEMoneyField(title: "Amount", text: $amountText, draft: record.saved)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                } footer: {
                    if isTooMuch {
                        Label {
                            Text("That's more than the \(maximum, format: .currency(code: record.code)) left on this share.")
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    } else {
                        Text("Raises your balance. A repayment isn't income and doesn't change your spending.")
                    }
                }

                if case .record = action, maximum > 0 {
                    Section {
                        Button {
                            amountText = AEMoney.text(for: maximum, fractionDigits: record.saved.fractionDigits)
                        } label: {
                            Text("Use what's left · \(maximum, format: .currency(code: record.code))")
                        }
                    }
                }

                if case .edit = action {
                    Section {
                        Button("Delete repayment", systemImage: "trash", role: .destructive) {
                            isConfirmingUndo = true
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) { save() }
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Delete this repayment?", isPresented: $isConfirmingUndo, titleVisibility: .visible) {
                Button("Delete repayment", role: .destructive) {
                    if let repaymentID { record.undo(repaymentID) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("What they owe you goes back up, and so does Owed to you.")
            }
        }
        .presentationDetents([.medium, .large])
        .environment(\.explorationIconStyle, .soft)
    }

    private func save() {
        switch action {
        case .markPaid(let person):
            record.markPaid(person, on: date)
        case .record(let person):
            record.record(amount, from: person, on: date)
        case .edit(let repayment):
            record.update(repayment.id, amount: amount, date: date)
        }
        dismiss()
    }
}

// MARK: - Delete (TRX-004, SPL-011)

extension ExplorationTransactionType {
    var deleteTitle: LocalizedStringResource {
        switch self {
        case .expense: "Delete expense"
        case .income: "Delete income"
        }
    }

    var deleteQuestion: LocalizedStringResource {
        switch self {
        case .expense: "Delete this expense?"
        case .income: "Delete this income?"
        }
    }
}

/// Delete at the end of the screen, in its own tile.
struct TDDeleteButton: View {
    let record: TDRecord

    @State private var isConfirming = false

    var body: some View {
        Button(role: .destructive) {
            isConfirming = true
        } label: {
            Label {
                Text(record.saved.type.deleteTitle)
            } icon: {
                Image(systemName: "trash")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.glass)
        .tint(.red)
        .tdDeleteConfirmation(record: record, isPresented: $isConfirming)
    }
}

private struct TDDeleteConfirmation: ViewModifier {
    let record: TDRecord
    @Binding var isPresented: Bool

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content.confirmationDialog(
            Text(record.saved.type.deleteQuestion),
            isPresented: $isPresented,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                record.delete()
                dismiss()
            } label: {
                if record.totalRepaid > 0 {
                    Text("Delete with its repayments")
                } else {
                    Text(record.saved.type.deleteTitle)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            message
        }
    }

    private var message: Text {
        let code = record.code
        guard record.isSplit else { return Text("It's removed and your totals update.") }
        guard record.totalRepaid > 0 else {
            return Text("Its shares go too, so Owed to you drops by \(record.owedToYou, format: .currency(code: code)).")
        }
        let names = record.debts.filter { $0.paid > 0 }.map(\.person.name).formatted(.list(type: .and))
        return Text("Its repayments will be deleted too: \(record.totalRepaid, format: .currency(code: code)) from \(names). Your balance is recalculated as if neither existed.")
    }
}

extension View {
    /// The delete confirmation, with SPL-011's warning when the split has repayments. Confirming deletes
    /// and goes back.
    func tdDeleteConfirmation(record: TDRecord, isPresented: Binding<Bool>) -> some View {
        modifier(TDDeleteConfirmation(record: record, isPresented: isPresented))
    }
}
#endif
