//
//  FoodLogStoreTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Calry
import SwiftData
import Testing

@Suite("FoodLogStore Actor")
struct FoodLogStoreTests {
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

    // MARK: - CRUD Operations Tests

    @Test("add food entry")
    func addFoodEntry() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let entry = FoodEntry(
            kind: .catalog,
            name: "Test Food",
            meal: .breakfast,
            quantity: 100.0,
            unit: "g",
            foodGID: "fdc:123456",
            customName: nil,
            gramsResolved: 100.0,
            note: nil,
            snapEnergyKcal: 250.0,
            snapProtein: 10.0,
            snapFat: 5.0,
            snapSaturatedFat: 2.0,
            snapCarbs: 30.0,
            snapFiber: 3.0,
            snapSugars: 5.0,
            snapSodium: 200.0,
            snapCholesterol: 0.0,
            brand: "Test Brand",
            fdcId: 123_456,
            servingDescription: "100.00 g",
            resolvedToBase: 100.0,
            baseUnit: "g",
            calories: 250.0,
            protein: 10.0,
            fat: 5.0,
            carbs: 30.0,
            nutrientsSnapshot: ["calories": 250.0, "protein": 10.0]
        )

        try await store.add(entry)

        let entries = try await store.entries(for: Date())
        #expect(entries.count == 1)
        #expect(entries[0].name == "Test Food")
        #expect(entries[0].meal == .breakfast)
    }

    @Test("entries for specific date")
    func entriesForDate() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) ?? today

        // Add entry for today
        let todayEntry = FoodEntry(
            kind: .catalog,
            name: "Today Food",
            meal: .breakfast,
            quantity: 100.0,
            unit: "g",
            foodGID: "fdc:111111",
            customName: nil,
            gramsResolved: 100.0,
            note: nil,
            snapEnergyKcal: 200.0,
            snapProtein: 8.0,
            snapFat: 4.0,
            snapSaturatedFat: 1.0,
            snapCarbs: 25.0,
            snapFiber: 2.0,
            snapSugars: 4.0,
            snapSodium: 150.0,
            snapCholesterol: 0.0,
            brand: "Today Brand",
            fdcId: 111_111,
            servingDescription: "100.00 g",
            resolvedToBase: 100.0,
            baseUnit: "g",
            calories: 200.0,
            protein: 8.0,
            fat: 4.0,
            carbs: 25.0,
            nutrientsSnapshot: ["calories": 200.0]
        ).withDate(today)

        // Add entry for yesterday
        let yesterdayEntry = FoodEntry(
            kind: .catalog,
            name: "Yesterday Food",
            meal: .lunch,
            quantity: 150.0,
            unit: "g",
            foodGID: "fdc:222222",
            customName: nil,
            gramsResolved: 150.0,
            note: nil,
            snapEnergyKcal: 300.0,
            snapProtein: 12.0,
            snapFat: 6.0,
            snapSaturatedFat: 3.0,
            snapCarbs: 40.0,
            snapFiber: 4.0,
            snapSugars: 6.0,
            snapSodium: 300.0,
            snapCholesterol: 0.0,
            brand: "Yesterday Brand",
            fdcId: 222_222,
            servingDescription: "150.00 g",
            resolvedToBase: 150.0,
            baseUnit: "g",
            calories: 300.0,
            protein: 12.0,
            fat: 6.0,
            carbs: 40.0,
            nutrientsSnapshot: ["calories": 300.0]
        ).withDate(yesterday)

        try await store.add(todayEntry)
        try await store.add(yesterdayEntry)

        let todayEntries = try await store.entries(for: today)
        let yesterdayEntries = try await store.entries(for: yesterday)

        #expect(todayEntries.count == 1)
        #expect(todayEntries[0].name == "Today Food")

        #expect(yesterdayEntries.count == 1)
        #expect(yesterdayEntries[0].name == "Yesterday Food")
    }

    @Test("entries for specific meal")
    func entriesForMeal() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let today = Date()

        let breakfastEntry = FoodEntry(
            kind: .catalog,
            name: "Breakfast Food",
            meal: .breakfast,
            quantity: 100.0,
            unit: "g",
            foodGID: "fdc:333333",
            customName: nil,
            gramsResolved: 100.0,
            note: nil,
            snapEnergyKcal: 200.0,
            snapProtein: 8.0,
            snapFat: 4.0,
            snapSaturatedFat: 1.0,
            snapCarbs: 25.0,
            snapFiber: 2.0,
            snapSugars: 4.0,
            snapSodium: 150.0,
            snapCholesterol: 0.0,
            brand: "Breakfast Brand",
            fdcId: 333_333,
            servingDescription: "100.00 g",
            resolvedToBase: 100.0,
            baseUnit: "g",
            calories: 200.0,
            protein: 8.0,
            fat: 4.0,
            carbs: 25.0,
            nutrientsSnapshot: ["calories": 200.0]
        ).withDate(today)

        let lunchEntry = FoodEntry(
            kind: .catalog,
            name: "Lunch Food",
            meal: .lunch,
            quantity: 150.0,
            unit: "g",
            foodGID: "fdc:444444",
            customName: nil,
            gramsResolved: 150.0,
            note: nil,
            snapEnergyKcal: 300.0,
            snapProtein: 12.0,
            snapFat: 6.0,
            snapSaturatedFat: 3.0,
            snapCarbs: 40.0,
            snapFiber: 4.0,
            snapSugars: 6.0,
            snapSodium: 300.0,
            snapCholesterol: 0.0,
            brand: "Lunch Brand",
            fdcId: 444_444,
            servingDescription: "150.00 g",
            resolvedToBase: 150.0,
            baseUnit: "g",
            calories: 300.0,
            protein: 12.0,
            fat: 6.0,
            carbs: 40.0,
            nutrientsSnapshot: ["calories": 300.0]
        ).withDate(today)

        try await store.add(breakfastEntry)
        try await store.add(lunchEntry)

        let breakfastEntries = try await store.entries(for: today, meal: .breakfast)
        let lunchEntries = try await store.entries(for: today, meal: .lunch)

        #expect(breakfastEntries.count == 1)
        #expect(breakfastEntries[0].name == "Breakfast Food")

        #expect(lunchEntries.count == 1)
        #expect(lunchEntries[0].name == "Lunch Food")
    }

    @Test("update food entry")
    func updateFoodEntry() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let entry = FoodEntry(
            kind: .catalog,
            name: "Original Name",
            meal: .breakfast,
            quantity: 100.0,
            unit: "g",
            foodGID: "fdc:555555",
            customName: nil,
            gramsResolved: 100.0,
            note: nil,
            snapEnergyKcal: 200.0,
            snapProtein: 8.0,
            snapFat: 4.0,
            snapSaturatedFat: 1.0,
            snapCarbs: 25.0,
            snapFiber: 2.0,
            snapSugars: 4.0,
            snapSodium: 150.0,
            snapCholesterol: 0.0,
            brand: "Original Brand",
            fdcId: 555_555,
            servingDescription: "100.00 g",
            resolvedToBase: 100.0,
            baseUnit: "g",
            calories: 200.0,
            protein: 8.0,
            fat: 4.0,
            carbs: 25.0,
            nutrientsSnapshot: ["calories": 200.0]
        )

        try await store.add(entry)

        // Update the entry
        entry.name = "Updated Name"
        entry.brand = "Updated Brand"

        try await store.update(entry)

        let entries = try await store.entries(for: Date())
        #expect(entries.count == 1)
        #expect(entries[0].name == "Updated Name")
        #expect(entries[0].brand == "Updated Brand")
    }

    @Test("delete food entry")
    func deleteFoodEntry() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let entry = FoodEntry(
            kind: .catalog,
            name: "To Delete",
            meal: .breakfast,
            quantity: 100.0,
            unit: "g",
            foodGID: "fdc:666666",
            customName: nil,
            gramsResolved: 100.0,
            note: nil,
            snapEnergyKcal: 200.0,
            snapProtein: 8.0,
            snapFat: 4.0,
            snapSaturatedFat: 1.0,
            snapCarbs: 25.0,
            snapFiber: 2.0,
            snapSugars: 4.0,
            snapSodium: 150.0,
            snapCholesterol: 0.0,
            brand: "Delete Brand",
            fdcId: 666_666,
            servingDescription: "100.00 g",
            resolvedToBase: 100.0,
            baseUnit: "g",
            calories: 200.0,
            protein: 8.0,
            fat: 4.0,
            carbs: 25.0,
            nutrientsSnapshot: ["calories": 200.0]
        )

        try await store.add(entry)

        let entriesBefore = try await store.entries(for: Date())
        #expect(entriesBefore.count == 1)

        try await store.delete(entryId: entry.id)

        let entriesAfter = try await store.entries(for: Date())
        #expect(entriesAfter.isEmpty)
    }

    // MARK: - Quick Add Operations Tests

    @Test("recordUsage creates and updates RecentFood")
    func recordUsage() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // First usage
        try await store.recordUsage(foodGID: "fdc:777777", meal: .breakfast)

        let recents = try await store.recentFoods()
        #expect(recents.count == 1)
        #expect(recents[0].foodGID == "fdc:777777")
        #expect(recents[0].usageCount == 1)
        #expect(recents[0].lastMeal == .breakfast)

        // Second usage
        try await store.recordUsage(foodGID: "fdc:777777", meal: .lunch)

        let updatedRecents = try await store.recentFoods()
        #expect(updatedRecents.count == 1)
        #expect(updatedRecents[0].usageCount == 2)
        #expect(updatedRecents[0].lastMeal == .lunch)
    }

    @Test("recentFoods returns top N by score")
    func recentFoods() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Add multiple foods with different usage patterns
        try await store.recordUsage(foodGID: "fdc:111111", meal: .breakfast)
        try await store.recordUsage(foodGID: "fdc:111111", meal: .breakfast) // 2 uses

        try await store.recordUsage(foodGID: "fdc:222222", meal: .lunch) // 1 use

        try await store.recordUsage(foodGID: "fdc:333333", meal: .dinner)
        try await store.recordUsage(foodGID: "fdc:333333", meal: .dinner)
        try await store.recordUsage(foodGID: "fdc:333333", meal: .dinner) // 3 uses

        let recents = try await store.recentFoods(limit: 2)
        #expect(recents.count == 2)

        // Should be sorted by score (usage count + recency)
        #expect(recents[0].foodGID == "fdc:333333") // Highest usage
        #expect(recents[1].foodGID == "fdc:111111") // Second highest
    }

    @Test("favorites returns only isFavorite items")
    func favorites() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Add some foods
        try await store.recordUsage(foodGID: "fdc:111111", meal: .breakfast)
        try await store.recordUsage(foodGID: "fdc:222222", meal: .lunch)
        try await store.recordUsage(foodGID: "fdc:333333", meal: .dinner)

        // Mark some as favorites
        try await store.toggleFavorite(foodGID: "fdc:111111")
        try await store.toggleFavorite(foodGID: "fdc:333333")

        let favorites = try await store.favorites()
        #expect(favorites.count == 2)

        let favoriteGIDs = Set(favorites.map(\.foodGID))
        #expect(favoriteGIDs.contains("fdc:111111"))
        #expect(favoriteGIDs.contains("fdc:333333"))
        #expect(!favoriteGIDs.contains("fdc:222222"))
    }

    @Test("toggleFavorite changes flag")
    func toggleFavorite() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Add a food
        try await store.recordUsage(foodGID: "fdc:888888", meal: .breakfast)

        // Initially not favorite
        let initialFavorites = try await store.favorites()
        #expect(initialFavorites.isEmpty)

        // Toggle to favorite
        try await store.toggleFavorite(foodGID: "fdc:888888")

        let afterToggle = try await store.favorites()
        #expect(afterToggle.count == 1)
        #expect(afterToggle[0].foodGID == "fdc:888888")
        #expect(afterToggle[0].isFavorite == true)

        // Toggle back to not favorite
        try await store.toggleFavorite(foodGID: "fdc:888888")

        let afterSecondToggle = try await store.favorites()
        #expect(afterSecondToggle.isEmpty)
    }

    @Test("pruneOldRecents removes items older than 90 days")
    func pruneOldRecents() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Add a recent food
        try await store.recordUsage(foodGID: "fdc:999999", meal: .breakfast)

        let initialRecents = try await store.recentFoods()
        #expect(initialRecents.count == 1)

        // Note: In a real test, we'd need to manipulate the date
        // For now, we'll just test that the method doesn't crash
        try await store.pruneOldRecents()

        // The recent food should still be there since it's not old
        let afterPrune = try await store.recentFoods()
        #expect(afterPrune.count == 1)
    }

    // MARK: - FoodRef Operations Tests

    @Test("upsertFoodRef creates new FoodRef")
    func upsertFoodRefCreate() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let foodRef = FoodRef(
            gid: "fdc:123456",
            source: .fdc,
            name: "Test Food",
            brand: "Test Brand",
            servingSize: 100.0,
            servingSizeUnit: "g",
            gramsPerServing: 100.0,
            householdUnits: [
                HouseholdUnit(label: "1 cup", grams: 240.0)
            ],
            foodLoggingNutrients: FoodLoggingNutrients(
                energyKcal: 250.0,
                protein: 10.0,
                fat: 5.0,
                saturatedFat: 2.0,
                carbs: 30.0,
                fiber: 3.0,
                sugars: 5.0,
                addedSugars: 2.0,
                sodium: 200.0,
                cholesterol: 0.0
            )
        )

        try await store.upsertFoodRef(foodRef)

        let retrieved = try await store.foodRef(gid: "fdc:123456")
        #expect(retrieved != nil)
        #expect(retrieved?.name == "Test Food")
        #expect(retrieved?.brand == "Test Brand")
    }

    @Test("upsertFoodRef updates existing FoodRef")
    func upsertFoodRefUpdate() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let originalFoodRef = FoodRef(
            gid: "fdc:123456",
            source: .fdc,
            name: "Original Name",
            brand: "Original Brand",
            servingSize: 100.0,
            servingSizeUnit: "g",
            gramsPerServing: 100.0,
            householdUnits: nil,
            foodLoggingNutrients: nil
        )

        try await store.upsertFoodRef(originalFoodRef)

        let updatedFoodRef = FoodRef(
            gid: "fdc:123456",
            source: .fdc,
            name: "Updated Name",
            brand: "Updated Brand",
            servingSize: 150.0,
            servingSizeUnit: "g",
            gramsPerServing: 150.0,
            householdUnits: [
                HouseholdUnit(label: "1 cup", grams: 240.0)
            ],
            foodLoggingNutrients: FoodLoggingNutrients(
                energyKcal: 300.0,
                protein: 15.0,
                fat: 8.0,
                saturatedFat: 3.0,
                carbs: 40.0,
                fiber: 5.0,
                sugars: 8.0,
                addedSugars: 3.0,
                sodium: 300.0,
                cholesterol: 0.0
            )
        )

        try await store.upsertFoodRef(updatedFoodRef)

        let retrieved = try await store.foodRef(gid: "fdc:123456")
        #expect(retrieved != nil)
        #expect(retrieved?.name == "Updated Name")
        #expect(retrieved?.brand == "Updated Brand")
        #expect(retrieved?.servingSize == 150.0)
        #expect(retrieved?.gramsPerServing == 150.0)
    }

    @Test("foodRef returns correct FoodRef")
    func foodRefRetrieval() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let foodRef = FoodRef(
            gid: "fdc:555555",
            source: .fdc,
            name: "Retrieval Test",
            brand: "Retrieval Brand",
            servingSize: 200.0,
            servingSizeUnit: "g",
            gramsPerServing: 200.0,
            householdUnits: [
                HouseholdUnit(label: "1 slice", grams: 50.0)
            ],
            foodLoggingNutrients: FoodLoggingNutrients(
                energyKcal: 400.0,
                protein: 20.0,
                fat: 10.0,
                saturatedFat: 4.0,
                carbs: 50.0,
                fiber: 6.0,
                sugars: 10.0,
                addedSugars: 5.0,
                sodium: 400.0,
                cholesterol: 0.0
            )
        )

        try await store.upsertFoodRef(foodRef)

        let retrieved = try await store.foodRef(gid: "fdc:555555")
        #expect(retrieved != nil)
        #expect(retrieved?.gid == "fdc:555555")
        #expect(retrieved?.name == "Retrieval Test")
        #expect(retrieved?.brand == "Retrieval Brand")
        #expect(retrieved?.servingSize == 200.0)
        #expect(retrieved?.gramsPerServing == 200.0)
        #expect(retrieved?.householdUnits?.count == 1)
        #expect(retrieved?.foodLoggingNutrients?.energyKcal == 400.0)

        // Test non-existent GID
        let nonExistent = try await store.foodRef(gid: "fdc:999999")
        #expect(nonExistent == nil)
    }

    // MARK: - DTO Tests

    @Test("entries returns value-type snapshots")
    func entriesDTO() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        let entry = FoodEntry(
            kind: .manual,
            name: "DTO Test",
            meal: .snack,
            quantity: 50.0,
            unit: "g",
            foodGID: nil,
            customName: "DTO Test",
            gramsResolved: 50.0,
            note: "Test note",
            snapEnergyKcal: 100.0,
            snapProtein: 5.0,
            snapFat: 2.0,
            snapSaturatedFat: 1.0,
            snapCarbs: 15.0,
            snapFiber: 2.0,
            snapSugars: 3.0,
            snapSodium: 100.0,
            snapCholesterol: 0.0,
            brand: nil,
            fdcId: nil,
            servingDescription: "50.00 g",
            resolvedToBase: 50.0,
            baseUnit: "g",
            calories: 100.0,
            protein: 5.0,
            fat: 2.0,
            carbs: 15.0,
            nutrientsSnapshot: ["calories": 100.0, "protein": 5.0]
        )

        try await store.add(entry)

        let entries = try await store.entries(for: Date())
        #expect(entries.count == 1)

        let dto = entries[0]
        #expect(dto.id == entry.id)
        #expect(dto.kind == .manual)
        #expect(dto.name == "DTO Test")
        #expect(dto.meal == .snack)
        #expect(dto.quantity == 50.0)
        #expect(dto.unit == "g")
        #expect(dto.foodGID == nil)
        #expect(dto.customName == "DTO Test")
        #expect(dto.gramsResolved == 50.0)
        #expect(dto.note == "Test note")
        #expect(dto.snapEnergyKcal == 100.0)
        #expect(dto.snapProtein == 5.0)
        #expect(dto.snapFat == 2.0)
        #expect(dto.snapSaturatedFat == 1.0)
        #expect(dto.snapCarbs == 15.0)
        #expect(dto.snapFiber == 2.0)
        #expect(dto.snapSugars == 3.0)
        #expect(dto.snapSodium == 100.0)
        #expect(dto.snapCholesterol == 0.0)
        #expect(dto.brand == nil)
        #expect(dto.fdcId == nil)
        #expect(dto.servingDescription == "50.00 g")
        #expect(dto.resolvedToBase == 50.0)
        #expect(dto.baseUnit == "g")
        #expect(dto.calories == 100.0)
        #expect(dto.protein == 5.0)
        #expect(dto.fat == 2.0)
        #expect(dto.carbs == 15.0)
        #expect(dto.nutrientsSnapshot["calories"] == 100.0)
        #expect(dto.nutrientsSnapshot["protein"] == 5.0)
    }

    // MARK: - Preferences Operations Tests

    @Test("updatePreferences creates new UserFoodPrefs")
    func createPrefs() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        try await store.updatePreferences(
            foodGID: "fdc:123456",
            unit: .grams,
            qty: 150.0,
            meal: .breakfast
        )

        let prefs = try await store.getPreferences(foodGID: "fdc:123456")
        #expect(prefs != nil)
        #expect(prefs?.foodGID == "fdc:123456")
        #expect(prefs?.defaultUnit == .grams)
        #expect(prefs?.defaultQty == 150.0)
        #expect(prefs?.defaultMeal == .breakfast)
        #expect(prefs?.userId == "default")
    }

    @Test("updatePreferences updates existing prefs")
    func updatePrefs() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Create initial preferences
        try await store.updatePreferences(
            foodGID: "fdc:789012",
            unit: .serving,
            qty: 1.0,
            meal: .lunch
        )

        let initialPrefs = try await store.getPreferences(foodGID: "fdc:789012")
        #expect(initialPrefs?.defaultUnit == .serving)
        #expect(initialPrefs?.defaultQty == 1.0)
        #expect(initialPrefs?.defaultMeal == .lunch)

        // Update preferences
        try await store.updatePreferences(
            foodGID: "fdc:789012",
            unit: .milliliters,
            qty: 250.0,
            meal: .dinner
        )

        let updatedPrefs = try await store.getPreferences(foodGID: "fdc:789012")
        #expect(updatedPrefs?.defaultUnit == .milliliters)
        #expect(updatedPrefs?.defaultQty == 250.0)
        #expect(updatedPrefs?.defaultMeal == .dinner)
        #expect(updatedPrefs?.foodGID == "fdc:789012") // Same food
    }

    @Test("getPreferences returns correct prefs")
    func getPrefs() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Create preferences for multiple foods
        try await store.updatePreferences(
            foodGID: "fdc:111111",
            unit: .grams,
            qty: 100.0,
            meal: .breakfast
        )

        try await store.updatePreferences(
            foodGID: "fdc:222222",
            unit: .household(label: "1 cup"),
            qty: 1.0,
            meal: .snack
        )

        // Get specific preferences
        let prefs1 = try await store.getPreferences(foodGID: "fdc:111111")
        #expect(prefs1?.foodGID == "fdc:111111")
        #expect(prefs1?.defaultUnit == .grams)
        #expect(prefs1?.defaultQty == 100.0)
        #expect(prefs1?.defaultMeal == .breakfast)

        let prefs2 = try await store.getPreferences(foodGID: "fdc:222222")
        #expect(prefs2?.foodGID == "fdc:222222")
        #expect(prefs2?.defaultUnit == .household(label: "1 cup"))
        #expect(prefs2?.defaultQty == 1.0)
        #expect(prefs2?.defaultMeal == .snack)

        // Get non-existent preferences
        let prefs3 = try await store.getPreferences(foodGID: "fdc:999999")
        #expect(prefs3 == nil)
    }

    @Test("getAllPreferences returns all user preferences")
    func getAllPrefs() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Create preferences for multiple foods
        try await store.updatePreferences(
            foodGID: "fdc:111111",
            unit: .grams,
            qty: 100.0,
            meal: .breakfast
        )

        try await Task.sleep(for: .milliseconds(10)) // Ensure different timestamps

        try await store.updatePreferences(
            foodGID: "fdc:222222",
            unit: .serving,
            qty: 2.0,
            meal: .lunch
        )

        try await Task.sleep(for: .milliseconds(10))

        try await store.updatePreferences(
            foodGID: "fdc:333333",
            unit: .milliliters,
            qty: 200.0,
            meal: .dinner
        )

        let allPrefs = try await store.getAllPreferences()
        #expect(allPrefs.count == 3)

        // Should be sorted by updatedAt (most recent first)
        #expect(allPrefs[0].foodGID == "fdc:333333") // Most recent
        #expect(allPrefs[1].foodGID == "fdc:222222")
        #expect(allPrefs[2].foodGID == "fdc:111111") // Oldest

        // Verify all belong to default user
        for prefs in allPrefs {
            #expect(prefs.userId == "default")
        }
    }

    @Test("deletePreferences removes specific preferences")
    func deletePrefs() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Create preferences for multiple foods
        try await store.updatePreferences(
            foodGID: "fdc:111111",
            unit: .grams,
            qty: 100.0,
            meal: .breakfast
        )

        try await store.updatePreferences(
            foodGID: "fdc:222222",
            unit: .serving,
            qty: 2.0,
            meal: .lunch
        )

        let initialPrefs = try await store.getAllPreferences()
        #expect(initialPrefs.count == 2)

        // Delete one set of preferences
        try await store.deletePreferences(foodGID: "fdc:111111")

        let remainingPrefs = try await store.getAllPreferences()
        #expect(remainingPrefs.count == 1)
        #expect(remainingPrefs[0].foodGID == "fdc:222222")

        // Verify the deleted preferences are gone
        let deletedPrefs = try await store.getPreferences(foodGID: "fdc:111111")
        #expect(deletedPrefs == nil)
    }

    @Test("preferences support different users")
    func multiUserPrefs() async throws {
        let container = try createTestContainer()
        let store = FoodLogStore(container: container)

        // Create preferences for different users
        try await store.updatePreferences(
            foodGID: "fdc:111111",
            unit: .grams,
            qty: 100.0,
            meal: .breakfast,
            userId: "user1"
        )

        try await store.updatePreferences(
            foodGID: "fdc:111111",
            unit: .serving,
            qty: 2.0,
            meal: .lunch,
            userId: "user2"
        )

        // Get preferences for each user
        let user1Prefs = try await store.getPreferences(foodGID: "fdc:111111", userId: "user1")
        #expect(user1Prefs?.userId == "user1")
        #expect(user1Prefs?.defaultUnit == .grams)
        #expect(user1Prefs?.defaultQty == 100.0)
        #expect(user1Prefs?.defaultMeal == .breakfast)

        let user2Prefs = try await store.getPreferences(foodGID: "fdc:111111", userId: "user2")
        #expect(user2Prefs?.userId == "user2")
        #expect(user2Prefs?.defaultUnit == .serving)
        #expect(user2Prefs?.defaultQty == 2.0)
        #expect(user2Prefs?.defaultMeal == .lunch)

        // Default user should have no preferences
        let defaultPrefs = try await store.getPreferences(foodGID: "fdc:111111", userId: "default")
        #expect(defaultPrefs == nil)
    }
}
