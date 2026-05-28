//
//  SnapshotNutrientCalculator+Validation.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

public extension SnapshotNutrientCalculator {
    /// Check if a unit can resolve to grams given available metadata
    static func canResolve(
        unit: Unit,
        gramsPerServing: Double?,
        householdUnits: [HouseholdUnit]?,
        densityGPerMl: Double? = nil
    ) -> Bool {
        PortionResolver.resolveToGrams(
            quantity: 1.0,
            unit: unit,
            gramsPerServing: gramsPerServing,
            densityGPerMl: densityGPerMl,
            householdUnits: householdUnits
        ) != nil
    }
}
