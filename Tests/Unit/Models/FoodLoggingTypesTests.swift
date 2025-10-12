//
//  FoodLoggingTypesTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Testing

@testable import Calry

@Suite("FoodLogging Types")
struct FoodLoggingTypesTests {
    @Test("Unit enum codable roundtrip")
    func unitEnumCodable() throws {
        // Test basic units
        let basicUnits: [Unit] = [.grams, .milliliters, .serving]
        for unit in basicUnits {
            let encoded = try JSONEncoder().encode(unit)
            let decoded = try JSONDecoder().decode(Unit.self, from: encoded)
            #expect(decoded == unit)
        }

        // Test household unit with label
        let householdUnit = Unit.household(label: "1 can")
        let encoded = try JSONEncoder().encode(householdUnit)
        let decoded = try JSONDecoder().decode(Unit.self, from: encoded)
        #expect(decoded == householdUnit)

        if case let .household(label) = decoded {
            #expect(label == "1 can")
        } else {
            Issue.record("Expected household unit")
        }
    }

    @Test("Unit household with labels")
    func unitHousehold() throws {
        let labels = ["1 can", "1 slice", "1 cup", "1 tablespoon"]

        for label in labels {
            let unit = Unit.household(label: label)
            #expect(unit.displayName == label)

            // Test equality
            let sameUnit = Unit.household(label: label)
            #expect(unit == sameUnit)

            // Test hash
            #expect(unit.hashValue == sameUnit.hashValue)
        }
    }

    @Test("Meal enum cases and raw values")
    func mealEnum() throws {
        let expectedCases: [(Meal, String)] = [
            (.breakfast, "breakfast"),
            (.lunch, "lunch"),
            (.dinner, "dinner"),
            (.snack, "snack")
        ]

        for (meal, expectedRawValue) in expectedCases {
            #expect(meal.rawValue == expectedRawValue)

            // Test creation from raw value
            let createdMeal = Meal(rawValue: expectedRawValue)
            #expect(createdMeal == meal)
        }

        // Test CaseIterable
        let allCases = Meal.allCases
        #expect(allCases.count == 4)
        #expect(allCases.contains(.breakfast))
        #expect(allCases.contains(.lunch))
        #expect(allCases.contains(.dinner))
        #expect(allCases.contains(.snack))
    }

    @Test("EntryKind cases")
    func entryKind() throws {
        let expectedCases: [(EntryKind, String)] = [
            (.catalog, "catalog"),
            (.manual, "manual")
        ]

        for (kind, expectedRawValue) in expectedCases {
            #expect(kind.rawValue == expectedRawValue)

            // Test creation from raw value
            let createdKind = EntryKind(rawValue: expectedRawValue)
            #expect(createdKind == kind)
        }
    }

    @Test("HouseholdUnit init and equality")
    func householdUnit() throws {
        let unit1 = HouseholdUnit(label: "1 can", grams: 150.0)
        let unit2 = HouseholdUnit(label: "1 can", grams: 150.0)
        let unit3 = HouseholdUnit(label: "1 slice", grams: 150.0)
        let unit4 = HouseholdUnit(label: "1 can", grams: 200.0)

        // Test equality
        #expect(unit1 == unit2)
        #expect(unit1 != unit3)
        #expect(unit1 != unit4)

        // Test hash
        #expect(unit1.hashValue == unit2.hashValue)
        #expect(unit1.hashValue != unit3.hashValue)
        #expect(unit1.hashValue != unit4.hashValue)

        // Test properties
        #expect(unit1.label == "1 can")
        #expect(unit1.grams == 150.0)
    }

    @Test("FoodLoggingNutrients nil vs zero distinction")
    func foodLoggingNutrientsNilVsZero() throws {
        // Test with nil values
        let nilNutrients = FoodLoggingNutrients()
        #expect(nilNutrients.energyKcal == nil)
        #expect(nilNutrients.protein == nil)
        #expect(nilNutrients.fat == nil)

        // Test with zero values
        let zeroNutrients = FoodLoggingNutrients(
            energyKcal: 0.0,
            protein: 0.0,
            fat: 0.0
        )
        #expect(zeroNutrients.energyKcal == 0.0)
        #expect(zeroNutrients.protein == 0.0)
        #expect(zeroNutrients.fat == 0.0)

        // Test with mixed nil and zero
        let mixedNutrients = FoodLoggingNutrients(
            energyKcal: 100.0,
            protein: nil,
            fat: 0.0,
            carbs: nil
        )
        #expect(mixedNutrients.energyKcal == 100.0)
        #expect(mixedNutrients.protein == nil)
        #expect(mixedNutrients.fat == 0.0)
        #expect(mixedNutrients.carbs == nil)

        // Test equality
        let sameNilNutrients = FoodLoggingNutrients()
        #expect(nilNutrients == sameNilNutrients)

        let sameZeroNutrients = FoodLoggingNutrients(
            energyKcal: 0.0,
            protein: 0.0,
            fat: 0.0
        )
        #expect(zeroNutrients == sameZeroNutrients)

        // Test inequality
        #expect(nilNutrients != zeroNutrients)
    }
}
