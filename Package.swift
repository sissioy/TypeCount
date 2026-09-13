// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "TypeCount",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TypeCount", targets: ["TypeCount"])
    ],
    targets: [
        .target(
            name: "TypeCountCore",
            linkerSettings: [
                .linkedFramework("CoreGraphics")
            ]
        ),
        .executableTarget(
            name: "TypeCount",
            dependencies: ["TypeCountCore"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("SwiftUI")
            ]
        ),
        .testTarget(
            name: "TypeCountCoreTests",
            dependencies: ["TypeCountCore"]
        )
    ]
)
