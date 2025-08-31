// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "FountainAiLauncher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FountainAiLauncher", targets: ["FountainAiLauncher"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.63.0")
    ],
    targets: [
        .executableTarget(
            name: "FountainAiLauncher",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio")
            ],
            path: "Sources",
            resources: [
                .copy("services.json")
            ]
        ),
        .testTarget(
            name: "FountainAiLauncherTests",
            dependencies: ["FountainAiLauncher"],
            path: "Tests/FountainAiLauncherTests"
        )
    ]
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
