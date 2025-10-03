//
//  ProxyClientParsingTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Food_Scanner
import Foundation
import Testing

enum TestError: Error {
    case missingProductData
}

@Suite("ProxyClient Parsing")
struct ProxyClientParsingTests {
    // MARK: - Sample Response Data (from worker API examples)

    // Sample FDC Branded Food (from example 3a)
    private let sampleFDCBrandedData = Data("""
    {
        "fdcId": 2451234,
        "dataType": "Branded",
        "description": "Greek Nonfat Yogurt, Plain",
        "brandOwner": "Kirkland Signature",
        "gtinUpc": "0096619123456",
        "ingredients": "Cultured pasteurized Grade A nonfat milk...",
        "servingSize": 170,
        "servingSizeUnit": "g",
        "householdServingFullText": "1 container (170g)",
        "brandedFoodCategory": "Yogurt",
        "marketCountry": "United States",
        "tradeChannels": ["Club Store"],
        "labelNutrients": {
            "calories": { "value": 90 },
            "fat": { "value": 0 },
            "saturatedFat": { "value": 0 },
            "transFat": { "value": 0 },
            "cholesterol": { "value": 5 },
            "sodium": { "value": 65 },
            "carbohydrates": { "value": 5 },
            "fiber": { "value": 0 },
            "sugars": { "value": 5 },
            "protein": { "value": 17 },
            "potassium": { "value": 240 },
            "calcium": { "value": 190 }
        },
        "foodNutrients": [
            {
                "amount": 10.0,
                "nutrient": { "id": 1003, "number": "203", "name": "Protein", "unitName": "G", "rank": 600 }
            },
            {
                "amount": 3.0,
                "nutrient": { "id": 1005, "number": "205", "name": "Carbohydrate, by difference", "unitName": "G", "rank": 1110 }
            },
            {
                "amount": 0.4,
                "nutrient": { "id": 1004, "number": "204", "name": "Total lipid (fat)", "unitName": "G", "rank": 800 }
            },
            {
                "amount": 59.0,
                "nutrient": { "id": 1008, "number": "208", "name": "Energy", "unitName": "KCAL", "rank": 300 }
            }
        ],
        "foodPortions": []
    }
    """.utf8)

    // Sample OFF Product (from example 5)
    private let sampleOFFProductData = Data("""
    {
        "status": 1,
        "code": "0885909950800",
        "product": {
            "code": "0885909950800",
            "product_name": "Crunchy Peanut Butter",
            "brands": "Example Brand",
            "quantity": "510 g",
            "packaging": "Jar",
            "categories": "Spreads, Nut butters",
            "countries": "United States",
            "ingredients_text": "Roasted peanuts, sugar, hydrogenated vegetable oils (rapeseed, cottonseed, soybean), salt.",
            "allergens": "peanuts",
            "additives_tags": ["en:e471"],
            "serving_size": "2 Tbsp (32 g)",
            "serving_quantity": 32,
            "nutrition_data_per": "serving",
            "nutriments": {
                "energy-kcal_serving": 190,
                "fat_serving": 16,
                "saturated-fat_serving": 3,
                "carbohydrates_serving": 7,
                "sugars_serving": 3,
                "fiber_serving": 2,
                "proteins_serving": 8,
                "salt_serving": 0.14,
                "salt_unit": "g",
                "energy-kcal_100g": 594,
                "fat_100g": 50,
                "saturated-fat_100g": 9.4,
                "carbohydrates_100g": 22,
                "sugars_100g": 9.4,
                "fiber_100g": 6.2,
                "proteins_100g": 25,
                "sodium_100g": 0.055,
                "sodium_unit": "g",
                "energy_unit": "kcal"
            },
            "selected_images": {
                "front": {
                    "display": { "en": "https://img.off/0885909950800/front_en.400.jpg" },
                    "small": { "en": "https://img.off/0885909950800/front_en.200.jpg" }
                },
                "nutrition": {
                    "display": { "en": "https://img.off/0885909950800/nutrition_en.400.jpg" }
                }
            },
            "nutriscore_grade": "d",
            "nova_group": 4,
            "ecoscore_grade": "c",
            "last_modified_t": 1727704000
        }
    }
    """.utf8)

    // Sample FDC Search Response (from example 2)
    private let sampleFDCSearchData = Data("""
    {
        "totalHits": 341,
        "currentPage": 1,
        "foods": [
            {
                "fdcId": 2451234,
                "dataType": "Branded",
                "description": "Greek Nonfat Yogurt, Plain",
                "brandOwner": "Kirkland Signature",
                "gtinUpc": "0096619123456",
                "ingredients": "Cultured pasteurized Grade A nonfat milk...",
                "servingSize": 170,
                "servingSizeUnit": "g",
                "householdServingFullText": "1 container (170g)",
                "labelNutrients": {
                    "calories": { "value": 90 },
                    "protein":  { "value": 17 },
                    "fat":      { "value": 0 },
                    "carbohydrates": { "value": 5 },
                    "sugars":   { "value": 5 }
                }
            },
            {
                "fdcId": 1105678,
                "dataType": "Foundation",
                "description": "Yogurt, plain, nonfat",
                "wweiaFoodCategory": {
                    "wweiaFoodCategoryCode": 1252,
                    "wweiaFoodCategoryDescription": "Yogurt"
                }
            }
        ]
    }
    """.utf8)

    // Sample Health Response (from example 1)
    private let sampleHealthData = Data("""
    {
        "isHealthy": true,
        "sources": {
            "fdc": "https://api.nal.usda.gov/fdc/v1",
            "off": "https://world.openfoodfacts.org"
        },
        "version": 1
    }
    """.utf8)

    // MARK: - Envelope Parsing Tests

    @Test
    func fDCEnvelopeParsing() throws {
        let envelopeData = Data("""
        {
            "gid": "fdc:2451234",
            "source": "fdc",
            "barcode": "0096619123456",
            "fetchedAt": "2025-09-30T18:23:45Z",
            "raw": \(String(data: sampleFDCBrandedData, encoding: .utf8) ?? "")
        }
        """.utf8)

        let envelope = try JSONDecoder().decode(FdcEnvelope.self, from: envelopeData)

        #expect(envelope.gid == "fdc:2451234")
        #expect(envelope.source == .fdc)
        #expect(envelope.barcode == "0096619123456")
        #expect(envelope.fetchedAt == "2025-09-30T18:23:45Z")

        // Test FDC food data
        let fdcFood = envelope.raw
        #expect(fdcFood.fdcId == 2_451_234)
        #expect(fdcFood.dataType == .branded)
        #expect(fdcFood.description == "Greek Nonfat Yogurt, Plain")
        #expect(fdcFood.brandOwner == "Kirkland Signature")
        #expect(fdcFood.gtinUpc == "0096619123456")
        #expect(fdcFood.servingSize == 170)
        #expect(fdcFood.servingSizeUnit == "g")
        #expect(fdcFood.householdServingFullText == "1 container (170g)")

        // Test label nutrients (per-serving)
        #expect(fdcFood.labelNutrients?.calories?.value == 90)
        #expect(fdcFood.labelNutrients?.protein?.value == 17)
        #expect(fdcFood.labelNutrients?.fat?.value == 0)

        // Test food nutrients (per-100g)
        #expect(fdcFood.foodNutrients?.count == 4)
        let proteinNutrient = fdcFood.foodNutrients?.first { $0.nutrient?.name == "Protein" }
        #expect(proteinNutrient?.amount == 10.0)
        #expect(proteinNutrient?.nutrient?.unitName == "G")
    }

    @Test
    func oFFEnvelopeParsing() throws {
        // Extract just the product data from the sample OFF response
        let fullOFFResponse = try JSONDecoder().decode([String: AnyCodable].self, from: sampleOFFProductData)
        guard let productData = fullOFFResponse["product"] else {
            throw TestError.missingProductData
        }

        let envelopeData = try Data("""
        {
            "gid": "off:0885909950800",
            "source": "off",
            "barcode": "0885909950800",
            "fetchedAt": "2025-09-30T18:26:00Z",
            "raw": \(String(data: JSONEncoder().encode(productData), encoding: .utf8) ?? "")
        }
        """.utf8)

        let envelope = try JSONDecoder().decode(OffEnvelope.self, from: envelopeData)

        #expect(envelope.gid == "off:0885909950800")
        #expect(envelope.source == .off)
        #expect(envelope.barcode == "0885909950800")
        #expect(envelope.fetchedAt == "2025-09-30T18:26:00Z")

        // Test OFF product data
        let offProduct = envelope.raw
        #expect(offProduct.code == "0885909950800")
        #expect(offProduct.productName == "Crunchy Peanut Butter")
        #expect(offProduct.brands == "Example Brand")
        #expect(offProduct.quantity == "510 g")
        #expect(offProduct.packaging == "Jar")
        #expect(offProduct.servingSize == "2 Tbsp (32 g)")
        #expect(offProduct.servingQuantity == 32)
        #expect(offProduct.nutritionDataPer == "serving")

        // Test nutriments (both per-100g and per-serving)
        #expect(offProduct.nutriments?.energyKcal100g == 594)
        #expect(offProduct.nutriments?.proteins100g == 25)
        #expect(offProduct.nutriments?.fat100g == 50)
        #expect(offProduct.nutriments?.energyKcalServing == 190)
        #expect(offProduct.nutriments?.proteinsServing == 8)
        #expect(offProduct.nutriments?.fatServing == 16)

        // Test images
        #expect(offProduct.selectedImages?.front?.display?["en"]?.absoluteString.contains("front_en.400.jpg") == true)
    }

    @Test
    func fDCSearchResponseParsing() throws {
        let searchResponse = try JSONDecoder().decode(FdcSearchResponse.self, from: sampleFDCSearchData)

        #expect(searchResponse.totalHits == 341)
        #expect(searchResponse.currentPage == 1)
        #expect(searchResponse.foods?.count == 2)

        // Test first food (Branded)
        let firstFood = searchResponse.foods?[0]
        #expect(firstFood?.fdcId == 2_451_234)
        #expect(firstFood?.dataType == "Branded")
        #expect(firstFood?.description == "Greek Nonfat Yogurt, Plain")
        #expect(firstFood?.brandOwner == "Kirkland Signature")
        #expect(firstFood?.gtinUpc == "0096619123456")

        // Test second food (Foundation)
        let secondFood = searchResponse.foods?[1]
        #expect(secondFood?.fdcId == 1_105_678)
        #expect(secondFood?.dataType == "Foundation")
        #expect(secondFood?.description == "Yogurt, plain, nonfat")
    }

    @Test
    func healthResponseParsing() throws {
        let healthResponse = try JSONDecoder().decode(ProxyHealthResponse.self, from: sampleHealthData)

        #expect(healthResponse.isHealthy == true)
        #expect(healthResponse.sources["fdc"] == "https://api.nal.usda.gov/fdc/v1")
        #expect(healthResponse.sources["off"] == "https://world.openfoodfacts.org")
        #expect(healthResponse.version == 1)
    }

    @Test
    func searchEnvelopeParsing() throws {
        // Test with FDC search data
        let fdcSearchEnvelopeData = Data("""
        {
            "gid": "fdc:2451234",
            "source": "fdc",
            "barcode": null,
            "fetchedAt": "2025-09-30T18:23:10Z",
            "raw": \(String(data: sampleFDCSearchData, encoding: .utf8) ?? "")
        }
        """.utf8)

        let fdcSearchEnvelope = try JSONDecoder().decode(Envelope<AnyCodable>.self, from: fdcSearchEnvelopeData)
        #expect(fdcSearchEnvelope.source == .fdc)
        #expect(fdcSearchEnvelope.barcode == nil)

        // Test that we can decode the search response from the raw data
        let rawData = try JSONEncoder().encode(fdcSearchEnvelope.raw)
        let searchResponse = try JSONDecoder().decode(FdcSearchResponse.self, from: rawData)
        #expect(searchResponse.totalHits == 341)
        #expect(searchResponse.foods?.count == 2)
    }

    @Test
    func genericEnvelopeParsing() throws {
        // Test with FDC data
        let fdcEnvelopeData = Data("""
        {
            "gid": "fdc:2451234",
            "source": "fdc",
            "barcode": "0096619123456",
            "fetchedAt": "2025-09-30T18:23:45Z",
            "raw": \(String(data: sampleFDCBrandedData, encoding: .utf8) ?? "")
        }
        """.utf8)

        let fdcEnvelope = try JSONDecoder().decode(Envelope<AnyCodable>.self, from: fdcEnvelopeData)
        #expect(fdcEnvelope.source == .fdc)

        // Test with OFF data
        let offEnvelopeData = Data("""
        {
            "gid": "off:0885909950800",
            "source": "off",
            "barcode": "0885909950800",
            "fetchedAt": "2025-09-30T18:26:00Z",
            "raw": \(String(data: sampleOFFProductData, encoding: .utf8) ?? "")
        }
        """.utf8)

        let offEnvelope = try JSONDecoder().decode(Envelope<AnyCodable>.self, from: offEnvelopeData)
        #expect(offEnvelope.source == .off)
    }

    @Test
    func errorResponseParsing() throws {
        // Test redirect response (updated to match actual API format)
        let redirectData = Data("""
        {
            "ok": true,
            "redirect": {
                "gid": "fdc:2451234",
                "reason": "kv_hint"
            }
        }
        """.utf8)

        let redirectResponse = try JSONDecoder().decode(ProxyRedirect.self, from: redirectData)
        #expect(redirectResponse.success == true)
        #expect(redirectResponse.isSuccessful == true) // Test computed property
        #expect(redirectResponse.redirect.gid == "fdc:2451234")
        #expect(redirectResponse.redirect.reason == "kv_hint")

        // Test error response
        let errorData = Data("""
        {
            "error": "NOT_FOUND",
            "id": "gtin:00000096619123456"
        }
        """.utf8)

        let errorResponse = try JSONDecoder().decode(ProxyErrorResponse.self, from: errorData)
        #expect(errorResponse.error == "NOT_FOUND")
        #expect(errorResponse.id == "gtin:00000096619123456")
    }

    // MARK: - Safe Decoding Tests

    @Test
    func safeDecodingWithUnknownFields() throws {
        // Test that unknown fields don't break parsing
        let envelopeWithUnknownFields = Data("""
        {
            "gid": "fdc:2451234",
            "source": "fdc",
            "barcode": "0096619123456",
            "fetchedAt": "2025-09-30T18:23:45Z",
            "unknownField": "should be ignored",
            "raw": {
                "fdcId": 2451234,
                "dataType": "Branded",
                "description": "Test Food",
                "unknownNutrientField": "should be ignored",
                "foodNutrients": []
            }
        }
        """.utf8)

        let envelope = try JSONDecoder().decode(Envelope<AnyCodable>.self, from: envelopeWithUnknownFields)
        #expect(envelope.gid == "fdc:2451234")
        #expect(envelope.source == .fdc)
    }

    @Test
    func decodingWithMissingOptionalFields() throws {
        // Test that missing optional fields don't break parsing
        let minimalEnvelope = Data("""
        {
            "gid": "fdc:2451234",
            "source": "fdc",
            "fetchedAt": "2025-09-30T18:23:45Z",
            "raw": {
                "fdcId": 2451234,
                "description": "Test Food"
            }
        }
        """.utf8)

        let envelope = try JSONDecoder().decode(Envelope<AnyCodable>.self, from: minimalEnvelope)
        #expect(envelope.gid == "fdc:2451234")
        #expect(envelope.source == .fdc)
        #expect(envelope.barcode == nil)
    }
}
