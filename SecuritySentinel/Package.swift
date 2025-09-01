// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "SecuritySentinel",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SecuritySentinelGatewayPlugin",
            targets: ["SecuritySentinelGatewayPluginModule"]
        )
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "SecuritySentinelGatewayPluginModule",
            dependencies: [
                .product(name: "FountainRuntime", package: "the-fountainai"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/SecuritySentinelGatewayPlugin"
        ),
        .testTarget(
            name: "SecuritySentinelGatewayPluginTests",
            dependencies: [
                "SecuritySentinelGatewayPluginModule",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "FountainRuntime", package: "the-fountainai")
            ],
            path: "Tests/SecuritySentinelGatewayPluginTests"
        )
    ]
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
