// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DynamicIsland",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "DynamicIsland",
            targets: ["DynamicIsland"]
        ),
        .library(
            name: "DynamicIslandCore",
            targets: ["DynamicIslandCore"]
        )
    ],
    targets: [
        .executableTarget(
            name: "DynamicIsland",
            dependencies: ["DynamicIslandCore"]
        ),
        .target(
            name: "DynamicIslandCore"
        ),
        .testTarget(
            name: "DynamicIslandCoreTests",
            dependencies: ["DynamicIslandCore"]
        )
    ]
)
