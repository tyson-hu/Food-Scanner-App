//
//  FoodNormalizationServiceTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Food_Scanner
import Foundation
import Testing

@Suite("FoodNormalizationService")
@MainActor
struct FoodNormalizationServiceTests {
    private let normalizationService = FoodNormalizationServiceImpl()

    @Test
    func fDCBrandedNormalization() throws {
        // Test FDC branded food normalization
        let fdcData = Data("""
        {
            "fdcId": 2451234,
            "dataType": "Branded",
            "description": "Greek Nonfat Yogurt, Plain",
            "brandOwner": "Kirkland Signature",
            "gtinUpc": "0096619123456",
            "servingSize": 170,
            "servingSizeUnit": "g",
            "householdServingFullText": "1 container (170g)",
            "labelNutrients": {
                "calories": { "value": 90 },
                "protein": { "value": 17 }
            },
            "foodNutrients": [
                {
                    "amount": 10.0,
                    "nutrient": { "id": 1003, "name": "Protein", "unitName": "G" }
                },
                {
                    "amount": 59.0,
                    "nutrient": { "id": 1008, "name": "Energy", "unitName": "KCAL" }
                }
            ]
        }
        """.utf8)

        let fdcFood = try JSONDecoder().decode(FdcProduct.self, from: fdcData)
        let envelope = FdcEnvelope(
            gid: "fdc:2_451_234",
            source: .fdc,
            barcode: "0096619123456",
            fetchedAt: "2025-09-30T18:23:45Z",
            raw: fdcFood
        )

        let normalizedFood = normalizationService.normalizeFDC(envelope)

        #expect(normalizedFood.gid == "fdc:2_451_234")
        #expect(normalizedFood.source == .fdc)
        #expect(normalizedFood.barcode == "0096619123456")
        #expect(normalizedFood.primaryName == "Greek Nonfat Yogurt, Plain")
        #expect(normalizedFood.brand == "Kirkland Signature")

        // Test that nutrients are normalized to per-100g
        let proteinNutrient = normalizedFood.nutrients.first { $0.name == "Protein" }
        #expect(proteinNutrient?.amount == 10.0)
        #expect(proteinNutrient?.basis == .per100g)
    }

    @Test
    func oFFProductNormalization() throws {
        // Test OFF product normalization
        let offData = Data("""
        {
            "code": "0885909950800",
            "product_name": "Crunchy Peanut Butter",
            "brands": "Example Brand",
            "serving_size": "2 Tbsp (32 g)",
            "serving_quantity": 32,
            "nutrition_data_per": "serving",
            "nutriments": {
                "energy-kcal_100g": 594,
                "proteins_100g": 25,
                "fat_100g": 50,
                "energy-kcal_serving": 190,
                "proteins_serving": 8,
                "fat_serving": 16
            }
        }
        """.utf8)

        let offProduct = try JSONDecoder().decode(OffProduct.self, from: offData)
        let envelope = OffEnvelope(
            gid: "off:0885909950800",
            source: .off,
            barcode: "0885909950800",
            fetchedAt: "2025-09-30T18:26:00Z",
            raw: offProduct
        )

        let normalizedFood = normalizationService.normalizeOFF(envelope)

        #expect(normalizedFood.gid == "off:0885909950800")
        #expect(normalizedFood.source == .off)
        #expect(normalizedFood.barcode == "0885909950800")
        #expect(normalizedFood.primaryName == "Crunchy Peanut Butter")
        #expect(normalizedFood.brand == "Example Brand")

        // Test that nutrients are normalized to per-100g
        let proteinNutrient = normalizedFood.nutrients.first { $0.name == "Protein" }
        #expect(proteinNutrient?.amount == 25.0)
        #expect(proteinNutrient?.basis == .per100g)
    }
}
