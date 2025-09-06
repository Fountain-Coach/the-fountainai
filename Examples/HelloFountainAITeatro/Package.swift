// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HelloFountainAITeatro",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "hello-fountainai-teatro", targets: ["HelloFountainAITeatro"])
    ],
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/Teatro.git", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "HelloFountainAITeatro",
            dependencies: [
                .product(name: "TeatroRenderAPI", package: "Teatro")
            ],
            path: "Linux"
        ),
        .testTarget(
            name: "HelloFountainAITeatroTests",
            dependencies: ["HelloFountainAITeatro"],
            path: "Tests/HelloFountainAITeatroTests"
        )
    ]
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

