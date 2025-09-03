import Foundation
import Dispatch
import FountainRuntime
import FountainStoreClient
import LauncherSignature

verifyLauncherSignature()

let svc = FountainStoreClient(client: MockFountainStoreClient())
Task {
    await svc.ensureCollections()
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
