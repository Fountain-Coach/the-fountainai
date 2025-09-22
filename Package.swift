// swift-tools-version: 6.1
import PackageDescription
import Foundation

// Lean build mode avoids building the entire stack on local macOS toolchains.
// Set FULL_TESTS=1 to build and test all targets.
let LEAN = (ProcessInfo.processInfo.environment["FULL_TESTS"] != "1")

var fullProducts: [Product] = [
    .library(name: "FountainCodex", targets: ["FountainCodex"]),
    .library(name: "FountainRuntime", targets: ["FountainRuntime"]),
    .library(name: "FountainStoreClient", targets: ["FountainStoreClient"]),
    .library(name: "MIDI2Models", targets: ["MIDI2Models"]),
    .library(name: "MIDI2Core", targets: ["MIDI2Core"]),
    .library(name: "FlexBridge", targets: ["FlexBridge"]),
    .library(name: "SSEOverMIDI", targets: ["SSEOverMIDI"]),
    .library(name: "TutorDashboard", targets: ["TutorDashboard"]),
    .executable(name: "tutor-dashboard", targets: ["tutor-dashboard"]),
    .executable(name: "gateway-server", targets: ["gateway-server"]),
    .executable(name: "fountain-gateway", targets: ["gateway-server"]),
    .executable(name: "clientgen-service", targets: ["clientgen-service"]),
    .executable(name: "publishing-frontend", targets: ["publishing-frontend"]),
    
    .executable(name: "flexctl", targets: ["flexctl"]),
    .executable(name: "tools-factory-server", targets: ["tools-factory-server"]),
    .executable(name: "tools-factory", targets: ["tools-factory-server"]),
    .executable(name: "tool-server", targets: ["tool-server"]),
    .executable(name: "sse-client", targets: ["sse-client"]),
    .library(name: "PlannerService", targets: ["PlannerService"]),
    .executable(name: "planner-server", targets: ["planner-server"]),
    .executable(name: "planner", targets: ["planner-server"]),
    .library(name: "FunctionCallerService", targets: ["FunctionCallerService"]),
    .executable(name: "function-caller-server", targets: ["function-caller-server"]),
    .executable(name: "function-caller", targets: ["function-caller-server"]),
    .library(name: "ToolsFactoryService", targets: ["ToolsFactoryService"]),
    .executable(name: "openapi-curator-cli", targets: ["openapi-curator-cli"]),
    .executable(name: "openapi-curator-service", targets: ["openapi-curator-service"]),
    .library(name: "GatewayPersonaOrchestrator", targets: ["GatewayPersonaOrchestrator"]),
    .library(name: "CuratorGatewayPlugin", targets: ["CuratorGatewayPlugin"]),
    .executable(name: "semantic-browser-server", targets: ["semantic-browser-server"]),
    .executable(name: "semantic-browser", targets: ["semantic-browser-server"]),
    .executable(name: "baseline-awareness-server", targets: ["baseline-awareness-server"]),
    .executable(name: "baseline-awareness", targets: ["baseline-awareness-server"]),
    .executable(name: "bootstrap-server", targets: ["bootstrap-server"]),
    .executable(name: "bootstrap", targets: ["bootstrap-server"]),
    .executable(name: "persist-server", targets: ["persist-server"]),
    .executable(name: "persist", targets: ["persist-server"])
]

var leanProducts: [Product] = [
    .library(name: "ApiClientsCore", targets: ["ApiClientsCore"]),
    .library(name: "GatewayAPI", targets: ["GatewayAPI"]),
    .library(name: "PersistAPI", targets: ["PersistAPI"]),
    .library(name: "SemanticBrowserAPI", targets: ["SemanticBrowserAPI"]),
    .library(name: "LLMGatewayAPI", targets: ["LLMGatewayAPI"]),
    .library(name: "TutorDashboard", targets: ["TutorDashboard"]),
    .executable(name: "tutor-dashboard", targets: ["tutor-dashboard"]),
    .executable(name: "publishing-frontend", targets: ["publishing-frontend"])
]

#if os(macOS)
fullProducts.append(contentsOf: [
    .executable(name: "FountainLauncherUI", targets: ["FountainLauncherUI"]),
    .executable(name: "FountainDashboard", targets: ["FountainLauncherUI"])
])
leanProducts.append(contentsOf: [
    .executable(name: "FountainLauncherUI", targets: ["FountainLauncherUI"]),
    .executable(name: "FountainDashboard", targets: ["FountainLauncherUI"])
])
#endif

var products: [Product] = LEAN ? leanProducts : fullProducts

var fullTargets: [Target] = [
    .target(
        name: "ApiClientsCore",
        dependencies: [],
        path: "libs/ApiClientsCore/Sources/ApiClientsCore"
    ),
    .testTarget(
        name: "SystemSmokeTests",
        dependencies: [
            "FountainRuntime",
            "FountainStoreClient",
            "PlannerService",
            "BootstrapService",
            "ToolsFactoryService",
            "gateway-server",
            "openapi-curator-service"
        ],
        path: "Tests/SystemSmokeTests"
    ),
    .testTarget(
        name: "TutorPathModule1Tests",
        dependencies: [
            "TutorDashboard",
            .product(name: "Yams", package: "Yams")
        ],
        path: "Tests/TutorPathModule1Tests"
    ),
    .target(
        name: "GatewayAPI",
        dependencies: ["ApiClientsCore"],
        path: "libs/GatewayAPI/Sources/GatewayAPI"
    ),
    .target(
        name: "PersistAPI",
        dependencies: ["ApiClientsCore"],
        path: "libs/PersistAPI/Sources/PersistAPI"
    ),
    .target(
        name: "SemanticBrowserAPI",
        dependencies: ["ApiClientsCore"],
        path: "libs/SemanticBrowserAPI/Sources/SemanticBrowserAPI"
    ),
    .target(
        name: "LLMGatewayAPI",
        dependencies: ["ApiClientsCore"],
        path: "libs/LLMGatewayAPI/Sources/LLMGatewayAPI"
    ),
    .target(
        name: "TutorDashboard",
        dependencies: [
            "ApiClientsCore",
            .product(name: "Yams", package: "Yams")
        ],
        path: "libs/TutorDashboard/Sources"
    ),
    .executableTarget(
        name: "tutor-dashboard",
        dependencies: [
            "TutorDashboard",
            .product(name: "SwiftCursesKit", package: "swiftcurseskit")
        ],
        path: "apps/TutorDashboardApp"
    ),
    .target(
        name: "FountainAICore",
        dependencies: [],
        path: "libs/FountainAICore/Sources/FountainAICore"
    ),
    .target(
        name: "FountainAIAdapters",
        dependencies: ["FountainAICore", "LLMGatewayAPI", "SemanticBrowserAPI", "PersistAPI"],
        path: "libs/FountainAIAdapters/Sources/FountainAIAdapters"
    ),
    
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
            .product(name: "Atomics", package: "swift-atomics"),
            "FountainStoreClient",
            .product(name: "FountainStore", package: "fountain-store")
        ],
        path: "libs/FountainRuntime",
        exclude: ["DNS/README.md"]
    ),
    .target(
        name: "LauncherSignature",
        path: "libs/LauncherSignature"
    ),
    .target(
        name: "FountainStoreClient",
        dependencies: [.product(name: "FountainStore", package: "fountain-store")],
        path: "libs/FountainStoreClient"
    ),
    .executableTarget(
        name: "clientgen-service",
        dependencies: [],
        path: "tools/ClientgenService/clientgen-service"
    ),
    .executableTarget(
        name: "sse-client",
        dependencies: [],
        path: "tools/SSEClient"
    ),
    .executableTarget(
        name: "openapi-curator-cli",
        dependencies: ["OpenAPICurator", "Yams"],
        path: "tools/OpenAPICuratorCLI"
    ),
    .executableTarget(
        name: "openapi-curator-service",
        dependencies: ["FountainRuntime", "OpenAPICurator", "Yams", "LauncherSignature"],
        path: "services/OpenAPICuratorService",
        exclude: ["README.md"]
    ),
    .executableTarget(
        name: "semantic-browser-server",
        dependencies: [
            .product(name: "SemanticBrowser", package: "semantic-browser"),
            "LauncherSignature"
        ],
        path: "services/SemanticBrowserServer",
        exclude: ["README.md"]
    ),
        .executableTarget(
        name: "gateway-server",
        dependencies: [
            "FountainRuntime",
            "PublishingFrontend",
            "LLMGatewayPlugin",
            "AuthGatewayPlugin",
            "CuratorGatewayPlugin",
            "RateLimiterGatewayPlugin",
            "BudgetBreakerGatewayPlugin",
            "PayloadInspectionGatewayPlugin",
            "DestructiveGuardianGatewayPlugin",
            "RoleHealthCheckGatewayPlugin",
            "SecuritySentinelGatewayPlugin",
            "GatewayPersonaOrchestrator",
            "LauncherSignature",
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "X509", package: "swift-certificates"),
            "Yams"
        ],
        path: "services/GatewayServer",
        exclude: ["README.md"]
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
        name: "SecuritySentinelGatewayPlugin",
        dependencies: [
            "FountainRuntime",
            .product(name: "AsyncHTTPClient", package: "async-http-client"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "Logging", package: "swift-log")
        ],
        path: "libs/GatewayPlugins/SecuritySentinelGatewayPlugin",
    ),
    .target(
        name: "CuratorGatewayPlugin",
        dependencies: ["FountainRuntime", "OpenAPICurator"],
        path: "libs/GatewayPlugins/CuratorGatewayPlugin",
    ),
    .target(
        name: "GatewayPersonaOrchestrator",
        dependencies: [
            "FountainRuntime",
            "SecuritySentinelGatewayPlugin",
            "DestructiveGuardianGatewayPlugin"
        ],
        path: "libs/GatewayPersonaOrchestrator"
    ),
    .target(
        name: "PublishingFrontend",
        dependencies: ["FountainRuntime", "Yams"],
        path: "libs/PublishingFrontend"
    ),
    .target(
        name: "AwarenessService",
        dependencies: ["FountainStoreClient", .product(name: "Numerics", package: "swift-numerics"), .product(name: "Atomics", package: "swift-atomics"), "FountainRuntime"],
        path: "libs/AwarenessService"
    ),
    .target(
        name: "BootstrapService",
        dependencies: ["FountainStoreClient", .product(name: "Numerics", package: "swift-numerics"), .product(name: "Atomics", package: "swift-atomics"), "FountainRuntime"],
        path: "libs/BootstrapService"
    ),
    .target(
        name: "PlannerService",
        dependencies: ["FountainRuntime", "FountainStoreClient"],
        path: "libs/PlannerService"
    ),
    .target(
        name: "FunctionCallerService",
        dependencies: ["FountainRuntime", "FountainStoreClient", .product(name: "AsyncHTTPClient", package: "async-http-client")],
        path: "libs/FunctionCallerService"
    ),
    .executableTarget(
        name: "publishing-frontend",
        dependencies: ["PublishingFrontend"],
        path: "tools/PublishingFrontendCLI"
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
        path: "tools/Flexctl",
        resources: [.process("flexctl/Resources")]
    ),
    .target(
        name: "ToolServer",
        dependencies: [
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "Toolsmith", package: "toolsmith"),
            "FountainStoreClient",
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
        dependencies: ["FountainRuntime", "ToolServer", "FountainStoreClient"],
        path: "libs/ToolsFactoryService"
    ),
    .executableTarget(
        name: "tools-factory-server",
        dependencies: ["FountainRuntime", "ToolsFactoryService", "FountainStoreClient", "LauncherSignature"],
        path: "services/ToolsFactoryServer",
        exclude: ["README.md"]
    ),
    .executableTarget(
        name: "tool-server",
        dependencies: ["FountainRuntime", "ToolServerService", "LauncherSignature"],
        path: "services/ToolServer"
    ),
    .executableTarget(
        name: "planner-server",
        dependencies: ["FountainRuntime", "FountainStoreClient", "PlannerService", "Yams", "LauncherSignature"],
        path: "services/PlannerServer",
        exclude: ["README.md"]
    ),
    .executableTarget(
        name: "function-caller-server",
        dependencies: ["FountainRuntime", "FountainStoreClient", "FunctionCallerService", "Yams", "LauncherSignature"],
        path: "services/FunctionCallerServer",
        exclude: ["README.md"]
    ),
    .executableTarget(
        name: "persist-server",
        dependencies: ["FountainRuntime", "FountainStoreClient", "Yams", "LauncherSignature"],
        path: "services/PersistServer",
        exclude: ["README.md"]
    ),
    .executableTarget(
        name: "baseline-awareness-server",
        dependencies: ["FountainStoreClient", "AwarenessService", "LauncherSignature"],
        path: "services/BaselineAwarenessServer",
        exclude: ["README.md"]
    ),
    .executableTarget(
        name: "bootstrap-server",
        dependencies: ["FountainStoreClient", "BootstrapService", "LauncherSignature"],
        path: "services/BootstrapServer",
        exclude: ["README.md"]
    ),
    .executableTarget(
        name: "gui-diagnostics",
        dependencies: ["ApiClientsCore", "GatewayAPI", "PersistAPI", "SemanticBrowserAPI", "LLMGatewayAPI"],
        path: "tools/GuiDiagnostics"
    ),
    .testTarget(
        name: "ApiClientsCoreTests",
        dependencies: ["ApiClientsCore"],
        path: "Tests/ApiClientsCoreTests"
    ),
    .testTarget(
        name: "GatewayAPITests2",
        dependencies: ["GatewayAPI", "ApiClientsCore"],
        path: "Tests/GatewayAPITests2"
    ),
    .testTarget(
        name: "PersistAPITests",
        dependencies: ["PersistAPI", "ApiClientsCore"],
        path: "Tests/PersistAPITests"
    ),
    .testTarget(
        name: "SemanticBrowserAPITests",
        dependencies: ["SemanticBrowserAPI", "ApiClientsCore"],
        path: "Tests/SemanticBrowserAPITests"
    ),
    .testTarget(
        name: "LLMGatewayAPITests",
        dependencies: ["LLMGatewayAPI", "ApiClientsCore"],
        path: "Tests/LLMGatewayAPITests"
    ),
    .testTarget(
        name: "SSEClientIntegrationTests",
        dependencies: ["sse-client"],
        path: "Tests/SSEClientIntegrationTests"
    ),
    .testTarget(
        name: "ClientgenServiceIntegrationTests",
        dependencies: ["clientgen-service"],
        path: "Tests/ClientgenServiceIntegrationTests"
    ),
    .testTarget(
        name: "OpenAPICuratorCLIIntegrationTests",
        dependencies: ["openapi-curator-cli"],
        path: "Tests/OpenAPICuratorCLIIntegrationTests"
    ),
    .testTarget(
        name: "OpenAPICuratorServiceIntegrationTests",
        dependencies: ["openapi-curator-service", "FountainStoreClient"],
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
    .testTarget(name: "PublishingFrontendTests", dependencies: ["PublishingFrontend", "FountainStoreClient"], path: "Tests/PublishingFrontendTests"),
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
    .testTarget(name: "GatewayAppTests", dependencies: ["gateway-server", "LLMGatewayPlugin", "AuthGatewayPlugin", "DestructiveGuardianGatewayPlugin", "PayloadInspectionGatewayPlugin", "BudgetBreakerGatewayPlugin", "RateLimiterGatewayPlugin", "RoleHealthCheckGatewayPlugin", "persist-server", "FountainStoreClient"], path: "Tests/GatewayAppTests"),
    .testTarget(name: "ToolsFactoryServiceTests", dependencies: ["ToolsFactoryService", "FountainStoreClient"], path: "Tests/ToolsFactoryServiceTests"),
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
        name: "AwarenessServiceTests",
        dependencies: ["AwarenessService", "FountainStoreClient"],
        path: "Tests/AwarenessServiceTests"
    ),
    .testTarget(
        name: "BootstrapServiceTests",
        dependencies: ["BootstrapService", "FountainStoreClient"],
        path: "Tests/BootstrapServiceTests"
    ),
    .testTarget(
        name: "PlannerServiceTests",
        dependencies: ["PlannerService", "FountainStoreClient", "Yams"],
        path: "Tests/PlannerServiceTests"
    ),
    .testTarget(
        name: "FunctionCallerServiceTests",
        dependencies: ["FunctionCallerService", "FountainStoreClient", "FountainRuntime", "Yams"],
        path: "Tests/FunctionCallerServiceTests"
    ),
    .testTarget(
        name: "E2ETests",
        dependencies: ["AwarenessService", "BootstrapService", "FountainStoreClient"],
        path: "Tests/E2ETests"
    ),
    .testTarget(
        name: "ResourceLoaderTests",
        dependencies: ["ResourceLoader"],
        path: "Tests/ResourceLoaderTests",
        resources: [.process("Resources")]
    ),
    .testTarget(
        name: "TokenValidationTests",
        dependencies: ["gateway-server", .product(name: "Crypto", package: "swift-crypto")],
        path: "Tests/TokenValidationTests"
    ),
    .testTarget(
        name: "FountainStoreClientTests",
        dependencies: ["FountainStoreClient"],
        path: "Tests/FountainStoreClientTests"
    ),
    .testTarget(
        name: "OpenAPIConformanceTests",
        dependencies: ["Yams", "AwarenessService", "BootstrapService", "FountainStoreClient", "FountainRuntime", "RoleHealthCheckGatewayPlugin"],
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
        dependencies: ["FountainRuntime", "FountainStoreClient", .product(name: "NIOHTTP1", package: "swift-nio")],
        path: "Tests/FountainRuntimeTests"
    ),
    .testTarget(
        name: "GatewayConfigStoreTests",
        dependencies: ["gateway-server", "FountainStoreClient"],
        path: "Tests/GatewayConfigStoreTests"
    ),
    .testTarget(
        name: "GatewayPluginsTests",
        dependencies: [
            "RateLimiterGatewayPlugin",
            "AuthGatewayPlugin",
            "PayloadInspectionGatewayPlugin",
            "BudgetBreakerGatewayPlugin",
            "LLMGatewayPlugin",
            "RoleHealthCheckGatewayPlugin",
            "SecuritySentinelGatewayPlugin",
            "DestructiveGuardianGatewayPlugin",
            "CuratorGatewayPlugin",
            "FountainRuntime",
            .product(name: "Crypto", package: "swift-crypto")
        ],
        path: "Tests/GatewayPluginsTests"
    ),
    .testTarget(
        name: "GatewayPersonaOrchestratorTests",
        dependencies: [
            "GatewayPersonaOrchestrator",
            "FountainRuntime",
            "SecuritySentinelGatewayPlugin",
            "DestructiveGuardianGatewayPlugin"
        ],
        path: "Tests/GatewayPersonaOrchestratorTests"
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
        name: "SemanticBrowserTests",
        dependencies: [.product(name: "SemanticBrowser", package: "semantic-browser")],
        path: "Tests/SemanticBrowserTests"
    ),
    .testTarget(
        name: "OpenAPICuratorTests",
        dependencies: [.product(name: "OpenAPICurator", package: "OpenAPICurator")],
        path: "Tests/OpenAPICuratorTests",
        resources: [.copy("Fixtures")]
    ),
    .testTarget(
        name: "SwiftCursesKitIntegrationTests",
        dependencies: [
            .product(name: "SwiftCursesKit", package: "swiftcurseskit")
        ],
        path: "Tests/SwiftCursesKitIntegrationTests"
    ),
]

let leanTargets: [Target] = [
    .target(
        name: "ApiClientsCore",
        dependencies: [],
        path: "libs/ApiClientsCore/Sources/ApiClientsCore"
    ),
    .target(
        name: "GatewayAPI",
        dependencies: ["ApiClientsCore"],
        path: "libs/GatewayAPI/Sources/GatewayAPI"
    ),
    .target(
        name: "PersistAPI",
        dependencies: ["ApiClientsCore"],
        path: "libs/PersistAPI/Sources/PersistAPI"
    ),
    .target(
        name: "SemanticBrowserAPI",
        dependencies: ["ApiClientsCore"],
        path: "libs/SemanticBrowserAPI/Sources/SemanticBrowserAPI"
    ),
    .target(
        name: "LLMGatewayAPI",
        dependencies: ["ApiClientsCore"],
        path: "libs/LLMGatewayAPI/Sources/LLMGatewayAPI"
    ),
    .target(
        name: "TutorDashboard",
        dependencies: [
            "ApiClientsCore",
            .product(name: "Yams", package: "Yams")
        ],
        path: "libs/TutorDashboard/Sources"
    ),
    .testTarget(
        name: "ApiClientsCoreTests",
        dependencies: ["ApiClientsCore"],
        path: "Tests/ApiClientsCoreTests"
    ),
    .testTarget(
        name: "GatewayAPITests2",
        dependencies: ["GatewayAPI", "ApiClientsCore"],
        path: "Tests/GatewayAPITests2"
    ),
    .testTarget(
        name: "PersistAPITests",
        dependencies: ["PersistAPI", "ApiClientsCore"],
        path: "Tests/PersistAPITests"
    ),
    .testTarget(
        name: "SemanticBrowserAPITests",
        dependencies: ["SemanticBrowserAPI", "ApiClientsCore"],
        path: "Tests/SemanticBrowserAPITests"
    ),
    .testTarget(
        name: "LLMGatewayAPITests",
        dependencies: ["LLMGatewayAPI", "ApiClientsCore"],
        path: "Tests/LLMGatewayAPITests"
    ),
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
            .product(name: "Atomics", package: "swift-atomics"),
            "FountainStoreClient",
            .product(name: "FountainStore", package: "fountain-store")
        ],
        path: "libs/FountainRuntime",
        exclude: ["DNS/README.md"]
    ),
    .target(
        name: "LauncherSignature",
        path: "libs/LauncherSignature"
    ),
    .target(
        name: "FountainStoreClient",
        dependencies: [.product(name: "FountainStore", package: "fountain-store")],
        path: "libs/FountainStoreClient"
    ),
    .executableTarget(
        name: "semantic-browser-server",
        dependencies: [
            .product(name: "SemanticBrowser", package: "semantic-browser"),
            "LauncherSignature"
        ],
        path: "services/SemanticBrowserServer",
        exclude: ["README.md"]
    ),
    .executableTarget(
        name: "gateway-server",
        dependencies: [
            "FountainRuntime",
            "PublishingFrontend",
            "LLMGatewayPlugin",
            "AuthGatewayPlugin",
            "CuratorGatewayPlugin",
            "RateLimiterGatewayPlugin",
            "BudgetBreakerGatewayPlugin",
            "PayloadInspectionGatewayPlugin",
            "DestructiveGuardianGatewayPlugin",
            "RoleHealthCheckGatewayPlugin",
            "SecuritySentinelGatewayPlugin",
            "GatewayPersonaOrchestrator",
            "LauncherSignature",
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "X509", package: "swift-certificates"),
            "Yams"
        ],
        path: "services/GatewayServer",
        exclude: ["README.md"]
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
        name: "SecuritySentinelGatewayPlugin",
        dependencies: [
            "FountainRuntime",
            .product(name: "AsyncHTTPClient", package: "async-http-client"),
            .product(name: "NIOCore", package: "swift-nio"),
            .product(name: "Logging", package: "swift-log")
        ],
        path: "libs/GatewayPlugins/SecuritySentinelGatewayPlugin"
    ),
    .target(
        name: "CuratorGatewayPlugin",
        dependencies: ["FountainRuntime", "OpenAPICurator"],
        path: "libs/GatewayPlugins/CuratorGatewayPlugin"
    ),
    .target(
        name: "GatewayPersonaOrchestrator",
        dependencies: [
            "FountainRuntime",
            "SecuritySentinelGatewayPlugin",
            "DestructiveGuardianGatewayPlugin"
        ],
        path: "libs/GatewayPersonaOrchestrator"
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
            "FountainStoreClient",
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
        name: "DNSTests",
        dependencies: [
            "PublishingFrontend",
            "FountainRuntime",
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "NIOEmbedded", package: "swift-nio"),
            .product(name: "NIO", package: "swift-nio")
        ],
        path: "Tests/DNSTests"
    ),
    .testTarget(
        name: "DNSPerfTests",
        dependencies: ["FountainRuntime", .product(name: "NIOCore", package: "swift-nio")],
        path: "Tests/DNSPerfTests"
    ),
    .testTarget(
        name: "FountainCodexTests",
        dependencies: ["FountainCodex", .product(name: "NIOHTTP1", package: "swift-nio")],
        path: "Tests/FountainCodexTests"
    ),
    .testTarget(
        name: "FountainRuntimeTests",
        dependencies: ["FountainRuntime", "FountainStoreClient", .product(name: "NIOHTTP1", package: "swift-nio")],
        path: "Tests/FountainRuntimeTests"
    ),
    .testTarget(
        name: "GatewayPluginsTests",
        dependencies: [
            "RateLimiterGatewayPlugin",
            "AuthGatewayPlugin",
            "PayloadInspectionGatewayPlugin",
            "BudgetBreakerGatewayPlugin",
            "LLMGatewayPlugin",
            "RoleHealthCheckGatewayPlugin",
            "SecuritySentinelGatewayPlugin",
            "DestructiveGuardianGatewayPlugin",
            "CuratorGatewayPlugin",
            "FountainRuntime",
            .product(name: "Crypto", package: "swift-crypto")
        ],
        path: "Tests/GatewayPluginsTests"
    ),
    .testTarget(
        name: "GatewayPersonaOrchestratorTests",
        dependencies: [
            "GatewayPersonaOrchestrator",
            "FountainRuntime",
            "SecuritySentinelGatewayPlugin",
            "DestructiveGuardianGatewayPlugin"
        ],
        path: "Tests/GatewayPersonaOrchestratorTests"
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
        name: "SemanticBrowserTests",
        dependencies: [.product(name: "SemanticBrowser", package: "semantic-browser")],
        path: "Tests/SemanticBrowserTests"
    ),
    .testTarget(
        name: "ResourceLoaderTests",
        dependencies: ["ResourceLoader"],
        path: "Tests/ResourceLoaderTests",
        resources: [.process("Resources")]
    ),
    .testTarget(
        name: "TokenValidationTests",
        dependencies: ["gateway-server", .product(name: "Crypto", package: "swift-crypto")],
        path: "Tests/TokenValidationTests"
    ),
    .testTarget(
        name: "FountainStoreClientTests",
        dependencies: ["FountainStoreClient"],
        path: "Tests/FountainStoreClientTests"
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

#if os(macOS)
fullTargets.append(
    .executableTarget(
        name: "FountainLauncherUI",
        dependencies: [
            .product(name: "SecretStore", package: "swift-secretstore")
        ],
        path: "apps/FountainLauncherUI"
    )
)
#endif

// Minimal lean target set focused on API clients + tests to avoid linking heavy executables during local runs.
var uiLeanTargets: [Target] = [
    .target(name: "ApiClientsCore", dependencies: [], path: "libs/ApiClientsCore/Sources/ApiClientsCore"),
    .target(name: "GatewayAPI", dependencies: ["ApiClientsCore"], path: "libs/GatewayAPI/Sources/GatewayAPI"),
    .target(name: "PersistAPI", dependencies: ["ApiClientsCore"], path: "libs/PersistAPI/Sources/PersistAPI"),
    .target(name: "SemanticBrowserAPI", dependencies: ["ApiClientsCore"], path: "libs/SemanticBrowserAPI/Sources/SemanticBrowserAPI"),
    .target(name: "LLMGatewayAPI", dependencies: ["ApiClientsCore"], path: "libs/LLMGatewayAPI/Sources/LLMGatewayAPI"),
    .target(
        name: "TutorDashboard",
        dependencies: [
            "ApiClientsCore",
            .product(name: "Yams", package: "Yams")
        ],
        path: "libs/TutorDashboard/Sources"
    ),
    .executableTarget(
        name: "tutor-dashboard",
        dependencies: [
            "TutorDashboard",
            .product(name: "SwiftCursesKit", package: "swiftcurseskit")
        ],
        path: "apps/TutorDashboardApp"
    ),
    .target(name: "FountainAICore", dependencies: [], path: "libs/FountainAICore/Sources/FountainAICore"),
    .target(name: "FountainAIAdapters", dependencies: ["FountainAICore", "LLMGatewayAPI", "SemanticBrowserAPI", "PersistAPI"], path: "libs/FountainAIAdapters/Sources/FountainAIAdapters"),
    
    // Minimal server to host static GUI files
    .target(
        name: "PublishingFrontend",
        dependencies: ["FountainRuntime", "Yams"],
        path: "libs/PublishingFrontend/PublishingFrontend"
    ),
    .executableTarget(
        name: "publishing-frontend",
        dependencies: ["PublishingFrontend"],
        path: "tools/PublishingFrontendCLI/publishing-frontend"
    ),
    // Runtime needed by PublishingFrontend
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
            .product(name: "Atomics", package: "swift-atomics"),
            "FountainStoreClient",
            .product(name: "FountainStore", package: "fountain-store")
        ],
        path: "libs/FountainRuntime",
        exclude: ["DNS/README.md"]
    ),
    .target(
        name: "FountainStoreClient",
        dependencies: [.product(name: "FountainStore", package: "fountain-store")],
        path: "libs/FountainStoreClient"
    ),
    .testTarget(name: "ApiClientsCoreTests", dependencies: ["ApiClientsCore", "LLMGatewayAPI"], path: "Tests/ApiClientsCoreTests"),
    .testTarget(name: "GatewayAPITests2", dependencies: ["GatewayAPI", "ApiClientsCore"], path: "Tests/GatewayAPITests2"),
    .testTarget(name: "PersistAPITests", dependencies: ["PersistAPI", "ApiClientsCore"], path: "Tests/PersistAPITests"),
    .testTarget(name: "SemanticBrowserAPITests", dependencies: ["SemanticBrowserAPI", "ApiClientsCore"], path: "Tests/SemanticBrowserAPITests"),
    .testTarget(name: "FountainAICoreTests", dependencies: ["FountainAICore"], path: "Tests/FountainAICoreTests"),
    .testTarget(
        name: "SwiftCursesKitIntegrationTests",
        dependencies: [
            .product(name: "SwiftCursesKit", package: "swiftcurseskit")
        ],
        path: "Tests/SwiftCursesKitIntegrationTests"
    ),
    .testTarget(
        name: "TutorPathModule1Tests",
        dependencies: [
            "TutorDashboard",
            .product(name: "Yams", package: "Yams")
        ],
        path: "Tests/TutorPathModule1Tests"
    ),
]

#if os(macOS)
uiLeanTargets.append(contentsOf: [
    .executableTarget(
        name: "FountainLauncherUI",
        dependencies: [
            .product(name: "SecretStore", package: "swift-secretstore")
        ],
        path: "apps/FountainLauncherUI"
    ),
    .executableTarget(name: "gui-diagnostics", dependencies: ["ApiClientsCore", "GatewayAPI", "PersistAPI", "SemanticBrowserAPI", "LLMGatewayAPI"], path: "tools/GuiDiagnostics"),
    .executableTarget(name: "gui-seed", dependencies: ["ApiClientsCore", "PersistAPI"], path: "tools/GuiSeed"),
    .executableTarget(name: "gui-browse", dependencies: ["ApiClientsCore", "PersistAPI", "SemanticBrowserAPI"], path: "tools/GuiBrowse"),
    .executableTarget(name: "gui-capabilities", dependencies: ["ApiClientsCore", "PersistAPI"], path: "tools/GuiCapabilities")
])
#endif

var targets: [Target] = LEAN ? uiLeanTargets : fullTargets

let package = Package(
    name: "the-fountainai",
    platforms: [
        .macOS(.v14)
    ],
    products: products,
    dependencies: [
        .package(url: "https://github.com/Fountain-Coach/toolsmith.git", exact: "1.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.63.0"),
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/apple/swift-certificates.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/Fountain-Coach/midi2.git", from: "0.3.1"),
        .package(url: "https://github.com/Fountain-Coach/swiftcurseskit.git", exact: "0.2.0"),
        .package(url: "https://github.com/apple/swift-numerics.git", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-atomics.git", from: "1.3.0"),
        .package(url: "https://github.com/Fountain-Coach/Fountain-Store.git", from: "0.1.0"),
        .package(url: "https://github.com/Fountain-Coach/semantic-browser.git", exact: "0.0.2"),
        .package(url: "https://github.com/Fountain-Coach/Teatro.git", branch: "main"),
        .package(url: "https://github.com/Fountain-Coach/swift-secretstore.git", exact: "0.1.0"),
        .package(path: "libs/OpenAPICurator"),
    ],
    targets: targets
)

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
