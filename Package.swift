// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ResonanceKit",
    platforms: [
        .iOS(.v12), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "ResonanceKit",
            targets: ["ResonanceKit"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/belozierov/SwiftCoroutine.git", from: "2.1.2"),
        .package(url: "https://github.com/possen/SwiftyBeaver.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "ResonanceKit",
            dependencies: ["SwiftCoroutine", "SwiftyBeaverKit"]
        ),
        .testTarget(
            name: "ResonanceKitTests",
            dependencies: ["ResonanceKit"]
        ),
    ]
)
