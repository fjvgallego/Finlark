//
//  AddEditRound2Components.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2: Kestrel, the owner's pick, as a shell. Amount, details and the "When you
//  save" tile stay as they are; each variant swaps in its own category control and split control.
//

#if DEBUG
import SwiftUI

// MARK: - Kestrel shell

struct AE2KestrelShell<CategoryControl: View, SplitControl: View>: View {
    @Bindable var draft: AEDraft
    @ViewBuilder var category: CategoryControl
    /// Shown in the split tile while the split is on.
    @ViewBuilder var split: SplitControl

    @FocusState private var isAmountFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: r2TileSpacing) {
                    R2Tile(padding: 18) {
                        VStack(spacing: 16) {
                            AETypePicker(draft: draft)
                            AEAmountField(draft: draft, focus: $isAmountFocused)
                                .frame(maxWidth: .infinity)
                        }
                    }

                    R2Tile {
                        VStack(alignment: .leading, spacing: 10) {
                            R2TileHeader(title: "Category", symbol: "square.grid.2x2.fill")
                            category
                        }
                    }

                    R2Tile {
                        VStack(alignment: .leading, spacing: 0) {
                            R2TileHeader(title: "Details", symbol: "text.alignleft")
                                .padding(.bottom, 6)
                            DatePicker("Date", selection: $draft.date, displayedComponents: .date)
                                .padding(.vertical, 6)
                            Divider()
                            TextField("Note", text: $draft.note, prompt: Text("Note (optional)"), axis: .vertical)
                                .padding(.vertical, 12)
                        }
                    }

                    if draft.type == .expense {
                        R2Tile {
                            VStack(alignment: .leading, spacing: 14) {
                                Toggle(isOn: $draft.isSplit.animation()) {
                                    Label("Split with friends", systemImage: "person.2.fill")
                                        .font(.headline)
                                }
                                if draft.isSplit {
                                    split
                                } else {
                                    Text("For an expense you paid that others owe you part of.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    if draft.purpose == .add, draft.total > 0 {
                        R2Tile {
                            VStack(alignment: .leading, spacing: 10) {
                                R2TileHeader(title: "When you save", symbol: "sparkles")
                                AEImpactSummary(draft: draft)
                            }
                        }
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .background { R2Backdrop() }
            .aeEditorChrome(draft)
        }
        .onAppear { isAmountFocused = draft.purpose == .add }
    }
}

// MARK: - Split pieces

extension AESplitMode {
    /// A few words, for controls too small for the full explanation.
    var shortExplanation: LocalizedStringKey {
        switch self {
        case .equal: "Same for everyone"
        case .exact: "Type each share"
        case .byItem: "Who had what"
        }
    }
}

/// Items (By item only), the shares and the footer: the end of most split controls.
struct AE2SharesBlock: View {
    @Bindable var draft: AEDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if draft.splitMode == .byItem {
                AEItemRows(draft: draft, isCarded: true)
            }
            VStack(spacing: 12) {
                AEShareRows(draft: draft)
            }
            AESplitFooter(draft: draft)
        }
    }
}

/// The three modes as cards side by side, each with an icon and a few words. Stacks at large sizes.
struct AE2ModeCards: View {
    @Bindable var draft: AEDraft

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 8))

        layout {
            ForEach(AESplitMode.allCases) { mode in
                let isSelected = draft.splitMode == mode
                Button {
                    withAnimation(reduceMotion ? nil : .snappy) { draft.splitMode = mode }
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: mode.symbol)
                                .font(.headline)
                            Spacer(minLength: 0)
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                        }
                        Text(mode.title)
                            .font(.subheadline.weight(.semibold))
                            .fixedSize(horizontal: false, vertical: true)
                        Text(mode.shortExplanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
                    .background(
                        isSelected ? AnyShapeStyle(.tint.opacity(0.12)) : AnyShapeStyle(.fill.quaternary),
                        in: .rect(cornerRadius: 14, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), lineWidth: 1.5)
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Everyone as a big avatar in a row that scrolls sideways. Tap to add or remove; included people
/// are outlined and checked (a lock when they've repaid), the rest are dimmed.
struct AE2FacesRow: View {
    @Bindable var draft: AEDraft
    var showsShares = true

    @State private var isAddingPerson = false
    @State private var newName = ""

    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .top, spacing: 14) {
                face(.me)
                ForEach(draft.people) { face($0) }
                Button {
                    newName = ""
                    isAddingPerson = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .frame(width: 48, height: 48)
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .strokeBorder(.tint, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            }
                        Text("New")
                            .font(.caption)
                    }
                    .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("New person"))
            }
            .padding(.vertical, 4)
        }
        .scrollIndicators(.hidden)
        .scrollClipDisabled()
        .alert("New person", isPresented: $isAddingPerson) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Add") { draft.addPerson(named: newName) }
        } message: {
            Text("They'll be added to this split and to People.")
        }
    }

    private func face(_ person: AEPerson) -> some View {
        let isIncluded = draft.isIncluded(person)
        let share = draft.shares.first { $0.id == person.id }

        return VStack(spacing: 4) {
            Button {
                withAnimation(.snappy) { draft.toggle(person) }
            } label: {
                AEAvatar(person: person, size: 48)
                    .opacity(isIncluded ? 1 : 0.35)
                    .overlay {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .strokeBorder(isIncluded ? person.color : .clear, lineWidth: 2)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if isIncluded {
                            Image(systemName: person.isMe || draft.canRemove(person) ? "checkmark.circle.fill" : "lock.circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, person.color)
                                .offset(x: 4, y: 4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .disabled(person.isMe)
            .accessibilityLabel(person.displayName)
            .accessibilityValue(isIncluded ? Text("In the split") : Text("Not in the split"))
            .accessibilityAddTraits(isIncluded ? .isSelected : [])

            person.displayName
                .font(.caption.weight(.medium))
                .lineLimit(1)
            if showsShares, let share {
                Text(share.amount, format: .currency(code: draft.currencyCode))
                    .font(.caption2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 60)
    }
}

/// Every category as a wrapping set of chips, nothing hidden.
struct AE2CategoryChipFlow: View {
    @Bindable var draft: AEDraft

    var body: some View {
        AEFlowLayout(spacing: 8, lineSpacing: 8) {
            ForEach(draft.type.categories) { category in
                AE2CategoryChip(category: category, isSelected: draft.categoryID == category.id) {
                    draft.categoryID = category.id
                }
            }
        }
    }
}

struct AE2CategoryChip: View {
    let category: ExplorationCategory
    let isSelected: Bool
    var showsRemove = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.symbol)
                    .foregroundStyle(category.color)
                    .accessibilityHidden(true)
                Text(category.name)
                if showsRemove {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
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
#endif
