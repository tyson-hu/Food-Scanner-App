//
//  FoodRefBuilderTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Calry
import Testing

@Suite("FoodRefBuilder Service")
struct FoodRefBuilderTests {
    @Test("FoodCard to FoodRef conversion")
    func foodCardConversion() throws {
        let foodCard = FoodCard(
            id: "12345",
            source: .fdc,
            name: "Test Apple",
            brand: "Generic",
            servingSize: 100.0,
            servingSizeUnit: .grams,
            gramsPerServing: 100.0,
            portions: [
                FoodPortion(label: "1 medium", grams: 182.0),
                FoodPortion(label: "1 cup sliced", grams: 110.0)
            ],
            per100Base: FoodLoggingNutrients(
                energyKcal: 52.0,
                protein: 0.3,
                fat: 0.2,
                carbs: 13.8,
                fiber: 2.4,
                sugars: 10.4
            )
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)

        #expect(foodRef.gid == "fdc:12345")
        #expect(foodRef.source == .fdc)
        #expect(foodRef.name == "Test Apple")
        #expect(foodRef.brand == "Generic")
        #expect(foodRef.servingSize == 100.0)
        #expect(foodRef.servingSizeUnit == .grams)
        #expect(foodRef.gramsPerServing == 100.0)
        #expect(foodRef.densityGPerMl == nil)

        // Test household units
        let householdUnits = foodRef.householdUnits
        #expect(householdUnits?.count == 2)
        #expect(householdUnits?.contains { $0.label == "1 medium" && $0.grams == 182.0 } == true)
        #expect(householdUnits?.contains { $0.label == "1 cup sliced" && $0.grams == 110.0 } == true)

        // Test nutrients
        let nutrients = foodRef.foodLoggingNutrients
        #expect(nutrients?.energyKcal == 52.0)
        #expect(nutrients?.protein == 0.3)
        #expect(nutrients?.fat == 0.2)
        #expect(nutrients?.carbs == 13.8)
        #expect(nutrients?.fiber == 2.4)
        #expect(nutrients?.sugars == 10.4)
    }

    @Test("FoodDetails to FoodRef conversion")
    func foodDetailsConversion() throws {
        let foodDetails = FoodDetails(
            id: "67890",
            source: .off,
            name: "Test Orange Juice",
            brand: "Fresh Brand",
            servingSize: 250.0,
            servingSizeUnit: .milliliters,
            gramsPerServing: 250.0,
            portions: [
                FoodPortion(label: "1 cup", grams: 240.0),
                FoodPortion(label: "1 bottle", grams: 500.0)
            ],
            per100Base: FoodLoggingNutrients(
                energyKcal: 45.0,
                protein: 0.7,
                fat: 0.2,
                carbs: 10.4,
                fiber: 0.2,
                sugars: 8.4,
                sodium: 1.0
            )
        )

        let foodRef = FoodRefBuilder.from(foodDetails: foodDetails)

        #expect(foodRef.gid == "off:67890")
        #expect(foodRef.source == .off)
        #expect(foodRef.name == "Test Orange Juice")
        #expect(foodRef.brand == "Fresh Brand")
        #expect(foodRef.servingSize == 250.0)
        #expect(foodRef.servingSizeUnit == .milliliters)
        #expect(foodRef.gramsPerServing == 250.0)
        #expect(foodRef.densityGPerMl == nil)

        // Test household units
        let householdUnits = foodRef.householdUnits
        #expect(householdUnits?.count == 2)
        #expect(householdUnits?.contains { $0.label == "1 cup" && $0.grams == 240.0 } == true)
        #expect(householdUnits?.contains { $0.label == "1 bottle" && $0.grams == 500.0 } == true)

        // Test nutrients
        let nutrients = foodRef.foodLoggingNutrients
        #expect(nutrients?.energyKcal == 45.0)
        #expect(nutrients?.protein == 0.7)
        #expect(nutrients?.fat == 0.2)
        #expect(nutrients?.carbs == 10.4)
        #expect(nutrients?.fiber == 0.2)
        #expect(nutrients?.sugars == 8.4)
        #expect(nutrients?.sodium == 1.0)
    }

    @Test("household units extraction from portions")
    func householdUnitsExtraction() throws {
        let portions = [
            FoodPortion(label: "1 slice", grams: 28.0),
            FoodPortion(label: "1 cup", grams: 128.0),
            FoodPortion(label: "1 can", grams: 340.0)
        ]

        let foodCard = FoodCard(
            id: "test",
            source: .fdc,
            name: "Test Food",
            portions: portions,
            per100Base: nil
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)
        let householdUnits = foodRef.householdUnits

        #expect(householdUnits?.count == 3)
        #expect(householdUnits?.contains { $0.label == "1 slice" && $0.grams == 28.0 } == true)
        #expect(householdUnits?.contains { $0.label == "1 cup" && $0.grams == 128.0 } == true)
        #expect(householdUnits?.contains { $0.label == "1 can" && $0.grams == 340.0 } == true)
    }

    @Test("household units extraction with invalid portions")
    func householdUnitsExtractionInvalid() throws {
        let portions = [
            FoodPortion(label: "1 slice", grams: 28.0),
            FoodPortion(label: "invalid", grams: nil), // Missing grams
            FoodPortion(label: nil, grams: 100.0), // Missing label
            FoodPortion(label: "zero", grams: 0.0) // Zero grams
        ]

        let foodCard = FoodCard(
            id: "test",
            source: .fdc,
            name: "Test Food",
            portions: portions,
            per100Base: nil
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)
        let householdUnits = foodRef.householdUnits

        // Should only include the valid portion
        #expect(householdUnits?.count == 1)
        #expect(householdUnits?.first?.label == "1 slice")
        #expect(householdUnits?.first?.grams == 28.0)
    }

    @Test("household units extraction with empty portions")
    func householdUnitsExtractionEmpty() throws {
        let foodCard = FoodCard(
            id: "test",
            source: .fdc,
            name: "Test Food",
            portions: [],
            per100Base: nil
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)
        #expect(foodRef.householdUnits == nil)
    }

    @Test("household units extraction with nil portions")
    func householdUnitsExtractionNil() throws {
        let foodCard = FoodCard(
            id: "test",
            source: .fdc,
            name: "Test Food",
            portions: nil,
            per100Base: nil
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)
        #expect(foodRef.householdUnits == nil)
    }

    @Test("nutrients extraction preserves nil")
    func nutrientsExtraction() throws {
        let per100Base = FoodLoggingNutrients(
            energyKcal: 100.0,
            protein: nil, // Missing protein
            fat: 5.0,
            carbs: nil, // Missing carbs
            fiber: 2.0,
            sugars: 10.0,
            sodium: nil // Missing sodium
        )

        let foodCard = FoodCard(
            id: "test",
            source: .fdc,
            name: "Test Food",
            portions: nil,
            per100Base: per100Base
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)
        let nutrients = foodRef.foodLoggingNutrients

        #expect(nutrients?.energyKcal == 100.0)
        #expect(nutrients?.protein == nil)
        #expect(nutrients?.fat == 5.0)
        #expect(nutrients?.carbs == nil)
        #expect(nutrients?.fiber == 2.0)
        #expect(nutrients?.sugars == 10.0)
        #expect(nutrients?.sodium == nil)
    }

    @Test("nutrients extraction with nil per100Base")
    func nutrientsExtractionNil() throws {
        let foodCard = FoodCard(
            id: "test",
            source: .fdc,
            name: "Test Food",
            portions: nil,
            per100Base: nil
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)
        #expect(foodRef.foodLoggingNutrients == nil)
    }

    @Test("GID generation for different sources")
    func gidGeneration() throws {
        let fdcCard = FoodCard(
            id: "12345",
            source: .fdc,
            name: "FDC Food",
            portions: nil,
            per100Base: nil
        )

        let offCard = FoodCard(
            id: "67890",
            source: .off,
            name: "OFF Food",
            portions: nil,
            per100Base: nil
        )

        let fdcRef = FoodRefBuilder.from(foodCard: fdcCard)
        let offRef = FoodRefBuilder.from(foodCard: offCard)

        #expect(fdcRef.gid == "fdc:12345")
        #expect(offRef.gid == "off:67890")
    }

    @Test("complete conversion with all fields")
    func completeConversion() throws {
        let portions = [
            FoodPortion(label: "1 medium", grams: 182.0),
            FoodPortion(label: "1 large", grams: 223.0)
        ]

        let per100Base = FoodLoggingNutrients(
            energyKcal: 52.0,
            protein: 0.3,
            fat: 0.2,
            saturatedFat: 0.1,
            carbs: 13.8,
            fiber: 2.4,
            sugars: 10.4,
            addedSugars: 0.0,
            sodium: 1.0,
            cholesterol: 0.0
        )

        let foodCard = FoodCard(
            id: "complete",
            source: .fdc,
            name: "Complete Apple",
            brand: "Organic Brand",
            servingSize: 100.0,
            servingSizeUnit: .grams,
            gramsPerServing: 100.0,
            portions: portions,
            per100Base: per100Base
        )

        let foodRef = FoodRefBuilder.from(foodCard: foodCard)

        // Verify all fields
        #expect(foodRef.gid == "fdc:complete")
        #expect(foodRef.source == .fdc)
        #expect(foodRef.name == "Complete Apple")
        #expect(foodRef.brand == "Organic Brand")
        #expect(foodRef.servingSize == 100.0)
        #expect(foodRef.servingSizeUnit == .grams)
        #expect(foodRef.gramsPerServing == 100.0)
        #expect(foodRef.densityGPerMl == nil)

        // Verify household units
        #expect(foodRef.householdUnits?.count == 2)

        // Verify nutrients
        let nutrients = foodRef.foodLoggingNutrients
        #expect(nutrients?.energyKcal == 52.0)
        #expect(nutrients?.protein == 0.3)
        #expect(nutrients?.fat == 0.2)
        #expect(nutrients?.saturatedFat == 0.1)
        #expect(nutrients?.carbs == 13.8)
        #expect(nutrients?.fiber == 2.4)
        #expect(nutrients?.sugars == 10.4)
        #expect(nutrients?.addedSugars == 0.0)
        #expect(nutrients?.sodium == 1.0)
        #expect(nutrients?.cholesterol == 0.0)
    }
}
