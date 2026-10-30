//
//  04-BoraPlan.swift
//  Finlark
//
//  FIN-9 Plan, Round 1 "Bora": the most native option. A grouped list with a summary section, the
//  planned categories and the unplanned ones. Edit works in place, as in Settings or Contacts: every
//  category turns into an amount field with what's been spent this month under its name, and Done
//  saves. No sheet.
//

#if DEBUG
import SwiftUI

struct BoraPlan: View {
    @Bindable var store: PLStore

    @State private var isEditing = false
    @State private var texts: [String: String] = [:]

    private var code: String { store.code }

    var body: some View {
        let report = store.report

        List {
            if isEditing {
                editor(report)
            } else {
                overview(report)
            }
        }
        .plChrome(store: store, showsEdit: false)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) { setEditing(false) }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark", role: .confirm) {
                        store.replacePlan(with: texts.compactMapValues { AEMoney.parse($0) })
                        setEditing(false)
                    }
                }
            } else if store.isCurrentMonth, store.hasPlan {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { setEditing(true) }
                }
            }
        }
    }

    private func setEditing(_ editing: Bool) {
        if editing {
            let digits = AEMoney.fractionDigits(for: code)
            texts = store.plan.mapValues { AEMoney.text(for: $0, fractionDigits: digits) }
        }
        withAnimation { isEditing = editing }
    }

    // MARK: Overview

    @ViewBuilder
    private func overview(_ report: PLReport) -> some View {
        if report.hasPlan {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    PLPaceSentence(report: report, code: code)
                        .font(.headline)
                    if let status = report.status {
                        PLStatusLabel(status: status)
                            .font(.subheadline.weight(.semibold))
                    }
                    PLBar.Total(report: report)
                    PLFigures(report: report, code: code)
                }
                .padding(.vertical, 6)
                .monospacedDigit()
                .accessibilityElement(children: .combine)
            }

            Section("Categories") {
                ForEach(report.entries) { entry in
                    PLEntryRow(entry: entry, code: code)
                        .padding(.vertical, 4)
                }
            }
        } else {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if store.isCurrentMonth {
                        Text("Set up your Monthly Plan")
                            .font(.headline)
                        Text("Plan how much you'll spend per category and see early whether you'll stay within it.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("No plan this month")
                            .font(.headline)
                        Text("You hadn't set a plan yet, so all spending was unplanned.")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                if store.isCurrentMonth {
                    Button("Set Up Plan", systemImage: "plus.circle.fill") { setEditing(true) }
                }
            }
        }

        if !report.unplanned.isEmpty {
            Section {
                ForEach(report.unplanned) { entry in
                    PLUnplannedRow(entry: entry, code: code)
                }
            } header: {
                HStack {
                    Text("Unplanned")
                    Spacer()
                    Text(report.unplannedSpent, format: .currency(code: code))
                        .monospacedDigit()
                }
            } footer: {
                if report.hasPlan {
                    PLFootnote(report: report, code: code)
                        .padding(.top, 8)
                }
            }
        }
    }

    // MARK: Editor (PLN-001)

    @ViewBuilder
    private func editor(_ report: PLReport) -> some View {
        Section {
            LabeledContent("Total planned") {
                Text(texts.values.reduce(0) { $0 + (AEMoney.parse($1) ?? 0) }, format: .currency(code: code))
                    .font(.headline)
                    .monospacedDigit()
            }
        }

        Section {
            ForEach(store.activeCategories) { category in
                HStack(spacing: 12) {
                    ExplorationCategoryIcon(category: category)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.name)
                        let spent = (report.entries + report.unplanned).first { $0.id == category.id }?.spent ?? 0
                        Text("\(spent, format: .currency(code: code)) spent this month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                    Spacer(minLength: 8)
                    PLAmountField(title: category.name, text: binding(for: category), code: code)
                }
            }
        } header: {
            Text("Planned per month")
        } footer: {
            Text("Leave a category empty to keep it unplanned. Changes apply from \(PLFormat.month(PLStore.currentMonth)) onward; earlier months keep the amounts they had.")
        }
    }

    private func binding(for category: ExplorationCategory) -> Binding<String> {
        Binding {
            texts[category.id] ?? ""
        } set: {
            texts[category.id] = $0
        }
    }
}

#Preview("Bora") {
    PLHost { BoraPlan(store: $0) }
}

#Preview("Bora · Last month") {
    PLHost(store: .lastMonth) { BoraPlan(store: $0) }
}

#Preview("Bora · No plan") {
    PLHost(store: .noPlan) { BoraPlan(store: $0) }
}
#endif
