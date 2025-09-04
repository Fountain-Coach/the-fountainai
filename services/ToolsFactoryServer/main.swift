import Foundation
import FountainStoreClient
import ToolsFactoryService
import FountainRuntime
import LauncherSignature

verifyLauncherSignature()

let adapters: [String: ToolAdapter] = [
    "imagemagick": ImageMagickAdapter(),
    "ffmpeg": FFmpegAdapter(),
    "exiftool": ExifToolAdapter(),
    "pandoc": PandocAdapter(),
    "libplist": LibPlistAdapter(),
    "scan": PDFScanAdapter(),
    "index": PDFIndexAdapter(),
    "query": PDFQueryAdapter(),
    "export-matrix": PDFExportMatrixAdapter()
]
let manifestURL = URL(fileURLWithPath: "tools.json")
let manifest = (try? ToolManifest.load(from: manifestURL)) ?? ToolManifest(image: .init(name: "", tarball: "", sha256: "", qcow2: "", qcow2_sha256: ""), tools: [:], operations: [])
let corpusId = ProcessInfo.processInfo.environment["TOOLS_FACTORY_CORPUS_ID"] ??
               ProcessInfo.processInfo.environment["DEFAULT_CORPUS_ID"] ?? "tools-factory"

let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
Task {
    await svc.ensureCollections(corpusId: corpusId)
    try? await publishFunctions(manifest: manifest, corpusId: corpusId, service: svc)
    let kernel = makeToolsFactoryKernel(service: svc, adapters: adapters, manifest: manifest)
    let server = NIOHTTPServer(kernel: kernel)
    do {
        _ = try await server.start(port: 8080)
        print("tools-factory (NIO) listening on :8080")
    } catch {
        FileHandle.standardError.write(Data("[tools-factory] Failed to start: \(error)\n".utf8))
    }
}
dispatchMain()

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
