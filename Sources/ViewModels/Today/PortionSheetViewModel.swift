//
//  PortionSheetViewModel.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class PortionSheetViewModel {
    private let store: FoodLogStore
    private let repository: FoodLogRepository

    let foodGID: String
    var meal: Meal // Mutable, preselected from context

    var foodRef: FoodRefDTO?
    var userPrefs: UserFoodPrefsDTO?

    var quantity: Double = 1.0
    var selectedUnit: Unit = .serving
    var availableUnits: [Unit] = []

    var liveSnapshot: FoodLoggingNutrients = .init()
    var isLoading = false
    var error: String?

    init(foodGID: String, meal: Meal, store: FoodLogStore, repository: FoodLogRepository) {
        self.foodGID = foodGID
        self.meal = meal
        self.store = store
        self.repository = repository
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            foodRef = try await store.foodRef(gid: foodGID)
            userPrefs = try await store.getPreferences(foodGID: foodGID)

            if let prefs = userPrefs {
                quantity = prefs.defaultQty
                selectedUnit = prefs.defaultUnit
                meal = prefs.defaultMeal // Can override preselected meal
            }

            buildAvailableUnits()
            updateLiveSnapshot()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func updateLiveSnapshot() {
        guard let foodRef,
              let per100Nutrients = foodRef.foodLoggingNutrients else {
            liveSnapshot = .init()
            return
        }

        let params = SnapshotNutrientCalculator.CalculationParams(
            quantity: quantity,
            unit: selectedUnit,
            gramsPerServing: foodRef.gramsPerServing,
            densityGPerMl: nil,
            householdUnits: foodRef.householdUnits
        )

        liveSnapshot = SnapshotNutrientCalculator.calculateSnapshot(
            per100Nutrients: per100Nutrients,
            params: params
        )
    }

    private func buildAvailableUnits() {
        guard let foodRef else { return }

        var units: [Unit] = [.grams]

        if foodRef.gramsPerServing != nil {
            units.append(.serving)
        }

        if let householdUnits = foodRef.householdUnits {
            for householdUnit in householdUnits {
                units.append(.household(label: householdUnit.label))
            }
        }

        availableUnits = units

        // Ensure selected unit is available
        if !units.contains(selectedUnit) {
            selectedUnit = units.first ?? .grams
        }
    }

    func logEntry() async {
        guard let foodRef else { return }

        let foodRefModel = FoodRef(
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

        let entry = await FoodEntryBuilder.from(
            foodRef: foodRefModel,
            quantity: quantity,
            unit: selectedUnit,
            meal: meal
        )

        do {
            try await repository.log(entry)
            try await store.recordUsage(foodGID: foodGID, meal: meal)
            try await store.updatePreferences(
                foodGID: foodGID,
                unit: selectedUnit,
                qty: quantity,
                meal: meal
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
