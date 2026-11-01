//
//  07-ReefLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Reef": a panel at the bottom. Home is blurred past reading, and a glass
//  panel rises from the bottom like a sheet, with the mark, the title and the button where the thumb
//  is. The app switcher shows the blurred Home with the panel's mark and title.
//

#if DEBUG
import SwiftUI

struct ReefLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        LKCentered(alignment: .bottom) {
            R2Tile(padding: 22) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        if !dynamicTypeSize.isAccessibilitySize {
                            LKMark(size: 48)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(LKText.title)
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            if lock != nil, !dynamicTypeSize.isAccessibilitySize {
                                Text("Your balance, plan and splits are one step away.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let lock {
                        LKUnlockButton(lock: lock)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, -20)
        }
        .background {
            Color(.systemBackground)
                .opacity(0.2)
                .ignoresSafeArea()
        }
    }
}

#Preview("Reef") {
    LKHost(blursContent: true) { ReefLock(lock: $0) } cover: { ReefLock(lock: nil) }
}

#Preview("Reef · Touch ID") {
    LKHost(biometry: .touchID, blursContent: true) { ReefLock(lock: $0) } cover: { ReefLock(lock: nil) }
}

#Preview("Reef · App Switcher") {
    LKAppSwitcher(blursContent: true) { ReefLock(lock: nil) }
}

#Preview("Reef · Dark") {
    LKHost(blursContent: true) { ReefLock(lock: $0) } cover: { ReefLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
