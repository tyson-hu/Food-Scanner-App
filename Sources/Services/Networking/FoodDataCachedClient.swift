//
//  FoodDataCachedClient.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Cached food data client

struct FoodDataCachedClient: FoodDataClient {
    private let underlyingClient: FoodDataClient
    let cacheService: FDCCacheService

    init(underlyingClient: FoodDataClient, cacheService: FDCCacheService) {
        self.underlyingClient = underlyingClient
        self.cacheService = cacheService
    }

    // Expose underlying client for type checking
    var underlyingClientType: FoodDataClient {
        underlyingClient
    }

    // MARK: - New API Methods (v1 Worker API)

    func getHealth() async throws -> FoodHealthResponse {
        try await underlyingClient.getHealth()
    }

    func searchFoods(query: String, limit: Int?) async throws -> FoodSearchResponse {
        try await underlyingClient.searchFoods(query: query, limit: limit)
    }

    func getFoodByBarcode(code: String) async throws -> FoodCard {
        try await underlyingClient.getFoodByBarcode(code: code)
    }

    func getFood(gid: String) async throws -> FoodCard {
        try await underlyingClient.getFood(gid: gid)
    }

    func getFoodDetails(gid: String) async throws -> FoodDetails {
        try await underlyingClient.getFoodDetails(gid: gid)
    }

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        let result = try await searchFoodsWithPagination(matching: query, page: page, pageSize: 25)
        return result.foods
    }

    func searchFoodsWithPagination(
        matching query: String,
        page: Int,
        pageSize: Int
    ) async throws -> FoodDataSearchResult {
        // Check cache first
        let cachedResults = await MainActor.run {
            cacheService.cachedPaginatedSearchResults(
                for: query,
                page: page,
                pageSize: pageSize
            )
        }
        if let cachedResults {
            return cachedResults
        }

        // Fetch from network
        let results = try await underlyingClient.searchFoodsWithPagination(
            matching: query,
            page: page,
            pageSize: pageSize
        )

        // Cache the results
        await MainActor.run {
            cacheService.cachePaginatedSearchResults(results, for: query, page: page, pageSize: pageSize)
        }

        return results
    }

    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        // Check cache first
        let cachedResponse = await MainActor.run {
            cacheService.cachedFoodDetails(for: fdcId)
        }
        if let cachedResponse {
            return cachedResponse.toFDCFoodDetails()
        }

        // Fetch from network
        let response = try await underlyingClient.fetchFoodDetailResponse(fdcId: fdcId)

        // Cache the response
        await MainActor.run {
            cacheService.cacheFoodDetails(response, for: fdcId)
        }

        return response.toFDCFoodDetails()
    }

    func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse {
        // Check cache first
        let cachedResponse = await MainActor.run {
            cacheService.cachedFoodDetails(for: fdcId)
        }
        if let cachedResponse {
            return cachedResponse
        }

        // Fetch from network
        let response = try await underlyingClient.fetchFoodDetailResponse(fdcId: fdcId)

        // Cache the response
        await MainActor.run {
            cacheService.cacheFoodDetails(response, for: fdcId)
        }

        return response
    }
}
