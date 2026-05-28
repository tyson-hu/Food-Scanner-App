//
//  EnhancedFoodEntryBuilderTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Testing

@testable import Calry

@Suite("Enhanced FoodEntryBuilder")
struct EnhancedFoodEntryBuilderTests {
    @Test("catalog entry from FoodRef")
    func catalogFromFoodRef() throws {
        // Create a test FoodRef
        let foodRef = FoodRef(
            gid: "fdc:123456",
            source: .fdc,
            name: "Test Food",
            brand: "Test Brand",
            servingSize: 100.0,
            servingSizeUnit: "g",
            gramsPerServing: 100.0,
            householdUnits: [
                HouseholdUnit(label: "1 cup", grams: 240.0),
                HouseholdUnit(label: "1 tbsp", grams: 15.0)
            ],
            foodLoggingNutrients: FoodLoggingNutrients(
                energyKcal: 200.0,
                protein: 10.0,
                fat: 5.0,
                carbs: 30.0,
                fiber: 3.0,
                sugars: 8.0,
                sodium: 300.0
            )
        )

        // Build entry from FoodRef
        let entry = FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: 150.0,
            unit: .grams,
            meal: .breakfast
        )

        // Verify basic properties
        #expect(entry.name == "Test Food")
        #expect(entry.brand == "Test Brand")
        #expect(entry.fdcId == 123_456)
        #expect(entry.kind == .catalog)
        #expect(entry.meal == .breakfast)
        #expect(entry.foodGID == "fdc:123456")
        #expect(entry.quantity == 150.0)
        #expect(entry.unit == "g")
        #expect(entry.servingDescription == "150.00 g")

        // Verify nutrient calculations (150g of 200kcal/100g = 300kcal)
        #expect(entry.calories == 300.0)
        #expect(entry.protein == 15.0)
        #expect(entry.fat == 7.5)
        #expect(entry.carbs == 45.0)
        #expect(entry.snapEnergyKcal == 300.0)
        #expect(entry.snapProtein == 15.0)
        #expect(entry.snapFat == 7.5)
        #expect(entry.snapCarbs == 45.0)
        #expect(entry.snapFiber == 4.5)
        #expect(entry.snapSugars == 12.0)
        #expect(entry.snapSodium == 450.0)

        // Verify resolved quantities
        #expect(entry.resolvedToBase == 150.0)
        #expect(entry.gramsResolved == 150.0)
        #expect(entry.baseUnit == "g")
    }

    @Test("catalog entry with household unit")
    func catalogWithHouseholdUnit() throws {
        let foodRef = FoodRef(
            gid: "fdc:789012",
            source: .fdc,
            name: "Milk",
            brand: "Test Dairy",
            servingSize: 240.0,
            servingSizeUnit: "ml",
            gramsPerServing: 240.0,
            householdUnits: [
                HouseholdUnit(label: "1 cup", grams: 240.0)
            ],
            foodLoggingNutrients: FoodLoggingNutrients(
                energyKcal: 150.0,
                protein: 8.0,
                fat: 8.0,
                carbs: 12.0
            )
        )

        // Build entry using household unit
        let entry = FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: 2.0,
            unit: .household(label: "1 cup"),
            meal: .lunch
        )

        // Verify properties
        #expect(entry.name == "Milk")
        #expect(entry.meal == .lunch)
        #expect(entry.quantity == 2.0)
        #expect(entry.unit == "1 cup")
        #expect(entry.servingDescription == "2.00× 1 cup")

        // Verify nutrient calculations (2 cups = 480g of 150kcal/100g = 720kcal)
        #expect(entry.calories == 720.0)
        #expect(entry.protein == 38.4)
        #expect(entry.fat == 38.4)
        #expect(entry.carbs == 57.6)

        // Verify resolved quantities (2 cups = 480g)
        #expect(entry.resolvedToBase == 480.0)
        #expect(entry.gramsResolved == 480.0)
    }

    @Test("manual entry creation")
    func manualEntry() throws {
        let entry = FoodEntryBuilder.manual(
            name: "Custom Food",
            energyKcal: 250.0,
            protein: 15.0,
            fat: 10.0,
            carbs: 20.0,
            meal: .dinner
        )

        // Verify basic properties
        #expect(entry.name == "Custom Food")
        #expect(entry.brand == nil)
        #expect(entry.fdcId == nil)
        #expect(entry.kind == .manual)
        #expect(entry.meal == .dinner)
        #expect(entry.foodGID == nil)
        #expect(entry.quantity == 1.0)
        #expect(entry.unit == "serving")
        #expect(entry.servingDescription == "1× serving")

        // Verify nutrients
        #expect(entry.calories == 250.0)
        #expect(entry.protein == 15.0)
        #expect(entry.fat == 10.0)
        #expect(entry.carbs == 20.0)
        #expect(entry.snapEnergyKcal == 250.0)
        #expect(entry.snapProtein == 15.0)
        #expect(entry.snapFat == 10.0)
        #expect(entry.snapCarbs == 20.0)

        // Verify resolved quantities
        #expect(entry.resolvedToBase == 100.0)
        #expect(entry.gramsResolved == 100.0)
        #expect(entry.baseUnit == "g")
    }

    @Test("manual entry with minimal nutrients")
    func manualEntryMinimal() throws {
        let entry = FoodEntryBuilder.manual(
            name: "Simple Food",
            energyKcal: 100.0,
            meal: .snack
        )

        // Verify basic properties
        #expect(entry.name == "Simple Food")
        #expect(entry.kind == .manual)
        #expect(entry.meal == .snack)

        // Verify nutrients (only calories provided)
        #expect(entry.calories == 100.0)
        #expect(entry.protein == 0.0)
        #expect(entry.fat == 0.0)
        #expect(entry.carbs == 0.0)
        #expect(entry.snapEnergyKcal == 100.0)
        #expect(entry.snapProtein == nil)
        #expect(entry.snapFat == nil)
        #expect(entry.snapCarbs == nil)
    }

    @Test("snapshot calculation integration")
    func snapshotIntegration() throws {
        let foodRef = FoodRef(
            gid: "fdc:555555",
            source: .fdc,
            name: "Test Integration",
            brand: nil,
            servingSize: 50.0,
            servingSizeUnit: "g",
            gramsPerServing: 50.0,
            householdUnits: nil,
            foodLoggingNutrients: FoodLoggingNutrients(
                energyKcal: 400.0,
                protein: 20.0,
                fat: 15.0,
                carbs: 50.0,
                fiber: 5.0,
                sugars: 10.0,
                sodium: 500.0,
                cholesterol: 30.0
            )
        )

        // Build entry with 75g (1.5x serving)
        let entry = FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: 75.0,
            unit: .grams,
            meal: .breakfast
        )

        // Verify snapshot calculations (75g of 400kcal/100g = 300kcal)
        #expect(entry.snapEnergyKcal == 300.0)
        #expect(entry.snapProtein == 15.0)
        #expect(entry.snapFat == 11.25)
        #expect(entry.snapCarbs == 37.5)
        #expect(entry.snapFiber == 3.75)
        #expect(entry.snapSugars == 7.5)
        #expect(entry.snapSodium == 375.0)
        #expect(entry.snapCholesterol == 22.5)

        // Verify legacy nutrients match snapshots
        #expect(entry.calories == entry.snapEnergyKcal)
        #expect(entry.protein == entry.snapProtein)
        #expect(entry.fat == entry.snapFat)
        #expect(entry.carbs == entry.snapCarbs)
    }

    @Test("backward compatibility with existing methods")
    func backwardCompatibility() throws {
        // Test that existing methods still work
        let foodCard = FoodCard(
            id: "fdc:123456",
            description: "Test Card",
            brand: "Test Brand",
            provenance: FoodProvenance(source: .fdc),
            serving: FoodServing(amount: 100.0, unit: "g"),
            baseUnit: .grams,
            per100Base: [
                FoodNutrient(name: "Energy", amount: 200.0, unit: "kcal", basis: .per100g),
                FoodNutrient(name: "Protein", amount: 10.0, unit: "g", basis: .per100g)
            ],
            portions: [],
            densityGPerMl: nil
        )

        let entry = FoodEntryBuilder.from(
            foodCard: foodCard,
            multiplier: 1.5,
            at: Date()
        )

        // Verify basic properties
        #expect(entry.name == "Test Card")
        #expect(entry.brand == "Test Brand")
        #expect(entry.fdcId == 123_456)
        #expect(entry.quantity == 1.5)
        #expect(entry.unit == "serving")

        // Verify nutrients (1.5x serving of 200kcal/100g = 300kcal)
        #expect(entry.calories == 300.0)
        #expect(entry.protein == 15.0)
    }

    @Test("serving unit handling")
    func servingUnitHandling() throws {
        let foodRef = FoodRef(
            gid: "fdc:999999",
            source: .fdc,
            name: "Serving Test",
            brand: nil,
            servingSize: 1.0,
            servingSizeUnit: "serving",
            gramsPerServing: 150.0,
            householdUnits: nil,
            foodLoggingNutrients: FoodLoggingNutrients(
                energyKcal: 300.0,
                protein: 15.0,
                fat: 10.0,
                carbs: 40.0
            )
        )

        // Build entry with 2 servings
        let entry = FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: 2.0,
            unit: .serving,
            meal: .lunch
        )

        // Verify properties
        #expect(entry.quantity == 2.0)
        #expect(entry.unit == "serving")
        #expect(entry.servingDescription == "2.00× serving")

        // Verify nutrient calculations (2 servings of 300kcal = 600kcal)
        #expect(entry.calories == 600.0)
        #expect(entry.protein == 30.0)
        #expect(entry.fat == 20.0)
        #expect(entry.carbs == 80.0)

        // Verify resolved quantities (2 servings × 150g = 300g)
        #expect(entry.resolvedToBase == 300.0)
        #expect(entry.gramsResolved == 300.0)
    }

    @Test("milliliters unit handling")
    func millilitersUnitHandling() throws {
        let foodRef = FoodRef(
            gid: "fdc:888888",
            source: .fdc,
            name: "Liquid Test",
            brand: nil,
            servingSize: 250.0,
            servingSizeUnit: "ml",
            gramsPerServing: 250.0,
            householdUnits: nil,
            foodLoggingNutrients: FoodLoggingNutrients(
                energyKcal: 100.0,
                protein: 5.0,
                fat: 2.0,
                carbs: 15.0
            )
        )

        // Build entry with 500ml
        let entry = FoodEntryBuilder.from(
            foodRef: foodRef,
            quantity: 500.0,
            unit: .milliliters,
            meal: .breakfast
        )

        // Verify properties
        #expect(entry.quantity == 500.0)
        #expect(entry.unit == "ml")
        #expect(entry.servingDescription == "500.00 ml")

        // Verify nutrient calculations (500ml of 100kcal/100g = 500kcal)
        #expect(entry.calories == 500.0)
        #expect(entry.protein == 25.0)
        #expect(entry.fat == 10.0)
        #expect(entry.carbs == 75.0)

        // Verify resolved quantities (500ml = 500g, assuming 1:1 density)
        #expect(entry.resolvedToBase == 500.0)
        #expect(entry.gramsResolved == 500.0)
    }
}
