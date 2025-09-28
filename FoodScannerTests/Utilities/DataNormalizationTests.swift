//
//  DataNormalizationTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
//

@testable import Food_Scanner
import Testing

@Suite("DataNormalization")
struct DataNormalizationTests {
    // MARK: - Energy Conversion Tests

    @Test
    func testConvertEnergyToKcal() async throws {
        // Test kJ to kcal conversion
        #expect(abs(DataNormalization.convertEnergyToKcal(418.4, fromUnit: "kJ") - 100.0) < 0.1)
        #expect(abs(DataNormalization.convertEnergyToKcal(418.4, fromUnit: "kilojoule") - 100.0) < 0.1)

        // Test kcal stays kcal
        #expect(DataNormalization.convertEnergyToKcal(100.0, fromUnit: "kcal") == 100.0)
        #expect(DataNormalization.convertEnergyToKcal(100.0, fromUnit: "calorie") == 100.0)

        // Test unknown unit defaults to kcal
        #expect(DataNormalization.convertEnergyToKcal(100.0, fromUnit: "unknown") == 100.0)
    }

    @Test
    func testConvertEnergyToKj() async throws {
        // Test kcal to kJ conversion
        #expect(abs(DataNormalization.convertEnergyToKj(100.0, fromUnit: "kcal") - 418.4) < 0.1)
        #expect(abs(DataNormalization.convertEnergyToKj(100.0, fromUnit: "calorie") - 418.4) < 0.1)

        // Test kJ stays kJ
        #expect(DataNormalization.convertEnergyToKj(418.4, fromUnit: "kJ") == 418.4)

        // Test unknown unit defaults to kcal conversion
        #expect(abs(DataNormalization.convertEnergyToKj(100.0, fromUnit: "unknown") - 418.4) < 0.1)
    }

    // MARK: - Unit Normalization Tests

    @Test
    func testNormalizeUnit() async throws {
        #expect(DataNormalization.normalizeUnit("g") == "g")
        #expect(DataNormalization.normalizeUnit(" G ") == "g")
        #expect(DataNormalization.normalizeUnit("Gram") == "gram")
        #expect(DataNormalization.normalizeUnit("mg") == "mg")
        #expect(DataNormalization.normalizeUnit(nil).isEmpty)
    }

    @Test
    func testNormalizeUnitAlias() async throws {
        #expect(DataNormalization.normalizeUnitAlias("μg") == "μg")
        #expect(DataNormalization.normalizeUnitAlias("mcg") == "μg")
        #expect(DataNormalization.normalizeUnitAlias("microgram") == "μg")
        #expect(DataNormalization.normalizeUnitAlias("mg") == "mg")
        #expect(DataNormalization.normalizeUnitAlias("milligram") == "mg")
        #expect(DataNormalization.normalizeUnitAlias("g") == "g")
        #expect(DataNormalization.normalizeUnitAlias("gram") == "g")
        #expect(DataNormalization.normalizeUnitAlias("kg") == "kg")
        #expect(DataNormalization.normalizeUnitAlias("ml") == "ml")
        #expect(DataNormalization.normalizeUnitAlias("l") == "L")
        #expect(DataNormalization.normalizeUnitAlias("liter") == "L")
        #expect(DataNormalization.normalizeUnitAlias("oz") == "oz")
        #expect(DataNormalization.normalizeUnitAlias("cup") == "cup")
        #expect(DataNormalization.normalizeUnitAlias("tbsp") == "tbsp")
        #expect(DataNormalization.normalizeUnitAlias("tsp") == "tsp")
        #expect(DataNormalization.normalizeUnitAlias("unknown") == "unknown")
    }

    // MARK: - String Hygiene Tests

    @Test
    func testNormalizeText() async throws {
        #expect(DataNormalization.normalizeText("  hello  ") == "hello")
        #expect(DataNormalization.normalizeText("hello   world") == "hello world")
        #expect(DataNormalization.normalizeText("") == nil)
        #expect(DataNormalization.normalizeText("   ") == nil)
        #expect(DataNormalization.normalizeText(nil) == nil)
    }

    @Test
    func testFallbackText() async throws {
        #expect(DataNormalization.fallbackText("hello") == "hello")
        #expect(DataNormalization.fallbackText("") == "—")
        #expect(DataNormalization.fallbackText(nil) == "—")
        #expect(DataNormalization.fallbackText("hello", fallback: "N/A") == "hello")
        #expect(DataNormalization.fallbackText("", fallback: "N/A") == "N/A")
    }

    // MARK: - Serving Size Tests

    @Test
    func testNormalizeServingSize() async throws {
        #expect(DataNormalization.normalizeServingSize(size: 100.0, unit: "g") == "100 g")
        #expect(DataNormalization.normalizeServingSize(size: 100.5, unit: "g") == "100.5 g")
        #expect(DataNormalization.normalizeServingSize(size: 100.0, unit: "ml") == "100 ml")
        #expect(DataNormalization.normalizeServingSize(size: nil, unit: "g") == nil)
        #expect(DataNormalization.normalizeServingSize(size: 100.0, unit: nil) == "100 ")
    }

    @Test
    func testFormatNumber() async throws {
        #expect(DataNormalization.formatNumber(100.0) == "100")
        #expect(DataNormalization.formatNumber(100.5) == "100.5")
        #expect(DataNormalization.formatNumber(100.0) == "100")
    }

    // MARK: - Nutrient Value Tests

    @Test
    func testNormalizeNutrientValue() async throws {
        let result1 = DataNormalization.normalizeNutrientValue(100.0, unit: "g")
        #expect(result1 != nil)
        #expect(result1?.value == 100.0)
        #expect(result1?.unit == "g")

        let result2 = DataNormalization.normalizeNutrientValue(100.5, unit: "mg")
        #expect(result2 != nil)
        #expect(result2?.value == 100.5)
        #expect(result2?.unit == "mg")

        let result3 = DataNormalization.normalizeNutrientValue(nil, unit: "g")
        #expect(result3 == nil)
    }

    // MARK: - Brand Name Tests

    @Test
    func testNormalizeBrandName() async throws {
        #expect(DataNormalization.normalizeBrandName("  Coca-Cola  ") == "Coca-Cola")
        #expect(DataNormalization.normalizeBrandName("") == nil)
        #expect(DataNormalization.normalizeBrandName("   ") == nil)
        #expect(DataNormalization.normalizeBrandName(nil) == nil)
    }

    @Test
    func testCombineBrandNames() async throws {
        #expect(
            DataNormalization.combineBrandNames(owner: "Coca-Cola Company", name: "Coca-Cola") ==
                "Coca-Cola (Coca-Cola Company)"
        )
        #expect(DataNormalization.combineBrandNames(owner: "Coca-Cola Company", name: nil) == "Coca-Cola Company")
        #expect(DataNormalization.combineBrandNames(owner: nil, name: "Coca-Cola") == "Coca-Cola")
        #expect(DataNormalization.combineBrandNames(owner: "Coca-Cola", name: "Coca-Cola") == "Coca-Cola")
        #expect(DataNormalization.combineBrandNames(owner: nil, name: nil) == nil)
    }

    // MARK: - UPC Tests

    @Test
    func testNormalizeUPC() async throws {
        #expect(DataNormalization.normalizeUPC("  1234567890123  ") == "1234567890123")
        #expect(DataNormalization.normalizeUPC("") == nil)
        #expect(DataNormalization.normalizeUPC(nil) == nil)
    }

    // MARK: - Food Category Tests

    @Test
    func testNormalizeFoodCategory() async throws {
        #expect(DataNormalization.normalizeFoodCategory("  Beverages  ") == "Beverages")
        #expect(DataNormalization.normalizeFoodCategory("") == nil)
        #expect(DataNormalization.normalizeFoodCategory(nil) == nil)
    }

    // MARK: - Ingredients Tests

    @Test
    func testNormalizeIngredients() async throws {
        #expect(
            DataNormalization.normalizeIngredients("  Water, Sugar, Natural Flavors  ") ==
                "Water, Sugar, Natural Flavors"
        )
        #expect(DataNormalization.normalizeIngredients("") == nil)
        #expect(DataNormalization.normalizeIngredients(nil) == nil)
    }
}
