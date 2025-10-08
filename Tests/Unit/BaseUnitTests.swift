//
//  BaseUnitTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Food_Scanner
import Testing

struct BaseUnitTests {
    // MARK: - BaseUnit Tests

    @Test func baseUnitDisplayNames() {
        #expect(BaseUnit.grams.displayName == "g")
        #expect(BaseUnit.milliliters.displayName == "ml")
    }

    @Test func baseUnitPer100DisplayNames() {
        #expect(BaseUnit.grams.per100DisplayName == "per 100 g")
        #expect(BaseUnit.milliliters.per100DisplayName == "per 100 ml")
    }

    // MARK: - FoodEntry Base Unit Tests

    @Test func foodEntryBaseUnitDetermination() {
        // Test volume units → ml
        let volumeUnits = [
            "ml",
            "milliliter",
            "milliliters",
            "mlt",
            "l",
            "liter",
            "liters",
            "fl oz",
            "fluid ounce",
            "fluid ounces"
        ]
        for unit in volumeUnits {
            let baseUnit = FoodEntryBuilder.determineBaseUnit(from: unit)
            #expect(baseUnit == "ml", "Unit '\(unit)' should map to ml")
        }

        // Test mass units → g
        let massUnits = [
            "g",
            "gram",
            "grams",
            "kg",
            "kilogram",
            "kilograms",
            "oz",
            "ounce",
            "ounces",
            "lb",
            "pound",
            "pounds"
        ]
        for unit in massUnits {
            let baseUnit = FoodEntryBuilder.determineBaseUnit(from: unit)
            #expect(baseUnit == "g", "Unit '\(unit)' should map to g")
        }

        // Test nil → g
        let nilBaseUnit = FoodEntryBuilder.determineBaseUnit(from: nil)
        #expect(nilBaseUnit == "g", "Nil unit should default to g")
    }

    @Test func foodEntryResolvedQuantityCalculation() {
        // Test with serving size in grams
        let resolvedGrams = FoodEntryBuilder.calculateResolvedQuantity(
            quantity: 2.0,
            servingSize: 150.0,
            servingSizeUnit: "g",
            baseUnit: "g"
        )
        #expect(resolvedGrams == 300.0, "2 servings of 150g should equal 300g")

        // Test with serving size in ml
        let resolvedMl = FoodEntryBuilder.calculateResolvedQuantity(
            quantity: 1.5,
            servingSize: 250.0,
            servingSizeUnit: "ml",
            baseUnit: "ml"
        )
        #expect(resolvedMl == 375.0, "1.5 servings of 250ml should equal 375ml")

        // Test with no serving size (default to 100)
        let resolvedDefault = FoodEntryBuilder.calculateResolvedQuantity(
            quantity: 2.0,
            servingSize: nil,
            servingSizeUnit: nil,
            baseUnit: "g"
        )
        #expect(resolvedDefault == 200.0, "2 servings with no size should default to 200g")
    }

    @Test func foodEntryUnitConversion() {
        // Test gram conversions
        #expect(FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "g", targetBaseUnit: "g") == 1.0)
        #expect(FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "kg", targetBaseUnit: "g") == 1_000.0)
        #expect(FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "oz", targetBaseUnit: "g") == 28.3495)

        // Test ml conversions
        #expect(FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "ml", targetBaseUnit: "ml") == 1.0)
        #expect(FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "l", targetBaseUnit: "ml") == 1_000.0)
        #expect(FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "fl oz", targetBaseUnit: "ml") == 29.5735)

        // Test volume to grams (approximate for water)
        #expect(FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "ml", targetBaseUnit: "g") == 1.0)
        #expect(FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "l", targetBaseUnit: "g") == 1_000.0)
    }

    // MARK: - FoodCard Tests

    @Test func foodMinimalCardWithBaseUnit() {
        let nutrients = [
            FoodNutrient(id: 1_008, name: "Energy", unit: "kcal", amount: 42.0, basis: .per100Base),
            FoodNutrient(id: 1_003, name: "Protein", unit: "g", amount: 0.0, basis: .per100Base)
        ]

        let portions = [
            FoodPortion(label: "can", amount: 1.0, unit: "can", household: "1 can", massG: 368.0, volMl: 355.0)
        ]

        let foodCard = FoodCard(
            id: "fdc:123456",
            kind: .branded,
            code: "1234567890123",
            description: "Coca-Cola",
            brand: "Coke",
            baseUnit: .milliliters,
            per100Base: nutrients,
            serving: FoodServing(amount: 355.0, unit: "ml", household: "1 can"),
            portions: portions,
            densityGPerMl: 1.037,
            nutrients: nutrients, // legacy field
            provenance: FoodProvenance(source: .fdc, id: "fdc:123456", fetchedAt: "2025-09-30T12:00:00Z")
        )

        #expect(foodCard.baseUnit == .milliliters)
        #expect(foodCard.baseUnit.per100DisplayName == "per 100 ml")
        #expect(foodCard.per100Base.count == 2)
        #expect(foodCard.densityGPerMl == 1.037)
        #expect(foodCard.portions?.first?.massG == 368.0)
        #expect(foodCard.portions?.first?.volMl == 355.0)
    }

    // MARK: - FoodEntry Creation Tests

    @Test func foodEntryFromFoodCard() {
        let nutrients = [
            FoodNutrient(id: 1_008, name: "Energy", unit: "kcal", amount: 42.0, basis: .per100Base),
            FoodNutrient(id: 1_003, name: "Protein", unit: "g", amount: 0.0, basis: .per100Base)
        ]

        let foodCard = FoodCard(
            id: "fdc:123456",
            kind: .branded,
            code: "1234567890123",
            description: "Coca-Cola",
            brand: "Coke",
            baseUnit: .milliliters,
            per100Base: nutrients,
            serving: FoodServing(amount: 355.0, unit: "ml", household: "1 can"),
            portions: nil,
            densityGPerMl: nil,
            nutrients: nutrients,
            provenance: FoodProvenance(source: .fdc, id: "fdc:123456", fetchedAt: "2025-09-30T12:00:00Z")
        )

        let foodEntry = FoodEntryBuilder.from(foodCard: foodCard, multiplier: 1.0)

        #expect(foodEntry.baseUnit == "ml")
        #expect(foodEntry.resolvedToBase == 355.0) // 1 serving of 355ml
        #expect(foodEntry.calories == 42.0 * 3.55) // 42 kcal per 100ml * 3.55 servings
        #expect(foodEntry.nutrientsSnapshot["calories"] == 42.0 * 3.55)
    }

    // MARK: - Edge Cases

    @Test func unknownUnitHandling() {
        let unknownBaseUnit = FoodEntryBuilder.determineBaseUnit(from: "unknown_unit")
        #expect(unknownBaseUnit == "g", "Unknown units should default to grams")

        let unknownConversion = FoodEntryBuilder.convertToBaseUnit(amount: 1.0, unit: "unknown", targetBaseUnit: "g")
        #expect(unknownConversion == 1.0, "Unknown units should return the amount as-is")
    }

    @Test func zeroServingSize() {
        let resolvedZero = FoodEntryBuilder.calculateResolvedQuantity(
            quantity: 2.0,
            servingSize: 0.0,
            servingSizeUnit: "g",
            baseUnit: "g"
        )
        #expect(resolvedZero == 0.0, "Zero serving size should result in zero resolved quantity")
    }

    @Test func largeQuantities() {
        // Test with large containers (2L bottle)
        let resolvedLarge = FoodEntryBuilder.calculateResolvedQuantity(
            quantity: 1.0,
            servingSize: 2_000.0,
            servingSizeUnit: "ml",
            baseUnit: "ml"
        )
        #expect(resolvedLarge == 2_000.0, "1 serving of 2000ml should equal 2000ml")
    }

    @Test func mLTUnitSupport() {
        // Test that MLT unit is recognized as a volume unit
        let baseUnit = FoodEntryBuilder.determineBaseUnit(from: "MLT")
        #expect(baseUnit == "ml", "MLT should be recognized as a volume unit (ml)")

        // Test unit conversion for MLT
        let converted = FoodEntryBuilder.convertToBaseUnit(amount: 222.0, unit: "MLT", targetBaseUnit: "ml")
        #expect(converted == 222.0, "MLT should convert 1:1 to ml")

        // Test resolved quantity calculation with MLT
        let resolved = FoodEntryBuilder.calculateResolvedQuantity(
            quantity: 1.0,
            servingSize: 222.0,
            servingSizeUnit: "MLT",
            baseUnit: "ml"
        )
        #expect(resolved == 222.0, "1 serving of 222 MLT should equal 222ml")
    }
}
