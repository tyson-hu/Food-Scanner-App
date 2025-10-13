//
//  PortionResolverTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Calry
import Testing

@Suite("PortionResolver Service")
struct PortionResolverTests {
    @Test("mass conversion grams kilograms ounces pounds")
    func massConversion() throws {
        #expect(PortionResolver.convertMass(amount: 1_000, from: .grams, to: .kilograms) == 1.0)
        #expect(PortionResolver.convertMass(amount: 1, from: .kilograms, to: .grams) == 1_000)
        #expect(PortionResolver.convertMass(amount: 28.3495, from: .grams, to: .ounces) == 1.0)
        #expect(PortionResolver.convertMass(amount: 1, from: .ounces, to: .grams) == 28.3495)
        #expect(PortionResolver.convertMass(amount: 453.592, from: .grams, to: .pounds) == 1.0)
        #expect(PortionResolver.convertMass(amount: 1, from: .pounds, to: .grams) == 453.592)
    }

    @Test("volume conversion milliliters liters fluidOunces")
    func volumeConversion() throws {
        #expect(PortionResolver.convertVolume(amount: 1_000, from: .milliliters, to: .liters) == 1.0)
        #expect(PortionResolver.convertVolume(amount: 1, from: .liters, to: .milliliters) == 1_000)
        #expect(PortionResolver.convertVolume(amount: 29.5735, from: .milliliters, to: .fluidOunces) == 1.0)
        #expect(PortionResolver.convertVolume(amount: 1, from: .fluidOunces, to: .milliliters) == 29.5735)
    }

    @Test("grams direct passthrough")
    func gramsDirect() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 120,
            unit: .grams,
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: nil
        )
        #expect(result == 120)
    }

    @Test("serving to grams when known")
    func servingToGrams() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 2,
            unit: .serving,
            gramsPerServing: 50,
            densityGPerMl: nil,
            householdUnits: nil
        )
        #expect(result == 100)
    }

    @Test("serving to grams when gramsPerServing is nil")
    func servingToGramsNil() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 2,
            unit: .serving,
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: nil
        )
        #expect(result == nil)
    }

    @Test("serving to grams when gramsPerServing is zero")
    func servingToGramsZero() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 2,
            unit: .serving,
            gramsPerServing: 0,
            densityGPerMl: nil,
            householdUnits: nil
        )
        #expect(result == nil)
    }

    @Test("household to grams when available")
    func householdToGrams() throws {
        let units = [HouseholdUnit(label: "1 cup", grams: 240)]
        let result = PortionResolver.resolveToGrams(
            quantity: 1,
            unit: .household(label: "1 cup"),
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: units
        )
        #expect(result == 240)
    }

    @Test("household to grams with case insensitive matching")
    func householdToGramsCaseInsensitive() throws {
        let units = [HouseholdUnit(label: "1 Cup", grams: 240)]
        let result = PortionResolver.resolveToGrams(
            quantity: 1,
            unit: .household(label: "1 cup"),
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: units
        )
        #expect(result == 240)
    }

    @Test("household to grams with whitespace normalization")
    func householdToGramsWhitespace() throws {
        let units = [HouseholdUnit(label: "  1 cup  ", grams: 240)]
        let result = PortionResolver.resolveToGrams(
            quantity: 1,
            unit: .household(label: "1 cup"),
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: units
        )
        #expect(result == 240)
    }

    @Test("household to grams when not found")
    func householdToGramsNotFound() throws {
        let units = [HouseholdUnit(label: "1 cup", grams: 240)]
        let result = PortionResolver.resolveToGrams(
            quantity: 1,
            unit: .household(label: "1 slice"),
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: units
        )
        #expect(result == nil)
    }

    @Test("milliliters with valid density 0.95 converts")
    func millilitersWithValidDensity() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 100,
            unit: .milliliters,
            gramsPerServing: nil,
            densityGPerMl: 0.95,
            householdUnits: nil
        )
        #expect(result == 95.0)
    }

    @Test("milliliters with valid density at lower bound")
    func millilitersWithValidDensityLowerBound() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 100,
            unit: .milliliters,
            gramsPerServing: nil,
            densityGPerMl: 0.2,
            householdUnits: nil
        )
        #expect(result == 20.0)
    }

    @Test("milliliters with valid density at upper bound")
    func millilitersWithValidDensityUpperBound() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 100,
            unit: .milliliters,
            gramsPerServing: nil,
            densityGPerMl: 2.0,
            householdUnits: nil
        )
        #expect(result == 200.0)
    }

    @Test("milliliters without density returns nil")
    func millilitersWithoutDensity() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 100,
            unit: .milliliters,
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: nil
        )
        #expect(result == nil)
    }

    @Test("milliliters with out-of-bounds density returns nil")
    func millilitersWithInvalidDensity() throws {
        let lowResult = PortionResolver.resolveToGrams(
            quantity: 100,
            unit: .milliliters,
            gramsPerServing: nil,
            densityGPerMl: 0.1, // < 0.2
            householdUnits: nil
        )
        #expect(lowResult == nil)

        let highResult = PortionResolver.resolveToGrams(
            quantity: 100,
            unit: .milliliters,
            gramsPerServing: nil,
            densityGPerMl: 2.5, // > 2.0
            householdUnits: nil
        )
        #expect(highResult == nil)
    }

    @Test("returns nil when quantity is zero")
    func zeroQuantity() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: 0,
            unit: .grams,
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: nil
        )
        #expect(result == nil)
    }

    @Test("returns nil when quantity is negative")
    func negativeQuantity() throws {
        let result = PortionResolver.resolveToGrams(
            quantity: -1,
            unit: .grams,
            gramsPerServing: nil,
            densityGPerMl: nil,
            householdUnits: nil
        )
        #expect(result == nil)
    }
}
