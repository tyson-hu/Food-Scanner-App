//
//  FDCProxyClientTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
//

@testable import Food_Scanner
import Foundation
import Testing

@Suite("FDCProxyClient")
struct FDCProxyClientTests {
    // MARK: - Search Tests

    @Test @MainActor
    func searchFoodsWithValidResponse() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given
        let mockResponse = ProxySearchResponse(
            totalHits: 10,
            currentPage: 1,
            totalPages: 1,
            pageList: [1],
            foodSearchCriteria: FoodSearchCriteria(
                dataType: ["Branded"],
                query: "apple",
                generalSearchInput: "apple",
                pageNumber: 1,
                numberOfResultsPerPage: 25,
                pageSize: 25,
                requireAllWords: false,
                foodTypes: []
            ),
            foods: [
                ProxyFoodItem(
                    fdcId: 12345,
                    description: "Apple, raw",
                    dataType: "Branded",
                    gtinUpc: "1234567890123",
                    publishedDate: "2023-01-01",
                    brandOwner: "Test Brand",
                    brandName: "Test Brand",
                    ingredients: "Apple",
                    marketCountry: "US",
                    foodCategory: "Fruits",
                    modifiedDate: "2023-01-01",
                    dataSource: "Test",
                    packageWeight: "100g",
                    servingSizeUnit: "g",
                    servingSize: 100.0,
                    householdServingFullText: "1 medium apple",
                    tradeChannels: ["Retail"],
                    allHighlightFields: nil,
                    score: 0.95,
                    microbes: nil,
                    foodNutrients: nil,
                    finalFoodInputFoods: nil,
                    foodMeasures: nil,
                    foodAttributes: nil,
                    foodAttributeTypes: nil,
                    foodVersionIds: nil
                )
            ],
            aggregations: nil
        )

        do {
            mockSession.mockData = try JSONEncoder().encode(mockResponse)
        } catch {
            Issue.record("Failed to encode mock response: \(error)")
            return
        }
        guard let url = URL(string: "https://api.calry.org/v1/foods/search") else {
            Issue.record("Failed to create URL")
            return
        }
        mockSession.mockResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When
        let result = try await client.searchFoodsWithPagination(matching: "apple", page: 1, pageSize: 25)

        // Then
        #expect(result.foods.count == 1)
        #expect(result.totalHits == 10)
        #expect(result.currentPage == 1)
        #expect(result.totalPages == 1)
        #expect(result.pageSize == 25)
        #expect(result.hasMore == false)

        guard let food = result.foods.first else {
            Issue.record("Expected at least one food item")
            return
        }
        #expect(food.id == 12345)
        #expect(food.name == "Apple, raw")
        #expect(food.brand == "Test Brand")
        #expect(food.upc == "1234567890123")
    }

    @Test @MainActor
    func searchFoodsWithEmptyQuery() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // When
        let result = try await client.searchFoodsWithPagination(matching: "", page: 1, pageSize: 25)

        // Then
        #expect(result.foods.isEmpty)
        #expect(result.totalHits == 0)
        #expect(result.currentPage == 1)
        #expect(result.totalPages == 0)
    }

    @Test @MainActor
    func searchFoodsWithShortQuery() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // When
        let result = try await client.searchFoodsWithPagination(matching: "a", page: 1, pageSize: 25)

        // Then
        #expect(result.foods.isEmpty)
        #expect(result.totalHits == 0)
        #expect(result.currentPage == 1)
        #expect(result.totalPages == 0)
    }

    @Test @MainActor
    func searchFoodsWithHTTPError() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given
        mockSession.mockError = FDCError.httpError(404)

        // When/Then
        do {
            _ = try await client.searchFoodsWithPagination(matching: "nonexistent", page: 1, pageSize: 25)
            Issue.record("Expected error to be thrown")
        } catch let error as FDCError {
            if case .httpError(404) = error {
                // Expected error
            } else {
                Issue.record("Expected HTTP 404 error")
            }
        } catch {
            Issue.record("Expected FDCError")
        }
    }

    @Test @MainActor
    func searchFoodsWithNetworkError() async throws {
        // Skip network tests in CI for stability
        #if CI_OFFLINE_MODE
            throw XCTSkip("Network tests disabled in CI offline mode")
        #endif
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given
        mockSession.mockError = URLError(.notConnectedToInternet)

        // When/Then
        do {
            _ = try await client.searchFoodsWithPagination(matching: "apple", page: 1, pageSize: 25)
            Issue.record("Expected error to be thrown")
        } catch let error as FDCError {
            if case .networkError = error {
                // Expected error
            } else {
                Issue.record("Expected network error")
            }
        } catch {
            Issue.record("Expected FDCError")
        }
    }

    // MARK: - Retry Logic Tests

    @Test @MainActor
    func retryLogicWithTransientError() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given - First request fails, second succeeds
        let mockResponse = ProxySearchResponse(
            totalHits: 0,
            currentPage: 1,
            totalPages: 0,
            pageList: [],
            foodSearchCriteria: FoodSearchCriteria(
                dataType: ["Branded"],
                query: "test",
                generalSearchInput: "test",
                pageNumber: 1,
                numberOfResultsPerPage: 25,
                pageSize: 25,
                requireAllWords: false,
                foodTypes: []
            ),
            foods: [],
            aggregations: nil
        )

        do {
            mockSession.mockData = try JSONEncoder().encode(mockResponse)
        } catch {
            Issue.record("Failed to encode mock response: \(error)")
            return
        }
        guard let url = URL(string: "https://api.calry.org/v1/foods/search") else {
            Issue.record("Failed to create URL")
            return
        }
        mockSession.mockResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // Simulate first failure, then success
        mockSession.shouldFailFirst = true
        mockSession.mockFirstError = URLError(.timedOut)

        // When
        do {
            let result = try await client.searchFoodsWithPagination(matching: "test", page: 1, pageSize: 25)

            // Then
            #expect(result.foods.isEmpty)
            #expect(mockSession.requestCount == 2) // Should have retried
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test @MainActor
    func retryLogicWithNonRetryableError() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given
        mockSession.mockError = FDCError.invalidURL

        // When/Then
        do {
            _ = try await client.searchFoodsWithPagination(matching: "test", page: 1, pageSize: 25)
            Issue.record("Expected error to be thrown")
        } catch let error as FDCError {
            if case .invalidURL = error {
                // Expected error
            } else {
                Issue.record("Expected invalid URL error")
            }
        } catch {
            Issue.record("Expected FDCError")
        }

        #expect(mockSession.requestCount == 1) // Should not retry
    }

    @Test @MainActor
    func retryLogicWithDecodingError() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given - Invalid JSON that will cause decoding error
        mockSession.mockData = Data("invalid json".utf8)
        guard let url = URL(string: "https://api.calry.org/v1/foods/search") else {
            Issue.record("Failed to create URL")
            return
        }
        mockSession.mockResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            _ = try await client.searchFoodsWithPagination(matching: "test", page: 1, pageSize: 25)
            Issue.record("Expected error to be thrown")
        } catch let error as FDCError {
            if case .decodingError = error {
                // Expected error type
            } else {
                Issue.record("Expected decoding error, got: \(error)")
            }
        } catch {
            Issue.record("Expected FDCError, got: \(error)")
        }

        #expect(mockSession.requestCount == 1) // Should not retry decoding errors
    }

    @Test @MainActor
    func retryLogicWithBadURLError() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given - Bad URL error (non-retryable)
        mockSession.mockError = URLError(.badURL)

        // When/Then
        do {
            _ = try await client.searchFoodsWithPagination(matching: "test", page: 1, pageSize: 25)
            Issue.record("Expected error to be thrown")
        } catch let error as FDCError {
            if case .invalidURL = error {
                // Expected error type
            } else {
                Issue.record("Expected invalid URL error, got: \(error)")
            }
        } catch {
            Issue.record("Expected FDCError, got: \(error)")
        }

        #expect(mockSession.requestCount == 1) // Should not retry bad URL errors
    }

    @Test @MainActor
    func retryLogicWithNetworkTimeoutError() async throws {
        // Skip network tests in CI for stability
        #if CI_OFFLINE_MODE
            throw XCTSkip("Network tests disabled in CI offline mode")
        #endif
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given - Network timeout error (retryable)
        mockSession.mockError = URLError(.timedOut)

        // When/Then
        do {
            _ = try await client.searchFoodsWithPagination(matching: "test", page: 1, pageSize: 25)
            Issue.record("Expected error to be thrown")
        } catch let error as FDCError {
            if case .networkError = error {
                // Expected error type
            } else {
                Issue.record("Expected network error, got: \(error)")
            }
        } catch {
            Issue.record("Expected FDCError, got: \(error)")
        }

        #expect(mockSession.requestCount > 1) // Should retry network timeout errors
    }

    // MARK: - UPC Barcode Search Tests

    @Test @MainActor
    func searchFoodsWithValidUPC() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given - Mock response for UPC search
        let testUPC = "0031604031121"
        let mockResponse = ProxySearchResponse(
            totalHits: 1,
            currentPage: 1,
            totalPages: 1,
            pageList: [1],
            foodSearchCriteria: FoodSearchCriteria(
                dataType: ["Branded"],
                query: testUPC,
                generalSearchInput: testUPC,
                pageNumber: 1,
                numberOfResultsPerPage: 25,
                pageSize: 25,
                requireAllWords: false,
                foodTypes: []
            ),
            foods: [
                ProxyFoodItem(
                    fdcId: 123_456,
                    description: "Test Product, UPC: \(testUPC)",
                    dataType: "Branded",
                    gtinUpc: testUPC,
                    publishedDate: "2023-01-01",
                    brandOwner: "Test Brand",
                    brandName: "Test Brand",
                    ingredients: "Test ingredients",
                    marketCountry: "US",
                    foodCategory: "Test Category",
                    modifiedDate: "2023-01-01",
                    dataSource: "Test",
                    packageWeight: "100g",
                    servingSizeUnit: "g",
                    servingSize: 100.0,
                    householdServingFullText: "1 serving",
                    tradeChannels: ["Retail"],
                    allHighlightFields: nil,
                    score: 0.95,
                    microbes: nil,
                    foodNutrients: nil,
                    finalFoodInputFoods: nil,
                    foodMeasures: nil,
                    foodAttributes: nil,
                    foodAttributeTypes: nil,
                    foodVersionIds: nil
                )
            ],
            aggregations: nil
        )

        do {
            mockSession.mockData = try JSONEncoder().encode(mockResponse)
        } catch {
            Issue.record("Failed to encode mock response: \(error)")
            return
        }
        guard let url = URL(string: "https://api.calry.org/v1/foods/search") else {
            Issue.record("Failed to create URL")
            return
        }
        mockSession.mockResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When
        let result = try await client.searchFoodsWithPagination(matching: testUPC, page: 1, pageSize: 25)

        // Then
        #expect(result.foods.count == 1)
        #expect(result.totalHits == 1)
        #expect(result.currentPage == 1)
        #expect(result.totalPages == 1)
        #expect(result.pageSize == 25)
        #expect(result.hasMore == false)

        guard let food = result.foods.first else {
            Issue.record("Expected at least one food item")
            return
        }
        #expect(food.id == 123_456)
        #expect(food.name == "Test Product, UPC: \(testUPC)")
        #expect(food.brand == "Test Brand")
        #expect(food.upc == testUPC)
    }

    @Test @MainActor
    func searchFoodsWithUPCNotFound() async throws {
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given - Mock response for UPC that doesn't exist
        let testUPC = "0031604031121"
        let mockResponse = ProxySearchResponse(
            totalHits: 0,
            currentPage: 1,
            totalPages: 0,
            pageList: [],
            foodSearchCriteria: FoodSearchCriteria(
                dataType: ["Branded"],
                query: testUPC,
                generalSearchInput: testUPC,
                pageNumber: 1,
                numberOfResultsPerPage: 25,
                pageSize: 25,
                requireAllWords: false,
                foodTypes: []
            ),
            foods: [],
            aggregations: nil
        )

        do {
            mockSession.mockData = try JSONEncoder().encode(mockResponse)
        } catch {
            Issue.record("Failed to encode mock response: \(error)")
            return
        }
        guard let url = URL(string: "https://api.calry.org/v1/foods/search") else {
            Issue.record("Failed to create URL")
            return
        }
        mockSession.mockResponse = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When
        let result = try await client.searchFoodsWithPagination(matching: testUPC, page: 1, pageSize: 25)

        // Then
        #expect(result.foods.isEmpty)
        #expect(result.totalHits == 0)
        #expect(result.currentPage == 1)
        #expect(result.totalPages == 0)
        #expect(result.hasMore == false)
    }

    @Test @MainActor
    func searchFoodsWithUPCNetworkError() async throws {
        // Skip network tests in CI for stability
        #if CI_OFFLINE_MODE
            throw XCTSkip("Network tests disabled in CI offline mode")
        #endif
        let mockSession = MockURLSession()
        let client = FDCProxyClient(session: mockSession)

        // Given
        let testUPC = "0031604031121"
        mockSession.mockError = URLError(.notConnectedToInternet)

        // When/Then
        do {
            _ = try await client.searchFoodsWithPagination(matching: testUPC, page: 1, pageSize: 25)
            Issue.record("Expected error to be thrown")
        } catch let error as FDCError {
            if case .networkError = error {
                // Expected error
            } else {
                Issue.record("Expected network error")
            }
        } catch {
            Issue.record("Expected FDCError")
        }
    }
}

// MARK: - Mock URLSession

class MockURLSession: URLSessionProtocol, @unchecked Sendable {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var shouldFailFirst = false
    var mockFirstError: Error?
    var requestCount = 0

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        requestCount += 1

        if shouldFailFirst, requestCount == 1 {
            throw mockFirstError ?? URLError(.timedOut)
        }

        if let error = mockError {
            throw error
        }

        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }
}
