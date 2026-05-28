//
//  SnapshotNutrientCalculatorTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Calry
import Testing

@Suite("SnapshotNutrientCalculator Service")
struct SnapshotNutrientCalculatorTests {
    @Test("snapshot from per100 nutrients")
    func snapshotCalculation() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10, fat: 5, carbs: 20)
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: 150, unit: .grams)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == 150)
        #expect(snapshot.protein == 15)
        #expect(snapshot.fat == 7.5)
        #expect(snapshot.carbs == 30)
    }

    @Test("portion scaling 2 servings equals 2x nutrients")
    func portionScaling() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 200, protein: 20, fat: 10)
        let params = SnapshotNutrientCalculator.CalculationParams(
            quantity: 2,
            unit: .serving,
            gramsPerServing: 100
        )
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == 400)
        #expect(snapshot.protein == 40)
        #expect(snapshot.fat == 20)
    }

    @Test("missing nutrients stay nil")
    func missingNutrients() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: nil, fat: 5)
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: 200, unit: .grams)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == 200)
        #expect(snapshot.protein == nil)
        #expect(snapshot.fat == 10)
    }

    @Test("zero nutrients stay zero")
    func zeroNutrients() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 0, protein: 0, fat: 0)
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: 150, unit: .grams)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == 0)
        #expect(snapshot.protein == 0)
        #expect(snapshot.fat == 0)
    }

    @Test("milliliters without density returns empty snapshot")
    func millilitersWithoutDensity() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: 100, unit: .milliliters)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == nil)
        #expect(snapshot.protein == nil)
    }

    @Test("milliliters with valid density calculates correctly")
    func millilitersWithValidDensity() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let params = SnapshotNutrientCalculator.CalculationParams(
            quantity: 100,
            unit: .milliliters,
            densityGPerMl: 1.05
        )
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == 105)
        #expect(snapshot.protein == 10.5)
    }

    @Test("household units with matching label")
    func householdUnitsMatching() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let units = [HouseholdUnit(label: "1 cup", grams: 240)]
        let params = SnapshotNutrientCalculator.CalculationParams(
            quantity: 1,
            unit: .household(label: "1 cup"),
            householdUnits: units
        )
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == 240)
        #expect(snapshot.protein == 24)
    }

    @Test("household units with no matching label")
    func householdUnitsNoMatch() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let units = [HouseholdUnit(label: "1 cup", grams: 240)]
        let params = SnapshotNutrientCalculator.CalculationParams(
            quantity: 1,
            unit: .household(label: "1 slice"),
            householdUnits: units
        )
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == nil)
        #expect(snapshot.protein == nil)
    }

    @Test("serving without gramsPerServing")
    func servingWithoutGramsPerServing() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: 2, unit: .serving)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == nil)
        #expect(snapshot.protein == nil)
    }

    @Test("serving with zero gramsPerServing")
    func servingWithZeroGramsPerServing() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let params = SnapshotNutrientCalculator.CalculationParams(
            quantity: 2,
            unit: .serving,
            gramsPerServing: 0
        )
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == nil)
        #expect(snapshot.protein == nil)
    }

    @Test("zero quantity returns empty snapshot")
    func zeroQuantity() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: 0, unit: .grams)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == nil)
        #expect(snapshot.protein == nil)
    }

    @Test("negative quantity returns empty snapshot")
    func negativeQuantity() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: -1, unit: .grams)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == nil)
        #expect(snapshot.protein == nil)
    }

    @Test("fractional scaling preserves precision")
    func fractionalScaling() throws {
        let per100 = FoodLoggingNutrients(energyKcal: 100, protein: 10)
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: 75, unit: .grams)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == 75)
        #expect(snapshot.protein == 7.5)
    }

    @Test("all nutrients scaling")
    func allNutrientsScaling() throws {
        let per100 = FoodLoggingNutrients(
            energyKcal: 100,
            protein: 10,
            fat: 5,
            saturatedFat: 2,
            carbs: 20,
            fiber: 3,
            sugars: 8,
            addedSugars: 4,
            sodium: 200,
            cholesterol: 30
        )
        let params = SnapshotNutrientCalculator.CalculationParams(quantity: 150, unit: .grams)
        let snapshot = SnapshotNutrientCalculator.calculateSnapshot(per100Nutrients: per100, params: params)
        #expect(snapshot.energyKcal == 150)
        #expect(snapshot.protein == 15)
        #expect(snapshot.fat == 7.5)
        #expect(snapshot.saturatedFat == 3)
        #expect(snapshot.carbs == 30)
        #expect(snapshot.fiber == 4.5)
        #expect(snapshot.sugars == 12)
        #expect(snapshot.addedSugars == 6)
        #expect(snapshot.sodium == 300)
        #expect(snapshot.cholesterol == 45)
    }
}
