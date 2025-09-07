import Foundation

public enum HTTPMethod: String, Sendable {
    case GET, POST, PUT, PATCH, DELETE
}

public struct APIRequest: Sendable {
    public var method: HTTPMethod
    public var url: URL
    public var headers: [String: String]
    public var body: Data?

    public init(method: HTTPMethod, url: URL, headers: [String: String] = [:], body: Data? = nil) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
    }
}

public struct APIResponse: Sendable {
    public var status: Int
    public var headers: [AnyHashable: Any]
    public var data: Data
}

public enum APIError: Error, Equatable, Sendable {
    case invalidURL
    case httpStatus(Int, String)
    case decode(String)
}

public final class RESTClient: @unchecked Sendable {
    public let baseURL: URL
    public var defaultHeaders: [String: String]

    public init(baseURL: URL, defaultHeaders: [String: String] = [:]) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
    }

    public func send(_ request: APIRequest) async throws -> APIResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        let headers = defaultHeaders.merging(request.headers, uniquingKeysWith: { _, new in new })
        for (k, v) in headers { urlRequest.setValue(v, forHTTPHeaderField: k) }
        urlRequest.httpBody = request.body
        let (data, resp) = try await URLSession.shared.data(for: urlRequest)
        guard let http = resp as? HTTPURLResponse else {
            throw APIError.httpStatus(-1, "Non-HTTP response")
        }
        if !(200...299).contains(http.statusCode) {
            let text = String(data: data, encoding: .utf8) ?? ""
            throw APIError.httpStatus(http.statusCode, text)
        }
        return APIResponse(status: http.statusCode, headers: http.allHeaderFields, data: data)
    }

    public func buildURL(path: String, query: [String: String?] = [:]) -> URL? {
        var comps = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        let trimmed = path.hasPrefix("/") ? String(path.dropFirst()) : path
        comps?.path = baseURL.path.appending("/").appending(trimmed)
        if !query.isEmpty {
            comps?.queryItems = query.compactMap { (k, v) in
                if let v = v { return URLQueryItem(name: k, value: v) }
                return nil
            }
        }
        return comps?.url
    }
}

public struct EmptyBody: Codable, Sendable {}

