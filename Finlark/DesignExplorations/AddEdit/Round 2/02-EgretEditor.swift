//
//  02-EgretEditor.swift
//  Finlark
//
//  FIN-9 Add & edit, Round 2 "Egret". Category: the grid as swipeable pages of eight, most used first,
//  so the tile stays two rows tall. Split: big faces to pick people, and the three modes as cards
//  that say what each one does, instead of a segmented control.
//

#if DEBUG
import SwiftUI

struct EgretEditor: View {
    private struct Page: Identifiable {
        let id: Int
        let categories: [ExplorationCategory]
    }

    @State private var draft: AEDraft

    init(draft: AEDraft) {
        _draft = State(initialValue: draft)
    }

    private var pages: [Page] {
        let categories = draft.type.frequentCategories
        return stride(from: 0, to: categories.count, by: 8).map { start in
            Page(id: start, categories: Array(categories[start..<min(start + 8, categories.count)]))
        }
    }

    var body: some View {
        AE2KestrelShell(draft: draft) {
            R5Pager(pages) { page in
                AECategoryGrid(draft: draft, categories: page.categories)
            }
            // Pages change with the type, so the pager starts over.
            .id(draft.type)
        } split: {
            VStack(alignment: .leading, spacing: 16) {
                AE2FacesRow(draft: draft, showsShares: false)
                AE2ModeCards(draft: draft)
                AE2SharesBlock(draft: draft)
            }
        }
    }
}

#Preview("Egret · Add") {
    AEHomeHost { EgretEditor(draft: $0) }
}

#Preview("Egret · Edit split") {
    AEDetailHost { EgretEditor(draft: .editSplitSample) }
}
#endif
