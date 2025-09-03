import Foundation
import FountainStoreClient
import AwarenessService
import FountainRuntime
import LauncherSignature

verifyLauncherSignature()

let corpusId = ProcessInfo.processInfo.environment["DEFAULT_CORPUS_ID"] ?? "tools-factory"
let storePath = ProcessInfo.processInfo.environment["FOUNTAIN_STORE_PATH"] ?? "./data/fountain-store"
do {
    try FileManager.default.createDirectory(atPath: storePath, withIntermediateDirectories: true)
} catch {
    FileHandle.standardError.write(Data("[baseline-awareness] Failed to create store directory: \(error)\n".utf8))
}
let svc = FountainStoreClient(client: EmbeddedFountainStoreClient(path: storePath))
Task {
    await svc.ensureCollections(corpusId: corpusId)
    let server = NIOHTTPServer(kernel: makeAwarenessKernel(service: svc))
    do {
        _ = try await server.start(port: 8081)
        print("baseline-awareness (NIO) listening on :8081")
    } catch {
        FileHandle.standardError.write(Data("[baseline-awareness] Failed to start: \(error)\n".utf8))
    }
}
dispatchMain()

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
