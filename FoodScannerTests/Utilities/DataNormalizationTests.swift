//
//  DataNormalizationTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
//

@testable import Food_Scanner
import XCTest

final class DataNormalizationTests: XCTestCase {
    // MARK: - Energy Conversion Tests

    func testConvertEnergyToKcal() {
        // Test kJ to kcal conversion
        XCTAssertEqual(DataNormalization.convertEnergyToKcal(418.4, fromUnit: "kJ"), 100.0, accuracy: 0.1)
        XCTAssertEqual(DataNormalization.convertEnergyToKcal(418.4, fromUnit: "kilojoule"), 100.0, accuracy: 0.1)

        // Test kcal stays kcal
        XCTAssertEqual(DataNormalization.convertEnergyToKcal(100.0, fromUnit: "kcal"), 100.0)
        XCTAssertEqual(DataNormalization.convertEnergyToKcal(100.0, fromUnit: "calorie"), 100.0)

        // Test unknown unit defaults to kcal
        XCTAssertEqual(DataNormalization.convertEnergyToKcal(100.0, fromUnit: "unknown"), 100.0)
    }

    func testConvertEnergyToKj() {
        // Test kcal to kJ conversion
        XCTAssertEqual(DataNormalization.convertEnergyToKj(100.0, fromUnit: "kcal"), 418.4, accuracy: 0.1)
        XCTAssertEqual(DataNormalization.convertEnergyToKj(100.0, fromUnit: "calorie"), 418.4, accuracy: 0.1)

        // Test kJ stays kJ
        XCTAssertEqual(DataNormalization.convertEnergyToKj(418.4, fromUnit: "kJ"), 418.4)

        // Test unknown unit defaults to kcal conversion
        XCTAssertEqual(DataNormalization.convertEnergyToKj(100.0, fromUnit: "unknown"), 418.4, accuracy: 0.1)
    }

    // MARK: - Unit Normalization Tests

    func testNormalizeUnit() {
        XCTAssertEqual(DataNormalization.normalizeUnit("g"), "g")
        XCTAssertEqual(DataNormalization.normalizeUnit(" G "), "g")
        XCTAssertEqual(DataNormalization.normalizeUnit("Gram"), "gram")
        XCTAssertEqual(DataNormalization.normalizeUnit("mg"), "mg")
        XCTAssertEqual(DataNormalization.normalizeUnit(nil), "")
    }

    func testNormalizeUnitAlias() {
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("μg"), "μg")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("mcg"), "μg")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("microgram"), "μg")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("mg"), "mg")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("milligram"), "mg")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("g"), "g")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("gram"), "g")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("kg"), "kg")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("ml"), "ml")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("l"), "L")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("liter"), "L")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("oz"), "oz")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("cup"), "cup")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("tbsp"), "tbsp")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("tsp"), "tsp")
        XCTAssertEqual(DataNormalization.normalizeUnitAlias("unknown"), "unknown")
    }

    // MARK: - String Hygiene Tests

    func testNormalizeText() {
        XCTAssertEqual(DataNormalization.normalizeText("  hello  "), "hello")
        XCTAssertEqual(DataNormalization.normalizeText("hello   world"), "hello world")
        XCTAssertEqual(DataNormalization.normalizeText(""), nil)
        XCTAssertEqual(DataNormalization.normalizeText("   "), nil)
        XCTAssertEqual(DataNormalization.normalizeText(nil), nil)
    }

    func testFallbackText() {
        XCTAssertEqual(DataNormalization.fallbackText("hello"), "hello")
        XCTAssertEqual(DataNormalization.fallbackText(""), "—")
        XCTAssertEqual(DataNormalization.fallbackText(nil), "—")
        XCTAssertEqual(DataNormalization.fallbackText("hello", fallback: "N/A"), "hello")
        XCTAssertEqual(DataNormalization.fallbackText("", fallback: "N/A"), "N/A")
    }

    // MARK: - Serving Size Tests

    func testNormalizeServingSize() {
        XCTAssertEqual(DataNormalization.normalizeServingSize(size: 100.0, unit: "g"), "100 g")
        XCTAssertEqual(DataNormalization.normalizeServingSize(size: 100.5, unit: "g"), "100.5 g")
        XCTAssertEqual(DataNormalization.normalizeServingSize(size: 100.0, unit: "ml"), "100 ml")
        XCTAssertEqual(DataNormalization.normalizeServingSize(size: nil, unit: "g"), nil)
        XCTAssertEqual(DataNormalization.normalizeServingSize(size: 100.0, unit: nil), "100 ")
    }

    func testFormatNumber() {
        XCTAssertEqual(DataNormalization.formatNumber(100.0), "100")
        XCTAssertEqual(DataNormalization.formatNumber(100.5), "100.5")
        XCTAssertEqual(DataNormalization.formatNumber(100.0), "100")
    }

    // MARK: - Nutrient Value Tests

    func testNormalizeNutrientValue() {
        let result1 = DataNormalization.normalizeNutrientValue(100.0, unit: "g")
        XCTAssertNotNil(result1)
        XCTAssertEqual(result1?.value, 100.0)
        XCTAssertEqual(result1?.unit, "g")

        let result2 = DataNormalization.normalizeNutrientValue(100.5, unit: "mg")
        XCTAssertNotNil(result2)
        XCTAssertEqual(result2?.value, 100.5)
        XCTAssertEqual(result2?.unit, "mg")

        let result3 = DataNormalization.normalizeNutrientValue(nil, unit: "g")
        XCTAssertNil(result3)
    }

    // MARK: - Brand Name Tests

    func testNormalizeBrandName() {
        XCTAssertEqual(DataNormalization.normalizeBrandName("  Coca-Cola  "), "Coca-Cola")
        XCTAssertEqual(DataNormalization.normalizeBrandName(""), nil)
        XCTAssertEqual(DataNormalization.normalizeBrandName("   "), nil)
        XCTAssertEqual(DataNormalization.normalizeBrandName(nil), nil)
    }

    func testCombineBrandNames() {
        XCTAssertEqual(
            DataNormalization.combineBrandNames(owner: "Coca-Cola Company", name: "Coca-Cola"),
            "Coca-Cola (Coca-Cola Company)"
        )
        XCTAssertEqual(DataNormalization.combineBrandNames(owner: "Coca-Cola Company", name: nil), "Coca-Cola Company")
        XCTAssertEqual(DataNormalization.combineBrandNames(owner: nil, name: "Coca-Cola"), "Coca-Cola")
        XCTAssertEqual(DataNormalization.combineBrandNames(owner: "Coca-Cola", name: "Coca-Cola"), "Coca-Cola")
        XCTAssertEqual(DataNormalization.combineBrandNames(owner: nil, name: nil), nil)
    }

    // MARK: - UPC Tests

    func testNormalizeUPC() {
        XCTAssertEqual(DataNormalization.normalizeUPC("  1234567890123  "), "1234567890123")
        XCTAssertEqual(DataNormalization.normalizeUPC(""), nil)
        XCTAssertEqual(DataNormalization.normalizeUPC(nil), nil)
    }

    // MARK: - Food Category Tests

    func testNormalizeFoodCategory() {
        XCTAssertEqual(DataNormalization.normalizeFoodCategory("  Beverages  "), "Beverages")
        XCTAssertEqual(DataNormalization.normalizeFoodCategory(""), nil)
        XCTAssertEqual(DataNormalization.normalizeFoodCategory(nil), nil)
    }

    // MARK: - Ingredients Tests

    func testNormalizeIngredients() {
        XCTAssertEqual(
            DataNormalization.normalizeIngredients("  Water, Sugar, Natural Flavors  "),
            "Water, Sugar, Natural Flavors"
        )
        XCTAssertEqual(DataNormalization.normalizeIngredients(""), nil)
        XCTAssertEqual(DataNormalization.normalizeIngredients(nil), nil)
    }
}
