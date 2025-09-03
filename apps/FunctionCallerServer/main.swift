import Foundation
import Dispatch
import FountainRuntime
import FountainStoreClient
import FunctionCallerService
import LauncherSignature

verifyLauncherSignature()

let svc = FountainStoreClient(client: MockFountainStoreClient())
Task {
    await svc.ensureCollections()
    let kernel = makeFunctionCallerKernel(service: svc)
    let server = NIOHTTPServer(kernel: kernel)
    do {
        _ = try await server.start(port: 8084)
        print("function-caller server listening on port 8084")
    } catch {
        FileHandle.standardError.write(Data("[function-caller] Failed to start: \(error)\n".utf8))
    }
}
dispatchMain()

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
