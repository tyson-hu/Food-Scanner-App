//
//  FoodDataClientAdapter.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Food Data Client Adapter

public struct FoodDataClientAdapter: FoodDataClient {
    private let proxyClient: ProxyClient
    private let normalizer: FoodDataNormalizer
    private let converter: FoodDataConverter

    public init(
        proxyClient: ProxyClient,
        normalizationService: FoodNormalizationService = FoodNormalizationServiceImpl()
    ) {
        self.proxyClient = proxyClient
        normalizer = FoodDataNormalizer(normalizationService: normalizationService)
        converter = FoodDataConverter()
    }

    // MARK: - New API Methods (v1 Worker API)

    public func getHealth() async throws -> FoodHealthResponse {
        do {
            let workerResponse = try await proxyClient.getHealth()

            return FoodHealthResponse(
                isHealthy: workerResponse.isHealthy,
                sources: workerResponse.sources
            )
        } catch let error as ProxyError {
            throw convertProxyErrorToFoodDataError(error)
        }
    }

    public func searchFoods(query: String, limit: Int?) async throws -> FoodSearchResponse {
        do {
            let searchResponse = try await proxyClient.searchFoods(query: query, pageSize: limit)
            let results = normalizer.normalizeFdcSearchResponse(searchResponse)

            let generic = results
                .filter { $0.kind == .generic }
                .map(converter.convertToFoodMinimalCard)

            let branded = results
                .filter { $0.kind == .branded }
                .map(converter.convertToFoodMinimalCard)

            return FoodSearchResponse(
                query: query,
                generic: generic,
                branded: branded
            )
        } catch let error as ProxyError {
            throw convertProxyErrorToFoodDataError(error)
        } catch {
            throw error
        }
    }

    public func getFoodByBarcode(code: String) async throws -> FoodMinimalCard {
        do {
            let envelope = try await proxyClient.lookupByBarcode(barcode: code)
            let normalizedFood = normalizer.normalizeOffEnvelope(envelope)
            return converter.convertToFoodMinimalCard(normalizedFood)
        } catch let error as ProxyError {
            // If GTIN lookup fails, try searching by barcode as text
            if case .invalidResponse = error {
                do {
                    let searchResults = try await searchFoods(query: code, limit: 1)
                    if let firstResult = searchResults.branded.first ?? searchResults.generic.first {
                        return firstResult
                    }
                } catch {
                    // Text search also failed, continue with original error
                }
            }
            throw convertProxyErrorToFoodDataError(error)
        }
    }

    public func getFood(gid: String) async throws -> FoodMinimalCard {
        do {
            // Parse GID to determine source and ID
            if gid.hasPrefix("fdc:") {
                let fdcIdString = String(gid.dropFirst(4))
                guard let fdcId = Int(fdcIdString) else {
                    throw FoodDataError.invalidURL
                }
                let envelope = try await proxyClient.getFoodDetails(fdcId: fdcId)
                let normalizedFood = normalizer.normalizeFdcEnvelope(envelope)
                return converter.convertToFoodMinimalCard(normalizedFood)
            } else if gid.hasPrefix("off:") {
                let barcode = String(gid.dropFirst(4))
                let envelope = try await proxyClient.getOFFProduct(barcode: barcode)
                let normalizedFood = normalizer.normalizeOffEnvelope(envelope)
                return converter.convertToFoodMinimalCard(normalizedFood)
            } else {
                throw FoodDataError.invalidURL
            }
        } catch let error as ProxyError {
            throw convertProxyErrorToFoodDataError(error)
        }
    }

    public func getFoodDetails(gid: String) async throws -> FoodAuthoritativeDetail {
        do {
            // Parse GID to determine source and ID
            if gid.hasPrefix("fdc:") {
                let fdcIdString = String(gid.dropFirst(4))
                guard let fdcId = Int(fdcIdString) else {
                    throw FoodDataError.invalidURL
                }
                let envelope = try await proxyClient.getFoodDetails(fdcId: fdcId)
                let normalizedFood = normalizer.normalizeFdcEnvelope(envelope)
                return converter.convertToFoodAuthoritativeDetail(normalizedFood)
            } else if gid.hasPrefix("off:") {
                let barcode = String(gid.dropFirst(4))
                let envelope = try await proxyClient.getOFFProduct(barcode: barcode)
                let normalizedFood = normalizer.normalizeOffEnvelope(envelope)
                return converter.convertToFoodAuthoritativeDetail(normalizedFood)
            } else {
                throw FoodDataError.invalidURL
            }
        } catch let error as ProxyError {
            throw convertProxyErrorToFoodDataError(error)
        }
    }

    // MARK: - Legacy Methods (for backward compatibility)

    public func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        let response = try await searchFoodsWithPagination(matching: query, page: page, pageSize: 25)
        return response.foods
    }

    public func searchFoodsWithPagination(
        matching query: String,
        page: Int,
        pageSize: Int
    ) async throws -> FoodDataSearchResult {
        // For now, we'll use the new search API and convert the results
        // In a real implementation, you might want to implement proper pagination
        let response = try await searchFoods(query: query, limit: pageSize)

        let allFoods = response.generic + response.branded
        let fdcSummaries = allFoods.map(converter.convertToFDCFoodSummary)

        return FoodDataSearchResult(
            foods: fdcSummaries,
            totalHits: fdcSummaries.count,
            currentPage: page,
            totalPages: 1,
            pageSize: pageSize
        )
    }

    public func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        do {
            let envelope = try await proxyClient.getFoodDetails(fdcId: fdcId)
            let normalizedFood = normalizer.normalizeFdcEnvelope(envelope)
            return converter.convertToFDCFoodDetails(normalizedFood)
        } catch let error as ProxyError {
            throw convertProxyErrorToFoodDataError(error)
        }
    }

    public func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse {
        do {
            // This is a legacy method that returns the raw proxy response
            // For now, we'll create a minimal response
            // In a real implementation, you might want to preserve the raw FDC data
            _ = try await proxyClient.getFoodDetails(fdcId: fdcId)

            // For legacy compatibility, we'll create a minimal response
            // In a real implementation, you'd want to extract the FDC data properly
            return ProxyFoodDetailResponse(
                fdcId: fdcId,
                description: "Legacy FDC Food",
                publicationDate: nil,
                foodNutrients: nil,
                dataType: nil,
                foodClass: nil,
                inputFoods: nil,
                foodComponents: nil,
                foodAttributes: nil,
                nutrientConversionFactors: nil,
                ndbNumber: nil,
                isHistoricalReference: nil,
                foodCategory: nil,
                brandOwner: nil,
                brandName: nil,
                dataSource: nil,
                gtinUpc: nil,
                marketCountry: nil,
                servingSize: nil,
                servingSizeUnit: nil,
                householdServingFullText: nil,
                ingredients: nil,
                brandedFoodCategory: nil,
                packageWeight: nil,
                discontinuedDate: nil,
                availableDate: nil,
                modifiedDate: nil,
                foodPortions: nil,
                foodUpdateLog: nil,
                labelNutrients: nil,
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
        } catch let error as ProxyError {
            throw convertProxyErrorToFoodDataError(error)
        }
    }
}

// MARK: - Missing Proxy Types (for backward compatibility)

public struct ProxyFoodDetailResponse: Codable, Equatable {
    let fdcId: Int
    let description: String
    let publicationDate: String?
    let foodNutrients: [ProxyFoodNutrient]?
    let dataType: String?
    let foodClass: String?
    let inputFoods: [ProxyInputFood]?
    let foodComponents: [AnyCodable]?
    let foodAttributes: [AnyCodable]?
    let nutrientConversionFactors: [ProxyNutrientConversionFactor]?
    let ndbNumber: Int?
    let isHistoricalReference: Bool?
    let foodCategory: ProxyFoodCategory?

    // Additional fields from Calry API
    let brandOwner: String?
    let brandName: String?
    let dataSource: String?
    let gtinUpc: String?
    let marketCountry: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let householdServingFullText: String?
    let ingredients: String?
    let brandedFoodCategory: String?
    let packageWeight: String?
    let discontinuedDate: String?
    let availableDate: String?
    let modifiedDate: String?
    let foodPortions: [ProxyFoodPortion]?
    let foodUpdateLog: [AnyCodable]?
    let labelNutrients: ProxyLabelNutrients?

    // Additional fields from FDC API schema
    let scientificName: String?
    let footNote: String?
    let foodCode: String?
    let endDate: String?
    let startDate: String?
    let wweiaFoodCategory: ProxyWweiaFoodCategory?
    let foodMeasures: [ProxyFoodMeasure]?
    let microbes: [String]?
    let tradeChannels: [String]?
    let allHighlightFields: String?
    let score: Double?
    let foodVersionIds: [String]?
    let foodAttributeTypes: [AnyCodable]?
    let finalFoodInputFoods: [String]?
}

public struct ProxyInputFood: Codable, Equatable {
    let id: Int?
    let foodDescription: String?
    let inputFood: ProxyInputFoodDetail?
}

public struct ProxyInputFoodDetail: Codable, Equatable {
    let fdcId: Int?
    let description: String?
    let publicationDate: String?
    let foodAttributeTypes: [AnyCodable]?
    let foodClass: String?
    let totalRefuse: Int?
    let dataType: String?
    let foodGroup: ProxyFoodGroup?
}

public struct ProxyFoodGroup: Codable, Equatable {
    let id: Int?
    let code: String?
    let description: String?
}

public struct ProxyFoodCategory: Codable, Equatable {
    let id: Int?
    let code: String?
    let description: String?
}

public struct ProxyWweiaFoodCategory: Codable, Equatable {
    let wweiaFoodCategoryCode: Int?
    let wweiaFoodCategoryDescription: String?
}

public struct ProxyNutrientConversionFactor: Codable, Equatable {
    let id: Int?
    let proteinValue: Double?
    let fatValue: Double?
    let carbohydrateValue: Double?
    let type: String?
    let name: String?
}

public struct ProxyFoodNutrient: Codable, Equatable {
    let nutrient: ProxyNutrientInfo?
    let amount: Double?
    let dataPoints: Int?
    let derivation: ProxyDerivation?
    let type: String?
}

public struct ProxyNutrientInfo: Codable, Equatable {
    let id: Int
    let number: String?
    let name: String
    let rank: Int?
    let unitName: String?
}

public struct ProxyDerivation: Codable, Equatable {
    let id: Int?
    let code: String?
    let description: String?
    let sourceDescription: String?
}

public struct ProxyFoodPortion: Codable, Equatable {
    let id: Int?
    let amount: Double?
    let dataPoints: Int?
    let gramWeight: Double?
    let minYearAcquired: Int?
    let modifier: String?
    let portionDescription: String?
    let sequenceNumber: Int?
    let measureUnit: ProxyMeasureUnit?
}

public struct ProxyMeasureUnit: Codable, Equatable {
    let id: Int?
    let abbreviation: String?
    let name: String?
}

public struct ProxyFoodMeasure: Codable, Equatable {
    let id: Int?
    let amount: Double?
    let gramWeight: Double?
    let modifier: String?
    let portionDescription: String?
    let sequenceNumber: Int?
    let measureUnit: ProxyMeasureUnit?
}

public struct ProxyLabelNutrients: Codable, Equatable {
    let calories: ProxyNutrientValue?
    let fat: ProxyNutrientValue?
    let saturatedFat: ProxyNutrientValue?
    let transFat: ProxyNutrientValue?
    let cholesterol: ProxyNutrientValue?
    let sodium: ProxyNutrientValue?
    let carbohydrates: ProxyNutrientValue?
    let fiber: ProxyNutrientValue?
    let sugars: ProxyNutrientValue?
    let protein: ProxyNutrientValue?
    let calcium: ProxyNutrientValue?
    let iron: ProxyNutrientValue?
    let potassium: ProxyNutrientValue?
}

public struct ProxyNutrientValue: Codable, Equatable {
    let value: Double
    let unit: String?
}

// MARK: - Error Conversion

// swiftformat:disable:next redundantReturn
private func convertProxyErrorToFoodDataError(_ error: ProxyError) -> FoodDataError {
    switch error {
    case .invalidURL:
        return .invalidURL
    case .invalidResponse:
        return .invalidResponse
    case let .httpError(code):
        return .httpError(code)
    case let .networkError(error):
        return .networkError(error)
    case .serverUnavailable:
        return .serverUnavailable
    case let .rateLimited(retryAfter):
        return .rateLimited(retryAfter)
    case .invalidGID:
        return .invalidURL
    case let .proxyError(errorResponse):
        return .customError(ProxyError.proxyError(errorResponse).errorDescription ?? "Proxy error occurred")
    }
}
