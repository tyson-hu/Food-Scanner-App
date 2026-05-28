//
//  TodayViewModel.swift
//  Calry
//
//  Created by Tyson Hu on 9/19/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class TodayViewModel {
    let repository: FoodLogRepository
    let store: FoodLogStore

    var currentDate = Date()
    var entries: [FoodEntryDTO] = []
    var totals = DayTotals(calories: 0, protein: 0, fat: 0, carbs: 0)
    var isLoading = false
    var error: String?
    var activeSheet: SheetRoute?

    // Computed properties for meal grouping
    var breakfastEntries: [FoodEntryDTO] {
        entries.filter { $0.meal == .breakfast }
    }

    var lunchEntries: [FoodEntryDTO] {
        entries.filter { $0.meal == .lunch }
    }

    var dinnerEntries: [FoodEntryDTO] {
        entries.filter { $0.meal == .dinner }
    }

    var snackEntries: [FoodEntryDTO] {
        entries.filter { $0.meal == .snack }
    }

    // Quick Add properties
    var recentFoods: [RecentFoodDTO] = []
    var favoriteFoods: [RecentFoodDTO] = []
    var foodNames: [String: String] = [:]

    init(repository: FoodLogRepository, store: FoodLogStore) {
        self.repository = repository
        self.store = store
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            entries = try await repository.entries(on: currentDate)
            totals = try await repository.totals(on: currentDate)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func openSearch(forMeal meal: Meal) {
        activeSheet = .search(meal: meal, onSelect: { [weak self] gid in
            self?.handleSearchSelection(gid, meal: meal)
        })
    }

    private func handleSearchSelection(_ gid: String, meal: Meal) {
        activeSheet = .portion(foodGID: gid, meal: meal)
    }

    func editEntry(_ id: UUID) {
        activeSheet = .editEntry(entryId: id)
    }

    func deleteEntry(_ id: UUID) async {
        do {
            try await repository.delete(entryId: id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Quick Add Methods

    func loadQuickAdd() async {
        do {
            recentFoods = try await store.recentFoods(limit: 12)
            favoriteFoods = try await store.favorites(limit: 8)

            // Load food names for all GIDs
            let allGIDs = Set(recentFoods.map(\.foodGID) + favoriteFoods.map(\.foodGID))
            var names: [String: String] = [:]

            for gid in allGIDs {
                if let refDTO = try await store.foodRef(gid: gid) {
                    names[gid] = refDTO.name
                }
            }

            foodNames = names
        } catch {
            self.error = error.localizedDescription
        }
    }

    func quickAdd(foodGID: String, meal: Meal) {
        Task { @MainActor in
            do {
                try await performQuickAdd(foodGID: foodGID, meal: meal)
            } catch {
                // Error - fall back to portion sheet
                activeSheet = .portion(foodGID: foodGID, meal: meal)
            }
        }
    }

    private func performQuickAdd(foodGID: String, meal: Meal) async throws {
        // Try to load prefs and FoodRef
        guard let prefs = try await store.getPreferences(foodGID: foodGID),
              let refDTO = try await store.foodRef(gid: foodGID) else {
            // No prefs or ref - open portion sheet
            activeSheet = .portion(foodGID: foodGID, meal: meal)
            return
        }

        // Check if unit can resolve
        guard SnapshotNutrientCalculator.canResolve(
            unit: prefs.defaultUnit,
            gramsPerServing: refDTO.gramsPerServing,
            householdUnits: refDTO.householdUnits
        ) else {
            // Can't resolve - open portion sheet
            activeSheet = .portion(foodGID: foodGID, meal: meal)
            return
        }

        // Build FoodRef from DTO
        let foodRef = buildFoodRef(from: refDTO)

        // Build and log entry directly
        let entry = await FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: prefs.defaultQty,
            unit: prefs.defaultUnit,
            meal: meal
        )

        try await repository.log(entry)
        try await store.recordUsage(foodGID: foodGID, meal: meal)

        // Reload entries
        await load()

        // Show success feedback
        didQuickAdd(meal)
    }

    private func buildFoodRef(from refDTO: FoodRefDTO) -> FoodRef {
        FoodRef(
            gid: refDTO.gid,
            source: refDTO.source,
            name: refDTO.name,
            brand: refDTO.brand,
            servingSize: refDTO.servingSize,
            servingSizeUnit: refDTO.servingSizeUnit,
            gramsPerServing: refDTO.gramsPerServing,
            householdUnits: refDTO.householdUnits,
            foodLoggingNutrients: refDTO.foodLoggingNutrients
        )
    }

    @MainActor
    private func didQuickAdd(_ meal: Meal) {
        // Success feedback placeholder (tracked in issue #xxx)
    }
}
