//
//  FoodDataNormalizer.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - Food Data Normalizer

public struct FoodDataNormalizer {
    private let normalizationService: FoodNormalizationService

    public init(normalizationService: FoodNormalizationService = FoodNormalizationServiceImpl()) {
        self.normalizationService = normalizationService
    }

    // MARK: - New API Normalization Helpers

    func normalizeSearchEnvelope(_ envelope: Envelope<AnyCodable>) -> [NormalizedFood] {
        // Try to decode as FDC search response first, then OFF
        do {
            // Convert AnyCodable to FdcSearchResponse by decoding the raw data
            let rawData = try JSONEncoder().encode(envelope.raw)
            let searchResponse = try JSONDecoder().decode(FdcSearchResponse.self, from: rawData)

            // Process each food in the search results
            var normalizedFoods: [NormalizedFood] = []
            for fdcFood in searchResponse.foods ?? [] {
                // Skip foods without valid FDC ID
                guard let fdcId = fdcFood.fdcId else {
                    continue
                }

                // Create unique GID for each food item
                let foodGid = "fdc:\(fdcId)"
                // Convert FdcSearchItem to FdcProduct for normalization
                let fdcProductData = FdcProduct(
                    dataType: fdcFood.dataType.flatMap { FdcDataType(rawValue: $0) },
                    fdcId: fdcFood.fdcId,
                    description: fdcFood.description,
                    publicationDate: nil,
                    foodClass: nil,
                    brandOwner: fdcFood.brandOwner,
                    brandName: nil,
                    gtinUpc: fdcFood.gtinUpc,
                    ingredients: fdcFood.ingredients,
                    servingSize: fdcFood.servingSize,
                    servingSizeUnit: fdcFood.servingSizeUnit,
                    householdServingFullText: nil,
                    brandedFoodCategory: nil,
                    marketCountry: nil,
                    tradeChannels: nil,
                    labelNutrients: fdcFood.labelNutrients,
                    foodNutrients: nil,
                    foodPortions: nil,
                    wweiaFoodCategory: fdcFood.wweiaFoodCategory,
                    inputFoods: nil,
                    nutrientConversionFactors: nil
                )
                let fdcEnvelope = FdcEnvelope(
                    gid: foodGid,
                    source: envelope.source,
                    barcode: fdcFood.gtinUpc,
                    fetchedAt: envelope.fetchedAt,
                    raw: fdcProductData
                )
                normalizedFoods.append(normalizationService.normalizeFDC(fdcEnvelope))
            }
            return normalizedFoods
        } catch {
            do {
                // Convert AnyCodable to OffProduct by decoding the raw data
                let rawData = try JSONEncoder().encode(envelope.raw)
                let offProduct = try JSONDecoder().decode(OffProduct.self, from: rawData)
                // For search results, create a GID from the barcode if available
                let offGid = envelope.gid ?? (envelope.barcode.map { "off:\($0)" } ?? "off:unknown")
                let offEnvelope = OffEnvelope(
                    gid: offGid,
                    source: envelope.source,
                    barcode: envelope.barcode,
                    fetchedAt: envelope.fetchedAt,
                    raw: offProduct
                )
                return [normalizationService.normalizeOFF(offEnvelope)]
            } catch {
                // If both fail, return empty array
                return []
            }
        }
    }

    func normalizeFdcSearchResponse(_ searchResponse: FdcSearchResponse) -> [NormalizedFood] {
        guard let foods = searchResponse.foods else {
            return []
        }

        var normalizedFoods: [NormalizedFood] = []
        for fdcFood in foods {
            // Skip foods without valid FDC ID
            guard let fdcId = fdcFood.fdcId else {
                continue
            }

            // Create unique GID for each food item
            let foodGid = "fdc:\(fdcId)"
            // Convert FdcSearchItem to FdcProduct for normalization
            let fdcProductData = FdcProduct(
                dataType: fdcFood.dataType.flatMap { FdcDataType(rawValue: $0) },
                fdcId: fdcFood.fdcId,
                description: fdcFood.description,
                publicationDate: nil,
                foodClass: nil,
                brandOwner: fdcFood.brandOwner,
                brandName: nil,
                gtinUpc: fdcFood.gtinUpc,
                ingredients: fdcFood.ingredients,
                servingSize: fdcFood.servingSize,
                servingSizeUnit: fdcFood.servingSizeUnit,
                householdServingFullText: nil,
                brandedFoodCategory: nil,
                marketCountry: nil,
                tradeChannels: nil,
                labelNutrients: fdcFood.labelNutrients,
                foodNutrients: nil,
                foodPortions: nil,
                wweiaFoodCategory: fdcFood.wweiaFoodCategory,
                inputFoods: nil,
                nutrientConversionFactors: nil
            )

            let fdcEnvelope = FdcEnvelope(
                gid: foodGid,
                source: .fdc,
                barcode: fdcFood.gtinUpc,
                fetchedAt: ISO8601DateFormatter().string(from: Date()),
                raw: fdcProductData
            )
            normalizedFoods.append(normalizationService.normalizeFDC(fdcEnvelope))
        }
        return normalizedFoods
    }

    func normalizeOffEnvelope(_ envelope: Envelope<OffReadResponse>) -> NormalizedFood {
        // Create an OffEnvelope from the OffReadResponse
        let offEnvelope = OffEnvelope(
            gid: envelope.gid,
            source: envelope.source,
            barcode: envelope.barcode,
            fetchedAt: envelope.fetchedAt,
            raw: envelope.raw.product ?? OffProduct(
                code: nil,
                productName: nil,
                brands: nil,
                quantity: nil,
                packaging: nil,
                categories: nil,
                categoriesTags: nil,
                countries: nil,
                countriesTags: nil,
                ingredientsText: nil,
                ingredients: nil,
                allergens: nil,
                allergensTags: nil,
                additivesTags: nil,
                imageURL: nil,
                imageSmallURL: nil,
                selectedImages: nil,
                nutriments: nil,
                nutritionDataPer: nil,
                servingSize: nil,
                servingQuantity: nil,
                nutriscoreGrade: nil,
                novaGroup: nil,
                ecoscoreGrade: nil,
                lang: nil,
                languageCode: nil,
                lastModifiedT: nil
            )
        )

        return normalizationService.normalizeOFF(offEnvelope)
    }

    func normalizeFdcEnvelope(_ envelope: FdcEnvelope) -> NormalizedFood {
        normalizationService.normalizeFDC(envelope)
    }
}
