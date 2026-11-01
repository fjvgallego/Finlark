//
//  09-ZeppelinLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Zeppelin": the unlock as a moment. A lock in a glass circle opens and
//  turns green when authentication passes, then the screen lifts away into Home. With Reduce Motion,
//  the lock still opens but the screen just fades. The app switcher shows the closed lock.
//

#if DEBUG
import SwiftUI

struct ZeppelinLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    private let circleSize: CGFloat = 104
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isOpen: Bool {
        lock?.phase == .succeeded
    }

    var body: some View {
        LKCentered {
            VStack(spacing: 22) {
                Image(systemName: isOpen ? "lock.open.fill" : "lock.fill")
                    .font(.system(size: circleSize * 0.4, weight: .semibold))
                    .foregroundStyle(isOpen ? Color.green : Color.accentColor)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: circleSize, height: circleSize)
                    .glassEffect(.regular, in: .circle)
                    .scaleEffect(isOpen && !reduceMotion ? 1.1 : 1)
                    .accessibilityHidden(true)
                Group {
                    if isOpen {
                        Text("Unlocked")
                    } else {
                        Text(LKText.title)
                    }
                }
                .font(.title2.bold())
                .contentTransition(.opacity)
                .accessibilityAddTraits(.isHeader)
            }
            .multilineTextAlignment(.center)
            .animation(.spring(duration: 0.4, bounce: 0.3), value: isOpen)
        } bottom: {
            if let lock {
                LKUnlockButton(lock: lock)
                    .opacity(isOpen ? 0 : 1)
            }
        }
        .background { LKBackdrop() }
    }
}

#Preview("Zeppelin") {
    LKHost(successPause: .seconds(0.6), transition: .scale(scale: 1.15).combined(with: .opacity)) {
        ZeppelinLock(lock: $0)
    } cover: {
        ZeppelinLock(lock: nil)
    }
}

#Preview("Zeppelin · Touch ID") {
    LKHost(biometry: .touchID, successPause: .seconds(0.6), transition: .scale(scale: 1.15).combined(with: .opacity)) {
        ZeppelinLock(lock: $0)
    } cover: {
        ZeppelinLock(lock: nil)
    }
}

#Preview("Zeppelin · App Switcher") {
    LKAppSwitcher { ZeppelinLock(lock: nil) }
}

#Preview("Zeppelin · Dark") {
    LKHost(successPause: .seconds(0.6), transition: .scale(scale: 1.15).combined(with: .opacity)) {
        ZeppelinLock(lock: $0)
    } cover: {
        ZeppelinLock(lock: nil)
    }
    .preferredColorScheme(.dark)
}
#endif
