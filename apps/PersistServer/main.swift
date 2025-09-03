import Foundation
import Dispatch
import FountainRuntime
import FountainStoreClient
import LauncherSignature

verifyLauncherSignature()

let corpusId = ProcessInfo.processInfo.environment["DEFAULT_CORPUS_ID"] ?? "tools-factory"
let storePath = ProcessInfo.processInfo.environment["FOUNTAIN_STORE_PATH"] ?? "./data/fountain-store"
do {
    try FileManager.default.createDirectory(atPath: storePath, withIntermediateDirectories: true)
} catch {
    FileHandle.standardError.write(Data("[persist] Failed to create store directory: \(error)\n".utf8))
}
let svc = FountainStoreClient(client: EmbeddedFountainStoreClient(path: storePath))
Task {
    await svc.ensureCollections(corpusId: corpusId)
    let kernel = makePersistKernel(service: svc)
    let server = NIOHTTPServer(kernel: kernel)
    do {
        _ = try await server.start(port: 8005)
        print("persist server listening on port 8005")
    } catch {
        FileHandle.standardError.write(Data("[persist] Failed to start: \(error)\n".utf8))
    }
}
dispatchMain()

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
