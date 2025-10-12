//
//  FoodLogStore.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData

/// Actor that owns ModelContext and performs all SwiftData operations
/// Exposes value-type snapshots to prevent model leakage across actors
actor FoodLogStore {
    private let container: ModelContainer
    private let executor: any ModelExecutor
    private var context: ModelContext { executor.modelContext }

    init(container: ModelContainer) {
        self.container = container
        executor = DefaultSerialModelExecutor(
            modelContext: ModelContext(container)
        )
    }

    // MARK: - CRUD Operations for FoodEntry

    /// Add a new food entry
    func add(_ entry: FoodEntry) throws {
        context.insert(entry)
        try context.save()
    }

    /// Get all entries for a specific date
    func entries(for date: Date) throws -> [FoodEntryDTO] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let predicate = #Predicate<FoodEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay
        }

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        let entries = try context.fetch(descriptor)
        return entries.map(FoodEntryDTO.from)
    }

    /// Get entries for a specific date and meal
    func entries(for date: Date, meal: Meal) throws -> [FoodEntryDTO] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        let predicate = #Predicate<FoodEntry> { entry in
            entry.date >= startOfDay && entry.date < endOfDay && entry.meal == meal
        }

        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )

        let entries = try context.fetch(descriptor)
        return entries.map(FoodEntryDTO.from)
    }

    /// Update an existing food entry
    func update(_ entry: FoodEntry) throws {
        try context.save()
    }

    /// Delete a food entry by ID
    func delete(entryId: UUID) throws {
        let predicate = #Predicate<FoodEntry> { entry in
            entry.id == entryId
        }

        let descriptor = FetchDescriptor<FoodEntry>(predicate: predicate)
        let entries = try context.fetch(descriptor)

        for entry in entries {
            context.delete(entry)
        }

        try context.save()
    }

    // MARK: - Quick Add Operations (RecentFood)

    /// Record usage of a food item for recent/favorites tracking
    func recordUsage(foodGID: String, meal: Meal) throws {
        let predicate = #Predicate<RecentFood> { recent in
            recent.foodGID == foodGID
        }

        let descriptor = FetchDescriptor<RecentFood>(predicate: predicate)
        let existing = try context.fetch(descriptor).first

        if let existing {
            // Update existing entry
            existing.lastUsedAt = Date()
            existing.useCount += 1
        } else {
            // Create new entry
            let recentFood = RecentFood(
                foodGID: foodGID,
                lastUsedAt: Date(),
                useCount: 1,
                isFavorite: false
            )
            context.insert(recentFood)
        }

        try context.save()
    }

    /// Get recent foods sorted by score (usage count + recency)
    func recentFoods(limit: Int = 12) throws -> [RecentFoodDTO] {
        let descriptor = FetchDescriptor<RecentFood>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )

        let allRecents = try context.fetch(descriptor)
        let sorted = allRecents.sorted { $0.score > $1.score }
        let limited = Array(sorted.prefix(limit))

        return limited.map(RecentFoodDTO.from)
    }

    /// Get favorite foods
    func favorites(limit: Int = 8) throws -> [RecentFoodDTO] {
        let predicate = #Predicate<RecentFood> { recent in
            recent.isFavorite == true
        }

        let descriptor = FetchDescriptor<RecentFood>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )

        let favorites = try context.fetch(descriptor)
        let limited = Array(favorites.prefix(limit))

        return limited.map(RecentFoodDTO.from)
    }

    /// Toggle favorite status for a food item
    func toggleFavorite(foodGID: String) throws {
        let predicate = #Predicate<RecentFood> { recent in
            recent.foodGID == foodGID
        }

        let descriptor = FetchDescriptor<RecentFood>(predicate: predicate)
        let existing = try context.fetch(descriptor).first

        if let existing {
            existing.isFavorite.toggle()
        } else {
            // Create new entry as favorite
            let recentFood = RecentFood(
                foodGID: foodGID,
                lastUsedAt: Date(),
                useCount: 0,
                isFavorite: true
            )
            context.insert(recentFood)
        }

        try context.save()
    }

    /// Remove old recent food entries (older than 90 days)
    func pruneOldRecents() throws {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        let predicate = #Predicate<RecentFood> { recent in
            recent.lastUsedAt < cutoffDate
        }

        let descriptor = FetchDescriptor<RecentFood>(predicate: predicate)
        let oldRecents = try context.fetch(descriptor)

        for recent in oldRecents {
            context.delete(recent)
        }

        try context.save()
    }

    // MARK: - FoodRef Operations

    /// Upsert a FoodRef (insert or update)
    func upsertFoodRef(_ foodRef: FoodRef) throws {
        let descriptor = FetchDescriptor<FoodRef>()
        let allFoodRefs = try context.fetch(descriptor)
        let existing = allFoodRefs.first { $0.gid == foodRef.gid }

        if let existing {
            // Update existing
            existing.name = foodRef.name
            existing.brand = foodRef.brand
            existing.servingSize = foodRef.servingSize
            existing.servingSizeUnit = foodRef.servingSizeUnit
            existing.gramsPerServing = foodRef.gramsPerServing
            existing.householdUnits = foodRef.householdUnits
            existing.foodLoggingNutrients = foodRef.foodLoggingNutrients
        } else {
            // Insert new
            context.insert(foodRef)
        }

        try context.save()
    }

    /// Get a FoodRef by GID
    func foodRef(gid: String) throws -> FoodRefDTO? {
        let descriptor = FetchDescriptor<FoodRef>()
        let allFoodRefs = try context.fetch(descriptor)
        let foodRef = allFoodRefs.first { $0.gid == gid }

        return foodRef.map(FoodRefDTO.from)
    }

    // MARK: - Preferences Operations (UserFoodPrefs)

    /// Update user preferences for a specific food
    func updatePreferences(
        foodGID: String,
        unit: Unit,
        qty: Double,
        meal: Meal,
        userId: String = "default"
    ) throws {
        let descriptor = FetchDescriptor<UserFoodPrefs>()
        let allPrefs = try context.fetch(descriptor)
        let existing = allPrefs.first { $0.foodGID == foodGID && $0.userId == userId }

        if let existing {
            // Update existing preferences
            existing.defaultUnit = unit
            existing.defaultQty = qty
            existing.defaultMeal = meal
        } else {
            // Create new preferences
            let prefs = UserFoodPrefs(
                foodGID: foodGID,
                defaultUnit: unit,
                defaultQty: qty,
                defaultMeal: meal,
                userId: userId
            )
            context.insert(prefs)
        }

        try context.save()
    }

    /// Get user preferences for a specific food
    func getPreferences(foodGID: String, userId: String = "default") throws -> UserFoodPrefsDTO? {
        let descriptor = FetchDescriptor<UserFoodPrefs>()
        let allPrefs = try context.fetch(descriptor)
        let prefs = allPrefs.first { $0.foodGID == foodGID && $0.userId == userId }

        return prefs.map(UserFoodPrefsDTO.from)
    }

    /// Get all user preferences
    func getAllPreferences(userId: String = "default") throws -> [UserFoodPrefsDTO] {
        let descriptor = FetchDescriptor<UserFoodPrefs>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        let allPrefs = try context.fetch(descriptor)
        let userPrefs = allPrefs.filter { $0.userId == userId }

        return userPrefs.map(UserFoodPrefsDTO.from)
    }

    /// Delete preferences for a specific food
    func deletePreferences(foodGID: String, userId: String = "default") throws {
        let descriptor = FetchDescriptor<UserFoodPrefs>()
        let allPrefs = try context.fetch(descriptor)
        let prefsToDelete = allPrefs.filter { $0.foodGID == foodGID && $0.userId == userId }

        for prefs in prefsToDelete {
            context.delete(prefs)
        }

        try context.save()
    }
}

// MARK: - Value-type DTOs

/// Value-type snapshot of FoodEntry for cross-actor communication
struct FoodEntryDTO: Sendable, Equatable {
    let id: UUID
    let kind: EntryKind
    let name: String
    let meal: Meal
    let quantity: Double
    let unit: String
    let foodGID: String?
    let customName: String?
    let gramsResolved: Double
    let note: String?
    let snapEnergyKcal: Double?
    let snapProtein: Double?
    let snapFat: Double?
    let snapSaturatedFat: Double?
    let snapCarbs: Double?
    let snapFiber: Double?
    let snapSugars: Double?
    let snapSodium: Double?
    let snapCholesterol: Double?
    let brand: String?
    let fdcId: Int?
    let servingDescription: String
    let resolvedToBase: Double
    let baseUnit: String
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double
    let nutrientsSnapshot: [String: Double]
    let date: Date

    nonisolated static func from(_ entry: FoodEntry) -> FoodEntryDTO {
        FoodEntryDTO(
            id: entry.id,
            kind: entry.kind,
            name: entry.name,
            meal: entry.meal,
            quantity: entry.quantity,
            unit: entry.unit,
            foodGID: entry.foodGID,
            customName: entry.customName,
            gramsResolved: entry.gramsResolved ?? 0.0,
            note: entry.note,
            snapEnergyKcal: entry.snapEnergyKcal,
            snapProtein: entry.snapProtein,
            snapFat: entry.snapFat,
            snapSaturatedFat: entry.snapSaturatedFat,
            snapCarbs: entry.snapCarbs,
            snapFiber: entry.snapFiber,
            snapSugars: entry.snapSugars,
            snapSodium: entry.snapSodium,
            snapCholesterol: entry.snapCholesterol,
            brand: entry.brand,
            fdcId: entry.fdcId,
            servingDescription: entry.servingDescription,
            resolvedToBase: entry.resolvedToBase,
            baseUnit: entry.baseUnit,
            calories: entry.calories,
            protein: entry.protein,
            fat: entry.fat,
            carbs: entry.carbs,
            nutrientsSnapshot: entry.nutrientsSnapshot,
            date: entry.date
        )
    }
}

/// Value-type snapshot of RecentFood for cross-actor communication
struct RecentFoodDTO: Sendable, Equatable {
    let id: Int
    let foodGID: String
    let lastUsedAt: Date
    let useCount: Int
    let isFavorite: Bool

    nonisolated static func from(_ recent: RecentFood) -> RecentFoodDTO {
        RecentFoodDTO(
            id: recent.persistentModelID.hashValue, // Preserve model identifier
            foodGID: recent.foodGID,
            lastUsedAt: recent.lastUsedAt,
            useCount: recent.useCount,
            isFavorite: recent.isFavorite
        )
    }
}

/// Value-type snapshot of FoodRef for cross-actor communication
struct FoodRefDTO: Sendable, Equatable {
    let id: Int
    let gid: String
    let source: SourceTag
    let name: String
    let brand: String?
    let servingSize: Double?
    let servingSizeUnit: String?
    let gramsPerServing: Double?
    let householdUnits: [HouseholdUnit]?
    let foodLoggingNutrients: FoodLoggingNutrients?

    nonisolated static func from(_ foodRef: FoodRef) -> FoodRefDTO {
        FoodRefDTO(
            id: foodRef.persistentModelID.hashValue, // Preserve model identifier
            gid: foodRef.gid,
            source: foodRef.source,
            name: foodRef.name,
            brand: foodRef.brand,
            servingSize: foodRef.servingSize,
            servingSizeUnit: foodRef.servingSizeUnit,
            gramsPerServing: foodRef.gramsPerServing,
            householdUnits: foodRef.householdUnits,
            foodLoggingNutrients: foodRef.foodLoggingNutrients
        )
    }
}

/// Value-type snapshot of UserFoodPrefs for cross-actor communication
struct UserFoodPrefsDTO: Sendable, Equatable {
    let id: Int
    let userId: String
    let foodGID: String
    let defaultUnit: Unit
    let defaultQty: Double
    let defaultMeal: Meal
    let updatedAt: Date

    nonisolated static func from(_ prefs: UserFoodPrefs) -> UserFoodPrefsDTO {
        UserFoodPrefsDTO(
            id: prefs.persistentModelID.hashValue, // Preserve model identifier
            userId: prefs.userId,
            foodGID: prefs.foodGID,
            defaultUnit: prefs.defaultUnit,
            defaultQty: prefs.defaultQty,
            defaultMeal: prefs.defaultMeal,
            updatedAt: prefs.updatedAt
        )
    }
}
