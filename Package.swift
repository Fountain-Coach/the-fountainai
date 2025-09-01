// swift-tools-version: 6.1
import PackageDescription
import Foundation

// Lean build mode avoids building the entire stack on local macOS toolchains.
// Set FULL_TESTS=1 to build and test all targets.
let LEAN = (ProcessInfo.processInfo.environment["FULL_TESTS"] != "1")

let fullProducts: [Product] = [
    .library(name: "FountainCodex", targets: ["FountainCodex"]),
    .library(name: "FountainRuntime", targets: ["FountainRuntime"]),
    .library(name: "TypesensePersistence", targets: ["TypesensePersistence"]),
    .library(name: "MIDI2Models", targets: ["MIDI2Models"]),
    .library(name: "MIDI2Core", targets: ["MIDI2Core"]),
    .library(name: "FlexBridge", targets: ["FlexBridge"]),
    .library(name: "SSEOverMIDI", targets: ["SSEOverMIDI"]),
    .executable(name: "gateway-server", targets: ["gateway-server"]),
    .executable(name: "publishing-frontend", targets: ["publishing-frontend"]),
    .executable(name: "flexctl", targets: ["flexctl"]),
    .executable(name: "tools-factory-server", targets: ["tools-factory-server"]),
    .executable(name: "sse-client", targets: ["sse-client"]),
    .library(name: "PlannerService", targets: ["PlannerService"]),
    .executable(name: "planner-server", targets: ["planner-server"]),
    .library(name: "FunctionCallerService", targets: ["FunctionCallerService"]),
    .executable(name: "function-caller-server", targets: ["function-caller-server"]),
    .library(name: "ToolsFactoryService", targets: ["ToolsFactoryService"]),
    .executable(name: "openapi-curator-cli", targets: ["openapi-curator-cli"]),
    .executable(name: "openapi-curator-service", targets: ["openapi-curator-service"])]

let leanProducts: [Product] = [
    .library(name: "FountainCodex", targets: ["FountainCodex"]),
    .library(name: "FountainRuntime", targets: ["FountainRuntime"]),
    .executable(name: "gateway-server", targets: ["gateway-server"]),
    .library(name: "LLMGatewayPlugin", targets: ["LLMGatewayPlugin"]),
    .library(name: "AuthGatewayPlugin", targets: ["AuthGatewayPlugin"]),
    .library(name: "RateLimiterGatewayPlugin", targets: ["RateLimiterGatewayPlugin"]),
    .library(name: "BudgetBreakerGatewayPlugin", targets: ["BudgetBreakerGatewayPlugin"]),
    .library(name: "PayloadInspectionGatewayPlugin", targets: ["PayloadInspectionGatewayPlugin"]),
    .library(name: "DestructiveGuardianGatewayPlugin", targets: ["DestructiveGuardianGatewayPlugin"]),
    .library(name: "RoleHealthCheckGatewayPlugin", targets: ["RoleHealthCheckGatewayPlugin"])
]

var products: [Product] = LEAN ? leanProducts : fullProducts

let fullTargets: [Target] = [
    .target(
        name: "FountainCodex",
        dependencies: ["FountainRuntime"],
        path: "libs/FountainCodex",
        exclude: ["FountainCodex", "README.md"],
        sources: ["Reexport.swift"]
    ),
    .target(
        name: "FountainRuntime",
        dependencies: [
            .product(name: "AsyncHTTPClient", package: "async-http-client"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            "Yams",
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "Atomics", package: "swift-atomics")
        ],
        path: "libs/FountainRuntime",
        exclude: ["DNS/README.md"]
    ),
    .target(
        name: "LauncherSignature",
        path: "libs/LauncherSignature"
    ),
    .target(
        name: "TypesensePersistence",
        dependencies: [
            .product(name: "Typesense", package: "typesense-swift"),
            .product(name: "Numerics", package: "swift-numerics"),
            .product(name: "Atomics", package: "swift-atomics")
        ],
        path: "libs/TypesensePersistence"
    ),
    .executableTarget(
        name: "sse-client",
        dependencies: [],
        path: "apps/SSEClient"
    ),
    .executableTarget(
        name: "openapi-curator-cli",
        dependencies: ["OpenAPICurator", "Yams"],
        path: "apps/OpenAPICuratorCLI"
    ),
    .executableTarget(
        name: "openapi-curator-service",
        dependencies: ["FountainRuntime", "OpenAPICurator", "Yams", "LauncherSignature"],
        path: "apps/OpenAPICuratorService"
    ),
        .executableTarget(
        name: "gateway-server",
        dependencies: [
            "FountainRuntime",
            "PublishingFrontend",
            "LLMGatewayPlugin",
            "AuthGatewayPlugin",
            "RateLimiterGatewayPlugin",
            "BudgetBreakerGatewayPlugin",
            "PayloadInspectionGatewayPlugin",
            "DestructiveGuardianGatewayPlugin",
            "RoleHealthCheckGatewayPlugin",
            "LauncherSignature",
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "X509", package: "swift-certificates"),
            "Yams"
        ],
        path: "apps/GatewayServer"
    ),
    .target(
        name: "LLMGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/LLMGatewayPlugin"
    ),
    .target(
        name: "AuthGatewayPlugin",
        dependencies: ["FountainRuntime", .product(name: "Crypto", package: "swift-crypto")],
        path: "libs/GatewayPlugins/AuthGatewayPlugin"
    ),
    .target(
        name: "RateLimiterGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/RateLimiterGatewayPlugin",
    ),
    .target(
        name: "BudgetBreakerGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/BudgetBreakerGatewayPlugin",
    ),
    .target(
        name: "PayloadInspectionGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/PayloadInspectionGatewayPlugin",
    ),
    .target(
        name: "DestructiveGuardianGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/DestructiveGuardianGatewayPlugin",
    ),
    .target(
        name: "RoleHealthCheckGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/RoleHealthCheckGatewayPlugin",
    ),
    .target(
        name: "PublishingFrontend",
        dependencies: ["FountainRuntime", "Yams"],
        path: "libs/PublishingFrontend"
    ),
    .target(
        name: "AwarenessService",
        dependencies: ["TypesensePersistence", .product(name: "Numerics", package: "swift-numerics"), .product(name: "Atomics", package: "swift-atomics"), "FountainRuntime"],
        path: "libs/AwarenessService"
    ),
    .target(
        name: "BootstrapService",
        dependencies: ["TypesensePersistence", .product(name: "Numerics", package: "swift-numerics"), .product(name: "Atomics", package: "swift-atomics"), "FountainRuntime"],
        path: "libs/BootstrapService"
    ),
    .target(
        name: "PlannerService",
        dependencies: ["FountainRuntime", "TypesensePersistence"],
        path: "libs/PlannerService"
    ),
    .target(
        name: "FunctionCallerService",
        dependencies: ["FountainRuntime", "TypesensePersistence", .product(name: "AsyncHTTPClient", package: "async-http-client")],
        path: "libs/FunctionCallerService"
    ),
    .executableTarget(
        name: "publishing-frontend",
        dependencies: ["PublishingFrontend"],
        path: "apps/PublishingFrontendCLI"
    ),
    .target(name: "ResourceLoader", path: "libs/ResourceLoader"),
    .target(
        name: "MIDI2Models",
        dependencies: ["ResourceLoader"],
        path: "libs/MIDI2/MIDI2Models",
        resources: [.process("MIDI2Models/Resources")]
    ),
    .target(name: "MIDI2Core", dependencies: [.product(name: "MIDI2", package: "midi2")], path: "libs/MIDI2/MIDI2Core"),
    .target(name: "MIDI2Transports", path: "libs/MIDI2/MIDI2Transports"),
    .target(name: "SSEOverMIDI", dependencies: ["MIDI2Core", "MIDI2Transports", .product(name: "MIDI2", package: "midi2")], path: "libs/MIDI2/SSEOverMIDI"),
    .target(
        name: "FlexBridge",
        dependencies: [
            "MIDI2Core",
            "MIDI2Transports"
        ],
        path: "libs/MIDI2/FlexBridge"
    ),
    .executableTarget(
        name: "flexctl",
        dependencies: ["MIDI2Core", .product(name: "MIDI2", package: "midi2")],
        path: "apps/Flexctl",
        resources: [.process("flexctl/Resources")]
    ),
    .target(
        name: "ToolServer",
        dependencies: [
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "Toolsmith", package: "toolsmith"),
            "TypesensePersistence",
            .product(name: "Numerics", package: "swift-numerics"),
            .product(name: "Atomics", package: "swift-atomics")
        ],
        path: "libs/ToolServer",
        exclude: ["Service", "Dockerfile"],
        resources: [.process("openapi.yaml")]
    ),
    .target(
        name: "ToolServerService",
        dependencies: ["ToolServer"],
        path: "libs/ToolServer/Service",
        exclude: ["HTTPServer.swift"]
    ),
    .target(
        name: "ToolsFactoryService",
        dependencies: ["FountainRuntime", "ToolServer", "TypesensePersistence"],
        path: "libs/ToolsFactoryService"
    ),
    .executableTarget(
        name: "tools-factory-server",
        dependencies: ["FountainRuntime", "ToolsFactoryService", "TypesensePersistence", "LauncherSignature"],
        path: "apps/ToolsFactoryServer"
    ),
    .executableTarget(
        name: "planner-server",
        dependencies: ["FountainRuntime", "TypesensePersistence", "PlannerService", "Yams", "LauncherSignature"],
        path: "apps/PlannerServer"
    ),
    .executableTarget(
        name: "function-caller-server",
        dependencies: ["FountainRuntime", "TypesensePersistence", "FunctionCallerService", "Yams", "LauncherSignature"],
        path: "apps/FunctionCallerServer"
    ),
    .executableTarget(
        name: "persist-server",
        dependencies: ["FountainRuntime", "TypesensePersistence", "Yams", "LauncherSignature"],
        path: "apps/PersistServer"
    ),
    .executableTarget(
        name: "baseline-awareness-server",
        dependencies: ["TypesensePersistence", "AwarenessService", "LauncherSignature"],
        path: "apps/BaselineAwarenessServer"
    ),
    .executableTarget(
        name: "bootstrap-server",
        dependencies: ["TypesensePersistence", "BootstrapService", "LauncherSignature"],
        path: "apps/BootstrapServer"
    ),
    .testTarget(
        name: "SSEClientIntegrationTests",
        dependencies: ["sse-client"],
        path: "Tests/SSEClientIntegrationTests"
    ),
    .testTarget(
        name: "OpenAPICuratorCLIIntegrationTests",
        dependencies: ["openapi-curator-cli"],
        path: "Tests/OpenAPICuratorCLIIntegrationTests"
    ),
    .testTarget(
        name: "OpenAPICuratorServiceIntegrationTests",
        dependencies: ["openapi-curator-service"],
        path: "Tests/OpenAPICuratorServiceIntegrationTests"
    ),
    .testTarget(
        name: "GatewayServerIntegrationTests",
        dependencies: ["gateway-server"],
        path: "Tests/GatewayServerIntegrationTests"
    ),
    .testTarget(
        name: "PublishingFrontendIntegrationTests",
        dependencies: ["publishing-frontend"],
        path: "Tests/PublishingFrontendIntegrationTests"
    ),
    .testTarget(
        name: "FlexctlIntegrationTests",
        dependencies: ["flexctl"],
        path: "Tests/FlexctlIntegrationTests"
    ),
    .testTarget(
        name: "ToolsFactoryServerIntegrationTests",
        dependencies: ["tools-factory-server"],
        path: "Tests/ToolsFactoryServerIntegrationTests"
    ),
    .testTarget(
        name: "PlannerServerIntegrationTests",
        dependencies: ["planner-server"],
        path: "Tests/PlannerServerIntegrationTests"
    ),
    .testTarget(
        name: "FunctionCallerServerIntegrationTests",
        dependencies: ["function-caller-server"],
        path: "Tests/FunctionCallerServerIntegrationTests"
    ),
    .testTarget(
        name: "PersistServerIntegrationTests",
        dependencies: ["persist-server"],
        path: "Tests/PersistServerIntegrationTests"
    ),
    .testTarget(
        name: "BaselineAwarenessServerIntegrationTests",
        dependencies: ["baseline-awareness-server"],
        path: "Tests/BaselineAwarenessServerIntegrationTests"
    ),
    .testTarget(
        name: "BootstrapServerIntegrationTests",
        dependencies: ["bootstrap-server"],
        path: "Tests/BootstrapServerIntegrationTests"
    ),
    .testTarget(name: "ClientGeneratorTests", dependencies: ["FountainRuntime"], path: "Tests/ClientGeneratorTests"),
    .testTarget(name: "PublishingFrontendTests", dependencies: ["PublishingFrontend"], path: "Tests/PublishingFrontendTests"),
    .testTarget(name: "DNSTests", dependencies: ["PublishingFrontend", "FountainRuntime", .product(name: "Crypto", package: "swift-crypto"), .product(name: "NIOEmbedded", package: "swift-nio"), .product(name: "NIO", package: "swift-nio")], path: "Tests/DNSTests"),
    .testTarget(
        name: "IntegrationRuntimeTests",
        dependencies: ["gateway-server", "FountainRuntime", "LLMGatewayPlugin", "RateLimiterGatewayPlugin", .product(name: "NIO", package: "swift-nio"), .product(name: "AsyncHTTPClient", package: "async-http-client")],
        path: "Tests/IntegrationRuntimeTests",
        resources: [.process("Fixtures")]
    ),
    .testTarget(name: "DNSPerfTests", dependencies: ["FountainRuntime", .product(name: "NIOCore", package: "swift-nio")], path: "Tests/DNSPerfTests"),
    .testTarget(name: "MIDI2ModelsTests", dependencies: ["MIDI2Models"], path: "Tests/MIDI2ModelsTests"),
    .testTarget(name: "MIDI2CoreTests", dependencies: ["MIDI2Core", "ResourceLoader", "flexctl"], path: "Tests/MIDI2CoreTests"),
    .testTarget(name: "MIDI2TransportsTests", dependencies: ["MIDI2Transports"], path: "Tests/MIDI2TransportsTests"),
    .testTarget(name: "FlexctlTests", dependencies: ["flexctl", "ResourceLoader"], path: "Tests/FlexctlTests"),
    .testTarget(name: "GatewayAppTests", dependencies: ["gateway-server", "LLMGatewayPlugin", "AuthGatewayPlugin", "DestructiveGuardianGatewayPlugin", "PayloadInspectionGatewayPlugin", "BudgetBreakerGatewayPlugin", "RateLimiterGatewayPlugin", "RoleHealthCheckGatewayPlugin", "persist-server"], path: "Tests/GatewayAppTests"),
    .testTarget(name: "FountainOpsTests", dependencies: ["LLMGatewayPlugin"], path: "Tests/FountainOpsTests"),
    .testTarget(name: "ToolsFactoryServiceTests", dependencies: ["ToolsFactoryService", "TypesensePersistence"], path: "Tests/ToolsFactoryServiceTests"),
    .testTarget(
        name: "ToolsmithPackageTests",
        dependencies: [
            .product(name: "Toolsmith", package: "toolsmith"),
            .product(name: "SandboxRunner", package: "toolsmith"),
            .product(name: "ToolsmithSupport", package: "toolsmith"),
            .product(name: "ToolsmithAPI", package: "toolsmith")
        ],
        path: "Tests/ToolsmithPackageTests"
    ),
    .testTarget(
        name: "SSEOverMIDITests",
        dependencies: ["SSEOverMIDI", "MIDI2Transports", "MIDI2Core"],
        path: "Tests/SSEOverMIDITests"
    ),
    .testTarget(
        name: "TypesensePersistenceTests",
        dependencies: ["TypesensePersistence"],
        path: "Tests/TypesensePersistenceTests"
    ),
    .testTarget(
        name: "AwarenessServiceTests",
        dependencies: ["AwarenessService", "TypesensePersistence"],
        path: "Tests/AwarenessServiceTests"
    ),
    .testTarget(
        name: "BootstrapServiceTests",
        dependencies: ["BootstrapService", "TypesensePersistence"],
        path: "Tests/BootstrapServiceTests"
    ),
    .testTarget(
        name: "PlannerServiceTests",
        dependencies: ["PlannerService", "TypesensePersistence", "Yams"],
        path: "Tests/PlannerServiceTests"
    ),
    .testTarget(
        name: "FunctionCallerServiceTests",
        dependencies: ["FunctionCallerService", "TypesensePersistence", "FountainRuntime", "Yams"],
        path: "Tests/FunctionCallerServiceTests"
    ),
    .testTarget(
        name: "E2ETests",
        dependencies: ["AwarenessService", "BootstrapService", "TypesensePersistence"],
        path: "Tests/E2ETests"
    ),
    .testTarget(
        name: "ResourceLoaderTests",
        dependencies: ["ResourceLoader"],
        path: "Tests/ResourceLoaderTests"
    ),
    .testTarget(
        name: "OpenAPIConformanceTests",
        dependencies: ["Yams", "AwarenessService", "BootstrapService", "TypesensePersistence", "FountainRuntime", "RoleHealthCheckGatewayPlugin"],
        path: "Tests/OpenAPIConformanceTests"
    ),
    .testTarget(
        name: "ToolServerTests",
        dependencies: ["ToolServerService", "Yams"],
        path: "Tests/ToolServerTests"
    ),
    .testTarget(
        name: "FountainCodexTests",
        dependencies: ["FountainCodex", .product(name: "NIOHTTP1", package: "swift-nio")],
        path: "Tests/FountainCodexTests"
    ),
    .testTarget(
        name: "FountainRuntimeTests",
        dependencies: ["FountainRuntime", .product(name: "NIOHTTP1", package: "swift-nio")],
        path: "Tests/FountainRuntimeTests"
    ),
    .testTarget(
        name: "GatewayPluginsTests",
        dependencies: [
            "RateLimiterGatewayPlugin",
            "AuthGatewayPlugin",
            "PayloadInspectionGatewayPlugin",
            "FountainRuntime",
            .product(name: "Crypto", package: "swift-crypto")
        ],
        path: "Tests/GatewayPluginsTests"
    ),
    .testTarget(
        name: "LauncherSignatureTests",
        dependencies: ["LauncherSignature"],
        path: "Tests/LauncherSignatureTests"
    ),
    .testTarget(
        name: "MIDI2Tests",
        dependencies: ["MIDI2Models"],
        path: "Tests/MIDI2Tests"
    ),
    .testTarget(
        name: "OpenAPICuratorTests",
        dependencies: [.product(name: "OpenAPICurator", package: "OpenAPICurator")],
        path: "Tests/OpenAPICuratorTests",
        resources: [.copy("Fixtures")]
    ),
]

let leanTargets: [Target] = [
    .target(
        name: "FountainCodex",
        dependencies: ["FountainRuntime"],
        path: "libs/FountainCodex",
        exclude: ["FountainCodex", "README.md"],
        sources: ["Reexport.swift"]
    ),
    .target(
        name: "FountainRuntime",
        dependencies: [
            .product(name: "AsyncHTTPClient", package: "async-http-client"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "NIOHTTP1", package: "swift-nio"),
            "Yams",
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "Logging", package: "swift-log"),
            .product(name: "Atomics", package: "swift-atomics")
        ],
        path: "libs/FountainRuntime",
        exclude: ["DNS/README.md"]
    ),
    .target(
        name: "LauncherSignature",
        path: "libs/LauncherSignature"
    ),
    .target(
        name: "TypesensePersistence",
        dependencies: [
            .product(name: "Typesense", package: "typesense-swift"),
            .product(name: "Numerics", package: "swift-numerics"),
            .product(name: "Atomics", package: "swift-atomics")
        ],
        path: "libs/TypesensePersistence"
    ),
    .executableTarget(
        name: "gateway-server",
        dependencies: [
            "FountainRuntime",
            "PublishingFrontend",
            "LLMGatewayPlugin",
            "AuthGatewayPlugin",
            "RateLimiterGatewayPlugin",
            "BudgetBreakerGatewayPlugin",
            "PayloadInspectionGatewayPlugin",
            "DestructiveGuardianGatewayPlugin",
            "RoleHealthCheckGatewayPlugin",
            "LauncherSignature",
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "X509", package: "swift-certificates"),
            "Yams"
        ],
        path: "apps/GatewayServer"
    ),
    .target(
        name: "LLMGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/LLMGatewayPlugin"
    ),
    .target(
        name: "AuthGatewayPlugin",
        dependencies: ["FountainRuntime", .product(name: "Crypto", package: "swift-crypto")],
        path: "libs/GatewayPlugins/AuthGatewayPlugin"
    ),
    .target(
        name: "RateLimiterGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/RateLimiterGatewayPlugin"
    ),
    .target(
        name: "BudgetBreakerGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/BudgetBreakerGatewayPlugin"
    ),
    .target(
        name: "PayloadInspectionGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/PayloadInspectionGatewayPlugin"
    ),
    .target(
        name: "DestructiveGuardianGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/DestructiveGuardianGatewayPlugin"
    ),
    .target(
        name: "RoleHealthCheckGatewayPlugin",
        dependencies: ["FountainRuntime"],
        path: "libs/GatewayPlugins/RoleHealthCheckGatewayPlugin"
    ),
    .target(
        name: "PublishingFrontend",
        dependencies: ["FountainRuntime", "Yams"],
        path: "libs/PublishingFrontend"
    ),
    .target(name: "ResourceLoader", path: "libs/ResourceLoader"),
    .target(
        name: "MIDI2Models",
        dependencies: ["ResourceLoader"],
        path: "libs/MIDI2/MIDI2Models",
        resources: [.process("MIDI2Models/Resources")]
    ),
    .target(
        name: "ToolServer",
        dependencies: [
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "Toolsmith", package: "toolsmith"),
            "TypesensePersistence",
            .product(name: "Numerics", package: "swift-numerics"),
            .product(name: "Atomics", package: "swift-atomics")
        ],
        path: "libs/ToolServer",
        exclude: ["Service", "Dockerfile"],
        resources: [.process("openapi.yaml")]
    ),
    .target(
        name: "ToolServerService",
        dependencies: ["ToolServer"],
        path: "libs/ToolServer/Service",
        exclude: ["HTTPServer.swift"]
    ),
    .testTarget(
        name: "IntegrationRuntimeTests",
        dependencies: ["gateway-server", "FountainRuntime", "LLMGatewayPlugin", "RateLimiterGatewayPlugin", .product(name: "NIO", package: "swift-nio"), .product(name: "AsyncHTTPClient", package: "async-http-client")],
        path: "Tests/IntegrationRuntimeTests",
        resources: [.process("Fixtures")]
    ),
    .testTarget(
        name: "FountainCodexTests",
        dependencies: ["FountainCodex", .product(name: "NIOHTTP1", package: "swift-nio")],
        path: "Tests/FountainCodexTests"
    ),
    .testTarget(
        name: "FountainRuntimeTests",
        dependencies: ["FountainRuntime", .product(name: "NIOHTTP1", package: "swift-nio")],
        path: "Tests/FountainRuntimeTests"
    ),
    .testTarget(
        name: "GatewayPluginsTests",
        dependencies: [
            "RateLimiterGatewayPlugin",
            "AuthGatewayPlugin",
            "PayloadInspectionGatewayPlugin",
            "FountainRuntime",
            .product(name: "Crypto", package: "swift-crypto")
        ],
        path: "Tests/GatewayPluginsTests"
    ),
    .testTarget(
        name: "LauncherSignatureTests",
        dependencies: ["LauncherSignature"],
        path: "Tests/LauncherSignatureTests"
    ),
    .testTarget(
        name: "MIDI2Tests",
        dependencies: ["MIDI2Models"],
        path: "Tests/MIDI2Tests"
    ),
    .testTarget(
        name: "ResourceLoaderTests",
        dependencies: ["ResourceLoader"],
        path: "Tests/ResourceLoaderTests"
    ),
    .testTarget(
        name: "ToolServerTests",
        dependencies: ["ToolServerService", "Yams"],
        path: "Tests/ToolServerTests"
    ),
    .testTarget(
        name: "OpenAPICuratorTests",
        dependencies: [.product(name: "OpenAPICurator", package: "OpenAPICurator")],
        path: "Tests/OpenAPICuratorTests",
        resources: [.copy("Fixtures")]
    ),
]

var targets: [Target] = LEAN ? leanTargets : fullTargets

#if os(Linux)
products.append(.library(name: "PDFiumExtractor", targets: ["PDFiumExtractor"]))
targets.append(.target(name: "PDFiumExtractor", dependencies: [], path: "libs/PDFiumExtractor"))
#endif
// After appending core targets, include Linux-specific tests.
#if os(Linux)
targets.append(.testTarget(name: "PDFiumExtractorTests", dependencies: ["PDFiumExtractor"], path: "Tests/PDFiumExtractorTests"))
#endif

let package = Package(
    name: "the-fountainai",
    platforms: [
        .macOS(.v14)
    ],
    products: products,
    dependencies: [
        .package(url: "https://github.com/typesense/typesense-swift.git", from: "1.0.1"),
        .package(url: "https://github.com/Fountain-Coach/toolsmith.git", exact: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.63.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-certificates.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/Fountain-Coach/midi2.git", from: "0.3.1"),
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.3.0"),
        .package(path: "libs/OpenAPICurator"),
    ],
    targets: targets
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
