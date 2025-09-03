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
let defaultCorpus = ProcessInfo.processInfo.environment["TOOLS_FACTORY_CORPUS_ID"] ?? "tools-factory"

do {
    let svc = FountainStoreClient(client: MockFountainStoreClient())
    Task { await svc.ensureCollections(); try? await publishFunctions(manifest: manifest, corpusId: defaultCorpus, service: svc) }
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
