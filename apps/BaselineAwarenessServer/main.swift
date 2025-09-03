import Foundation
import FountainStoreClient
import AwarenessService
import FountainRuntime
import LauncherSignature

verifyLauncherSignature()

// Awareness server using the shared NIOHTTPServer for consistent HTTP handling
do {
    let svc = FountainStoreClient(client: MockFountainStoreClient())
    Task { await svc.ensureCollections() }
    let server = NIOHTTPServer(kernel: makeAwarenessKernel(service: svc))
    let port: Int = 8081
    _ = try await server.start(port: port)
    print("baseline-awareness (NIO) listening on :\(port)")
    dispatchMain()
} catch {
    print("Failed to start baseline-awareness: \(error)")
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
