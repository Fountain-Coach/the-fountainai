import Foundation
import FountainStoreClient
import BootstrapService
import FountainRuntime
import LauncherSignature

verifyLauncherSignature()

let corpusId = ProcessInfo.processInfo.environment["DEFAULT_CORPUS_ID"] ?? "tools-factory"
let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
Task {
    await svc.ensureCollections(corpusId: corpusId)
    let server = NIOHTTPServer(kernel: makeBootstrapKernel(service: svc))
    do {
        _ = try await server.start(port: 8082)
        print("bootstrap (NIO) listening on :8082")
    } catch {
        FileHandle.standardError.write(Data("[bootstrap] Failed to start: \(error)\n".utf8))
    }
}
dispatchMain()

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
