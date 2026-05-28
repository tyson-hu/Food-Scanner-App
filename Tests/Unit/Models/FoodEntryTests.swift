//
//  FoodEntryTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData
import Testing

@testable import Calry

@Suite("FoodEntry Enhanced Model")
struct FoodEntryTests {
    @Test("catalog kind with foodGID")
    func catalogEntry() throws {
        let entry = FoodEntry(
            kind: .catalog,
            name: "Apple",
            meal: .breakfast,
            quantity: 1.0,
            unit: "serving",
            foodGID: "fdc:12345",
            gramsResolved: 150.0,
            snapEnergyKcal: 80.0,
            snapProtein: 0.3
        )

        #expect(entry.kind == .catalog)
        #expect(entry.name == "Apple")
        #expect(entry.meal == .breakfast)
        #expect(entry.foodGID == "fdc:12345")
        #expect(entry.gramsResolved == 150.0)
        #expect(entry.snapEnergyKcal == 80.0)
        #expect(entry.snapProtein == 0.3)
        #expect(entry.customName == nil)
        #expect(entry.note == nil)
    }

    @Test("manual kind with customName")
    func manualEntry() throws {
        let entry = FoodEntry(
            kind: .manual,
            name: "Custom Food",
            meal: .dinner,
            quantity: 2.0,
            unit: "cups",
            customName: "Homemade Soup",
            note: "Made with fresh vegetables",
            snapEnergyKcal: 120.0,
            snapProtein: 5.0,
            snapFat: 3.0
        )

        #expect(entry.kind == .manual)
        #expect(entry.name == "Custom Food")
        #expect(entry.meal == .dinner)
        #expect(entry.customName == "Homemade Soup")
        #expect(entry.note == "Made with fresh vegetables")
        #expect(entry.foodGID == nil)
        #expect(entry.snapEnergyKcal == 120.0)
        #expect(entry.snapProtein == 5.0)
        #expect(entry.snapFat == 3.0)
    }

    @Test("meal type assignment")
    func mealAssignment() throws {
        let breakfast = FoodEntry(kind: .catalog, name: "Toast", meal: .breakfast)
        let lunch = FoodEntry(kind: .catalog, name: "Sandwich", meal: .lunch)
        let dinner = FoodEntry(kind: .catalog, name: "Pasta", meal: .dinner)
        let snack = FoodEntry(kind: .catalog, name: "Chips", meal: .snack)

        #expect(breakfast.meal == .breakfast)
        #expect(lunch.meal == .lunch)
        #expect(dinner.meal == .dinner)
        #expect(snack.meal == .snack)
    }

    @Test("gramsResolved calculation")
    func gramsResolution() throws {
        let entryWithGrams = FoodEntry(
            kind: .catalog,
            name: "Banana",
            gramsResolved: 120.0
        )

        let entryWithoutGrams = FoodEntry(
            kind: .manual,
            name: "Unknown Food"
        )

        #expect(entryWithGrams.gramsResolved == 120.0)
        #expect(entryWithoutGrams.gramsResolved == nil)
    }

    @Test("snapshot nutrients nil vs zero")
    func snapshotNutrients() throws {
        // Test with nil values (missing data)
        let nilNutrients = FoodEntry(
            kind: .catalog,
            name: "Food with Missing Data"
        )

        #expect(nilNutrients.snapEnergyKcal == nil)
        #expect(nilNutrients.snapProtein == nil)
        #expect(nilNutrients.snapFat == nil)
        #expect(nilNutrients.snapCarbs == nil)

        // Test with zero values (explicit zero)
        let zeroNutrients = FoodEntry(
            kind: .catalog,
            name: "Zero Calorie Food",
            snapEnergyKcal: 0.0,
            snapProtein: 0.0,
            snapFat: 0.0,
            snapCarbs: 0.0
        )

        #expect(zeroNutrients.snapEnergyKcal == 0.0)
        #expect(zeroNutrients.snapProtein == 0.0)
        #expect(zeroNutrients.snapFat == 0.0)
        #expect(zeroNutrients.snapCarbs == 0.0)

        // Test with mixed nil and zero
        let mixedNutrients = FoodEntry(
            kind: .catalog,
            name: "Mixed Data Food",
            snapEnergyKcal: 100.0,
            snapProtein: nil,
            snapFat: 0.0,
            snapCarbs: nil
        )

        #expect(mixedNutrients.snapEnergyKcal == 100.0)
        #expect(mixedNutrients.snapProtein == nil)
        #expect(mixedNutrients.snapFat == 0.0)
        #expect(mixedNutrients.snapCarbs == nil)
    }

    @Test("backward compatibility with existing fields")
    func backwardCompatibility() throws {
        // Test legacy initializer still works
        let legacyEntry = FoodEntry(
            name: "Legacy Food",
            calories: 200.0,
            protein: 10.0,
            fat: 5.0,
            carbs: 30.0,
            brand: "Generic Brand",
            fdcId: 12_345,
            quantity: 1.5,
            unit: "serving"
        )

        #expect(legacyEntry.name == "Legacy Food")
        #expect(legacyEntry.calories == 200.0)
        #expect(legacyEntry.protein == 10.0)
        #expect(legacyEntry.fat == 5.0)
        #expect(legacyEntry.carbs == 30.0)
        #expect(legacyEntry.brand == "Generic Brand")
        #expect(legacyEntry.fdcId == 12_345)
        #expect(legacyEntry.quantity == 1.5)
        #expect(legacyEntry.unit == "serving")

        // Verify new fields have defaults
        #expect(legacyEntry.kind == .catalog)
        #expect(legacyEntry.meal == .lunch)
        #expect(legacyEntry.foodGID == nil)
        #expect(legacyEntry.customName == nil)
        #expect(legacyEntry.gramsResolved == nil)
        #expect(legacyEntry.note == nil)

        // Verify snapshot nutrients are nil by default
        #expect(legacyEntry.snapEnergyKcal == nil)
        #expect(legacyEntry.snapProtein == nil)
        #expect(legacyEntry.snapFat == nil)
        #expect(legacyEntry.snapCarbs == nil)
    }

    @Test("enhanced initializer with all snapshot nutrients")
    func enhancedInitializerWithAllNutrients() throws {
        let entry = FoodEntry(
            kind: .catalog,
            name: "Complete Food",
            meal: .lunch,
            quantity: 1.0,
            unit: "serving",
            foodGID: "fdc:67890",
            gramsResolved: 200.0,
            note: "Test entry",
            snapEnergyKcal: 250.0,
            snapProtein: 15.0,
            snapFat: 10.0,
            snapSaturatedFat: 3.0,
            snapCarbs: 35.0,
            snapFiber: 5.0,
            snapSugars: 8.0,
            snapSodium: 400.0,
            snapCholesterol: 20.0
        )

        #expect(entry.kind == .catalog)
        #expect(entry.name == "Complete Food")
        #expect(entry.meal == .lunch)
        #expect(entry.foodGID == "fdc:67890")
        #expect(entry.gramsResolved == 200.0)
        #expect(entry.note == "Test entry")

        // Verify all snapshot nutrients
        #expect(entry.snapEnergyKcal == 250.0)
        #expect(entry.snapProtein == 15.0)
        #expect(entry.snapFat == 10.0)
        #expect(entry.snapSaturatedFat == 3.0)
        #expect(entry.snapCarbs == 35.0)
        #expect(entry.snapFiber == 5.0)
        #expect(entry.snapSugars == 8.0)
        #expect(entry.snapSodium == 400.0)
        #expect(entry.snapCholesterol == 20.0)
    }

    @Test("default values for new fields")
    func defaultValues() throws {
        let entry = FoodEntry(kind: .manual, name: "Minimal Entry")

        #expect(entry.kind == .manual)
        #expect(entry.name == "Minimal Entry")
        #expect(entry.meal == .lunch) // Default meal
        #expect(entry.quantity == 1.0) // Default quantity
        #expect(entry.unit == "serving") // Default unit
        #expect(entry.foodGID == nil)
        #expect(entry.customName == nil)
        #expect(entry.gramsResolved == nil)
        #expect(entry.note == nil)

        // All snapshot nutrients should be nil by default
        #expect(entry.snapEnergyKcal == nil)
        #expect(entry.snapProtein == nil)
        #expect(entry.snapFat == nil)
        #expect(entry.snapSaturatedFat == nil)
        #expect(entry.snapCarbs == nil)
        #expect(entry.snapFiber == nil)
        #expect(entry.snapSugars == nil)
        #expect(entry.snapSodium == nil)
        #expect(entry.snapCholesterol == nil)
    }
}
