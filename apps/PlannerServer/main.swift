import Foundation
import Dispatch
import FountainRuntime
import FountainStoreClient
import PlannerService
import LauncherSignature

verifyLauncherSignature()

let corpusId = ProcessInfo.processInfo.environment["DEFAULT_CORPUS_ID"] ?? "tools-factory"
let svc = FountainStoreClient(client: MockFountainStoreClient())
Task {
    await svc.ensureCollections(corpusId: corpusId)
    let kernel = makePlannerKernel(service: svc)
    let server = NIOHTTPServer(kernel: kernel)
    do {
        _ = try await server.start(port: 8083)
        print("planner server listening on port 8083")
    } catch {
        FileHandle.standardError.write(Data("[planner] Failed to start: \(error)\n".utf8))
    }
}
dispatchMain()

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
