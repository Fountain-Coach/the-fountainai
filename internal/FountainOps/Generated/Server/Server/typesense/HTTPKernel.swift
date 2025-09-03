import Foundation

public struct HTTPKernel {
    let router: Router
    let proxyKey: String?

    public init(handlers: Handlers = Handlers(),
                proxyKey: String? = ProcessInfo.processInfo.environment["FOUNTAINSTORE_PROXY_KEY"]) {
        self.router = Router(handlers: handlers)
        self.proxyKey = proxyKey
    }

    public func handle(_ request: HTTPRequest) async throws -> HTTPResponse {
        if let key = proxyKey {
            if request.headers["X-API-Key"] != key {
                return HTTPResponse(status: 401)
            }
        }
        return try await router.route(request)
    }
}

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
