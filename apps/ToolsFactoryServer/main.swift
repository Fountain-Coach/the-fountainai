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

do {
    let svc = FountainStoreClient(client: EmbeddedFountainStoreClient())
    Task { await svc.ensureCollections(corpusId: corpusId); try? await publishFunctions(manifest: manifest, corpusId: corpusId, service: svc) }
    let kernel = makeToolsFactoryKernel(service: svc, adapters: adapters, manifest: manifest)
    let server = NIOHTTPServer(kernel: kernel)
    let port: Int = 8080
    _ = try await server.start(port: port)
    print("tools-factory (NIO) listening on :\(port)")
    dispatchMain()
} catch {
    print("Failed to start tools-factory: \(error)")
}

// © 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
