//
//  02-CarrickLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Carrick": frosted. Home stays where it is, blurred past reading, with a
//  glass lock and a small Unlock button over it. Unlocking clears the blur, so it feels like the app
//  was there all along. The app switcher shows the blurred Home with the lock.
//

#if DEBUG
import SwiftUI

struct CarrickLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    private let glyphSize: CGFloat = 64

    var body: some View {
        LKCentered {
            VStack(spacing: 14) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: glyphSize, height: glyphSize)
                    .glassEffect(.regular, in: .circle)
                    .accessibilityHidden(true)
                Text(LKText.title)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                if let lock {
                    Button {
                        lock.unlock()
                    } label: {
                        Label {
                            Text("Unlock")
                        } icon: {
                            Image(systemName: lock.biometry.symbol)
                        }
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .disabled(lock.phase != .locked)
                    .accessibilityLabel(LKText.unlock(lock.biometry))
                }
            }
            .multilineTextAlignment(.center)
        }
        .background {
            Color(.systemBackground)
                .opacity(0.3)
                .ignoresSafeArea()
        }
    }
}

#Preview("Carrick") {
    LKHost(blursContent: true) { CarrickLock(lock: $0) } cover: { CarrickLock(lock: nil) }
}

#Preview("Carrick · Touch ID") {
    LKHost(biometry: .touchID, blursContent: true) { CarrickLock(lock: $0) } cover: { CarrickLock(lock: nil) }
}

#Preview("Carrick · App Switcher") {
    LKAppSwitcher(blursContent: true) { CarrickLock(lock: nil) }
}

#Preview("Carrick · Dark") {
    LKHost(blursContent: true) { CarrickLock(lock: $0) } cover: { CarrickLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
