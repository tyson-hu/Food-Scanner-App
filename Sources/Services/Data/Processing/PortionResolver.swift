//
//  PortionResolver.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

/// Service for resolving food portions to grams using density and household units
public struct PortionResolver: Sendable {
    private static let densityBounds = 0.2 ... 2.0 // g/ml

    // MARK: - Unit Conversion

    /// Convert between mass units
    public static func convertMass(amount: Double, from: MassUnit, to targetUnit: MassUnit) -> Double {
        // Convert to grams first
        let grams: Double = switch from {
        case .grams:
            amount
        case .kilograms:
            amount * 1_000
        case .ounces:
            amount * 28.3495
        case .pounds:
            amount * 453.592
        }

        // Convert from grams to target unit
        switch targetUnit {
        case .grams:
            return grams
        case .kilograms:
            return grams / 1_000
        case .ounces:
            return grams / 28.3495
        case .pounds:
            return grams / 453.592
        }
    }

    /// Convert between volume units
    public static func convertVolume(amount: Double, from: VolumeUnit, to targetUnit: VolumeUnit) -> Double {
        // Convert to milliliters first
        let milliliters: Double = switch from {
        case .milliliters:
            amount
        case .liters:
            amount * 1_000
        case .fluidOunces:
            amount * 29.5735
        }

        // Convert from milliliters to target unit
        switch targetUnit {
        case .milliliters:
            return milliliters
        case .liters:
            return milliliters / 1_000
        case .fluidOunces:
            return milliliters / 29.5735
        }
    }

    // MARK: - Portion Resolution

    /// Resolve portion to grams (returns nil if not determinable)
    public static func resolveToGrams(
        quantity: Double,
        unit: Unit,
        gramsPerServing: Double?,
        densityGPerMl: Double?,
        householdUnits: [HouseholdUnit]?
    ) -> Double? {
        guard quantity > 0 else { return nil }

        switch unit {
        case .grams:
            return quantity

        case .serving:
            guard let gps = gramsPerServing, gps > 0 else { return nil }
            return quantity * gps

        case .milliliters:
            // CRITICAL: Only convert if density is present AND within bounds
            guard let density = densityGPerMl, densityBounds.contains(density) else { return nil }
            return quantity * density

        case let .household(label):
            let norm = HouseholdUnit.normalize(label)
            if let unit = householdUnits?.first(where: { $0.normalizedLabel == norm }) {
                return quantity * unit.grams
            }
            return nil
        }
    }

    // MARK: - Internal Unit Enums

    /// Mass units for conversion (spelled-out names for SwiftLint compliance)
    public enum MassUnit: Sendable {
        case grams, kilograms, ounces, pounds
    }

    /// Volume units for conversion (spelled-out names for SwiftLint compliance)
    public enum VolumeUnit: Sendable {
        case milliliters, liters, fluidOunces
    }
}
