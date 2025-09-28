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

    // Expose underlying client for type checking
    var underlyingClientType: FDCClient {
        underlyingClient
    }

    // MARK: - New API Methods (v1 Worker API)

    func getHealth() async throws -> FoodHealthResponse {
        try await underlyingClient.getHealth()
    }

    func searchFoods(query: String, limit: Int?) async throws -> FoodSearchResponse {
        try await underlyingClient.searchFoods(query: query, limit: limit)
    }

    func getFoodByBarcode(code: String) async throws -> FoodMinimalCard {
        try await underlyingClient.getFoodByBarcode(code: code)
    }

    func getFood(gid: String) async throws -> FoodMinimalCard {
        try await underlyingClient.getFood(gid: gid)
    }

    func getFoodDetails(gid: String) async throws -> FoodAuthoritativeDetail {
        try await underlyingClient.getFoodDetails(gid: gid)
    }

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        let result = try await searchFoodsWithPagination(matching: query, page: page, pageSize: 25)
        return result.foods
    }

    func searchFoodsWithPagination(matching query: String, page: Int, pageSize: Int) async throws -> FDCSearchResult {
        // Check cache first
        if let cachedResults = cacheService.cachedPaginatedSearchResults(
            for: query,
            page: page,
            pageSize: pageSize
        ) {
            return cachedResults
        }

        // Fetch from network
        let results = try await underlyingClient.searchFoodsWithPagination(
            matching: query,
            page: page,
            pageSize: pageSize
        )

        // Cache the results
        cacheService.cachePaginatedSearchResults(results, for: query, page: page, pageSize: pageSize)

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
