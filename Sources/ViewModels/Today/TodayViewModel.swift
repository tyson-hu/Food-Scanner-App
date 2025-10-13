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

    func deleteEntry(_ id: UUID) async {
        do {
            try await repository.delete(entryId: id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}
