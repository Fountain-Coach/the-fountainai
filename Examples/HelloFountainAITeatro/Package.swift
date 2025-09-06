// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HelloFountainAITeatro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "HelloFountainAITeatro", targets: ["HelloFountainAITeatro"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/Teatro.git", branch: "main"),
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "HelloFountainAITeatro",
            dependencies: [
                .product(name: "Teatro", package: "teatro"),
                .product(name: "TeatroRenderAPI", package: "teatro"),
                .product(name: "FountainRuntime", package: "the-fountainai")
            ],
            path: "macOS"
        )
    ]
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
