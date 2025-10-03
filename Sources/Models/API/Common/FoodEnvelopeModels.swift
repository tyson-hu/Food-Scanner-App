//
//  FoodEnvelopeModels.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Envelope (generic over the raw payload)

public enum RawSource: String, Codable {
    case fdc, off
}

public enum FoodSource: String, Codable, CaseIterable {
    case fdc, off
}

public struct Envelope<T: Codable>: Codable {
    public let gid: String? // "fdc:123456" | "off:0123456789012" | null for search results
    public let source: RawSource // .fdc | .off
    public let barcode: String? // when known (OFF or Branded FDC)
    public let fetchedAt: String // ISO-8601
    public let raw: T // platform-specific raw payload
}

// Convenience aliases
public typealias FdcEnvelope = Envelope<FdcFood>
public typealias OffEnvelope = Envelope<OffProduct>

// Union type for barcode lookup results (can be either FDC or OFF)
public enum BarcodeLookupResult: Codable {
    case fdc(FdcEnvelope)
    case off(Envelope<OffReadResponse>)

    public var gid: String {
        switch self {
        case let .fdc(envelope):
            return envelope.gid ?? "unknown"
        case let .off(envelope):
            return envelope.gid ?? "unknown"
        }
    }

    public var source: RawSource {
        switch self {
        case let .fdc(envelope):
            return envelope.source
        case let .off(envelope):
            return envelope.source
        }
    }

    public var barcode: String? {
        switch self {
        case let .fdc(envelope):
            return envelope.barcode
        case let .off(envelope):
            return envelope.barcode
        }
    }

    public var fetchedAt: String {
        switch self {
        case let .fdc(envelope):
            return envelope.fetchedAt
        case let .off(envelope):
            return envelope.fetchedAt
        }
    }
}

// MARK: - FDC (USDA FoodData Central) raw model

public enum FdcDataType: String, Codable {
    case branded = "Branded"
    case foundation = "Foundation"
    case surveyFNDDS = "Survey (FNDDS)"
    case srLegacy = "SR Legacy"
    // Some APIs may return "Experimental Foods" in the future; treat unknowns as nil via optional decode.
}

public struct FdcFood: Codable {
    // Common
    public let dataType: FdcDataType?
    public let fdcId: Int?
    public let description: String?
    public let publicationDate: String?
    public let foodClass: String? // present on some types

    // Branded-only (often)
    public let brandOwner: String?
    public let brandName: String?
    public let gtinUpc: String?
    public let ingredients: String?
    public let servingSize: Double?
    public let servingSizeUnit: String?
    public let householdServingFullText: String?
    public let brandedFoodCategory: String?
    public let marketCountry: String?
    public let tradeChannels: [String]?
    public let labelNutrients: FdcLabelNutrients? // per serving, sparse

    // Universal nutrient list (varies by type; generally per 100 g)
    public let foodNutrients: [FdcFoodNutrient]?

    // Portions / measures (mostly Foundation/Survey; sometimes SR)
    public let foodPortions: [FdcFoodPortion]?

    // Category info (Survey/FNDDS)
    public let wweiaFoodCategory: FdcWweiaCategory?

    // For Foundation/Survey compositions
    public let inputFoods: [FdcInputFood]?
    public let nutrientConversionFactors: [FdcNutrientConversionFactor]?
}

public struct FdcFoodNutrient: Codable {
    public let id: Int?
    public let amount: Double?
    public let dataPoints: Int?
    public let type: String? // e.g. "FoodNutrient"
    public let nutrient: FdcNutrientRef?
    public let nutrientId: Int? // sometimes present
    public let derivationDescription: String?
    public let derivationCode: String?
}

public struct FdcNutrientRef: Codable {
    public let id: Int?
    public let number: String?
    public let name: String? // e.g., "Protein"
    public let unitName: String? // "G", "MG", "KCAL"
    public let rank: Int?
}

public struct FdcFoodPortion: Codable {
    public let id: Int?
    public let amount: Double?
    public let gramWeight: Double?
    public let portionDescription: String?
    public let sequenceNumber: Int?
    public let measureUnit: FdcMeasureUnit?
    public let modifier: String?
}

public struct FdcMeasureUnit: Codable {
    public let id: Int?
    public let name: String? // e.g., "cup", "tbsp"
}

public struct FdcWweiaCategory: Codable {
    public let wweiaFoodCategoryCode: Int?
    public let wweiaFoodCategoryDescription: String?
}

public struct FdcInputFood: Codable {
    public let id: Int?
    public let amount: Double?
    public let foodDescription: String?
}

public struct FdcNutrientConversionFactor: Codable {
    public let type: String? // "ProteinConversionFactor" etc.
    public let value: Double?
}

// Sparse bag of Nutrition-Facts fields (per serving) on Branded.
public struct FdcLabelNutrients: Codable {
    public let calories: FdcLNValue?
    public let fat: FdcLNValue?
    public let saturatedFat: FdcLNValue?
    public let transFat: FdcLNValue?
    public let cholesterol: FdcLNValue?
    public let sodium: FdcLNValue?
    public let carbohydrates: FdcLNValue?
    public let fiber: FdcLNValue?
    public let sugars: FdcLNValue?
    public let protein: FdcLNValue?
    public let addedSugars: FdcLNValue?
    public let potassium: FdcLNValue?
    public let calcium: FdcLNValue?
    public let iron: FdcLNValue?
    public let vitaminD: FdcLNValue?
    // Others can appear sparsely; decoding tolerates omissions.
}

public struct FdcLNValue: Codable {
    public let value: Double?
}

// MARK: - FDC Search Response Model (raw response; no envelope)

public struct FdcSearchResponse: Codable {
    public let totalHits: Int?
    public let currentPage: Int?
    public let pageList: [Int]?
    public let foodSearchCriteria: FdcFoodSearchCriteria?
    public let foods: [FdcSearchItem]?
}

public struct FdcFoodSearchCriteria: Codable {
    public let query: String?
    public let dataType: [String]?
    public let pageSize: Int?
}

public struct FdcSearchItem: Codable {
    public let fdcId: Int?
    public let dataType: String? // "Branded", "Foundation", etc.
    public let description: String?
    public let brandOwner: String?
    public let gtinUpc: String?
    public let ingredients: String?
    public let servingSize: Double?
    public let servingSizeUnit: String?
    public let labelNutrients: FdcLabelNutrients?
    public let wweiaFoodCategory: FdcWweiaCategory?
}

// MARK: - Proxy API Response Models

public struct ProxyHealthResponse: Sendable, Codable, Equatable {
    public let isHealthy: Bool
    public let sources: [String: String]
    public let version: Int
}

// For error responses from proxy
public struct ProxyApiError: Decodable, Error {
    public let error: String
    public let status: Int?
    public let id: String?
}

public struct ProxyRedirect: Codable, Equatable {
    public let isSuccessful: Bool
    public let redirect: RedirectInfo

    public struct RedirectInfo: Codable, Equatable {
        public let gid: String
        public let reason: String?
    }
}

// Legacy support
public struct ProxyRedirectResponse: Sendable, Codable, Equatable {
    public let isSuccessful: Bool
    public let redirect: ProxyRedirect
}

public struct ProxyErrorResponse: Sendable, Codable, Equatable {
    public let error: String
    public let status: Int?
    public let message: String?
    public let id: String?
}

// MARK: - Route Source Enum

public enum RouteSource {
    case fdcSearch(FdcSearchResponse)
    case fdcDetail(Envelope<FdcFood>)
    case offProduct(Envelope<OffReadResponse>)
    case redirect(ProxyRedirect)
    case proxyError(ProxyApiError)
}

// MARK: - Helper Functions for Safe Decoding

public func decodeEnvelope(data: Data) throws -> RawSource {
    // First, peek at the source only
    struct Meta: Decodable { let source: RawSource }
    return try JSONDecoder().decode(Meta.self, from: data).source
}

public func decodeFdc(_ data: Data) throws -> FdcEnvelope {
    try JSONDecoder().decode(FdcEnvelope.self, from: data)
}

public func decodeOff(_ data: Data) throws -> OffEnvelope {
    try JSONDecoder().decode(OffEnvelope.self, from: data)
}

public func decodeRoute(_ data: Data, for path: String) throws -> RouteSource {
    let jsonDecoder = JSONDecoder()

    if path.hasPrefix("/foods/search") {
        if let err = try? jsonDecoder.decode(ProxyApiError.self, from: data) { return .proxyError(err) }
        let obj = try jsonDecoder.decode(FdcSearchResponse.self, from: data)
        return .fdcSearch(obj)
    }

    if path.hasPrefix("/food/") {
        if let err = try? jsonDecoder.decode(ProxyApiError.self, from: data) { return .proxyError(err) }
        let env = try jsonDecoder.decode(Envelope<FdcFood>.self, from: data)
        return .fdcDetail(env)
    }

    if path.hasPrefix("/v1/off/product/") || path.hasPrefix("/v1/gtin/") {
        // Redirect envelope possible only on /v1/gtin/
        if let redirect = try? jsonDecoder.decode(ProxyRedirect.self, from: data), redirect.isSuccessful {
            return .redirect(redirect)
        }
        if let err = try? jsonDecoder.decode(ProxyApiError.self, from: data) { return .proxyError(err) }
        let env = try jsonDecoder.decode(Envelope<OffReadResponse>.self, from: data)
        return .offProduct(env)
    }

    if let err = try? jsonDecoder.decode(ProxyApiError.self, from: data) {
        return .proxyError(err)
    }
    throw NSError(domain: "Decode", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown payload"])
}
