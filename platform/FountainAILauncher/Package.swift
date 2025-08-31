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
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "FountainAiLauncher",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
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
