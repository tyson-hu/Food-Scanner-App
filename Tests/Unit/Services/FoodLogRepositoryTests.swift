//
//  FoodLogRepositoryTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Calry
import SwiftData
import Testing

@Suite("FoodLogRepository Enhanced")
struct FoodLogRepositoryTests {
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

    // MARK: - Basic Operations Tests

    @Test("log entry adds to store")
    func logEntry() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        let entry = FoodEntry(
            kind: .manual,
            name: "Test Food",
            meal: .breakfast,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            customName: "Test Food",
            gramsResolved: 100.0,
            note: nil,
            snapEnergyKcal: 100.0,
            snapProtein: 10.0,
            snapFat: 5.0,
            snapSaturatedFat: nil,
            snapCarbs: 15.0,
            snapFiber: nil,
            snapSugars: nil,
            snapAddedSugars: nil,
            snapSodium: nil,
            snapCholesterol: nil,
            brand: nil,
            fdcId: nil,
            servingDescription: "1 serving",
            resolvedToBase: 100.0,
            baseUnit: "g",
            calories: 100.0,
            protein: 10.0,
            fat: 5.0,
            carbs: 15.0,
            nutrientsSnapshot: ["calories": 100.0],
            date: Date()
        )

        try await repository.log(entry)

        let entries = try await repository.entries(on: Date())
        #expect(entries.count == 1)
        #expect(entries.first?.name == "Test Food")
    }

    @Test("entries by meal filtering")
    func entriesByMeal() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        let breakfastEntry = FoodEntry(
            kind: .manual,
            name: "Breakfast Food",
            meal: .breakfast,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 100,
            date: Date()
        )

        let lunchEntry = FoodEntry(
            kind: .manual,
            name: "Lunch Food",
            meal: .lunch,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 200,
            date: Date()
        )

        let dinnerEntry = FoodEntry(
            kind: .manual,
            name: "Dinner Food",
            meal: .dinner,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 300,
            date: Date()
        )

        try await repository.log(breakfastEntry)
        try await repository.log(lunchEntry)
        try await repository.log(dinnerEntry)

        let allEntries = try await repository.entries(on: Date())
        #expect(allEntries.count == 3)

        let breakfastEntries = try await repository.entries(on: Date(), forMeal: .breakfast)
        #expect(breakfastEntries.count == 1)
        #expect(breakfastEntries.first?.name == "Breakfast Food")

        let lunchEntries = try await repository.entries(on: Date(), forMeal: .lunch)
        #expect(lunchEntries.count == 1)
        #expect(lunchEntries.first?.name == "Lunch Food")

        let dinnerEntries = try await repository.entries(on: Date(), forMeal: .dinner)
        #expect(dinnerEntries.count == 1)
        #expect(dinnerEntries.first?.name == "Dinner Food")
    }

    @Test("update entry")
    func updateEntry() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        let entry = FoodEntry(
            kind: .manual,
            name: "Original Food",
            meal: .breakfast,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 100,
            date: Date()
        )

        try await repository.log(entry)

        var entries = try await repository.entries(on: Date())
        var entryToUpdate = try #require(entries.first)
        #expect(entryToUpdate.name == "Original Food")

        // Update the entry
        entryToUpdate.name = "Updated Food"
        try await repository.update(entryToUpdate.toFoodEntry())

        entries = try await repository.entries(on: Date())
        #expect(entries.count == 1)
        #expect(entries.first?.name == "Updated Food")
    }

    @Test("delete entry")
    func deleteEntry() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        let entry = FoodEntry(
            kind: .manual,
            name: "Food to Delete",
            meal: .dinner,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 100,
            date: Date()
        )

        try await repository.log(entry)

        let entriesBefore = try await repository.entries(on: Date())
        #expect(entriesBefore.count == 1)

        try await repository.delete(entryId: entry.id)

        let entriesAfter = try await repository.entries(on: Date())
        #expect(entriesAfter.isEmpty)
    }

    // MARK: - Totals Tests

    @Test("totals with basic nutrients")
    func totalsBasic() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        let entry1 = FoodEntry(
            kind: .manual,
            name: "Food 1",
            meal: .breakfast,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 100,
            calories: 100.0,
            protein: 10.0,
            fat: 5.0,
            carbs: 15.0,
            date: Date()
        )

        let entry2 = FoodEntry(
            kind: .manual,
            name: "Food 2",
            meal: .lunch,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 200,
            calories: 200.0,
            protein: 20.0,
            fat: 10.0,
            carbs: 30.0,
            date: Date()
        )

        try await repository.log(entry1)
        try await repository.log(entry2)

        let totals = try await repository.totals(on: Date())
        #expect(totals.calories == 300.0)
        #expect(totals.protein == 30.0)
        #expect(totals.fat == 15.0)
        #expect(totals.carbs == 45.0)
    }

    @Test("totals with new nutrients")
    func totalsWithNutrients() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        let entry1 = FoodEntry(
            kind: .manual,
            name: "Food 1",
            meal: .breakfast,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 100,
            calories: 100.0,
            protein: 10.0,
            fat: 5.0,
            carbs: 15.0,
            snapSaturatedFat: 2.0,
            snapFiber: 3.0,
            snapSugars: 5.0,
            snapSodium: 100.0,
            snapCholesterol: 30.0,
            date: Date()
        )

        let entry2 = FoodEntry(
            kind: .manual,
            name: "Food 2",
            meal: .lunch,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 200,
            calories: 200.0,
            protein: 20.0,
            fat: 10.0,
            carbs: 30.0,
            snapSaturatedFat: 4.0,
            snapFiber: 6.0,
            snapSugars: 10.0,
            snapSodium: 200.0,
            snapCholesterol: 60.0,
            date: Date()
        )

        try await repository.log(entry1)
        try await repository.log(entry2)

        let totals = try await repository.totals(on: Date())
        #expect(totals.calories == 300.0)
        #expect(totals.protein == 30.0)
        #expect(totals.fat == 15.0)
        #expect(totals.carbs == 45.0)
        #expect(totals.saturatedFat == 6.0)
        #expect(totals.fiber == 9.0)
        #expect(totals.sugars == 15.0)
        #expect(totals.sodium == 300.0)
        #expect(totals.cholesterol == 90.0)
    }

    @Test("totals with partial nutrients")
    func totalsPartialNutrients() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        let entry1 = FoodEntry(
            kind: .manual,
            name: "Food 1",
            meal: .breakfast,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 100,
            calories: 100.0,
            protein: 10.0,
            fat: 5.0,
            carbs: 15.0,
            snapSaturatedFat: 2.0,
            snapFiber: nil, // Missing
            snapSugars: 5.0,
            snapSodium: nil, // Missing
            snapCholesterol: 30.0,
            date: Date()
        )

        let entry2 = FoodEntry(
            kind: .manual,
            name: "Food 2",
            meal: .lunch,
            quantity: 1.0,
            unit: "serving",
            foodGID: nil,
            gramsResolved: 200,
            calories: 200.0,
            protein: 20.0,
            fat: 10.0,
            carbs: 30.0,
            snapSaturatedFat: 4.0,
            snapFiber: 6.0, // Present
            snapSugars: nil, // Missing
            snapSodium: 200.0, // Present
            snapCholesterol: nil, // Missing
            date: Date()
        )

        try await repository.log(entry1)
        try await repository.log(entry2)

        let totals = try await repository.totals(on: Date())
        #expect(totals.calories == 300.0)
        #expect(totals.protein == 30.0)
        #expect(totals.fat == 15.0)
        #expect(totals.carbs == 45.0)
        #expect(totals.saturatedFat == 6.0)
        #expect(totals.fiber == 6.0) // Only from entry2
        #expect(totals.sugars == 5.0) // Only from entry1
        #expect(totals.sodium == 200.0) // Only from entry2
        #expect(totals.cholesterol == 30.0) // Only from entry1
    }

    @Test("totals with no entries")
    func totalsNoEntries() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

        let totals = try await repository.totals(on: Date())
        #expect(totals.calories == 0.0)
        #expect(totals.protein == 0.0)
        #expect(totals.fat == 0.0)
        #expect(totals.carbs == 0.0)
        #expect(totals.saturatedFat == nil)
        #expect(totals.fiber == nil)
        #expect(totals.sugars == nil)
        #expect(totals.sodium == nil)
        #expect(totals.cholesterol == nil)
    }

    // MARK: - DTO Conversion Tests

    @Test("entries returns value-type snapshots")
    func entriesDTO() async throws {
        let container = try createTestContainer()
        let repository = FoodLogRepositorySwiftData(container: container)

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
            nutrientsSnapshot: ["calories": 100.0, "protein": 5.0],
            date: Date()
        )

        try await repository.log(entry)

        let entries = try await repository.entries(on: Date())
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
}

// Helper extension to convert DTO back to FoodEntry for update operations in tests
private extension FoodEntryDTO {
    func toFoodEntry() -> FoodEntry {
        FoodEntry(
            id: id,
            kind: kind,
            name: name,
            meal: meal,
            quantity: quantity,
            unit: unit,
            foodGID: foodGID,
            customName: customName,
            gramsResolved: gramsResolved,
            note: note,
            snapEnergyKcal: snapEnergyKcal,
            snapProtein: snapProtein,
            snapFat: snapFat,
            snapSaturatedFat: snapSaturatedFat,
            snapCarbs: snapCarbs,
            snapFiber: snapFiber,
            snapSugars: snapSugars,
            snapAddedSugars: snapAddedSugars,
            snapSodium: snapSodium,
            snapCholesterol: snapCholesterol,
            brand: brand,
            fdcId: fdcId,
            servingDescription: servingDescription,
            resolvedToBase: resolvedToBase,
            baseUnit: baseUnit,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            nutrientsSnapshot: nutrientsSnapshot,
            date: date
        )
    }
}
