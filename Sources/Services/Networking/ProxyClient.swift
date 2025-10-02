//
//  ProxyClient.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - URLSession Protocol

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - Proxy Client Protocol

public protocol ProxyClient: Sendable {
    // MARK: - Health Check

    /// Get service health status
    func getHealth() async throws -> ProxyHealthResponse

    // MARK: - FDC Pass-throughs

    /// Search foods via FDC (GET /foods/search)
    func searchFoods(query: String, pageSize: Int?) async throws -> FdcSearchResponse

    /// Get food details by FDC ID (GET /food/:fdcId)
    func getFoodDetails(fdcId: Int) async throws -> Envelope<FdcFood>

    // MARK: - OFF Direct Product

    /// Get OFF product by barcode (GET /v1/off/product/:barcode)
    func getOFFProduct(barcode: String) async throws -> Envelope<OffReadResponse>

    // MARK: - GTIN/UPC Lookup

    /// Lookup food by barcode with FDC fallback to OFF (GET /v1/gtin/:barcode)
    func lookupByBarcode(barcode: String) async throws -> Envelope<OffReadResponse>

    // MARK: - Redirect Handling

    /// Handle redirect responses from barcode lookup
    func followRedirect(_ redirect: ProxyRedirect) async throws -> Envelope<OffReadResponse>
}

// MARK: - Proxy Client Implementation

public struct ProxyClientImpl: ProxyClient {
    let baseURL: URL
    let session: URLSessionProtocol
    let authHeader: String?
    let authValue: String?

    // Retry configuration
    private let maxRetries: Int
    private let baseDelay: TimeInterval

    // Response caching
    private let cache = ResponseCache()

    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.calry.org") else {
            fatalError("Failed to create default base URL")
        }
        return url
    }()

    public init(
        baseURL: URL? = nil,
        session: URLSessionProtocol? = nil,
        authHeader: String? = nil,
        authValue: String? = nil,
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0
    ) {
        self.baseURL = baseURL ?? Self.defaultBaseURL
        self.session = session ?? Self.createDefaultSession()
        self.authHeader = authHeader
        self.authValue = authValue
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
    }

    /// Creates a URLSession with configuration that avoids proxy issues
    private static func createDefaultSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        // Disable proxy to avoid PAC evaluation errors
        config.connectionProxyDictionary = [:]
        return URLSession(configuration: config)
    }

    // MARK: - Health Check

    public func getHealth() async throws -> ProxyHealthResponse {
        let url = baseURL.appendingPathComponent("v1/health")
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProxyError.invalidResponse
            }

            try throwIfNeeded(httpResponse: httpResponse, data: data)

            return try JSONDecoder().decode(ProxyHealthResponse.self, from: data)
        }
    }

    // MARK: - FDC Pass-throughs

    public func searchFoods(query: String, pageSize: Int? = nil) async throws -> FdcSearchResponse {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = baseURL.appendingPathComponent("foods/search").path

        var queryItems = [URLQueryItem(name: "query", value: query)]
        if let pageSize {
            queryItems.append(URLQueryItem(name: "pageSize", value: String(pageSize)))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw ProxyError.invalidURL
        }

        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProxyError.invalidResponse
            }

            try throwIfNeeded(httpResponse: httpResponse, data: data)

            return try JSONDecoder().decode(FdcSearchResponse.self, from: data)
        }
    }

    public func getFoodDetails(fdcId: Int) async throws -> Envelope<FdcFood> {
        let url = baseURL.appendingPathComponent("food/\(fdcId)")
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProxyError.invalidResponse
            }

            try throwIfNeeded(httpResponse: httpResponse, data: data)

            return try JSONDecoder().decode(Envelope<FdcFood>.self, from: data)
        }
    }

    // MARK: - OFF Direct Product

    public func getOFFProduct(barcode: String) async throws -> Envelope<OffReadResponse> {
        try await getOFFProductWithRedirectHandling(barcode: barcode, depth: 0)
    }

    // MARK: - GTIN/UPC Lookup

    public func lookupByBarcode(barcode: String) async throws -> Envelope<OffReadResponse> {
        // Check cache first
        let cacheKey = "barcode:\(barcode)"
        if let cachedResponse = cache.get(for: cacheKey) {
            return cachedResponse
        }

        let url = baseURL.appendingPathComponent("v1/gtin/\(barcode)")
        let request = buildRequest(for: url)

        let response = try await performRequestWithRetry {
            let (data, response): (Data, URLResponse)

            do {
                (data, response) = try await session.data(for: request)
            } catch let error as URLError {
                // Convert URLError to appropriate ProxyError
                switch error.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    throw ProxyError.networkError(error)
                case .timedOut:
                    throw ProxyError.networkError(error)
                case .cannotConnectToHost:
                    throw ProxyError.networkError(error)
                default:
                    throw ProxyError.networkError(error)
                }
            } catch {
                throw error
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProxyError.invalidResponse
            }

            try throwIfNeeded(httpResponse: httpResponse, data: data)

            // Check for redirect envelope (kv hint)
            if let redirectResponse = try? JSONDecoder().decode(ProxyRedirect.self, from: data),
               redirectResponse.isSuccessful, !redirectResponse.redirect.gid.isEmpty {
                return try await followRedirect(redirectResponse, depth: 0, visited: [])
            }

            // Try to decode as the new envelope format
            return try JSONDecoder().decode(Envelope<OffReadResponse>.self, from: data)
        }

        // Cache successful response
        cache.set(response, for: cacheKey)
        return response
    }

    // MARK: - Redirect Handling

    public func followRedirect(_ redirect: ProxyRedirect) async throws -> Envelope<OffReadResponse> {
        try await followRedirect(redirect, depth: 0, visited: [])
    }

    private func followRedirect(
        _ redirect: ProxyRedirect,
        depth: Int,
        visited: Set<String>
    ) async throws -> Envelope<OffReadResponse> {
        // Prevent infinite redirect loops
        guard depth < 5 else {
            throw ProxyError.invalidResponse
        }

        let gid = redirect.redirect.gid

        // Check for redirect loops
        if visited.contains(gid) {
            throw ProxyError.invalidResponse
        }

        var newVisited = visited
        newVisited.insert(gid)

        if gid.hasPrefix("fdc:") {
            let fdcIdString = String(gid.dropFirst(4)) // Remove "fdc:" prefix
            guard Int(fdcIdString) != nil else {
                throw ProxyError.invalidGID(gid)
            }
            // For FDC redirects, we need to return an FDC envelope, but the method signature expects OffReadResponse
            // This is a design issue - we should handle this differently
            throw ProxyError.invalidResponse // FDC redirects should be handled differently
        } else if gid.hasPrefix("off:") {
            let barcode = String(gid.dropFirst(4)) // Remove "off:" prefix
            if barcode.isEmpty {
                throw ProxyError.invalidGID(gid)
            }
            // Call the direct OFF product endpoint without redirect handling to avoid loops
            return try await getOFFProductDirect(barcode: barcode)
        } else {
            throw ProxyError.invalidGID(gid)
        }
    }

    private func getOFFProductDirect(barcode: String) async throws -> Envelope<OffReadResponse> {
        // Check cache first
        let cacheKey = "off:\(barcode)"
        if let cachedResponse = cache.get(for: cacheKey) {
            return cachedResponse
        }

        let url = baseURL.appendingPathComponent("v1/off/product/\(barcode)")
        let request = buildRequest(for: url)

        let response = try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProxyError.invalidResponse
            }

            try throwIfNeeded(httpResponse: httpResponse, data: data)

            // Check if this is a redirect response first
            if let redirectResponse = try? JSONDecoder().decode(ProxyRedirect.self, from: data),
               redirectResponse.isSuccessful, !redirectResponse.redirect.gid.isEmpty {
                // If we get a redirect in the direct call, it means the API is inconsistent
                throw ProxyError.invalidResponse
            }

            return try decodeOffResponse(from: data)
        }

        // Cache successful response
        cache.set(response, for: cacheKey)
        return response
    }

    private func decodeOffResponse(from data: Data) throws -> Envelope<OffReadResponse> {
        // Try to decode as envelope first
        do {
            return try JSONDecoder().decode(Envelope<OffReadResponse>.self, from: data)
        } catch {
            // If that fails, try to decode as a generic envelope and convert
            do {
                let genericEnvelope = try JSONDecoder().decode(Envelope<AnyCodable>.self, from: data)

                // Extract the raw data and create a proper OffReadResponse
                if let rawData = genericEnvelope.raw.value as? [String: Any],
                   let productData = rawData["product"] {
                    // Create OffReadResponse with status=1 (found) and the product data
                    let offReadResponse = try OffReadResponse(
                        status: 1,
                        code: rawData["code"] as? String,
                        product: JSONDecoder().decode(
                            OffProduct.self,
                            from: JSONSerialization.data(withJSONObject: productData)
                        )
                    )

                    // Create a new envelope with the proper OffReadResponse
                    return Envelope(
                        gid: genericEnvelope.gid,
                        source: genericEnvelope.source,
                        barcode: genericEnvelope.barcode,
                        fetchedAt: genericEnvelope.fetchedAt,
                        raw: offReadResponse
                    )
                } else {
                    throw ProxyError.invalidResponse
                }
            } catch {
                throw ProxyError.invalidResponse
            }
        }
    }

    private func getOFFProductWithRedirectHandling(
        barcode: String,
        depth: Int
    ) async throws -> Envelope<OffReadResponse> {
        let url = baseURL.appendingPathComponent("v1/off/product/\(barcode)")
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw ProxyError.invalidResponse
            }

            try throwIfNeeded(httpResponse: httpResponse, data: data)

            // Check for redirect envelope (kv hint)
            if let redirectResponse = try? JSONDecoder().decode(ProxyRedirect.self, from: data),
               redirectResponse.isSuccessful, !redirectResponse.redirect.gid.isEmpty {
                return try await followRedirect(redirectResponse, depth: depth, visited: [])
            }

            return try JSONDecoder().decode(Envelope<OffReadResponse>.self, from: data)
        }
    }

    // MARK: - Private Helpers

    /// Perform request with exponential backoff retry logic
    private func performRequestWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?

        for attempt in 0 ... maxRetries {
            do {
                return try await operation()
            } catch let error as ProxyError {
                lastError = error

                if shouldRetryProxyError(error, attempt: attempt) {
                    try await performRetryDelay(attempt: attempt)
                } else {
                    throw error
                }
            } catch let cancellationError as CancellationError {
                throw cancellationError
            } catch let urlError as URLError where urlError.code == .cancelled {
                throw urlError
            } catch {
                lastError = error

                if shouldRetryNonProxyError(error, attempt: attempt) {
                    try await performRetryDelay(attempt: attempt)
                } else {
                    throw mapNonProxyErrorToProxyError(error)
                }
            }
        }

        throw lastError ?? ProxyError.networkError(NSError(
            domain: "ProxyClient",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error"]
        ))
    }

    /// Determine if a ProxyError should be retried
    private func shouldRetryProxyError(_ error: ProxyError, attempt: Int) -> Bool {
        if attempt == maxRetries {
            return false
        }

        switch error {
        case .invalidURL, .invalidGID, .proxyError:
            return false
        case let .httpError(statusCode):
            return statusCode >= 500 || statusCode == 429
        case .networkError, .invalidResponse, .serverUnavailable:
            return true
        case .rateLimited:
            return false
        }
    }

    /// Determine if a non-ProxyError should be retried
    private func shouldRetryNonProxyError(_ error: Error, attempt: Int) -> Bool {
        if attempt == maxRetries {
            return false
        }

        switch error {
        case is DecodingError:
            return false
        case let urlError as URLError:
            switch urlError.code {
            case .badURL, .unsupportedURL, .cannotFindHost, .cannotConnectToHost:
                return false
            case .timedOut, .notConnectedToInternet, .networkConnectionLost:
                return true
            case .cancelled:
                return false
            default:
                return true
            }
        default:
            return attempt < 1
        }
    }

    /// Perform retry delay with exponential backoff
    private func performRetryDelay(attempt: Int) async throws {
        let delay = baseDelay * pow(2.0, Double(attempt))
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Map non-ProxyError to appropriate ProxyError types
    private func mapNonProxyErrorToProxyError(_ error: Error) -> ProxyError {
        switch error {
        case is DecodingError:
            .invalidResponse
        case let urlError as URLError:
            switch urlError.code {
            case .badURL, .unsupportedURL:
                .invalidURL
            case .cannotFindHost, .cannotConnectToHost:
                .serverUnavailable
            case .timedOut, .notConnectedToInternet, .networkConnectionLost:
                .networkError(urlError)
            case .cancelled:
                .networkError(urlError)
            default:
                .networkError(urlError)
            }
        default:
            .networkError(error)
        }
    }

    private func buildRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)

        // Add optional auth headers if configured
        if let authHeader, let authValue {
            request.setValue(authValue, forHTTPHeaderField: authHeader)
        }

        return request
    }

    private func throwIfNeeded(httpResponse: HTTPURLResponse, data: Data) throws {
        guard httpResponse.statusCode != 429 else {
            let retryAfter = parseRetryAfter(httpResponse)
            throw ProxyError.rateLimited(retryAfter)
        }

        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode >= 500 {
                throw ProxyError.serverUnavailable
            }

            if let errorResponse = try? JSONDecoder().decode(ProxyApiError.self, from: data) {
                throw ProxyError.proxyError(errorResponse)
            }

            throw ProxyError.httpError(httpResponse.statusCode)
        }
    }

    private func parseRetryAfter(_ response: HTTPURLResponse) -> TimeInterval? {
        guard let value = response.value(forHTTPHeaderField: "Retry-After") ??
            response.value(forHTTPHeaderField: "retry-after")
        else { return nil }

        if let seconds = TimeInterval(value) {
            return seconds
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss zzz"
        if let date = formatter.date(from: value) {
            return date.timeIntervalSinceNow
        }

        return nil
    }

    /// Clear the response cache (useful for testing or memory management)
    public func clearCache() {
        cache.clear()
    }
}

// MARK: - Error Types

public enum ProxyError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)
    case serverUnavailable
    case rateLimited(TimeInterval?)
    case invalidGID(String)
    case proxyError(ProxyApiError)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL for food database request."
        case .invalidResponse:
            "Received invalid data from food database. Please try again."
        case let .httpError(code):
            switch code {
            case 400:
                "Invalid request. Please check your input."
            case 401:
                "Authentication failed. Please check your API key."
            case 403:
                "Access denied. Please try again later."
            case 404:
                "Food not found. Please try a different search."
            case 429:
                "Too many requests. Please wait a moment and try again."
            case 500 ... 599:
                "Food database is temporarily unavailable. Please try again later."
            default:
                "Server error (\(code)). Please try again later."
            }
        case let .networkError(error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    "No internet connection. Please check your network settings."
                case .timedOut:
                    "Request timed out. Please check your connection and try again."
                case .cannotConnectToHost:
                    "Cannot connect to food database. Please try again later."
                default:
                    "Network error: \(urlError.localizedDescription)"
                }
            } else {
                "Network error: \(error.localizedDescription)"
            }
        case .serverUnavailable:
            "Food database is temporarily unavailable. Please try again later."
        case let .rateLimited(retryAfter):
            if let retryAfter {
                "Too many requests. Please wait \(Int(retryAfter)) seconds and try again."
            } else {
                "Too many requests. Please wait a moment and try again."
            }
        case let .invalidGID(gid):
            "Invalid food identifier: \(gid)"
        case let .proxyError(errorResponse):
            if errorResponse.error == "NOT_FOUND" {
                "Product not found in database. Please try a different barcode or search manually."
            } else {
                "Proxy error: \(errorResponse.error)"
            }
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidURL, .invalidResponse, .invalidGID:
            "Please try again or contact support if the problem persists."
        case let .httpError(code):
            switch code {
            case 400:
                "Try using different search terms or check your input."
            case 401, 403:
                "Please check your API configuration."
            case 404:
                "Try searching for a different food item."
            case 429:
                "Wait a few seconds before trying again."
            case 500 ... 599:
                "The service should be back online shortly."
            default:
                "Please try again later."
            }
        case let .networkError(error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    "Check your Wi-Fi or cellular connection."
                case .timedOut:
                    "Try again with a better connection."
                case .cannotConnectToHost:
                    "The service may be temporarily down."
                default:
                    "Check your internet connection and try again."
                }
            } else {
                "Check your internet connection and try again."
            }
        case .serverUnavailable:
            "Please try again in a few minutes."
        case .rateLimited:
            "Reduce the frequency of your requests or wait before trying again."
        case let .proxyError(errorResponse):
            if errorResponse.error == "NOT_FOUND" {
                "Try scanning a different product or search for this item manually."
            } else {
                "Please try again or contact support if the problem persists."
            }
        }
    }
}

// MARK: - Response Cache

private final class ResponseCache: Sendable {
    private var cache: [String: Data] = [:]
    private let lock = NSLock()

    func get(for key: String) -> Envelope<OffReadResponse>? {
        lock.lock()
        defer { lock.unlock() }
        guard let data = cache[key] else { return nil }
        return try? JSONDecoder().decode(Envelope<OffReadResponse>.self, from: data)
    }

    func set(_ response: Envelope<OffReadResponse>, for key: String) {
        guard let data = try? JSONEncoder().encode(response) else { return }
        lock.lock()
        defer { lock.unlock() }
        cache[key] = data
    }

    func clear() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAll()
    }
}
