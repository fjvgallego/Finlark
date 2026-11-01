//
//  SecurityComponents.swift
//  Finlark
//
//  FIN-9 Security: pieces shared by the App Lock explorations (SEC-001, SEC-002, A-14). Each variant
//  draws two things: the lock screen, shown on launch and after a minute or more away, and the cover the
//  app switcher shows while App Lock is on. The host puts both over Marsh, the chosen Home.
//  Authentication is mocked. The real app asks LocalAuthentication for `.deviceOwnerAuthentication`,
//  which shows Face ID or Touch ID and falls back to the device passcode on its own.
//

#if DEBUG
import SwiftUI

// MARK: - Model

enum LKPhase {
    case locked
    /// The system's Face ID, Touch ID or passcode prompt is up.
    case authenticating
    /// Authentication passed and the lock screen is on its way out. Only lasts for variants that
    /// animate the unlock.
    case succeeded
    case unlocked
}

@Observable
final class LKLock {
    let biometry: STBiometry
    var phase: LKPhase
    /// How long `.succeeded` lasts before the lock screen goes away.
    let successPause: Duration

    init(biometry: STBiometry, phase: LKPhase, successPause: Duration) {
        self.biometry = biometry
        self.phase = phase
        self.successPause = successPause
    }

    var isLocked: Bool { phase != .unlocked }

    /// Mocked: the system prompt shows for a moment, then passes.
    func unlock() {
        guard phase == .locked else { return }
        phase = .authenticating
        Task {
            try? await Task.sleep(for: .seconds(1.2))
            if successPause > .zero {
                phase = .succeeded
                try? await Task.sleep(for: successPause)
            }
            phase = .unlocked
        }
    }

    func lock() {
        phase = .locked
    }
}

/// How long Finlark can stay in the background before it locks again (A-14).
let lkRelockInterval: TimeInterval = 60

/// Enough blur that no amount, name or category on Home can be read.
let lkBlurRadius: CGFloat = 28

// MARK: - Host

/// Marsh behind the lock. It's locked on launch, shows the cover whenever the scene isn't active (the
/// app switcher, Control Center), and locks again after a minute or more in the background. While
/// locked, Home is hidden from VoiceOver and can't be touched.
struct LKHost<LockScreen: View, Cover: View>: View {
    @State private var lock: LKLock
    @State private var backgroundedAt: Date?
    private let blursContent: Bool
    private let transition: AnyTransition
    private let lockScreen: (LKLock) -> LockScreen
    private let cover: Cover

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// - Parameters:
    ///   - blursContent: true for variants that show Home blurred behind the lock and the cover.
    ///   - transition: how the lock screen leaves once unlocked. Reduce Motion always fades.
    init(
        biometry: STBiometry = .faceID,
        phase: LKPhase = .locked,
        successPause: Duration = .zero,
        blursContent: Bool = false,
        transition: AnyTransition = .opacity,
        @ViewBuilder lockScreen: @escaping (LKLock) -> LockScreen,
        @ViewBuilder cover: () -> Cover
    ) {
        _lock = State(initialValue: LKLock(biometry: biometry, phase: phase, successPause: successPause))
        self.blursContent = blursContent
        self.transition = transition
        self.lockScreen = lockScreen
        self.cover = cover()
    }

    private var hidesContent: Bool {
        lock.isLocked || scenePhase != .active
    }

    var body: some View {
        MarshHomeView()
            .blur(radius: blursContent && hidesContent ? lkBlurRadius : 0)
            .background { LKBackdrop() }
            .accessibilityHidden(hidesContent)
            .allowsHitTesting(!lock.isLocked)
            .overlay {
                if lock.isLocked {
                    lockScreen(lock)
                        .transition(reduceMotion ? .opacity : transition)
                }
            }
            .overlay {
                if scenePhase != .active {
                    cover
                }
            }
            .overlay {
                if lock.phase == .authenticating {
                    LKSystemPromptStandIn(biometry: lock.biometry)
                }
            }
            .animation(.smooth(duration: 0.35), value: lock.phase)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background:
                    backgroundedAt = .now
                case .active:
                    if let backgroundedAt, Date.now.timeIntervalSince(backgroundedAt) >= lkRelockInterval {
                        lock.lock()
                    }
                    backgroundedAt = nil
                default:
                    break
                }
            }
    }
}

/// Stands in for the system's prompt, which iOS draws over the app: a Face ID glyph in the middle of
/// the screen, or the Touch ID and passcode sheets. The app can't style it.
struct LKSystemPromptStandIn: View {
    let biometry: STBiometry

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: biometry.symbol)
                .font(.system(size: 56, weight: .light))
            Text(biometry.title)
                .font(.subheadline)
        }
        .foregroundStyle(.secondary)
        .frame(width: 150, height: 150)
        .background(.regularMaterial, in: .rect(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The app switcher with Finlark's card in it, to judge the cover (SEC-002) where people see it.
struct LKAppSwitcher<Cover: View>: View {
    var blursContent = false
    @ViewBuilder let cover: Cover

    private let scale = 0.7

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    LKMark(size: 26)
                    Text(verbatim: "Finlark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                }
                ZStack {
                    if blursContent {
                        MarshHomeView()
                            .blur(radius: lkBlurRadius)
                            .background { LKBackdrop() }
                            .accessibilityHidden(true)
                    }
                    cover
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipShape(.rect(cornerRadius: 55, style: .continuous))
                .scaleEffect(scale)
                .frame(width: proxy.size.width * scale, height: proxy.size.height * scale)
                .allowsHitTesting(false)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background {
            LinearGradient(colors: [Color(white: 0.3), .black], startPoint: .top, endPoint: .bottom)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Pieces

/// Marsh's backdrop on an opaque base, since the lock screen hides what's under it.
struct LKBackdrop: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            R2Backdrop()
        }
        .ignoresSafeArea()
    }
}

/// Finlark's mark: a stand-in until the app icon exists, in the backdrop's indigo and teal. It grows with
/// the text up to the largest standard size, and no further, since it's decoration.
struct LKMark: View {
    var size: CGFloat = 64

    var body: some View {
        LKMarkTile(size: size)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private struct LKMarkTile: View {
    @ScaledMetric private var size: CGFloat

    init(size: CGFloat) {
        _size = ScaledMetric(wrappedValue: size)
    }

    var body: some View {
        Image(systemName: "bird.fill")
            .font(.system(size: size * 0.48, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(colors: [.indigo, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: .rect(cornerRadius: size * 0.225, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

enum LKText {
    static let title: LocalizedStringKey = "Finlark is Locked"

    static func unlock(_ biometry: STBiometry) -> Text {
        Text("Unlock with \(Text(biometry.title))")
    }
}

/// "Unlock with Face ID", Touch ID or Passcode. Disabled while the system prompt is up. At accessibility
/// sizes it says just "Unlock" so it stays on one line, and VoiceOver still hears the method.
struct LKUnlockButton: View {
    let lock: LKLock
    var prominent = true

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let button = Button {
            lock.unlock()
        } label: {
            Label {
                if dynamicTypeSize.isAccessibilitySize {
                    Text("Unlock")
                } else {
                    LKText.unlock(lock.biometry)
                }
            } icon: {
                Image(systemName: lock.biometry.symbol)
            }
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .disabled(lock.phase != .locked)
        .accessibilityLabel(LKText.unlock(lock.biometry))

        if prominent {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }
}

/// A lock screen's layout: its content placed in the screen, with a bar of controls at the bottom. It
/// scrolls when the content doesn't fit, at the largest text sizes.
struct LKCentered<Content: View, Bottom: View>: View {
    private let alignment: Alignment
    private let content: Content
    private let bottom: Bottom?

    init(alignment: Alignment = .center, @ViewBuilder content: () -> Content, @ViewBuilder bottom: () -> Bottom) {
        self.alignment = alignment
        self.content = content()
        self.bottom = bottom()
    }

    var body: some View {
        let laidOut = content
            .frame(maxWidth: .infinity, alignment: alignment)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)

        ViewThatFits(in: .vertical) {
            laidOut
                .frame(maxHeight: .infinity, alignment: alignment)
            ScrollView {
                laidOut
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let bottom {
                bottom
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
        }
    }
}

extension LKCentered where Bottom == Never {
    init(alignment: Alignment = .center, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.content = content()
        self.bottom = nil
    }
}
#endif
