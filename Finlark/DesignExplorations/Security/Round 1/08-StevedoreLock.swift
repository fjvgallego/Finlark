//
//  08-StevedoreLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Stevedore": the vault. Black from edge to edge in light and dark, a white
//  lock and the title, and a quiet glass button. The status bar hides so nothing breaks the black. The
//  app switcher shows the black card with the lock.
//

#if DEBUG
import SwiftUI

struct StevedoreLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    private let glyphSize: CGFloat = 44

    var body: some View {
        LKCentered {
            VStack(spacing: 18) {
                Image(systemName: "lock.fill")
                    .font(.system(size: glyphSize))
                    .accessibilityHidden(true)
                Text(LKText.title)
                    .font(.title3.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
        } bottom: {
            if let lock {
                LKUnlockButton(lock: lock, prominent: false)
            }
        }
        .background {
            Color.black
                .ignoresSafeArea()
        }
        .environment(\.colorScheme, .dark)
        .statusBarHidden()
    }
}

#Preview("Stevedore") {
    LKHost { StevedoreLock(lock: $0) } cover: { StevedoreLock(lock: nil) }
}

#Preview("Stevedore · Touch ID") {
    LKHost(biometry: .touchID) { StevedoreLock(lock: $0) } cover: { StevedoreLock(lock: nil) }
}

#Preview("Stevedore · App Switcher") {
    LKAppSwitcher { StevedoreLock(lock: nil) }
}

#Preview("Stevedore · Dark") {
    LKHost { StevedoreLock(lock: $0) } cover: { StevedoreLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
