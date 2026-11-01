//
//  04-ConstrictorLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Constrictor": nothing but the glyph. A large Face ID or Touch ID symbol
//  that pulses gently, and "Tap to Unlock" under it: the whole screen is the button. The app switcher
//  shows a lock in its place.
//

#if DEBUG
import SwiftUI

struct ConstrictorLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    private let glyphSize: CGFloat = 84
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LKCentered {
            VStack(spacing: 20) {
                Image(systemName: lock?.biometry.symbol ?? "lock.fill")
                    .font(.system(size: glyphSize, weight: .light))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse, options: .repeating, isActive: lock?.phase == .locked && !reduceMotion)
                    .accessibilityHidden(true)
                VStack(spacing: 6) {
                    Text(LKText.title)
                        .font(.headline)
                    if lock != nil {
                        Text("Tap to Unlock")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .multilineTextAlignment(.center)
        }
        .contentShape(.rect)
        .onTapGesture {
            lock?.unlock()
        }
        .background { LKBackdrop() }
        .accessibilityElement(children: .ignore)
        .modifier(ConstrictorUnlockAction(lock: lock))
    }
}

/// One button for VoiceOver, "Unlock with Face ID", since the whole screen is the tap target.
private struct ConstrictorUnlockAction: ViewModifier {
    let lock: LKLock?

    func body(content: Content) -> some View {
        if let lock {
            content
                .accessibilityLabel(LKText.unlock(lock.biometry))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { lock.unlock() }
        } else {
            content
                .accessibilityLabel(Text(LKText.title))
        }
    }
}

#Preview("Constrictor") {
    LKHost { ConstrictorLock(lock: $0) } cover: { ConstrictorLock(lock: nil) }
}

#Preview("Constrictor · Touch ID") {
    LKHost(biometry: .touchID) { ConstrictorLock(lock: $0) } cover: { ConstrictorLock(lock: nil) }
}

#Preview("Constrictor · App Switcher") {
    LKAppSwitcher { ConstrictorLock(lock: nil) }
}

#Preview("Constrictor · Dark") {
    LKHost { ConstrictorLock(lock: $0) } cover: { ConstrictorLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
