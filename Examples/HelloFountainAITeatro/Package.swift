// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "HelloFountainAITeatro",
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
        )
    ]
)
