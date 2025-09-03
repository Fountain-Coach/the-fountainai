import Foundation
import FountainStoreClient
import BootstrapService
import FountainRuntime
import LauncherSignature

verifyLauncherSignature()

// Bootstrap server using the shared NIOHTTPServer for consistent HTTP handling
do {
    let corpusId = ProcessInfo.processInfo.environment["DEFAULT_CORPUS_ID"] ?? "tools-factory"
    let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
    Task { await svc.ensureCollections(corpusId: corpusId) }
    let server = NIOHTTPServer(kernel: makeBootstrapKernel(service: svc))
    let port: Int = 8082
    _ = try await server.start(port: port)
    print("bootstrap (NIO) listening on :\(port)")
    dispatchMain()
} catch {
    print("Failed to start bootstrap: \(error)")
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
