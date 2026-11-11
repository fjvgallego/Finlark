// swift-tools-version: 6.2

import PackageDescription

// ADR-0006: the features that Xcode's Approachable Concurrency setting turns on, plus the app target's
// member import visibility.
let sharedSettings: [SwiftSetting] = [
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("MemberImportVisibility"),
]

// ADR-0006: every module except Domain defaults to the main actor.
let mainActorSettings: [SwiftSetting] = sharedSettings + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "FinlarkKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Services", targets: ["Services"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Features", targets: ["Features"]),
    ],
    targets: [
        .target(name: "Domain", swiftSettings: sharedSettings),
        .target(name: "Persistence", dependencies: ["Domain"], swiftSettings: mainActorSettings),
        .target(name: "Services", dependencies: ["Domain", "Persistence"], swiftSettings: mainActorSettings),
        .target(name: "DesignSystem", swiftSettings: mainActorSettings),
        .target(
            name: "Features",
            dependencies: ["Domain", "Persistence", "Services", "DesignSystem"],
            swiftSettings: mainActorSettings
        ),
        .testTarget(name: "DomainTests", dependencies: ["Domain"], swiftSettings: sharedSettings),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence"], swiftSettings: mainActorSettings),
    ],
    swiftLanguageModes: [.v6]
)
