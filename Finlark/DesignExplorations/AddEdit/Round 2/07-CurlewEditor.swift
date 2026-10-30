//
//  07-CurlewEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2 "Curlew". Category: a dial. Icons scroll sideways and snap, and the one
//  in the middle is the choice, named underneath; tapping an icon spins it to the middle. Split: a
//  short numbered checklist (who was there, how to split, check the shares), each step ticked when done.
//

#if DEBUG
import SwiftUI

struct CurlewEditor: View {
    @State private var draft: AEDraft

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    var body: some View {
        AE2KestrelShell(draft: draft) {
            CurlewDial(draft: draft)
                .id(draft.type)
        } split: {
            VStack(alignment: .leading, spacing: 18) {
                CurlewStep(number: 1, title: "Who was there?", isDone: !draft.participants.isEmpty) {
                    AE2FacesRow(draft: draft, showsShares: false)
                }
                CurlewStep(number: 2, title: "How do you split it?", isDone: !draft.participants.isEmpty) {
                    VStack(spacing: 0) {
                        ForEach(AESplitMode.allCases) { mode in
                            modeOption(mode)
                            if mode != AESplitMode.allCases.last {
                                Divider()
                            }
                        }
                    }
                }
                CurlewStep(number: 3, title: "Check the shares", isDone: draft.canSave) {
                    AE2SharesBlock(draft: draft)
                }
            }
        }
    }

    private func modeOption(_ mode: AESplitMode) -> some View {
        let isSelected = draft.splitMode == mode
        return Button {
            withAnimation(.snappy) { draft.splitMode = mode }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.title)
                        .fontWeight(.medium)
                    Text(mode.explanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// A numbered step whose number turns into a check when it's done.
private struct CurlewStep<Content: View>: View {
    let number: Int
    let title: LocalizedStringKey
    let isDone: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: isDone ? "checkmark.circle.fill" : "\(number).circle")
                    .font(.title3)
                    .foregroundStyle(isDone ? AnyShapeStyle(.green) : AnyShapeStyle(.secondary))
                    .accessibilityHidden(true)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityValue(isDone ? Text("Done") : Text("Step \(number)"))
            content
                .padding(.leading, 4)
        }
    }
}

/// Category icons on a snapping strip; the one under the center mark is selected.
private struct CurlewDial: View {
    @Bindable var draft: AEDraft

    @State private var centeredID: String?
    @State private var width: CGFloat = 0
    @ScaledMetric private var item: CGFloat = 52
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(draft.type.frequentCategories) { category in
                        let isSelected = draft.categoryID == category.id
                        Button {
                            withAnimation(reduceMotion ? nil : .snappy) { centeredID = category.id }
                        } label: {
                            Image(systemName: category.symbol)
                                .font(.system(size: item * 0.42, weight: .semibold))
                                .foregroundStyle(category.color)
                                .frame(width: item, height: item)
                                .background(category.color.opacity(isSelected ? 0.22 : 0.1), in: .circle)
                                .overlay {
                                    Circle().strokeBorder(isSelected ? category.color : .clear, lineWidth: 2)
                                }
                                .scaleEffect(isSelected ? 1.1 : 0.9)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(category.name))
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .id(category.id)
                    }
                }
                .scrollTargetLayout()
                .padding(.vertical, 6)
            }
            .contentMargins(.horizontal, max((width - item) / 2, 0), for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $centeredID, anchor: .center)
            .scrollIndicators(.hidden)
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
            .onChange(of: centeredID) { _, id in
                if let id { draft.categoryID = id }
            }
            .onAppear { centeredID = draft.categoryID }

            Group {
                if let category = draft.category {
                    Text(category.name)
                        .font(.headline)
                } else {
                    Text("Swipe or tap to choose")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityHidden(true)
        }
    }
}

#Preview("Curlew · Add") {
    AEHomeHost { CurlewEditor(draft: $0) }
}

#Preview("Curlew · Edit split") {
    AEDetailHost { CurlewEditor(draft: .editSplitSample) }
}
#endif
