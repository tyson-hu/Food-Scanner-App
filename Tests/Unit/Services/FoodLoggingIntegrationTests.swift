//
//  FoodLoggingIntegrationTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/12/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData
import Testing

@testable import Calry

@Suite("Food Logging Integration Tests")
struct FoodLoggingIntegrationTests {
    // MARK: - Setup

    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: FoodEntry.self,
            FoodRef.self,
            UserFoodPrefs.self,
            RecentFood.self,
            configurations: config
        )
        return container
    }

    // MARK: - Complete Food Logging Flow Tests

    @Test("complete food logging flow from API to persistence")
    func completeFoodLoggingFlow() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        // Step 1: Create FoodCard from API data (simulating API response)
        let foodCard = FoodCard(
            id: "fdc:123456",
            description: "Test Apple",
            provenance: FoodProvenance(source: .fdc, id: "123456"),
            serving: FoodServing(amount: 100, unit: "g"),
            per100Base: [
                FoodNutrient(name: "Energy", amount: 52, unit: "kcal"),
                FoodNutrient(name: "Protein", amount: 0.3, unit: "g"),
                FoodNutrient(name: "Fat", amount: 0.2, unit: "g"),
                FoodNutrient(name: "Carbohydrates", amount: 14, unit: "g"),
                FoodNutrient(name: "Fiber", amount: 2.4, unit: "g"),
                FoodNutrient(name: "Sugars", amount: 10.4, unit: "g"),
                FoodNutrient(name: "Sodium", amount: 1, unit: "mg")
            ],
            brand: "Test Brand",
            baseUnit: .grams,
            portions: [
                FoodPortion(
                    label: "1 medium",
                    massG: 182.0,
                    volumeMl: nil,
                    densityGPerMl: nil
                ),
                FoodPortion(
                    label: "1 cup sliced",
                    massG: 109.0,
                    volumeMl: nil,
                    densityGPerMl: nil
                )
            ]
        )

        // Step 2: Convert FoodCard to FoodRef using FoodRefBuilder
        let foodRef = FoodRefBuilder.from(foodCard: foodCard)

        // Verify FoodRef creation
        #expect(foodRef.gid == "fdc:123456")
        #expect(foodRef.source == .fdc)
        #expect(foodRef.name == "Test Apple")
        #expect(foodRef.brand == "Test Brand")
        #expect(foodRef.servingSize == 100.0)
        #expect(foodRef.servingSizeUnit == "g")
        #expect(foodRef.gramsPerServing == 100.0)
        #expect(foodRef.householdUnits?.count == 2)
        #expect(foodRef.foodLoggingNutrients?.energyKcal == 52.0)

        // Step 3: Store FoodRef in FoodLogStore
        try await repository.store.upsertFoodRef(foodRef)

        // Step 4: Create FoodEntry from FoodRef using FoodEntryBuilder
        let foodEntry = await FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: 1.5,
            unit: .serving,
            meal: .snack
        )

        // Verify FoodEntry creation
        #expect(foodEntry.kind == .catalog)
        #expect(foodEntry.name == "Test Apple")
        #expect(foodEntry.meal == .snack)
        #expect(foodEntry.quantity == 1.5)
        #expect(foodEntry.unit == "serving")
        #expect(foodEntry.foodGID == "fdc:123456")
        #expect(foodEntry.gramsResolved == 150.0) // 1.5 * 100g
        #expect(foodEntry.snapEnergyKcal == 78.0) // 52 * 1.5
        #expect(foodEntry.snapProtein == 0.45) // 0.3 * 1.5

        // Step 5: Log FoodEntry using repository
        try await repository.log(foodEntry)

        // Step 6: Record usage for recent foods
        try await repository.store.recordUsage(foodGID: "fdc:123456")

        // Step 7: Set user preferences
        try await repository.store.updatePreferences(
            foodGID: "fdc:123456",
            unit: .household(label: "1 medium"),
            qty: 1.0,
            meal: .snack
        )

        // Step 8: Verify data persistence and retrieval
        let entries = try await repository.entries(on: Date())
        #expect(entries.count == 1)
        #expect(entries.first?.name == "Test Apple")
        #expect(entries.first?.snapEnergyKcal == 78.0)

        let totals = try await repository.totals(on: Date())
        #expect(totals.calories == 78.0)
        #expect(totals.protein == 0.45)
        #expect(totals.carbs == 21.0) // 14 * 1.5

        let recentFoods = try await repository.store.recentFoods()
        #expect(recentFoods.count == 1)
        #expect(recentFoods.first?.foodGID == "fdc:123456")
        #expect(recentFoods.first?.useCount == 1)

        let preferences = try await repository.store.getPreferences(foodGID: "fdc:123456")
        #expect(preferences != nil)
        #expect(preferences?.defaultUnit == .household(label: "1 medium"))
        #expect(preferences?.defaultQty == 1.0)
        #expect(preferences?.defaultMeal == .snack)
    }

    @Test("manual food entry flow")
    func manualFoodEntryFlow() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        // Step 1: Create manual FoodEntry
        let manualEntry = FoodEntryBuilder.manual(
            name: "Homemade Sandwich",
            energyKcal: 350.0,
            meal: .lunch,
            protein: 25.0,
            fat: 15.0,
            carbs: 30.0
        )

        // Verify manual entry creation
        #expect(manualEntry.kind == .manual)
        #expect(manualEntry.name == "Homemade Sandwich")
        #expect(manualEntry.meal == .lunch)
        #expect(manualEntry.foodGID == nil)
        #expect(manualEntry.customName == "Homemade Sandwich")
        #expect(manualEntry.snapEnergyKcal == 350.0)
        #expect(manualEntry.snapProtein == 25.0)

        // Step 2: Log manual entry
        try await repository.log(manualEntry)

        // Step 3: Verify persistence
        let entries = try await repository.entries(on: Date())
        #expect(entries.count == 1)
        #expect(entries.first?.name == "Homemade Sandwich")
        #expect(entries.first?.kind == .manual)

        let totals = try await repository.totals(on: Date())
        #expect(totals.calories == 350.0)
        #expect(totals.protein == 25.0)
        #expect(totals.fat == 15.0)
        #expect(totals.carbs == 30.0)
    }

    @Test("multiple food entries with different meals")
    func multipleFoodEntriesFlow() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        // Create multiple food entries for different meals
        let breakfastEntry = FoodEntryBuilder.manual(
            name: "Oatmeal",
            energyKcal: 200.0,
            meal: .breakfast,
            protein: 8.0,
            carbs: 35.0
        )

        let lunchEntry = FoodEntryBuilder.manual(
            name: "Salad",
            energyKcal: 150.0,
            meal: .lunch,
            protein: 12.0,
            carbs: 20.0
        )

        let dinnerEntry = FoodEntryBuilder.manual(
            name: "Chicken",
            energyKcal: 300.0,
            meal: .dinner,
            protein: 35.0,
            carbs: 5.0
        )

        // Log all entries
        try await repository.log(breakfastEntry)
        try await repository.log(lunchEntry)
        try await repository.log(dinnerEntry)

        // Verify total entries
        let allEntries = try await repository.entries(on: Date())
        #expect(allEntries.count == 3)

        // Verify meal-specific filtering
        let breakfastEntries = try await repository.entries(on: Date(), forMeal: .breakfast)
        #expect(breakfastEntries.count == 1)
        #expect(breakfastEntries.first?.name == "Oatmeal")

        let lunchEntries = try await repository.entries(on: Date(), forMeal: .lunch)
        #expect(lunchEntries.count == 1)
        #expect(lunchEntries.first?.name == "Salad")

        let dinnerEntries = try await repository.entries(on: Date(), forMeal: .dinner)
        #expect(dinnerEntries.count == 1)
        #expect(dinnerEntries.first?.name == "Chicken")

        // Verify daily totals
        let totals = try await repository.totals(on: Date())
        #expect(totals.calories == 650.0) // 200 + 150 + 300
        #expect(totals.protein == 55.0) // 8 + 12 + 35
        #expect(totals.carbs == 60.0) // 35 + 20 + 5
    }

    @Test("food entry update and deletion flow")
    func foodEntryUpdateAndDeletionFlow() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        // Step 1: Create and log initial entry
        let initialEntry = FoodEntryBuilder.manual(
            name: "Test Food",
            energyKcal: 100.0,
            meal: .snack,
            protein: 5.0
        )

        try await repository.log(initialEntry)

        // Step 2: Verify initial entry
        var entries = try await repository.entries(on: Date())
        #expect(entries.count == 1)
        #expect(entries.first?.snapEnergyKcal == 100.0)

        // Step 3: Update entry
        let updatedEntry = try #require(entries.first)
        updatedEntry.name = "Updated Test Food"
        updatedEntry.snapEnergyKcal = 150.0
        updatedEntry.snapProtein = 8.0

        try await repository.update(updatedEntry)

        // Step 4: Verify update
        entries = try await repository.entries(on: Date())
        #expect(entries.count == 1)
        #expect(entries.first?.name == "Updated Test Food")
        #expect(entries.first?.snapEnergyKcal == 150.0)
        #expect(entries.first?.snapProtein == 8.0)

        // Step 5: Delete entry
        try await repository.delete(entryId: updatedEntry.id)

        // Step 6: Verify deletion
        entries = try await repository.entries(on: Date())
        #expect(entries.isEmpty)
    }

    @Test("recent foods and favorites flow")
    func recentFoodsAndFavoritesFlow() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        // Step 1: Record usage for multiple foods
        try await repository.store.recordUsage(foodGID: "fdc:111111")
        try await repository.store.recordUsage(foodGID: "fdc:222222")
        try await repository.store.recordUsage(foodGID: "fdc:333333")

        // Record additional usage for first food
        try await repository.store.recordUsage(foodGID: "fdc:111111")

        // Step 2: Verify recent foods
        let recentFoods = try await repository.store.recentFoods()
        #expect(recentFoods.count == 3)
        #expect(recentFoods.first?.foodGID == "fdc:111111") // Most used
        #expect(recentFoods.first?.useCount == 2)

        // Step 3: Toggle favorites
        try await repository.store.toggleFavorite(foodGID: "fdc:111111")
        try await repository.store.toggleFavorite(foodGID: "fdc:333333")

        // Step 4: Verify favorites
        let favorites = try await repository.store.favorites()
        #expect(favorites.count == 2)
        #expect(favorites.contains(where: { $0.foodGID == "fdc:111111" }))
        #expect(favorites.contains(where: { $0.foodGID == "fdc:333333" }))
        #expect(!favorites.contains(where: { $0.foodGID == "fdc:222222" }))
    }

    @Test("user preferences management flow")
    func userPreferencesManagementFlow() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        // Step 1: Set preferences for multiple foods
        try await repository.store.updatePreferences(
            foodGID: "fdc:111111",
            unit: .grams,
            qty: 100.0,
            meal: .breakfast
        )

        try await repository.store.updatePreferences(
            foodGID: "fdc:222222",
            unit: .household(label: "1 cup"),
            qty: 1.0,
            meal: .lunch
        )

        try await repository.store.updatePreferences(
            foodGID: "fdc:333333",
            unit: .serving,
            qty: 2.0,
            meal: .dinner
        )

        // Step 2: Verify individual preferences
        let prefs1 = try await repository.store.getPreferences(foodGID: "fdc:111111")
        #expect(prefs1?.defaultUnit == .grams)
        #expect(prefs1?.defaultQty == 100.0)
        #expect(prefs1?.defaultMeal == .breakfast)

        // Step 3: Verify all preferences
        let allPrefs = try await repository.store.getAllPreferences()
        #expect(allPrefs.count == 3)

        // Step 4: Update existing preferences
        try await repository.store.updatePreferences(
            foodGID: "fdc:111111",
            unit: .milliliters,
            qty: 250.0,
            meal: .snack
        )

        let updatedPrefs = try await repository.store.getPreferences(foodGID: "fdc:111111")
        #expect(updatedPrefs?.defaultUnit == .milliliters)
        #expect(updatedPrefs?.defaultQty == 250.0)
        #expect(updatedPrefs?.defaultMeal == .snack)

        // Step 5: Delete preferences
        try await repository.store.deletePreferences(foodGID: "fdc:222222")

        let remainingPrefs = try await repository.store.getAllPreferences()
        #expect(remainingPrefs.count == 2)
        #expect(!remainingPrefs.contains(where: { $0.foodGID == "fdc:222222" }))
    }

    @Test("nutrient calculation accuracy flow")
    func nutrientCalculationAccuracyFlow() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        // Create a food with known nutrient values
        let foodCard = FoodCard(
            id: "fdc:test123",
            description: "Test Food",
            provenance: FoodProvenance(source: .fdc, id: "test123"),
            serving: FoodServing(amount: 100, unit: "g"),
            per100Base: [
                FoodNutrient(name: "Energy", amount: 200, unit: "kcal"),
                FoodNutrient(name: "Protein", amount: 10, unit: "g"),
                FoodNutrient(name: "Fat", amount: 5, unit: "g"),
                FoodNutrient(name: "Carbohydrates", amount: 30, unit: "g"),
                FoodNutrient(name: "Fiber", amount: 5, unit: "g"),
                FoodNutrient(name: "Sugars", amount: 15, unit: "g"),
                FoodNutrient(name: "Sodium", amount: 500, unit: "mg")
            ],
            brand: nil,
            baseUnit: .grams,
            portions: []
        )

        // Convert to FoodRef and log entry
        let foodRef = FoodRefBuilder.from(foodCard: foodCard)
        try await repository.store.upsertFoodRef(foodRef)

        let foodEntry = await FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: 2.5, // 2.5 servings
            unit: .serving,
            meal: .lunch
        )

        try await repository.log(foodEntry)

        // Verify nutrient calculations are accurate
        let entries = try await repository.entries(on: Date())
        let entry = try #require(entries.first)

        #expect(entry.snapEnergyKcal == 500.0) // 200 * 2.5
        #expect(entry.snapProtein == 25.0) // 10 * 2.5
        #expect(entry.snapFat == 12.5) // 5 * 2.5
        #expect(entry.snapCarbs == 75.0) // 30 * 2.5
        #expect(entry.snapFiber == 12.5) // 5 * 2.5
        #expect(entry.snapSugars == 37.5) // 15 * 2.5
        #expect(entry.snapSodium == 1_250.0) // 500 * 2.5

        // Verify daily totals
        let totals = try await repository.totals(on: Date())
        #expect(totals.calories == 500.0)
        #expect(totals.protein == 25.0)
        #expect(totals.fat == 12.5)
        #expect(totals.carbs == 75.0)
    }

    @Test("household unit conversion flow")
    func householdUnitConversionFlow() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        // Create food with household units
        let foodCard = FoodCard(
            id: "fdc:household123",
            description: "Test Liquid",
            provenance: FoodProvenance(source: .fdc, id: "household123"),
            serving: FoodServing(amount: 100, unit: "ml"),
            per100Base: [
                FoodNutrient(name: "Energy", amount: 50, unit: "kcal"),
                FoodNutrient(name: "Protein", amount: 2, unit: "g")
            ],
            brand: nil,
            baseUnit: .milliliters,
            portions: [
                FoodPortion(
                    label: "1 cup",
                    massG: 240.0,
                    volumeMl: 240.0,
                    densityGPerMl: 1.0
                ),
                FoodPortion(
                    label: "1 tbsp",
                    massG: 15.0,
                    volumeMl: 15.0,
                    densityGPerMl: 1.0
                )
            ]
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)
        try await repository.store.upsertFoodRef(foodRef)

        // Test household unit conversion
        let foodEntry = await FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: 1.0,
            unit: .household(label: "1 cup"),
            meal: .breakfast
        )

        try await repository.log(foodEntry)

        // Verify conversion (1 cup = 240ml, so 2.4x the base serving)
        let entries = try await repository.entries(on: Date())
        let entry = try #require(entries.first)

        #expect(entry.snapEnergyKcal == 120.0) // 50 * 2.4
        #expect(entry.snapProtein == 4.8) // 2 * 2.4
        #expect(entry.gramsResolved == 240.0) // 1 cup = 240g
    }
}
