//
//  BarcodeSearchResultsViewModelTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
//

@testable import Food_Scanner
import Foundation
import Testing

@Suite("BarcodeSearchResultsViewModel")
struct BarcodeSearchResultsViewModelTests {
    // MARK: - Initialization Tests

    @Test @MainActor
    func initialState() async throws {
        let mockClient = MockFDCClient()
        let viewModel = BarcodeSearchResultsViewModel(upc: "0031604031121", client: mockClient)

        #expect(viewModel.upc == "0031604031121")
        #expect(viewModel.phase == .loading)
    }

    // MARK: - Successful Search Tests

    @Test @MainActor
    func successfulUPCSearch() async throws {
        let mockClient = MockFDCClient()
        let viewModel = BarcodeSearchResultsViewModel(upc: "0031604031121", client: mockClient)

        // Given - Mock successful barcode search response
        let mockFood = FoodMinimalCard(
            id: "gtin:0031604031121",
            kind: .brandedFood,
            code: "0031604031121",
            description: "Test Product, UPC: 0031604031121",
            brand: "Test Brand",
            serving: FoodServing(amount: 100, unit: "g", household: "1 serving"),
            nutrients: [],
            provenance: FoodProvenance(source: .fdc, id: "123456", fetchedAt: "2025-09-26T21:00:00Z"),
        )
        mockClient.mockBarcodeResult = mockFood

        // When
        await viewModel.search()

        // Then
        switch viewModel.phase {
        case let .loaded(result):
            #expect(result != nil)
            #expect(result?.id == "gtin:0031604031121")
            #expect(result?.description == "Test Product, UPC: 0031604031121")
            #expect(result?.code == "0031604031121")
            #expect(result?.brand == "Test Brand")
        case .loading:
            Issue.record("Expected loaded state, got loading")
        case let .error(message):
            Issue.record("Expected loaded state, got error: \(message)")
        }
    }

    @Test @MainActor
    func uPCSearchWithNoResults() async throws {
        let mockClient = MockFDCClient()
        let viewModel = BarcodeSearchResultsViewModel(upc: "0031604031121", client: mockClient)

        // Given - Mock no results response
        mockClient.mockBarcodeResult = nil
        mockClient.mockError = FDCError.noResults

        // When
        await viewModel.search()

        // Then
        switch viewModel.phase {
        case let .loaded(result):
            #expect(result == nil)
        case .loading:
            Issue.record("Expected loaded state, got loading")
        case let .error(message):
            Issue.record("Expected loaded state, got error: \(message)")
        }
    }

    // MARK: - Error Handling Tests

    @Test @MainActor
    func uPCSearchWithNetworkError() async throws {
        let mockClient = MockFDCClient()
        let viewModel = BarcodeSearchResultsViewModel(upc: "0031604031121", client: mockClient)

        // Given - Mock network error
        mockClient.mockError = FDCError.networkError(URLError(.notConnectedToInternet))

        // When
        await viewModel.search()

        // Then
        switch viewModel.phase {
        case .loaded:
            Issue.record("Expected error state, got loaded")
        case .loading:
            Issue.record("Expected error state, got loading")
        case let .error(message):
            #expect(message.contains("No internet connection"))
        }
    }

    @Test @MainActor
    func uPCSearchWithNoResultsError() async throws {
        let mockClient = MockFDCClient()
        let viewModel = BarcodeSearchResultsViewModel(upc: "0031604031121", client: mockClient)

        // Given - Mock no results error
        mockClient.mockError = FDCError.noResults

        // When
        await viewModel.search()

        // Then - Should treat no results as successful search with nil result
        switch viewModel.phase {
        case let .loaded(result):
            #expect(result == nil)
        case .loading:
            Issue.record("Expected loaded state, got loading")
        case let .error(message):
            Issue.record("Expected loaded state, got error: \(message)")
        }
    }

    @Test @MainActor
    func uPCSearchWithCancellationError() async throws {
        let mockClient = MockFDCClient()
        let viewModel = BarcodeSearchResultsViewModel(upc: "0031604031121", client: mockClient)

        // Given - Mock cancellation error
        mockClient.mockError = CancellationError()

        // When
        await viewModel.search()

        // Then
        switch viewModel.phase {
        case .loaded:
            Issue.record("Expected error state, got loaded")
        case .loading:
            Issue.record("Expected error state, got loading")
        case let .error(message):
            #expect(message.contains("cancelled"))
        }
    }

    @Test @MainActor
    func uPCSearchWithGenericError() async throws {
        let mockClient = MockFDCClient()
        let viewModel = BarcodeSearchResultsViewModel(upc: "0031604031121", client: mockClient)

        // Given - Mock generic error
        mockClient.mockError = FDCError.httpError(500)

        // When
        await viewModel.search()

        // Then
        switch viewModel.phase {
        case .loaded:
            Issue.record("Expected error state, got loaded")
        case .loading:
            Issue.record("Expected error state, got loading")
        case let .error(message):
            #expect(message.contains("500"))
        }
    }

    // MARK: - Integration Tests for Specific Issue

    @Test @MainActor
    func specificBarcodeIssue_2503998_074854374969() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            return
        }

        let client = FDCClientFactory.makeProxyClient()

        // Test 1: Barcode search should work
        do {
            let barcodeResult = try await client.getFoodByBarcode(code: "074854374969")
            print("✅ Barcode search successful for 074854374969")
            print("   GID: \(barcodeResult.id)")
            print("   Description: \(barcodeResult.description ?? "N/A")")
            print("   Brand: \(barcodeResult.brand ?? "N/A")")

            // Test 2: Using the GID from barcode search should work
            do {
                let foodResult = try await client.getFood(gid: barcodeResult.id)
                print("✅ Food lookup successful for GID: \(barcodeResult.id)")
                print("   Description: \(foodResult.description ?? "N/A")")
                print("   Brand: \(foodResult.brand ?? "N/A")")
            } catch {
                print("❌ Food lookup failed for GID: \(barcodeResult.id)")
                print("   Error: \(error)")
                Issue.record("Food lookup should succeed for valid GID from barcode search")
            }
        } catch {
            print("❌ Barcode search failed for 074854374969")
            print("   Error: \(error)")
            Issue.record("Barcode search should succeed for valid UPC")
        }
    }
}

// MARK: - Mock FDCClient

class MockFDCClient: @unchecked Sendable, FDCClient {
    var mockSearchResult: [FDCFoodSummary] = []
    var mockError: Error?
    var mockBarcodeResult: FoodMinimalCard?
    var mockFoodResult: FoodMinimalCard?

    // MARK: - New API Methods (v1 Worker API)

    func getHealth() async throws -> FoodHealthResponse {
        FoodHealthResponse(isHealthy: true, sources: [:])
    }

    func searchFoods(query: String, limit: Int?) async throws -> FoodSearchResponse {
        FoodSearchResponse(query: query, generic: [], branded: [])
    }

    func getFoodByBarcode(code: String) async throws -> FoodMinimalCard {
        if let error = mockError {
            throw error
        }
        if let result = mockBarcodeResult {
            return result
        }
        throw FDCError.noResults
    }

    func getFood(gid: String) async throws -> FoodMinimalCard {
        if let error = mockError {
            throw error
        }
        if let result = mockFoodResult {
            return result
        }
        throw FDCError.noResults
    }

    func getFoodDetails(gid: String) async throws -> FoodAuthoritativeDetail {
        if let error = mockError {
            throw error
        }
        throw FDCError.noResults
    }

    // MARK: - Legacy Methods (for backward compatibility)

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        if let error = mockError {
            throw error
        }
        return mockSearchResult
    }

    func searchFoodsWithPagination(matching query: String, page: Int, pageSize: Int) async throws -> FDCSearchResult {
        if let error = mockError {
            throw error
        }
        return FDCSearchResult(
            foods: mockSearchResult,
            totalHits: mockSearchResult.count,
            currentPage: page,
            totalPages: 1,
            pageSize: pageSize,
        )
    }

    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        if let error = mockError {
            throw error
        }
        // Return a mock food detail - this would need to be implemented based on your FDCFoodDetails structure
        throw FDCError.noResults
    }

    func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse {
        if let error = mockError {
            throw error
        }
        // Return a mock food detail response - this would need to be implemented based on your ProxyFoodDetailResponse
        // structure
        throw FDCError.noResults
    }
}
