//
//  LoggedFoodRepositorySwiftData.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData

final class FoodLogRepositorySwiftData: FoodLogRepository {
    let store: FoodLogStore

    init(container: ModelContainer) {
        store = FoodLogStore(container: container)
    }

    init(store: FoodLogStore) {
        self.store = store
    }

    func log(_ entry: FoodEntry) async throws {
        // Convert FoodEntry to DTO to avoid actor isolation issues
        let dto = FoodEntryDTO.from(entry)
        // Pass the DTO directly to the store instead of converting back to FoodEntry
        try await store.add(dto)
    }

    func entries(on day: Date) async throws -> [FoodEntryDTO] {
        try await store.entries(for: day)
    }

    func entries(on day: Date, forMeal meal: Meal) async throws -> [FoodEntryDTO] {
        try await store.entries(for: day, meal: meal)
    }

    func totals(on day: Date) async throws -> DayTotals {
        let items = try await entries(on: day)
        return items.reduce(DayTotals(
            calories: 0,
            protein: 0,
            fat: 0,
            saturatedFat: nil,
            carbs: 0,
            fiber: nil,
            sugars: nil,
            addedSugars: nil,
            sodium: nil,
            cholesterol: nil
        )) { acc, entry in
            DayTotals(
                calories: acc.calories + entry.calories,
                protein: acc.protein + entry.protein,
                fat: acc.fat + entry.fat,
                saturatedFat: acc.saturatedFat.map { $0 + (entry.snapSaturatedFat ?? 0) } ?? entry.snapSaturatedFat,
                carbs: acc.carbs + entry.carbs,
                fiber: acc.fiber.map { $0 + (entry.snapFiber ?? 0) } ?? entry.snapFiber,
                sugars: acc.sugars.map { $0 + (entry.snapSugars ?? 0) } ?? entry.snapSugars,
                addedSugars: acc.addedSugars.map { $0 + (entry.snapAddedSugars ?? 0) } ?? entry.snapAddedSugars,
                sodium: acc.sodium.map { $0 + (entry.snapSodium ?? 0) } ?? entry.snapSodium,
                cholesterol: acc.cholesterol.map { $0 + (entry.snapCholesterol ?? 0) } ?? entry.snapCholesterol
            )
        }
    }

    func update(_ entry: FoodEntry) async throws {
        // Convert FoodEntry to DTO to avoid actor isolation issues
        let dto = FoodEntryDTO.from(entry)
        // Pass the DTO directly to the store instead of converting back to FoodEntry
        try await store.update(dto)
    }

    func delete(entryId: UUID) async throws {
        try await store.delete(entryId: entryId)
    }
}
