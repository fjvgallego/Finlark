//
//  10-HarmattanPlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Harmattan": envelopes. Each planned category is a tile that leads with what's
//  left in it, the way people think of a budget envelope, and the total left leads the screen. Tapping
//  an envelope edits just that one amount in a small sheet (PLN-001), and a last tile plans another
//  category. Edit in the bar still opens the full editor.
//

#if DEBUG
import SwiftUI

struct HarmattanPlan: View {
    @Bindable var store: PLStore

    @State private var editing: ExplorationCategory?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var code: String { store.code }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: r2TileSpacing), count: count)
    }

    var body: some View {
        let report = store.report

        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if report.hasPlan {
                    hero(report)
                    LazyVGrid(columns: columns, spacing: r2TileSpacing) {
                        ForEach(report.entries) { entry in
                            envelope(entry, isEditable: report.isCurrent)
                        }
                        if report.isCurrent {
                            addTile
                        }
                    }
                } else {
                    PLInvite(store: store)
                }
                PLUnplannedTile(report: report, code: code)
                if report.hasPlan {
                    PLFootnote(report: report, code: code)
                        .padding(.horizontal, 4)
                }
            }
            .padding()
        }
        .background { R2Backdrop() }
        .plChrome(store: store)
        .sheet(item: $editing) { category in
            HarmattanAmountSheet(store: store, category: category)
                .presentationDetents([.medium])
        }
    }

    private func hero(_ report: PLReport) -> some View {
        R2Tile(padding: 20) {
            VStack(alignment: .leading, spacing: 8) {
                if report.spent > report.planned {
                    Text("\(report.spent - report.planned, format: .currency(code: code)) over plan")
                        .font(.system(.title, design: .rounded, weight: .bold))
                } else {
                    Text("\(report.remaining, format: .currency(code: code)) left")
                        .font(.system(.title, design: .rounded, weight: .bold))
                }
                PLPaceSentence(report: report, code: code)
                    .foregroundStyle(.secondary)
                if let status = report.status {
                    PLStatusLabel(status: status)
                        .font(.subheadline.weight(.semibold))
                }
            }
            .monospacedDigit()
            .accessibilityElement(children: .combine)
        }
    }

    private func envelope(_ entry: PLEntry, isEditable: Bool) -> some View {
        Button {
            editing = entry.category
        } label: {
            R2Tile(padding: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ExplorationCategoryIcon(category: entry.category)
                        Spacer(minLength: 4)
                        if let status = entry.status {
                            PLStatusBadge(status: status)
                        }
                    }
                    Text(entry.category.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    if let planned = entry.planned {
                        R3RemainingText(planned: planned, spent: entry.spent, code: code)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        PLBar(entry: entry)
                        Text("of \(planned, format: .currency(code: code))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .monospacedDigit()
                .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
        .disabled(!isEditable)
        .accessibilityElement(children: .combine)
        .accessibilityHint(isEditable ? Text("Changes the planned amount") : Text(verbatim: ""))
    }

    @ViewBuilder
    private var addTile: some View {
        let unplanned = store.activeCategories.filter { store.planned(for: $0) == nil }
        if !unplanned.isEmpty {
            Menu {
                ForEach(unplanned) { category in
                    Button {
                        editing = category
                    } label: {
                        Label {
                            Text(category.name)
                        } icon: {
                            Image(systemName: category.symbol)
                        }
                    }
                }
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                    Text("Plan a category")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.tint)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 24)
                .background {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(.tint.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                }
            }
        }
    }
}

/// One category's planned amount: set, change or remove it (PLN-001).
private struct HarmattanAmountSheet: View {
    let store: PLStore
    let category: ExplorationCategory

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var isFocused: Bool

    private var isPlanned: Bool { store.planned(for: category) != nil }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ExplorationCategoryIcon(category: category)
                    .scaleEffect(1.4)
                    .padding(.top, 8)
                amountField
                let spent = store.report.entries.first { $0.id == category.id }?.spent
                    ?? store.report.unplanned.first { $0.id == category.id }?.spent ?? 0
                Text("\(spent, format: .currency(code: store.code)) spent this month")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Text("Applies from \(PLFormat.month(PLStore.currentMonth)) onward.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                if isPlanned {
                    Button("Remove from Plan", systemImage: "trash", role: .destructive) {
                        store.setPlanned(nil, for: category)
                        dismiss()
                    }
                    .buttonStyle(.glass)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .navigationTitle(Text(category.name))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", role: .confirm) {
                        store.setPlanned(AEMoney.parse(text), for: category)
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            text = store.planned(for: category).map {
                AEMoney.text(for: $0, fractionDigits: AEMoney.fractionDigits(for: store.code))
            } ?? ""
            isFocused = true
        }
    }

    private var amountField: some View {
        let affix = AEMoney.affix(for: store.code)

        return HStack(alignment: .firstTextBaseline, spacing: 4) {
            if affix.isLeading { Text(verbatim: affix.symbol).foregroundStyle(.secondary) }
            TextField(String(localized: category.name), text: $text, prompt: Text(verbatim: "0"))
                .keyboardType(.decimalPad)
                .focused($isFocused)
                .fixedSize()
            if !affix.isLeading { Text(verbatim: affix.symbol).foregroundStyle(.secondary) }
        }
        .font(.system(.largeTitle, design: .rounded, weight: .bold))
        .monospacedDigit()
        .onChange(of: text) { _, newValue in
            let clean = AEMoney.sanitize(newValue, fractionDigits: AEMoney.fractionDigits(for: store.code))
            if clean != newValue { text = clean }
        }
    }
}

#Preview("Harmattan") {
    PLHost { HarmattanPlan(store: $0) }
}

#Preview("Harmattan · Last month") {
    PLHost(store: .lastMonth) { HarmattanPlan(store: $0) }
}

#Preview("Harmattan · No plan") {
    PLHost(store: .noPlan) { HarmattanPlan(store: $0) }
}
#endif
