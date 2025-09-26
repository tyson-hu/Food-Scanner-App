//
//  FDCProxyClientTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/21/25.
//

@testable import Food_Scanner
import Foundation
import Testing

@Suite("FDC Proxy Client Unit Tests")
struct FDCProxyClientTests {
    // MARK: - Mock Client Tests (Fast, Offline)

    @Test("Mock client search foods")
    @MainActor
    func mock_client_search_foods() async throws {
        let client = FDCClientFactory.makeMockClient()
        let results = try await client.searchFoods(matching: "oatmeal", page: 1)

        #expect(!results.isEmpty)
        #expect(results.first?.name.contains("Oatmeal") == true)
    }

    @Test("Mock client fetch food details")
    @MainActor
    func mock_client_fetch_food_details() async throws {
        let client = FDCClientFactory.makeMockClient()

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
        #expect(details.calories >= 0)
    }

    @Test("Mock client handle empty search query")
    @MainActor
    func mock_client_handle_empty_search_query() async throws {
        let client = FDCClientFactory.makeMockClient()
        let results = try await client.searchFoods(matching: "", page: 1)

        #expect(results.isEmpty)
    }

    @Test("Mock client handle short search query")
    @MainActor
    func mock_client_handle_short_search_query() async throws {
        let client = FDCClientFactory.makeMockClient()
        let results = try await client.searchFoods(matching: "a", page: 1)

        #expect(!results.isEmpty) // Mock has items that match "a"
    }

    @Test("Mock client pagination")
    @MainActor
    func mock_client_pagination() async throws {
        let client = FDCClientFactory.makeMockClient()

        let page1 = try await client.searchFoods(matching: "a", page: 1)
        let page2 = try await client.searchFoods(matching: "a", page: 2)

        #expect(!page1.isEmpty)
        #expect(page2.isEmpty) // Mock has limited data, page 2 will be empty

        // Pages should have different results when both have data
        let page1Ids = Set(page1.map(\.id))
        let page2Ids = Set(page2.map(\.id))
        #expect(page1Ids.isDisjoint(with: page2Ids))
    }

    // MARK: - Mock Client Specific ID Tests

    @Test("Mock client fetch specific FDC ID 1003")
    @MainActor
    func mock_client_fetch_specific_fdc_id_1003() async throws {
        let client = FDCClientFactory.makeMockClient()
        let details = try await client.fetchFoodDetails(fdcId: 1003)

        #expect(details.id == 1003)
        #expect(details.name == "Oatmeal, rolled oats")
        #expect(details.calories == 150)
        #expect(details.protein == 5)
        #expect(details.fat == 3)
        #expect(details.carbs == 27)
    }

    @Test("Mock client fetch unknown FDC ID fallback")
    @MainActor
    func mock_client_fetch_unknown_fdc_id_fallback() async throws {
        let client = FDCClientFactory.makeMockClient()
        let details = try await client.fetchFoodDetails(fdcId: 9999)

        #expect(details.id == 9999)
        #expect(!details.name.isEmpty)
        #expect(details.calories >= 0)
        #expect(details.protein >= 0)
        #expect(details.fat >= 0)
        #expect(details.carbs >= 0)
    }

    @Test("Mock client fetch raw detail response")
    @MainActor
    func mock_client_fetch_raw_detail_response() async throws {
        let client = FDCClientFactory.makeMockClient()
        let proxyResponse = try await client.fetchFoodDetailResponse(fdcId: 1003)

        #expect(proxyResponse.fdcId == 1003)
        #expect(!proxyResponse.description.isEmpty)
        #expect(proxyResponse.foodNutrients != nil)
        #expect(proxyResponse.foodNutrients?.count ?? 0 > 0)
        #expect(proxyResponse.labelNutrients != nil)
        #expect(proxyResponse.labelNutrients?.calories?.value == 150.0)
    }

    @Test("Mock client label nutrients fallback")
    @MainActor
    func mock_client_label_nutrients_fallback() async throws {
        let client = FDCClientFactory.makeMockClient()
        let proxyResponse = try await client.fetchFoodDetailResponse(fdcId: 1003)

        // Convert to FDCFoodDetails to test label nutrients fallback
        let details = proxyResponse.toFDCFoodDetails()

        #expect(details.id == 1003)
        #expect(details.name == "Oatmeal, rolled oats")
        // foodNutrients takes precedence over labelNutrients, so we get the foodNutrients values
        #expect(details.calories == 100) // From foodNutrients (1008)
        #expect(details.protein == 7) // From foodNutrients (1003)
        // fat and carbs are not in foodNutrients, so they fall back to labelNutrients
        #expect(details.fat == 3) // From labelNutrients fallback
        #expect(details.carbs == 27) // From labelNutrients fallback
    }

    @Test("Mock client label nutrients fallback when foodNutrients empty")
    @MainActor
    func mock_client_label_nutrients_fallback_when_food_nutrients_empty() async throws {
        // Create a mock response with empty foodNutrients but populated labelNutrients
        let labelNutrients = ProxyLabelNutrients(
            fat: ProxyLabelNutrient(value: 15.0),
            saturatedFat: nil,
            transFat: nil,
            cholesterol: nil,
            sodium: nil,
            carbohydrates: ProxyLabelNutrient(value: 30.0),
            fiber: nil,
            sugars: nil,
            protein: ProxyLabelNutrient(value: 8.0),
            calcium: nil,
            iron: nil,
            calories: ProxyLabelNutrient(value: 200.0)
        )

        let proxyResponse = ProxyFoodDetailResponse(
            fdcId: 9999,
            description: "Test Food",
            publicationDate: "2023-01-01",
            foodNutrients: [], // Empty foodNutrients
            dataType: "Branded",
            foodClass: "Processed",
            inputFoods: nil,
            foodComponents: nil,
            foodAttributes: nil,
            nutrientConversionFactors: nil,
            ndbNumber: 9999,
            isHistoricalReference: false,
            foodCategory: nil,
            brandOwner: "Test Brand",
            brandName: "Test Brand",
            dataSource: "Test",
            gtinUpc: nil,
            marketCountry: "United States",
            servingSize: 100.0,
            servingSizeUnit: "g",
            householdServingFullText: "1 serving",
            ingredients: "Test ingredients",
            brandedFoodCategory: "Test",
            packageWeight: nil,
            discontinuedDate: nil,
            availableDate: "2023-01-01",
            modifiedDate: "2023-01-01",
            foodPortions: nil,
            foodUpdateLog: nil,
            labelNutrients: labelNutrients, // Populated labelNutrients
            scientificName: nil,
            footNote: nil,
            foodCode: nil,
            endDate: nil,
            startDate: nil,
            wweiaFoodCategory: nil,
            foodMeasures: nil,
            microbes: nil,
            tradeChannels: nil,
            allHighlightFields: nil,
            score: nil,
            foodVersionIds: nil,
            foodAttributeTypes: nil,
            finalFoodInputFoods: nil
        )

        // Convert to FDCFoodDetails to test label nutrients fallback
        let details = proxyResponse.toFDCFoodDetails()

        #expect(details.id == 9999)
        #expect(details.name == "Test Food")
        #expect(details.brand == "Test Brand")
        // Should get values from labelNutrients since foodNutrients is empty
        #expect(details.calories == 200) // From labelNutrients
        #expect(details.protein == 8) // From labelNutrients
        #expect(details.fat == 15) // From labelNutrients
        #expect(details.carbs == 30) // From labelNutrients
    }

    // MARK: - Integration Tests (Live Network)

    @Test("Integration: Real proxy client search foods")
    @MainActor
    func integration_real_proxy_client_search_foods() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            #expect(Bool(true), "Integration tests disabled - set RUN_INTEGRATION_TESTS=1 to enable")
            return
        }

        let client = FDCClientFactory.makeProxyClient()
        let results = try await client.searchFoods(matching: "oatmeal", page: 1)

        #expect(!results.isEmpty)
        #expect(results.first?.name.contains("Oatmeal") == true)
    }

    @Test("Integration: Real proxy client fetch food details")
    @MainActor
    func integration_real_proxy_client_fetch_food_details() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            #expect(Bool(true), "Integration tests disabled - set RUN_INTEGRATION_TESTS=1 to enable")
            return
        }

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
        #expect(details.calories >= 0)
    }

    @Test("Integration: Real proxy client cancellation handling")
    @MainActor
    func integration_real_proxy_client_cancellation_handling() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            #expect(Bool(true), "Integration tests disabled - set RUN_INTEGRATION_TESTS=1 to enable")
            return
        }

        let client = FDCClientFactory.makeProxyClient()

        // Start a search task
        let searchTask = Task {
            try await client.searchFoods(matching: "oatmeal", page: 1)
        }

        // Cancel it immediately
        searchTask.cancel()

        // Should throw CancellationError, not FDCError.networkError
        do {
            _ = try await searchTask.value
            #expect(Bool(false), "Expected cancellation error")
        } catch is CancellationError {
            // This is the expected behavior
            #expect(Bool(true), "Correctly received CancellationError")
        } catch let urlError as URLError where urlError.code == .cancelled {
            // This is also acceptable
            #expect(Bool(true), "Correctly received URLError.cancelled")
        } catch let fdcError as FDCError {
            #expect(Bool(false), "Should not receive FDCError.networkError for cancellation, got: \(fdcError)")
        } catch {
            #expect(Bool(false), "Unexpected error type: \(type(of: error))")
        }
    }
}
