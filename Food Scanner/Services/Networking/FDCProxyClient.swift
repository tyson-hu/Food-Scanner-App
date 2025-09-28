//
//  FDCProxyClient.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/25/25.
//

import Foundation

// MARK: - URLSession Protocol

protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

// MARK: - FDCProxyClient

struct FDCProxyClient: FDCClient {
    let baseURL: URL
    let session: URLSessionProtocol
    let authHeader: String?
    let authValue: String?

    // Retry configuration
    private let maxRetries: Int
    private let baseDelay: TimeInterval

    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.calry.org/v1") else {
            fatalError("Failed to create default base URL")
        }
        return url
    }()

    init(
        baseURL: URL? = nil,
        session: URLSessionProtocol? = nil,
        authHeader: String? = nil,
        authValue: String? = nil,
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
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

    // MARK: - New API Methods (v1 Worker API)

    func getHealth() async throws -> FoodHealthResponse {
        let url = baseURL.appendingPathComponent("/health")
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FDCError.httpError(httpResponse.statusCode)
            }

            return try JSONDecoder().decode(FoodHealthResponse.self, from: data)
        }
    }

    func searchFoods(query: String, limit: Int? = nil) async throws -> FoodSearchResponse {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("/search"),
            resolvingAgainstBaseURL: false,
        ) else {
            throw FDCError.invalidURL
        }

        var queryItems = [URLQueryItem(name: "q", value: query)]
        if let limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            throw FDCError.invalidURL
        }

        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FDCError.httpError(httpResponse.statusCode)
            }

            return try JSONDecoder().decode(FoodSearchResponse.self, from: data)
        }
    }

    func getFoodByBarcode(code: String) async throws -> FoodMinimalCard {
        let url = baseURL.appendingPathComponent("/barcode/\(code)")
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw FDCError.noResults
                }
                throw FDCError.httpError(httpResponse.statusCode)
            }

            // Debug: Log raw response for barcode lookups
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Barcode Raw Response for \(code):")
                print(jsonString)
            }

            do {
                return try JSONDecoder().decode(FoodMinimalCard.self, from: data)
            } catch {
                // Debug: Log decoding error for barcode data
                print("❌ Barcode Decoding Error for \(code): \(error)")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(jsonString)")
                }
                throw error
            }
        }
    }

    func getFood(gid: String) async throws -> FoodMinimalCard {
        let url = baseURL.appendingPathComponent("/food/\(gid)")
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw FDCError.noResults
                }
                throw FDCError.httpError(httpResponse.statusCode)
            }

            logDSLDResponseIfNeeded(gid: gid, data: data)

            do {
                let foodCard = try JSONDecoder().decode(FoodMinimalCard.self, from: data)
                validateDSLDDataIfNeeded(gid: gid, foodCard: foodCard)
                return foodCard
            } catch {
                logDSLDDecodingErrorIfNeeded(gid: gid, error: error, data: data)
                throw error
            }
        }
    }

    func getFoodDetails(gid: String) async throws -> FoodAuthoritativeDetail {
        let url = baseURL.appendingPathComponent("/foodDetails/\(gid)")
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    throw FDCError.noResults
                }
                throw FDCError.httpError(httpResponse.statusCode)
            }

            return try JSONDecoder().decode(FoodAuthoritativeDetail.self, from: data)
        }
    }

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        let result = try await searchFoodsWithPagination(matching: query, page: page, pageSize: 25)
        return result.foods
    }

    func searchFoodsWithPagination(matching query: String, page: Int, pageSize: Int) async throws -> FDCSearchResult {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count >= 2 else {
            return FDCSearchResult(foods: [], totalHits: 0, currentPage: page, totalPages: 0, pageSize: pageSize)
        }

        let url = try buildSearchURL(query: trimmed, page: page, pageSize: pageSize)
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FDCError.httpError(httpResponse.statusCode)
            }

            let proxyResponse = try JSONDecoder().decode(ProxySearchResponse.self, from: data)
            let results = proxyResponse.foods.map { $0.toFDCFoodSummary() }

            return FDCSearchResult(
                foods: results,
                totalHits: proxyResponse.totalHits,
                currentPage: proxyResponse.currentPage,
                totalPages: proxyResponse.totalPages,
                pageSize: pageSize,
            )
        }
    }

    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        let response = try await fetchFoodDetailResponse(fdcId: fdcId)
        return response.toFDCFoodDetails()
    }

    func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse {
        let url = try buildFoodDetailsURL(fdcId: fdcId)
        let request = buildRequest(for: url)

        return try await performRequestWithRetry {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FDCError.httpError(httpResponse.statusCode)
            }

            return try JSONDecoder().decode(ProxyFoodDetailResponse.self, from: data)
        }
    }

    // MARK: - Private Helpers

    /// Perform request with exponential backoff retry logic
    private func performRequestWithRetry<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?

        for attempt in 0 ... maxRetries {
            do {
                return try await operation()
            } catch let error as FDCError {
                lastError = error

                if shouldRetryFDCError(error, attempt: attempt) {
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

                // Classify non-FDC errors before retrying
                if shouldRetryNonFDCError(error, attempt: attempt) {
                    try await performRetryDelay(attempt: attempt)
                } else {
                    // Map deterministic failures to appropriate FDCError types
                    throw mapNonFDCErrorToFDCError(error)
                }
            }
        }

        throw lastError ?? FDCError.networkError(NSError(
            domain: "FDCProxyClient",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error"],
        ))
    }

    /// Check if network is available before making requests
    private func isNetworkAvailable() -> Bool {
        // Simple check - in a real app you might want to use Network framework
        true // For now, let the URLSession handle connectivity
    }

    /// Determine if an FDCError should be retried
    private func shouldRetryFDCError(_ error: FDCError, attempt: Int) -> Bool {
        // If this was the last attempt, don't retry
        if attempt == maxRetries {
            return false
        }

        switch error {
        case .invalidURL, .noResults, .decodingError:
            return false
        case let .httpError(statusCode):
            // Don't retry client errors (4xx) except 429 (rate limit)
            return statusCode >= 500 || statusCode == 429
        case .networkError, .invalidResponse, .serverUnavailable:
            return true
        case .rateLimited:
            return true
        }
    }

    /// Perform retry delay with exponential backoff
    private func performRetryDelay(attempt: Int) async throws {
        let delay = baseDelay * pow(2.0, Double(attempt))
        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }

    /// Determine if a non-FDC error should be retried
    private func shouldRetryNonFDCError(_ error: Error, attempt: Int) -> Bool {
        // If this was the last attempt, don't retry
        if attempt == maxRetries {
            return false
        }

        // Don't retry deterministic failures that won't succeed on retry
        switch error {
        case is DecodingError:
            // Decoding errors are deterministic - malformed JSON won't become valid
            return false
        case let urlError as URLError:
            // Don't retry client-side errors that won't succeed on retry
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
            // For unknown errors, be conservative and retry once
            return attempt < 1
        }
    }

    /// Map non-FDC errors to appropriate FDCError types
    private func mapNonFDCErrorToFDCError(_ error: Error) -> FDCError {
        switch error {
        case let decodingError as DecodingError:
            .decodingError(decodingError)
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

    private func buildSearchURL(query: String, page: Int, pageSize: Int = 25) throws -> URL {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("/foods/search"),
            resolvingAgainstBaseURL: false,
        ) else {
            throw FDCError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "dataType", value: "Branded"),
            URLQueryItem(name: "pageSize", value: String(pageSize)),
            URLQueryItem(name: "pageNumber", value: String(page)),
        ]

        guard let url = components.url else {
            throw FDCError.invalidURL
        }

        return url
    }

    private func buildFoodDetailsURL(fdcId: Int) throws -> URL {
        let url = baseURL.appendingPathComponent("/food/\(fdcId)")
        return url
    }

    private func buildRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)

        // Add optional auth headers if configured
        if let authHeader, let authValue {
            request.setValue(authValue, forHTTPHeaderField: authHeader)
        }

        return request
    }

    // MARK: - DSLD Debugging Helpers

    private func logDSLDResponseIfNeeded(gid: String, data: Data) {
        guard gid.hasPrefix("dsld:") else { return }
        if let jsonString = String(data: data, encoding: .utf8) {
            print("🔍 DSLD Raw Response for \(gid):")
            print(jsonString)
        }
    }

    private func validateDSLDDataIfNeeded(gid: String, foodCard: FoodMinimalCard) {
        guard gid.hasPrefix("dsld:") else { return }

        if foodCard.description == nil, foodCard.brand == nil, foodCard.nutrients.isEmpty {
            print("⚠️ DSLD Warning: Received empty data for \(gid)")
            print("   This might indicate the DSLD ID is invalid or the proxy service has an issue")

            if gid == "dsld:undefined" {
                print("   Error: DSLD ID is 'undefined' - this suggests a problem with ID generation or passing")
            }
        }
    }

    private func logDSLDDecodingErrorIfNeeded(gid: String, error: Error, data: Data) {
        guard gid.hasPrefix("dsld:") else { return }
        print("❌ DSLD Decoding Error for \(gid): \(error)")
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON: \(jsonString)")
        }
    }
}
