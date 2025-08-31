import Foundation
import TypesensePersistence
import BootstrapService
import FountainRuntime
import LauncherSignature

verifyLauncherSignature()

// Bootstrap server using the shared NIOHTTPServer for consistent HTTP handling
do {
    let svc: TypesensePersistenceService
    if let url = ProcessInfo.processInfo.environment["TYPESENSE_URL"] ?? ProcessInfo.processInfo.environment["TYPESENSE_URLS"],
       let apiKey = ProcessInfo.processInfo.environment["TYPESENSE_API_KEY"], !apiKey.isEmpty {
        let urls = url.contains(",") ? url.split(separator: ",").map(String.init) : [url]
        #if canImport(Typesense)
        let client = RealTypesenseClient(nodes: urls, apiKey: apiKey, debug: false)
        svc = TypesensePersistenceService(client: client)
        #else
        svc = TypesensePersistenceService(client: MockTypesenseClient())
        #endif
    } else {
        svc = TypesensePersistenceService(client: MockTypesenseClient())
    }
    Task { await svc.ensureCollections() }
    let server = NIOHTTPServer(kernel: makeBootstrapKernel(service: svc))
    let port: Int = 8082
    _ = try await server.start(port: port)
    print("bootstrap (NIO) listening on :\(port)")
    dispatchMain()
} catch {
    print("Failed to start bootstrap: \(error)")
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
