//
//  FDCProxyClient.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/25/25.
//

import Foundation

struct FDCProxyClient: FDCClient {
    let baseURL: URL
    let session: URLSession
    let authHeader: String?
    let authValue: String?

    private static let defaultBaseURL: URL = {
        guard let url = URL(string: "https://api.calry.org") else {
            fatalError("Failed to create default base URL")
        }
        return url
    }()

    init(
        baseURL: URL? = nil,
        session: URLSession = .shared,
        authHeader: String? = nil,
        authValue: String? = nil
    ) {
        self.baseURL = baseURL ?? Self.defaultBaseURL
        self.session = session
        self.authHeader = authHeader
        self.authValue = authValue
    }

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count >= 2 else { return [] }

        let url = try buildSearchURL(query: trimmed, page: page)
        let request = buildRequest(for: url)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FDCError.httpError(httpResponse.statusCode)
            }

            let proxyResponse = try JSONDecoder().decode(ProxySearchResponse.self, from: data)
            return proxyResponse.foods.map { $0.toFDCFoodSummary() }

        } catch let fdcError as FDCError {
            throw fdcError
        } catch let cancellationError as CancellationError {
            throw cancellationError
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let networkError {
            throw FDCError.networkError(networkError)
        }
    }

    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        let url = try buildFoodDetailsURL(fdcId: fdcId)
        let request = buildRequest(for: url)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FDCError.httpError(httpResponse.statusCode)
            }

            let foodDetailResponse = try JSONDecoder().decode(ProxyFoodDetailResponse.self, from: data)
            return foodDetailResponse.toFDCFoodDetails()

        } catch let fdcError as FDCError {
            throw fdcError
        } catch let cancellationError as CancellationError {
            throw cancellationError
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let networkError {
            throw FDCError.networkError(networkError)
        }
    }

    func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse {
        let url = try buildFoodDetailsURL(fdcId: fdcId)
        let request = buildRequest(for: url)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FDCError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw FDCError.httpError(httpResponse.statusCode)
            }

            let foodDetailResponse = try JSONDecoder().decode(ProxyFoodDetailResponse.self, from: data)
            return foodDetailResponse

        } catch let fdcError as FDCError {
            throw fdcError
        } catch let cancellationError as CancellationError {
            throw cancellationError
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw urlError
        } catch let networkError {
            throw FDCError.networkError(networkError)
        }
    }

    // MARK: - Private Helpers

    private func buildSearchURL(query: String, page: Int) throws -> URL {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent("/foods/search"),
            resolvingAgainstBaseURL: false
        ) else {
            throw FDCError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "dataType", value: "Branded"),
            URLQueryItem(name: "pageSize", value: "25"),
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
