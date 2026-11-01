//
//  06-PrusikLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Prusik": explained. One glass card that says why Finlark is locked and
//  when it asks, with the button inside it, and a note on where to turn App Lock off. Good for the
//  first few times. The app switcher shows the card with the lock and title only.
//

#if DEBUG
import SwiftUI

struct PrusikLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    var body: some View {
        LKCentered {
            VStack(spacing: 16) {
                R2Tile(padding: 24) {
                    VStack(spacing: 14) {
                        STIcon("lock.fill", color: .indigo, size: 56)
                            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        Text(LKText.title)
                            .font(.title3.bold())
                            .accessibilityAddTraits(.isHeader)
                        if let lock {
                            Text("Finlark asks for \(Text(lock.biometry.title)) when you open it and after a minute away, so only you see your money.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            LKUnlockButton(lock: lock)
                                .padding(.top, 4)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                }
                .fixedSize(horizontal: false, vertical: true)
                if lock != nil {
                    Text("You can turn App Lock off in Settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, -12)
        }
        .background { LKBackdrop() }
    }
}

#Preview("Prusik") {
    LKHost { PrusikLock(lock: $0) } cover: { PrusikLock(lock: nil) }
}

#Preview("Prusik · Passcode") {
    LKHost(biometry: .passcode) { PrusikLock(lock: $0) } cover: { PrusikLock(lock: nil) }
}

#Preview("Prusik · App Switcher") {
    LKAppSwitcher { PrusikLock(lock: nil) }
}

#Preview("Prusik · Dark") {
    LKHost { PrusikLock(lock: $0) } cover: { PrusikLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
