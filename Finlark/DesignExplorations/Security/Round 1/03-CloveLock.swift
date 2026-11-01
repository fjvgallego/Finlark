//
//  03-CloveLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Clove": the brand. A full-bleed indigo gradient with the mark and the
//  Finlark wordmark in white, the same in light and dark. It reads as the app's own front door, and
//  the app switcher shows it as a clean branded card.
//

#if DEBUG
import SwiftUI

struct CloveLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    private let birdSize: CGFloat = 68

    var body: some View {
        LKCentered {
            VStack(spacing: 12) {
                Image(systemName: "bird.fill")
                    .font(.system(size: birdSize, weight: .semibold))
                    .accessibilityHidden(true)
                Text(verbatim: "Finlark")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .accessibilityAddTraits(.isHeader)
                Label("Locked", systemImage: "lock.fill")
                    .font(.headline)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
        } bottom: {
            if let lock {
                LKUnlockButton(lock: lock, prominent: false)
            }
        }
        .background {
            LinearGradient(
                colors: [.indigo, Color.indigo.mix(with: .teal, by: 0.4).mix(with: .black, by: 0.2)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        // White text and glass that reads on the gradient, whatever the appearance.
        .environment(\.colorScheme, .dark)
    }
}

#Preview("Clove") {
    LKHost { CloveLock(lock: $0) } cover: { CloveLock(lock: nil) }
}

#Preview("Clove · Passcode") {
    LKHost(biometry: .passcode) { CloveLock(lock: $0) } cover: { CloveLock(lock: nil) }
}

#Preview("Clove · App Switcher") {
    LKAppSwitcher { CloveLock(lock: nil) }
}

#Preview("Clove · Dark") {
    LKHost { CloveLock(lock: $0) } cover: { CloveLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
