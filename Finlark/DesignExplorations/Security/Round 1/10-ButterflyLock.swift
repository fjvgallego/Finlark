//
//  10-ButterflyLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Butterfly": a welcome. "Good evening" and today's date at the top, like
//  opening a notebook, and the lock and button at the bottom. Warmer than a lock screen usually is,
//  and it still shows nothing private. The app switcher shows the greeting without the button.
//

#if DEBUG
import SwiftUI

struct ButterflyLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        LKCentered(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 6) {
                LKMark(size: 48)
                    .padding(.bottom, 20)
                greeting
                    .font(.largeTitle.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)
            .padding(.horizontal, -8)
        } bottom: {
            if let lock {
                VStack(spacing: 12) {
                    if !dynamicTypeSize.isAccessibilitySize {
                        Label(LKText.title, systemImage: "lock.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    LKUnlockButton(lock: lock)
                }
            }
        }
        .background { LKBackdrop() }
    }

    private var greeting: Text {
        switch Calendar.current.component(.hour, from: .now) {
        case 5..<12: Text("Good morning")
        case 12..<19: Text("Good afternoon")
        default: Text("Good evening")
        }
    }
}

#Preview("Butterfly") {
    LKHost { ButterflyLock(lock: $0) } cover: { ButterflyLock(lock: nil) }
}

#Preview("Butterfly · Touch ID") {
    LKHost(biometry: .touchID) { ButterflyLock(lock: $0) } cover: { ButterflyLock(lock: nil) }
}

#Preview("Butterfly · App Switcher") {
    LKAppSwitcher { ButterflyLock(lock: nil) }
}

#Preview("Butterfly · Dark") {
    LKHost { ButterflyLock(lock: $0) } cover: { ButterflyLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
