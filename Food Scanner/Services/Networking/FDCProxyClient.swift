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
        session: URLSessionProtocol = URLSession.shared,
        authHeader: String? = nil,
        authValue: String? = nil,
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0
    ) {
        self.baseURL = baseURL ?? Self.defaultBaseURL
        self.session = session
        self.authHeader = authHeader
        self.authValue = authValue
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
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
            resolvingAgainstBaseURL: false
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

            return try JSONDecoder().decode(FoodMinimalCard.self, from: data)
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

            return try JSONDecoder().decode(FoodMinimalCard.self, from: data)
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
                pageSize: pageSize
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
                if attempt == maxRetries {
                    throw FDCError.networkError(error)
                }
                try await performRetryDelay(attempt: attempt)
            }
        }

        throw lastError ?? FDCError.networkError(NSError(
            domain: "FDCProxyClient",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Unknown error"]
        ))
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

    private func buildSearchURL(query: String, page: Int, pageSize: Int = 25) throws -> URL {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("/foods/search"),
            resolvingAgainstBaseURL: false
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
}
