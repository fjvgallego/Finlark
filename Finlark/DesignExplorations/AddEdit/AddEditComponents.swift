//
//  AddEditComponents.swift
//  Finlark
//
//  FIN-9 Add & edit: pieces shared by the add and edit transaction explorations. They follow Marsh,
//  the chosen Home: soft tinted icons, Liquid Glass on controls, system buttons.
//

#if DEBUG
import SwiftUI

// MARK: - Hosts

/// Opens an add screen from Marsh, as its toolbar "+" does (tap for an expense, hold for an income).
/// It opens right away, and "+" reopens it after it's dismissed.
struct AEHomeHost<Editor: View>: View {
    var type: ExplorationTransactionType = .expense
    @ViewBuilder let editor: (AEDraft) -> Editor

    var body: some View {
        MarshHomeView(addingType: type) { type in
            AnyView(editor(.new(type)))
        }
    }
}

/// Opens an edit screen as a sheet over a stand-in for the transaction detail (TRX-006), which isn't
/// designed yet. "Edit" reopens it.
struct AEDetailHost<Editor: View>: View {
    @ViewBuilder let editor: () -> Editor

    @State private var isEditing = true

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Transaction detail", systemImage: "doc.text")
            } description: {
                Text("This screen isn't part of the Add & edit exploration.")
            }
            .toolbar {
                Button("Edit") { isEditing = true }
            }
        }
        .sheet(isPresented: $isEditing) { editor() }
    }
}

// MARK: - Chrome

private struct AEEditorChrome: ViewModifier {
    let draft: AEDraft
    let title: LocalizedStringKey?
    let showsCancel: Bool
    let showsSave: Bool
    let onSave: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationTitle(title.map { Text($0) } ?? Text(draft.title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsCancel {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                    }
                }
                if showsSave {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save", systemImage: "checkmark", role: .confirm) {
                            onSave?()
                            dismiss()
                        }
                            .disabled(!draft.canSave)
                    }
                }
            }
            .environment(\.explorationIconStyle, .soft)
    }
}

extension View {
    /// Title, Cancel and Save (enabled only when the draft can be saved), with Marsh's soft icons.
    func aeEditorChrome(
        _ draft: AEDraft,
        title: LocalizedStringKey? = nil,
        showsCancel: Bool = true,
        showsSave: Bool = true,
        onSave: (() -> Void)? = nil
    ) -> some View {
        modifier(AEEditorChrome(
            draft: draft, title: title, showsCancel: showsCancel, showsSave: showsSave, onSave: onSave
        ))
    }
}

// MARK: - Amount

/// The amount as typed, with the currency symbol on the side the locale puts it.
struct AEAmountText: View {
    let text: String
    let currencyCode: String
    var baseSize: CGFloat = 52

    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1

    var body: some View {
        let affix = AEMoney.affix(for: currencyCode)
        let size = min(baseSize * scale, baseSize * 1.5)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if affix.isLeading { symbol(affix.symbol, size: size) }
            Text(verbatim: text.isEmpty ? "0" : text)
                .foregroundStyle(text.isEmpty ? .tertiary : .primary)
            if !affix.isLeading { symbol(affix.symbol, size: size) }
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Amount"))
        .accessibilityValue(Text(AEMoney.parse(text) ?? 0, format: .currency(code: currencyCode)))
    }

    private func symbol(_ symbol: String, size: CGFloat) -> some View {
        Text(verbatim: symbol)
            .font(.system(size: size * 0.6, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

/// The big amount field, typed with the decimal pad. In By item mode it shows the sum of the items
/// instead, which can't be typed (SPL-004).
struct AEAmountField: View {
    @Bindable var draft: AEDraft
    var focus: FocusState<Bool>.Binding
    var baseSize: CGFloat = 52

    @ScaledMetric(relativeTo: .largeTitle) private var scale: CGFloat = 1

    var body: some View {
        if draft.isAmountFromItems {
            VStack(spacing: 2) {
                AEAmountText(text: draft.amountDisplayText, currencyCode: draft.currencyCode, baseSize: baseSize)
                Text("Sum of the items")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            field
        }
    }

    private var field: some View {
        let affix = AEMoney.affix(for: draft.currencyCode)
        let size = min(baseSize * scale, baseSize * 1.5)

        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            if affix.isLeading { symbol(affix.symbol, size: size) }
            TextField("Amount", text: $draft.amountText, prompt: Text(verbatim: "0"))
                .keyboardType(.decimalPad)
                .focused(focus)
                .fixedSize()
            if !affix.isLeading { symbol(affix.symbol, size: size) }
        }
        .font(.system(size: size, weight: .bold, design: .rounded))
        .monospacedDigit()
        .onChange(of: draft.amountText) { _, newValue in
            let clean = AEMoney.sanitize(newValue, fractionDigits: draft.fractionDigits)
            if clean != newValue { draft.amountText = clean }
        }
    }

    private func symbol(_ symbol: String, size: CGFloat) -> some View {
        Text(verbatim: symbol)
            .font(.system(size: size * 0.6, weight: .semibold, design: .rounded))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
}

/// A small amount field for a share or an item.
struct AEMoneyField: View {
    let title: LocalizedStringKey
    @Binding var text: String
    let draft: AEDraft

    var body: some View {
        let affix = AEMoney.affix(for: draft.currencyCode)

        HStack(spacing: 2) {
            if affix.isLeading { Text(verbatim: affix.symbol).foregroundStyle(.secondary) }
            TextField(title, text: $text, prompt: Text(verbatim: "0"))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .fixedSize()
            if !affix.isLeading { Text(verbatim: affix.symbol).foregroundStyle(.secondary) }
        }
        .monospacedDigit()
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.fill.tertiary, in: .rect(cornerRadius: 10, style: .continuous))
        .onChange(of: text) { _, newValue in
            let clean = AEMoney.sanitize(newValue, fractionDigits: draft.fractionDigits)
            if clean != newValue { text = clean }
        }
    }
}

/// An in-app number pad on Liquid Glass keys, for variants that don't use the system keyboard.
/// Holding delete clears the amount.
struct AEKeypad: View {
    @Binding var text: String
    let fractionDigits: Int

    @ScaledMetric(relativeTo: .title2) private var keyHeight: CGFloat = 50
    @State private var taps = 0

    private let rows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(rows, id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { digit in
                            key(Text(verbatim: digit)) { append(digit) }
                        }
                    }
                }
                GridRow {
                    key(Text(verbatim: AEMoney.separator)) { append(AEMoney.separator) }
                        .accessibilityLabel(Text("Decimal separator"))
                        .disabled(fractionDigits == 0)
                    key(Text(verbatim: "0")) { append("0") }
                    key(Image(systemName: "delete.backward")) {
                        text = String(text.dropLast())
                    }
                    .accessibilityLabel(Text("Delete"))
                    .simultaneousGesture(LongPressGesture().onEnded { _ in text = "" })
                }
            }
        }
        .sensoryFeedback(.selection, trigger: taps)
    }

    private func append(_ character: String) {
        text = AEMoney.sanitize(text + character, fractionDigits: fractionDigits)
    }

    private func key(_ label: some View, action: @escaping () -> Void) -> some View {
        Button {
            taps += 1
            action()
        } label: {
            label
                .font(.system(.title2, design: .rounded, weight: .semibold))
                // Capped so large text can't push the rest of the screen out.
                .frame(maxWidth: .infinity, minHeight: min(keyHeight, 64))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Type (TRX-002, TRX-003)

/// Expense | Income. Locked while the expense is split, with the reason underneath.
struct AETypePicker: View {
    @Bindable var draft: AEDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            R6SegmentedControl(
                title: "Type",
                options: [(value: .expense, label: "Expense"), (value: .income, label: "Income")],
                selection: $draft.type
            )
            .disabled(!draft.canChangeType)

            if !draft.canChangeType {
                Text("A split expense can't become income. Turn off Split first.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Category

/// Every category of the draft's type as a grid of icons with names under them.
struct AECategoryGrid: View {
    @Bindable var draft: AEDraft
    var columns = 4
    /// A subset to show, for paged grids. All of the draft's type when nil.
    var categories: [ExplorationCategory]?
    /// Matches each cell with the same category in another grid, so a pick can fly between them.
    var namespace: Namespace.ID?
    /// Animates the pick and `onPick` together, which the matched cells need to move.
    var pickAnimation: Animation?
    var onPick: () -> Void = {}

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let count = dynamicTypeSize.isAccessibilitySize ? 2 : columns
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: count), spacing: 6) {
            ForEach(categories ?? draft.type.categories) { category in
                let isSelected = draft.categoryID == category.id
                Button {
                    if let pickAnimation {
                        withAnimation(pickAnimation) {
                            draft.categoryID = category.id
                            onPick()
                        }
                    } else {
                        draft.categoryID = category.id
                        onPick()
                    }
                } label: {
                    VStack(spacing: 6) {
                        ExplorationCategoryIcon(category: category)
                        Text(category.name)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .lineLimit(2, reservesSpace: !dynamicTypeSize.isAccessibilitySize)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 2)
                    .background(
                        isSelected ? category.color.opacity(0.14) : .clear,
                        in: .rect(cornerRadius: 14, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isSelected ? category.color : .clear, lineWidth: 1.5)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .modifier(AEMatchedCell(id: category.id, namespace: namespace))
            }
        }
    }
}

private struct AEMatchedCell: ViewModifier {
    let id: String
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedGeometryEffect(id: id, in: namespace)
        } else {
            content
        }
    }
}

/// The most used categories as a row of chips that scrolls sideways.
struct AECategoryChips: View {
    @Bindable var draft: AEDraft

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(draft.type.frequentCategories) { category in
                    let isSelected = draft.categoryID == category.id
                    Button {
                        draft.categoryID = category.id
                    } label: {
                        Label {
                            Text(category.name)
                        } icon: {
                            Image(systemName: category.symbol)
                                .foregroundStyle(category.color)
                        }
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            isSelected ? AnyShapeStyle(category.color.opacity(0.18)) : AnyShapeStyle(.fill.tertiary),
                            in: .capsule
                        )
                        .overlay {
                            Capsule().strokeBorder(isSelected ? category.color : .clear, lineWidth: 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

/// The selected category as a label, or a prompt.
struct AECategoryLabel: View {
    let category: ExplorationCategory?

    var body: some View {
        // An HStack rather than a Label: LabeledContent restyles a Label value into a tall stack.
        if let category {
            HStack(spacing: 6) {
                Image(systemName: category.symbol)
                    .foregroundStyle(category.color)
                    .accessibilityHidden(true)
                Text(category.name)
            }
        } else {
            Text("Choose")
                .foregroundStyle(.secondary)
        }
    }
}

/// Categories as a list to push to, as Settings-style pickers do.
struct AECategoryListScreen: View {
    @Bindable var draft: AEDraft
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List(draft.type.categories) { category in
            Button {
                draft.categoryID = category.id
                dismiss()
            } label: {
                HStack(spacing: 12) {
                    ExplorationCategoryIcon(category: category)
                    Text(category.name)
                    Spacer()
                    if draft.categoryID == category.id {
                        Image(systemName: "checkmark")
                            .fontWeight(.semibold)
                            .foregroundStyle(.tint)
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(draft.categoryID == category.id ? .isSelected : [])
        }
        .navigationTitle("Category")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.explorationIconStyle, .soft)
    }
}

/// The category grid in its own sheet.
struct AECategorySheet: View {
    @Bindable var draft: AEDraft
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                AECategoryGrid(draft: draft) { dismiss() }
                    .padding()
            }
            .navigationTitle("Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark", role: .close) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .environment(\.explorationIconStyle, .soft)
    }
}

// MARK: - Date and note

/// "Today", "Yesterday" or the date. `inSentence` gives lowercase forms for running text.
struct AEDateText: View {
    let date: Date
    var inSentence = false

    var body: some View {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            inSentence ? Text("today") : Text("Today")
        } else if calendar.isDateInYesterday(date) {
            inSentence ? Text("yesterday") : Text("Yesterday")
        } else if calendar.isDateInTomorrow(date) {
            inSentence ? Text("tomorrow") : Text("Tomorrow")
        } else if calendar.isDate(date, equalTo: .now, toGranularity: .year) {
            inSentence
                ? Text("on \(date, format: .dateTime.day().month())")
                : Text(date, format: .dateTime.weekday().day().month())
        } else {
            inSentence
                ? Text("on \(date, format: .dateTime.day().month().year())")
                : Text(date, format: .dateTime.day().month().year())
        }
    }
}

/// Quick dates in a menu, plus a full calendar. Dates can be past or future (TRX-001).
struct AEDateMenu<MenuLabel: View>: View {
    @Bindable var draft: AEDraft
    @ViewBuilder var label: MenuLabel

    @State private var isPicking = false

    var body: some View {
        Menu {
            Button("Today", systemImage: "calendar") { draft.date = .now }
            Button("Yesterday", systemImage: "calendar.badge.clock") {
                draft.date = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
            }
            Button("Choose a date…", systemImage: "calendar.circle") { isPicking = true }
        } label: {
            label
        }
        .sheet(isPresented: $isPicking) {
            AEDateSheet(date: $draft.date)
        }
    }
}

struct AEDateSheet: View {
    @Binding var date: Date
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(.horizontal)
                .navigationTitle("Date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done", systemImage: "checkmark", role: .confirm) { dismiss() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

struct AENoteSheet: View {
    @Binding var note: String
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("Note", text: $note, prompt: Text("What was it for?"), axis: .vertical)
                    .lineLimit(3...6)
                    .focused($isFocused)
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", role: .confirm) { dismiss() }
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - People (SPL-001, PPL-001)

struct AEAvatar: View {
    let person: AEPerson
    var size: CGFloat = 30

    @ScaledMetric private var scale: CGFloat = 1

    var body: some View {
        let side = size * scale
        Group {
            if person.isMe {
                Image(systemName: "person.fill")
                    .font(.system(size: side * 0.45, weight: .semibold))
            } else {
                Text(verbatim: person.initial)
                    .font(.system(size: side * 0.45, weight: .bold, design: .rounded))
            }
        }
        .foregroundStyle(person.color)
        .frame(width: side, height: side)
        .background(person.color.opacity(0.18), in: .rect(cornerRadius: side * 0.32, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// A person who can be added to or removed from the split. A person with repayments shows a lock.
struct AEPersonChip: View {
    let person: AEPerson
    let isSelected: Bool
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                AEAvatar(person: person, size: 24)
                person.displayName
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(person.color)
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.leading, 4)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
            .background(
                isSelected ? AnyShapeStyle(person.color.opacity(0.16)) : AnyShapeStyle(.fill.tertiary),
                in: .capsule
            )
            .overlay {
                Capsule().strokeBorder(isSelected ? person.color.opacity(0.6) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isLocked ? Text("Has already repaid part of the share, so can't be removed.") : Text(""))
    }
}

/// Everyone who can take part, wrapping onto new lines, plus a chip to add someone new.
struct AEPeoplePicker: View {
    @Bindable var draft: AEDraft

    @State private var isAddingPerson = false
    @State private var newName = ""

    var body: some View {
        AEFlowLayout(spacing: 8, lineSpacing: 8) {
            AEPersonChip(person: .me, isSelected: true, isLocked: false) {}
                .disabled(true)
                .accessibilityHint(Text("You're always part of the split."))
            ForEach(draft.people) { person in
                AEPersonChip(
                    person: person,
                    isSelected: draft.isIncluded(person),
                    isLocked: draft.isIncluded(person) && !draft.canRemove(person)
                ) {
                    draft.toggle(person)
                }
            }
            Button {
                newName = ""
                isAddingPerson = true
            } label: {
                Label("New person", systemImage: "plus")
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .overlay { Capsule().strokeBorder(.tint, style: StrokeStyle(lineWidth: 1, dash: [4, 3])) }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tint)
        }
        .alert("New person", isPresented: $isAddingPerson) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Add") { draft.addPerson(named: newName) }
        } message: {
            Text("They'll be added to this split and to People.")
        }
    }
}

// MARK: - Split modes and shares (SPL-002–004)

struct AESplitModePicker: View {
    @Bindable var draft: AEDraft

    var body: some View {
        R6SegmentedControl(
            title: "Split mode",
            options: AESplitMode.allCases.map { (value: $0, label: $0.title) },
            selection: $draft.splitMode
        )
    }
}

/// One participant's share: avatar, name, what they've repaid if anything, and the amount (or a field).
struct AEShareRow<Amount: View>: View {
    let share: AEShare
    let currencyCode: String
    @ViewBuilder var amount: Amount

    var body: some View {
        HStack(spacing: 10) {
            AEAvatar(person: share.person)
            VStack(alignment: .leading, spacing: 1) {
                share.person.displayName
                if share.repaid > 0 {
                    Text("\(share.repaid, format: .currency(code: currencyCode)) repaid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if share.person.isMe {
                    Text("Counts as your spending")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 8)
            amount
        }
        .accessibilityElement(children: .combine)
    }
}

extension AEShareRow where Amount == Text {
    init(share: AEShare, currencyCode: String) {
        self.init(share: share, currencyCode: currencyCode) {
            Text(share.amount, format: .currency(code: currencyCode))
                .monospacedDigit()
                .fontWeight(.medium)
        }
    }
}

/// The shares, read-only in Equal and By item, typed in Exact amounts. Each share is its own row,
/// so a Form lays them out as list rows.
struct AEShareRows: View {
    @Bindable var draft: AEDraft

    var body: some View {
        ForEach(draft.shares) { share in
            if draft.splitMode == .exact {
                AEShareRow(share: share, currencyCode: draft.currencyCode) {
                    AEMoneyField(title: "Share", text: draft.exactText(for: share.person), draft: draft)
                }
            } else {
                AEShareRow(share: share, currencyCode: draft.currencyCode)
            }
        }
    }
}

/// The lines of the ticket in By item mode, each with who had it, and a button to add another.
struct AEItemRows: View {
    @Bindable var draft: AEDraft
    var isCarded = false

    var body: some View {
        ForEach($draft.items) { $item in
            AEItemRow(item: $item, draft: draft)
                .padding(isCarded ? 12 : 0)
                .background(
                    isCarded ? AnyShapeStyle(.fill.quaternary) : AnyShapeStyle(.clear),
                    in: .rect(cornerRadius: 16, style: .continuous)
                )
        }
        Button("Add item", systemImage: "plus.circle.fill") { draft.addItem() }
    }
}

struct AEItemRow: View {
    @Binding var item: AESplitItem
    let draft: AEDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                TextField("Item", text: $item.name, prompt: Text("Item"))
                AEMoneyField(title: "Item amount", text: $item.amountText, draft: draft)
                if draft.items.count > 1 {
                    Button("Remove item", systemImage: "minus.circle.fill", role: .destructive) {
                        draft.removeItem(item.id)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
            }
            AEFlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(draft.everyone) { person in
                    let isAssigned = item.assignees.contains(person.id)
                    Button {
                        draft.toggle(person, on: item.id)
                    } label: {
                        HStack(spacing: 4) {
                            AEAvatar(person: person, size: 20)
                            person.displayName
                        }
                        .font(.caption.weight(.medium))
                        .padding(.leading, 3)
                        .padding(.trailing, 8)
                        .padding(.vertical, 3)
                        .background(
                            isAssigned ? AnyShapeStyle(person.color.opacity(0.16)) : AnyShapeStyle(.fill.tertiary),
                            in: .capsule
                        )
                        .overlay {
                            Capsule().strokeBorder(isAssigned ? person.color.opacity(0.6) : .clear, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isAssigned ? .isSelected : [])
                }
            }
            Group {
                if item.assignees.isEmpty {
                    Text("No one chosen: counts as yours")
                } else if item.assignees.count > 1 {
                    Text("Shared equally by \(item.assignees.count) people")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

/// What's left to assign in Exact amounts, live (SPL-003). Shown with an icon and words, not color alone.
struct AERemainingLabel: View {
    let draft: AEDraft

    var body: some View {
        let remaining = draft.unassigned
        let code = draft.currencyCode
        if remaining == 0 {
            Label("All assigned", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        } else if remaining > 0 {
            Label("\(remaining, format: .currency(code: code)) left to assign", systemImage: "exclamationmark.circle.fill")
                .foregroundStyle(.orange)
        } else {
            Label("\(-remaining, format: .currency(code: code)) over the total", systemImage: "xmark.octagon.fill")
                .foregroundStyle(.red)
        }
    }
}

/// The remaining amount, any problems, and what the split means for spending.
struct AESplitFooter: View {
    let draft: AEDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if draft.splitMode == .exact {
                AERemainingLabel(draft: draft)
                    .fontWeight(.medium)
            }
            ForEach(draft.splitIssues) { issue in
                Label {
                    issue.message
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            if let category = draft.category {
                Text("Only your share counts as spending in \(Text(category.name)).")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.footnote)
    }
}

/// The whole split editor as Form sections: switch, people, mode, items and shares.
struct AESplitFormSections: View {
    @Bindable var draft: AEDraft
    /// Off when the screen around it already has the switch.
    var showsToggle = true

    var body: some View {
        if showsToggle {
            Section {
                Toggle(isOn: $draft.isSplit) {
                    Label("Split with friends", systemImage: "person.2.fill")
                }
            } footer: {
                if !draft.isSplit {
                    Text("For an expense you paid that others owe you part of.")
                }
            }
        }

        if draft.isSplit {
            Section("With") {
                AEPeoplePicker(draft: draft)
                    .padding(.vertical, 4)
            }
            Section {
                AESplitModePicker(draft: draft)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            } footer: {
                Text(draft.splitMode.explanation)
            }
            if draft.splitMode == .byItem {
                Section("Items") {
                    AEItemRows(draft: draft)
                }
            }
            Section {
                AEShareRows(draft: draft)
            } header: {
                Text("Shares")
            } footer: {
                AESplitFooter(draft: draft)
            }
        }
    }
}

/// The split editor in its own sheet, for variants that keep the main screen short.
struct AESplitSheet: View {
    @Bindable var draft: AEDraft
    var showsToggle = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                AESplitFormSections(draft: draft, showsToggle: showsToggle)
            }
            .navigationTitle("Split")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", role: .confirm) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Impact

/// What saving does to the balance, spending and Owed to you, in SPL-001's terms. Add only: when
/// editing, these would read as totals rather than changes.
struct AEImpactSummary: View {
    let draft: AEDraft

    var body: some View {
        let code = draft.currencyCode
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 16) { figures(code: code) }
            VStack(alignment: .leading, spacing: 10) { figures(code: code) }
        }
    }

    @ViewBuilder
    private func figures(code: String) -> some View {
        figure("Balance", value: draft.type == .expense ? -draft.total : draft.total, code: code)
        if draft.type == .expense {
            figure("Spending", value: draft.myShare, code: code)
            if draft.isSplit {
                figure("Owed to you", value: draft.owedToYou, code: code)
            }
        }
    }

    private func figure(_ title: LocalizedStringKey, value: Decimal, code: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: code).sign(strategy: .always()))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Layout

/// Lays views out left to right, wrapping onto new lines, each line centered vertically.
struct AEFlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(width: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrange(width: bounds.width, subviews: subviews).frames
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> (frames: [CGRect], size: CGSize) {
        var lines: [[(index: Int, size: CGSize)]] = [[]]
        var x: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(ProposedViewSize(width: width, height: nil))
            if x > 0, x + size.width > width {
                lines.append([])
                x = 0
            }
            lines[lines.count - 1].append((index, size))
            x += size.width + spacing
        }

        var frames = Array(repeating: CGRect.zero, count: subviews.count)
        var y: CGFloat = 0
        var widest: CGFloat = 0
        for line in lines where !line.isEmpty {
            let height = line.map(\.size.height).max() ?? 0
            var x: CGFloat = 0
            for entry in line {
                let origin = CGPoint(x: x, y: y + (height - entry.size.height) / 2)
                frames[entry.index] = CGRect(origin: origin, size: entry.size)
                x += entry.size.width + spacing
            }
            widest = max(widest, x - spacing)
            y += height + lineSpacing
        }
        return (frames, CGSize(width: widest, height: max(y - lineSpacing, 0)))
    }
}
#endif
