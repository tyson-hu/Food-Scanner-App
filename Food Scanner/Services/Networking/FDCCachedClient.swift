//
//  FDCCachedClient.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/25/25.
//

import Foundation

// MARK: - Cached FDC Client

struct FDCCachedClient: FDCClient {
    private let underlyingClient: FDCClient
    private let cacheService: FDCCacheService

    init(underlyingClient: FDCClient, cacheService: FDCCacheService) {
        self.underlyingClient = underlyingClient
        self.cacheService = cacheService
    }

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        // For now, only cache page 1 results to avoid complexity
        guard page == 1 else {
            return try await underlyingClient.searchFoods(matching: query, page: page)
        }

        // Check cache first
        if let cachedResults = cacheService.cachedSearchResults(for: query) {
            return cachedResults
        }

        // Fetch from network
        let results = try await underlyingClient.searchFoods(matching: query, page: page)

        // Cache the results
        cacheService.cacheSearchResults(results, for: query)

        return results
    }

    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        // Check cache first
        if let cachedResponse = cacheService.cachedFoodDetails(for: fdcId) {
            return cachedResponse.toFDCFoodDetails()
        }

        // Fetch from network
        let response = try await underlyingClient.fetchFoodDetailResponse(fdcId: fdcId)

        // Cache the response
        cacheService.cacheFoodDetails(response, for: fdcId)

        return response.toFDCFoodDetails()
    }

    func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse {
        // Check cache first
        if let cachedResponse = cacheService.cachedFoodDetails(for: fdcId) {
            return cachedResponse
        }

        // Fetch from network
        let response = try await underlyingClient.fetchFoodDetailResponse(fdcId: fdcId)

        // Cache the response
        cacheService.cacheFoodDetails(response, for: fdcId)

        return response
    }
}
