//
//  06-MiraHistory.swift
//  Finlark
//
//  FIN-9 History, Round 1 "Mira": all the filters in one sheet, like Photos' filter. Month, type and a
//  grid of categories, with a live count on the button that closes it. What's on shows as chips under
//  the title, each one tap to remove. The month's income and spending ride in a glass bar above the
//  tab bar, so they stay put while the days scroll.
//

#if DEBUG
import SwiftUI

struct MiraHistory: View {
    @Bindable var store: HYStore

    @State private var isFiltering = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: r2TileSpacing) {
                if !store.records.isEmpty {
                    chips
                    if store.results.isEmpty {
                        HYEmptyView(store: store)
                            .padding(.top, 24)
                    }
                    ForEach(store.days) { day in
                        HYDayTile(day: day, code: store.code)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .background { R2Backdrop() }
        .overlay {
            if store.records.isEmpty {
                HYEmptyView(store: store)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !store.records.isEmpty {
                totalsBar
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    isFiltering = true
                } label: {
                    Label(
                        "Filter",
                        systemImage: store.hasFilters
                            ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease"
                    )
                }
                .accessibilityValue(store.hasFilters ? Text("\(store.filterCount) on") : Text("Off"))
            }
        }
        .searchable(text: $store.searchText, prompt: Text("Search notes"))
        .sheet(isPresented: $isFiltering) {
            MiraFilterSheet(store: store)
        }
    }

    // MARK: Chips

    private var chips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                if !store.isSearching, let month = store.month {
                    chip(Text(month, format: .dateTime.month(.wide).year()), symbol: "calendar", removable: false) {
                        isFiltering = true
                    }
                    .accessibilityHint(Text("Opens the filters"))
                }
                if let type = store.type.type {
                    chip(Text(store.type.title), symbol: type.symbol, removable: true) {
                        store.type = .all
                    }
                    .accessibilityHint(Text("Removes this filter"))
                }
                ForEach(store.selectedCategories) { category in
                    AE2CategoryChip(category: category, isSelected: true, showsRemove: true) {
                        store.toggle(category)
                    }
                    .accessibilityHint(Text("Removes this filter"))
                }
            }
            .padding(.horizontal)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
    }

    private func chip(_ title: Text, symbol: String, removable: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
                title
                if removable {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
        .buttonStyle(.plain)
    }

    // MARK: Totals bar

    private var totalsBar: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 20) { totals }
            VStack(alignment: .leading, spacing: 6) { totals }
        }
        .font(.subheadline.weight(.semibold))
        .monospacedDigit()
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private var totals: some View {
        Label {
            Text("Income \(store.totals.income, format: .currency(code: store.code))")
        } icon: {
            Image(systemName: "arrow.down.left")
                .foregroundStyle(.secondary)
        }
        Label {
            Text("Spending \(store.totals.spending, format: .currency(code: store.code))")
        } icon: {
            Image(systemName: "arrow.up.right")
                .foregroundStyle(.secondary)
        }
    }
}

/// Month, type and categories, applied as you pick, with the count on the button that closes it.
private struct MiraFilterSheet: View {
    @Bindable var store: HYStore

    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HYMonthPicker(store: store)
                }
                Section("Type") {
                    Picker("Type", selection: $store.type) {
                        ForEach(HYTypeFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Section {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: dynamicTypeSize.isAccessibilitySize ? 1 : 3),
                        spacing: 8
                    ) {
                        ForEach(store.categoryOptions) { category in
                            categoryCell(category)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Categories")
                } footer: {
                    Text("Pick none to see every category.")
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Reset") { store.clearFilters() }
                        .disabled(!store.hasFilters)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    dismiss()
                } label: {
                    Text("Show \(store.results(in: store.month).count) transactions")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .padding()
            }
        }
        .presentationDetents([.large])
        .environment(\.explorationIconStyle, .soft)
    }

    private func categoryCell(_ category: ExplorationCategory) -> some View {
        let isSelected = store.categoryIDs.contains(category.id)

        return Button {
            store.toggle(category)
        } label: {
            VStack(spacing: 6) {
                ExplorationCategoryIcon(category: category)
                Text(category.name)
                    .font(.caption.weight(.medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2, reservesSpace: !dynamicTypeSize.isAccessibilitySize)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                isSelected ? AnyShapeStyle(category.color.opacity(0.16)) : AnyShapeStyle(.fill.quaternary),
                in: .rect(cornerRadius: 14, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? category.color : .clear, lineWidth: 1.5)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(category.color)
                        .padding(6)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Mira") {
    HYHost { MiraHistory(store: $0) }
}

#Preview("Mira · Filtered") {
    let store = HYStore.sample
    store.categoryIDs = [ExplorationCategory.dining.id, ExplorationCategory.groceries.id]
    return HYHost(store: store) { MiraHistory(store: $0) }
}

#Preview("Mira · Empty") {
    HYHost(store: .empty) { MiraHistory(store: $0) }
}
#endif
