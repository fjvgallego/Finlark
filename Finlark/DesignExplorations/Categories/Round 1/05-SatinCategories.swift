//
//  05-SatinCategories.swift
//  Finlark
//
//  FIN-9 Categories, Round 1 "Satin": Linen's list with a different editor, the studio. Its top tile
//  shows the category as it will look in History, in the category picker and in the Plan, live as it
//  changes. Below the name, Icon and Color share one big picker, switched by a segmented control.
//

#if DEBUG
import SwiftUI

struct SatinCategories: View {
    @Bindable var store: CTStore

    @State private var type: ExplorationTransactionType = .expense

    var body: some View {
        CTScreen(store: store, addType: type, editorStyle: .studio) { actions in
            CTTypeSwitch(selection: $type)
            CTListTile(
                title: type == .expense ? "Expense categories" : "Income categories",
                symbol: "square.grid.2x2.fill",
                categories: store.active(type),
                actions: actions
            )
            CTArchivedTile(categories: store.archived(type), actions: actions)
        }
    }
}

/// Previews on top, the name and type, then one picker for the icon or the color.
struct SatinStudioEditor: View {
    let store: CTStore
    @Bindable var draft: CTDraft

    private enum Part: Hashable {
        case icon
        case color
    }

    @State private var part: Part = .icon

    var body: some View {
        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                R2TileHeader(title: "Preview", symbol: "eye.fill")
                SatinTransactionPreview(store: store, draft: draft)
                Divider()
                SatinChipPreview(draft: draft)
                if draft.type == .expense {
                    Divider()
                    SatinPlanPreview(store: store, draft: draft)
                }
            }
        }
        .accessibilityElement(children: .combine)

        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 14) {
                CTNameField(store: store, draft: draft)
                CTTypeControl(draft: draft)
            }
        }

        R2Tile(padding: 18) {
            VStack(alignment: .leading, spacing: 16) {
                R6SegmentedControl(
                    title: "Part",
                    options: [(value: .icon, label: "Icon"), (value: .color, label: "Color")],
                    selection: $part
                )
                switch part {
                case .icon:
                    CTSymbolPicker(draft: draft)
                case .color:
                    SatinColorList(selection: $draft.color)
                }
            }
        }
    }
}

/// The name, or a placeholder until there is one.
private struct SatinName: View {
    let draft: CTDraft

    var body: some View {
        let trimmed = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            Text("Name")
                .foregroundStyle(.tertiary)
        } else {
            Text(verbatim: trimmed)
        }
    }
}

/// As a transaction in History.
private struct SatinTransactionPreview: View {
    let store: CTStore
    let draft: CTDraft

    var body: some View {
        HStack(spacing: 12) {
            ExplorationCategoryIcon(category: draft.icon)
            VStack(alignment: .leading, spacing: 2) {
                SatinName(draft: draft)
                    .font(.body.weight(.semibold))
                Text("Today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(draft.type == .expense ? Decimal(sign: .minus, exponent: -2, significand: 2490) : Decimal(150), format: .currency(code: store.code).sign(strategy: .always()))
                .font(.body.weight(.medium))
                .monospacedDigit()
        }
    }
}

/// As the picked category in Add & edit's chips.
private struct SatinChipPreview: View {
    let draft: CTDraft

    var body: some View {
        Label {
            SatinName(draft: draft)
        } icon: {
            Image(systemName: draft.symbol)
                .foregroundStyle(draft.color.color)
        }
        .font(.subheadline.weight(.medium))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(draft.color.color.opacity(0.18), in: .capsule)
        .overlay { Capsule().strokeBorder(draft.color.color, lineWidth: 1.5) }
    }
}

/// As a row of the Plan, with a bar in its color.
private struct SatinPlanPreview: View {
    let store: CTStore
    let draft: CTDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: draft.symbol)
                    .foregroundStyle(draft.color.color)
                SatinName(draft: draft)
                    .font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Text("\(Decimal(60), format: .currency(code: store.code)) of \(Decimal(100), format: .currency(code: store.code))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ExplorationPlanBar(spent: 60, projected: 85, planned: 100, tint: draft.color.color)
        }
    }
}

/// Colors as a list with their names, larger than the swatches elsewhere.
private struct SatinColorList: View {
    @Binding var selection: CTColor

    @ScaledMetric private var size: CGFloat = 28

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
            ForEach(CTColor.allCases) { color in
                let isSelected = color == selection
                Button { selection = color } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(color.color.gradient)
                            .frame(width: size, height: size)
                        Text(color.name)
                            .font(.subheadline.weight(.medium))
                        Spacer(minLength: 4)
                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.tint)
                        }
                    }
                    .padding(8)
                    .background(
                        isSelected ? AnyShapeStyle(color.color.opacity(0.16)) : AnyShapeStyle(.fill.quaternary),
                        in: .rect(cornerRadius: 12, style: .continuous)
                    )
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

#Preview("Satin") {
    CTHost { SatinCategories(store: $0) }
}

#Preview("Satin · Editor") {
    CTHost(opening: .editor(.edit("dining"))) { SatinCategories(store: $0) }
}

#Preview("Satin · Editor · Dark") {
    CTHost(opening: .editor(.edit("dining"))) { SatinCategories(store: $0) }
        .preferredColorScheme(.dark)
}
#endif
