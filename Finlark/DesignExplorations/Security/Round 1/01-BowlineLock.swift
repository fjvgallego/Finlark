//
//  01-BowlineLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Bowline": plain and familiar. Finlark's mark and "Finlark is Locked" in
//  the middle of Marsh's backdrop, and one button at the bottom, within thumb reach. The app switcher
//  shows the same screen without the button.
//

#if DEBUG
import SwiftUI

struct BowlineLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    var body: some View {
        LKCentered {
            VStack(spacing: 16) {
                LKMark(size: 76)
                Text(LKText.title)
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text("Your money stays private until you unlock.")
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
        } bottom: {
            if let lock {
                LKUnlockButton(lock: lock)
            }
        }
        .background { LKBackdrop() }
    }
}

#Preview("Bowline") {
    LKHost { BowlineLock(lock: $0) } cover: { BowlineLock(lock: nil) }
}

#Preview("Bowline · Touch ID") {
    LKHost(biometry: .touchID) { BowlineLock(lock: $0) } cover: { BowlineLock(lock: nil) }
}

#Preview("Bowline · App Switcher") {
    LKAppSwitcher { BowlineLock(lock: nil) }
}

#Preview("Bowline · Dark") {
    LKHost { BowlineLock(lock: $0) } cover: { BowlineLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
