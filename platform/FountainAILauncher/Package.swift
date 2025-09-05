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
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.63.0"),
        .package(url: "https://github.com/Fountain-Coach/Teatro.git", branch: "main"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0")
    ],
    targets: [
        .executableTarget(
            name: "FountainAiLauncher",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "Teatro", package: "teatro"),
                .product(name: "TeatroRenderAPI", package: "teatro"),
                .product(name: "Yams", package: "yams")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "FountainAiLauncherTests",
            dependencies: ["FountainAiLauncher"],
            path: "Tests"
        )
    ]
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
