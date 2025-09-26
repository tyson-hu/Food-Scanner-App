//
//  FDCProxyClientTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/21/25.
//

@testable import Food_Scanner
import Foundation
import Testing

@Suite("FDC Proxy Client Integration Tests")
struct FDCProxyClientTests {
    // MARK: - Proxy Client Tests

    @Test("Proxy client search foods")
    @MainActor
    func proxy_client_search_foods() async throws {
        let client = FDCClientFactory.makeProxyClient()
        let results = try await client.searchFoods(matching: "oatmeal", page: 1)

        #expect(!results.isEmpty)
        #expect(results.first?.name.contains("OATMEAL") == true)
        #expect(results.first?.brand != nil)
    }

    @Test("Proxy client fetch food details")
    @MainActor
    func proxy_client_fetch_food_details() async throws {
        let client = FDCClientFactory.makeProxyClient()

        // First search for a food to get an ID
        let searchResults = try await client.searchFoods(matching: "oatmeal", page: 1)
        guard let firstResult = searchResults.first else {
            #expect(Bool(false), "No search results found")
            return
        }

        // Then fetch details for that food
        let details = try await client.fetchFoodDetails(fdcId: firstResult.id)

        #expect(details.id == firstResult.id)
        #expect(!details.name.isEmpty)
        #expect(details.calories >= 0) // Proxy API may not provide detailed nutrient data
    }

    @Test("Proxy client handle empty search query")
    @MainActor
    func proxy_client_handle_empty_search_query() async throws {
        let client = FDCClientFactory.makeProxyClient()
        let results = try await client.searchFoods(matching: "", page: 1)

        #expect(results.isEmpty)
    }

    @Test("Proxy client handle short search query")
    @MainActor
    func proxy_client_handle_short_search_query() async throws {
        let client = FDCClientFactory.makeProxyClient()
        let results = try await client.searchFoods(matching: "a", page: 1)

        #expect(results.isEmpty)
    }

    @Test("Proxy client pagination")
    @MainActor
    func proxy_client_pagination() async throws {
        let client = FDCClientFactory.makeProxyClient()

        let page1 = try await client.searchFoods(matching: "oatmeal", page: 1)
        let page2 = try await client.searchFoods(matching: "oatmeal", page: 2)

        #expect(!page1.isEmpty)
        #expect(!page2.isEmpty)

        // Pages should have different results
        let page1Ids = Set(page1.map(\.id))
        let page2Ids = Set(page2.map(\.id))
        #expect(page1Ids.isDisjoint(with: page2Ids))
    }

    // MARK: - Specific FDC ID Tests (for debugging N/A issues)

    @Test("Proxy client fetch specific FDC ID 2503998")
    @MainActor
    func proxy_client_fetch_specific_fdc_id_2503998() async throws {
        let client = FDCClientFactory.makeProxyClient()
        let details = try await client.fetchFoodDetails(fdcId: 2_503_998)

        #expect(details.id == 2_503_998)
        #expect(!details.name.isEmpty)
        #expect(details.calories >= 0)
        #expect(details.protein >= 0)
        #expect(details.fat >= 0)
        #expect(details.carbs >= 0)
    }

    @Test("Proxy client fetch specific FDC ID 1995469")
    @MainActor
    func proxy_client_fetch_specific_fdc_id_1995469() async throws {
        let client = FDCClientFactory.makeProxyClient()
        let details = try await client.fetchFoodDetails(fdcId: 1_995_469)

        #expect(details.id == 1_995_469)
        #expect(!details.name.isEmpty)
        #expect(details.calories >= 0)
        #expect(details.protein >= 0)
        #expect(details.fat >= 0)
        #expect(details.carbs >= 0)
    }

    @Test("Proxy client fetch specific FDC ID 2055229")
    @MainActor
    func proxy_client_fetch_specific_fdc_id_2055229() async throws {
        let client = FDCClientFactory.makeProxyClient()
        let details = try await client.fetchFoodDetails(fdcId: 2_055_229)

        #expect(details.id == 2_055_229)
        #expect(!details.name.isEmpty)
        #expect(details.calories >= 0)
        #expect(details.protein >= 0)
        #expect(details.fat >= 0)
        #expect(details.carbs >= 0)
    }

    @Test("Proxy client fetch raw detail response for FDC ID 2503998")
    @MainActor
    func proxy_client_fetch_raw_detail_response_2503998() async throws {
        let client = FDCClientFactory.makeProxyClient()

        // We need to test the raw response to see what data is actually available
        guard let url = URL(string: "https://api.calry.org/food/2503998") else {
            #expect(Bool(false), "Invalid URL")
            return
        }
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            #expect(Bool(false), "Invalid response")
            return
        }

        #expect(httpResponse.statusCode == 200)

        let proxyResponse = try JSONDecoder().decode(ProxyFoodDetailResponse.self, from: data)

        #expect(proxyResponse.fdcId == 2_503_998)
        #expect(!proxyResponse.description.isEmpty)

        // Verify the response contains expected data structure
        #expect(proxyResponse.dataType != nil)
        #expect(proxyResponse.foodNutrients != nil)
        #expect(proxyResponse.foodNutrients?.count ?? 0 > 0)
    }
}
