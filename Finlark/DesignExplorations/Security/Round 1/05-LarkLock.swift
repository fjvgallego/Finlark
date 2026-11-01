//
//  05-LarkLock.swift
//  Finlark
//
//  FIN-9 Security, Round 1 "Lark": Home's outline. Behind the lock sits a placeholder of Home, its
//  tiles and rows as empty shapes with no data in them, so the app looks like itself without showing
//  anything. A glass panel at the bottom unlocks. The app switcher shows the outline alone.
//

#if DEBUG
import SwiftUI

struct LarkLock: View {
    /// Nil draws the app switcher's cover.
    let lock: LKLock?

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        LarkOutline()
            .safeAreaInset(edge: .bottom) {
                if let lock {
                    R2Tile(padding: 20) {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 14) {
                                if !dynamicTypeSize.isAccessibilitySize {
                                    LKMark(size: 44)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(LKText.title)
                                        .font(.headline)
                                        .accessibilityAddTraits(.isHeader)
                                    if !dynamicTypeSize.isAccessibilitySize {
                                        Text("Unlock to see your balance.")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            LKUnlockButton(lock: lock)
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }
            .background { LKBackdrop() }
    }
}

/// Home's shapes without its data: the balance tile, the plan tile and a few rows.
private struct LarkOutline: View {
    var body: some View {
        VStack(spacing: r2TileSpacing) {
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    LarkBar(width: 90, height: 12)
                    LarkBar(width: 190, height: 34)
                    LarkBar(height: 30)
                    ForEach(0..<3, id: \.self) { _ in
                        HStack {
                            LarkBar(width: 80, height: 12)
                            Spacer()
                            LarkBar(width: 64, height: 12)
                        }
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            R2Tile(padding: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    LarkBar(width: 110, height: 12)
                    ForEach(0..<3, id: \.self) { _ in
                        LarkBar(height: 8)
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .frame(width: 36, height: 36)
                        VStack(alignment: .leading, spacing: 6) {
                            LarkBar(width: 120, height: 12)
                            LarkBar(width: 70, height: 10)
                        }
                        Spacer()
                        LarkBar(width: 56, height: 12)
                    }
                }
            }
            .padding(.horizontal, 6)
            .padding(.top, 8)
        }
        .foregroundStyle(.quaternary)
        .padding()
        .frame(maxHeight: .infinity, alignment: .top)
        .mask {
            LinearGradient(colors: [.black, .black, .clear], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
        .accessibilityHidden(true)
    }
}

private struct LarkBar: View {
    var width: CGFloat?
    let height: CGFloat

    var body: some View {
        Capsule()
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

#Preview("Lark") {
    LKHost { LarkLock(lock: $0) } cover: { LarkLock(lock: nil) }
}

#Preview("Lark · Touch ID") {
    LKHost(biometry: .touchID) { LarkLock(lock: $0) } cover: { LarkLock(lock: nil) }
}

#Preview("Lark · App Switcher") {
    LKAppSwitcher { LarkLock(lock: nil) }
}

#Preview("Lark · Dark") {
    LKHost { LarkLock(lock: $0) } cover: { LarkLock(lock: nil) }
        .preferredColorScheme(.dark)
}
#endif
