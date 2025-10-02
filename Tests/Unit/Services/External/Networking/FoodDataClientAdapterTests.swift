//
//  FoodDataClientAdapterTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Food_Scanner
import Foundation
import Testing

@Suite("FoodDataClientAdapter")
struct FoodDataClientAdapterTests {
    @MainActor
    private final class MockProxyClient: ProxyClient {
        var healthResponse: ProxyHealthResponse?
        var searchResponse: FdcSearchResponse?
        var foodDetailsResponse: Envelope<FdcFood>?
        var offProductResponse: Envelope<OffReadResponse>?
        var barcodeLookupResponse: Envelope<OffReadResponse>?
        var error: Error?

        func getHealth() async throws -> ProxyHealthResponse {
            if let error { throw error }
            return healthResponse ?? ProxyHealthResponse(isHealthy: true, sources: [:], version: 1)
        }

        func searchFoods(query: String, pageSize: Int?) async throws -> FdcSearchResponse {
            if let error { throw error }
            return searchResponse ?? FdcSearchResponse(
                totalHits: 0,
                currentPage: 1,
                pageList: [1],
                foodSearchCriteria: nil,
                foods: []
            )
        }

        func getFoodDetails(fdcId: Int) async throws -> Envelope<FdcFood> {
            if let error { throw error }
            return foodDetailsResponse ?? createEmptyFdcEnvelope()
        }

        func getOFFProduct(barcode: String) async throws -> Envelope<OffReadResponse> {
            if let error { throw error }
            return offProductResponse ?? createEmptyOffEnvelope()
        }

        func lookupByBarcode(barcode: String) async throws -> Envelope<OffReadResponse> {
            if let error { throw error }
            return barcodeLookupResponse ?? createEmptyOffEnvelope()
        }

        func followRedirect(_ redirect: ProxyRedirect) async throws -> Envelope<OffReadResponse> {
            if let error { throw error }
            return createEmptyOffEnvelope()
        }

        private func createEmptyFdcEnvelope() -> Envelope<FdcFood> {
            Envelope<FdcFood>(
                gid: "test:empty",
                source: .fdc,
                barcode: nil,
                fetchedAt: "2025-09-30T12:00:00Z",
                raw: FdcFood(
                    dataType: nil,
                    fdcId: 0,
                    description: "Test Food",
                    publicationDate: nil,
                    foodClass: nil,
                    brandOwner: nil,
                    brandName: nil,
                    gtinUpc: nil,
                    ingredients: nil,
                    servingSize: 100,
                    servingSizeUnit: "g",
                    householdServingFullText: "1 serving",
                    brandedFoodCategory: nil,
                    marketCountry: nil,
                    tradeChannels: nil,
                    labelNutrients: nil,
                    foodNutrients: [],
                    foodPortions: nil,
                    wweiaFoodCategory: nil,
                    inputFoods: nil,
                    nutrientConversionFactors: nil
                )
            )
        }

        private func createEmptyOffEnvelope() -> Envelope<OffReadResponse> {
            Envelope<OffReadResponse>(
                gid: "test:empty",
                source: .off,
                barcode: nil,
                fetchedAt: "2025-09-30T12:00:00Z",
                raw: OffReadResponse(
                    status: 1,
                    code: "1234567890123",
                    product: OffProduct(
                        code: "1234567890123",
                        productName: "Test Product",
                        brands: "",
                        quantity: "100g",
                        packaging: "",
                        categories: "",
                        categoriesTags: [],
                        countries: "",
                        countriesTags: [],
                        ingredientsText: "",
                        ingredients: nil,
                        allergens: "",
                        allergensTags: [],
                        additivesTags: [],
                        imageURL: nil,
                        imageSmallURL: nil,
                        selectedImages: nil,
                        nutriments: nil,
                        nutritionDataPer: "100g",
                        servingSize: "100g",
                        servingQuantity: nil,
                        nutriscoreGrade: nil,
                        novaGroup: nil,
                        ecoscoreGrade: nil,
                        lang: nil,
                        languageCode: nil,
                        lastModifiedT: nil
                    )
                )
            )
        }
    }

    @MainActor
    private let mockClient = MockProxyClient()

    @Test
    @MainActor
    func testGetHealth() async throws {
        let adapter = FoodDataClientAdapter(proxyClient: mockClient)

        let healthResponse = ProxyHealthResponse(
            isHealthy: true,
            sources: ["fdc": "https://api.nal.usda.gov/fdc/v1"],
            version: 1
        )
        mockClient.healthResponse = healthResponse

        let response = try await adapter.getHealth()

        #expect(response.isHealthy == true)
        #expect(response.sources["fdc"] == "https://api.nal.usda.gov/fdc/v1")
    }

    @Test
    @MainActor
    func testGetFoodByBarcode() async throws {
        let adapter = FoodDataClientAdapter(proxyClient: mockClient)

        // Create FDC envelope with sample data

        let envelope = Envelope<OffReadResponse>(
            gid: "fdc:2451234",
            source: .fdc,
            barcode: "0096619123456",
            fetchedAt: "2025-09-30T18:23:45Z",
            raw: OffReadResponse(
                status: 1,
                code: "0096619123456",
                product: OffProduct(
                    code: "0096619123456",
                    productName: "Greek Nonfat Yogurt, Plain",
                    brands: "Kirkland Signature",
                    quantity: "170g",
                    packaging: "",
                    categories: "",
                    categoriesTags: [],
                    countries: "",
                    countriesTags: [],
                    ingredientsText: "",
                    ingredients: nil,
                    allergens: "",
                    allergensTags: [],
                    additivesTags: [],
                    imageURL: nil,
                    imageSmallURL: nil,
                    selectedImages: nil,
                    nutriments: nil,
                    nutritionDataPer: "100g",
                    servingSize: "170g",
                    servingQuantity: nil,
                    nutriscoreGrade: nil,
                    novaGroup: nil,
                    ecoscoreGrade: nil,
                    lang: nil,
                    languageCode: nil,
                    lastModifiedT: nil
                )
            )
        )

        mockClient.barcodeLookupResponse = envelope

        let foodCard = try await adapter.getFoodByBarcode(code: "0096619123456")

        #expect(foodCard.id == "fdc:2451234")
        #expect(foodCard.code == "0096619123456")
        #expect(foodCard.description == "Greek Nonfat Yogurt, Plain")
        #expect(foodCard.brand == "Kirkland Signature")
        #expect(foodCard.kind == .branded)
    }

    @Test
    @MainActor
    func testGetFood() async throws {
        let adapter = FoodDataClientAdapter(proxyClient: mockClient)

        // Create FDC envelope with sample data

        let envelope = Envelope<FdcFood>(
            gid: "fdc:2451234",
            source: .fdc,
            barcode: nil,
            fetchedAt: "2025-09-30T18:23:45Z",
            raw: FdcFood(
                dataType: .branded,
                fdcId: 2_451_234,
                description: "Greek Nonfat Yogurt, Plain",
                publicationDate: nil,
                foodClass: nil,
                brandOwner: "Kirkland Signature",
                brandName: nil,
                gtinUpc: nil,
                ingredients: nil,
                servingSize: 170,
                servingSizeUnit: "g",
                householdServingFullText: "1 container (170g)",
                brandedFoodCategory: nil,
                marketCountry: nil,
                tradeChannels: nil,
                labelNutrients: nil,
                foodNutrients: [],
                foodPortions: nil,
                wweiaFoodCategory: nil,
                inputFoods: nil,
                nutrientConversionFactors: nil
            )
        )

        mockClient.foodDetailsResponse = envelope

        let foodCard = try await adapter.getFood(gid: "fdc:2451234")

        #expect(foodCard.id == "fdc:2451234")
        #expect(foodCard.description == "Greek Nonfat Yogurt, Plain")
        #expect(foodCard.brand == "Kirkland Signature")
    }

    @Test
    @MainActor
    func errorPropagation() async {
        let adapter = FoodDataClientAdapter(proxyClient: mockClient)

        mockClient.error = ProxyError.networkError(URLError(.notConnectedToInternet))

        do {
            _ = try await adapter.getHealth()
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is FoodDataError)
        }
    }

    @Test
    @MainActor
    func oFFProductParsing() async throws {
        let adapter = FoodDataClientAdapter(proxyClient: mockClient)

        // Create OFF envelope with sample data

        let envelope = Envelope<OffReadResponse>(
            gid: "off:0885909950800",
            source: .off,
            barcode: "0885909950800",
            fetchedAt: "2025-09-30T18:26:00Z",
            raw: OffReadResponse(
                status: 1,
                code: "0885909950800",
                product: OffProduct(
                    code: "0885909950800",
                    productName: "Crunchy Peanut Butter",
                    brands: "Example Brand",
                    quantity: "32g",
                    packaging: "",
                    categories: "",
                    categoriesTags: [],
                    countries: "",
                    countriesTags: [],
                    ingredientsText: "",
                    ingredients: nil,
                    allergens: "",
                    allergensTags: [],
                    additivesTags: [],
                    imageURL: nil,
                    imageSmallURL: nil,
                    selectedImages: nil,
                    nutriments: nil,
                    nutritionDataPer: "serving",
                    servingSize: "2 Tbsp (32 g)",
                    servingQuantity: nil,
                    nutriscoreGrade: nil,
                    novaGroup: nil,
                    ecoscoreGrade: nil,
                    lang: nil,
                    languageCode: nil,
                    lastModifiedT: nil
                )
            )
        )

        mockClient.barcodeLookupResponse = envelope

        let foodCard = try await adapter.getFoodByBarcode(code: "0885909950800")

        #expect(foodCard.id == "off:0885909950800")
        #expect(foodCard.code == "0885909950800")
        #expect(foodCard.description == "Crunchy Peanut Butter")
        #expect(foodCard.brand == "Example Brand")
        #expect(foodCard.kind == .branded)
    }
}
