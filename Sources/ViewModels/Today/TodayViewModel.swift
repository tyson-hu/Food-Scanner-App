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
    private let repository: FoodLogRepository
    private let store: FoodLogStore

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
}
