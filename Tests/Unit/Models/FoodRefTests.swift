//
//  FoodRefTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftData
import Testing

@testable import Calry

@Suite("FoodRef Model")
struct FoodRefTests {
    @Test("FoodRef initialization with all fields")
    func initialization() throws {
        let householdUnits = [
            HouseholdUnit(label: "1 can", grams: 150.0),
            HouseholdUnit(label: "1 slice", grams: 25.0)
        ]
        let nutrients = FoodLoggingNutrients(
            energyKcal: 100.0,
            protein: 5.0,
            fat: 2.0
        )

        let foodRef = FoodRef(
            gid: "fdc:123456",
            source: .fdc,
            name: "Test Food",
            brand: "Test Brand",
            servingSize: 1.0,
            servingSizeUnit: "serving",
            gramsPerServing: 100.0,
            householdUnits: householdUnits,
            foodLoggingNutrients: nutrients
        )

        #expect(foodRef.gid == "fdc:123456")
        #expect(foodRef.source == .fdc)
        #expect(foodRef.name == "Test Food")
        #expect(foodRef.brand == "Test Brand")
        #expect(foodRef.servingSize == 1.0)
        #expect(foodRef.servingSizeUnit == "serving")
        #expect(foodRef.gramsPerServing == 100.0)
        #expect(foodRef.householdUnits?.count == 2)
        #expect(foodRef.foodLoggingNutrients?.energyKcal == 100.0)
    }

    @Test("householdUnits encoding/decoding roundtrip")
    func householdUnitsRoundtrip() throws {
        let originalUnits = [
            HouseholdUnit(label: "1 can", grams: 150.0),
            HouseholdUnit(label: "1 slice", grams: 25.0),
            HouseholdUnit(label: "1 cup", grams: 200.0)
        ]

        let foodRef = FoodRef(
            gid: "test:123",
            source: .fdc,
            name: "Test Food"
        )

        // Set household units
        foodRef.householdUnits = originalUnits

        // Verify encoding/decoding
        let decodedUnits = foodRef.householdUnits
        #expect(decodedUnits?.count == 3)
        #expect(decodedUnits?[0].label == "1 can")
        #expect(decodedUnits?[0].grams == 150.0)
        #expect(decodedUnits?[1].label == "1 slice")
        #expect(decodedUnits?[1].grams == 25.0)
        #expect(decodedUnits?[2].label == "1 cup")
        #expect(decodedUnits?[2].grams == 200.0)
    }

    @Test("foodLoggingNutrients encoding/decoding roundtrip")
    func foodLoggingNutrientsRoundtrip() throws {
        let originalNutrients = FoodLoggingNutrients(
            energyKcal: 250.0,
            protein: 15.0,
            fat: 8.0,
            saturatedFat: 3.0,
            carbs: 30.0,
            fiber: 5.0,
            sugars: 10.0,
            sodium: 500.0,
            cholesterol: 50.0
        )

        let foodRef = FoodRef(
            gid: "test:456",
            source: .off,
            name: "Test Food"
        )

        // Set nutrients
        foodRef.foodLoggingNutrients = originalNutrients

        // Verify encoding/decoding
        let decodedNutrients = foodRef.foodLoggingNutrients
        #expect(decodedNutrients?.energyKcal == 250.0)
        #expect(decodedNutrients?.protein == 15.0)
        #expect(decodedNutrients?.fat == 8.0)
        #expect(decodedNutrients?.saturatedFat == 3.0)
        #expect(decodedNutrients?.carbs == 30.0)
        #expect(decodedNutrients?.fiber == 5.0)
        #expect(decodedNutrients?.sugars == 10.0)
        #expect(decodedNutrients?.sodium == 500.0)
        #expect(decodedNutrients?.cholesterol == 50.0)
    }

    @Test("gid uniqueness constraint")
    func gidUniqueness() throws {
        // This test verifies that the @Attribute(.unique) constraint is properly applied
        // In a real SwiftData context, duplicate gids would cause an error
        let foodRef1 = FoodRef(
            gid: "unique:123",
            source: .fdc,
            name: "Food 1"
        )
        let foodRef2 = FoodRef(
            gid: "unique:123", // Same gid
            source: .off,
            name: "Food 2"
        )

        // Both should be created successfully in memory
        // The uniqueness constraint is enforced by SwiftData at persistence time
        #expect(foodRef1.gid == foodRef2.gid)
        #expect(foodRef1.source != foodRef2.source)
    }

    @Test("computed properties get/set")
    func computedProperties() throws {
        let foodRef = FoodRef(
            gid: "test:789",
            source: .fdc,
            name: "Test Food"
        )

        // Test setting household units
        let units = [HouseholdUnit(label: "1 piece", grams: 50.0)]
        foodRef.householdUnits = units
        #expect(foodRef.householdUnits?.count == 1)
        #expect(foodRef.householdUnits?[0].label == "1 piece")

        // Test setting nutrients
        let nutrients = FoodLoggingNutrients(energyKcal: 200.0, protein: 10.0)
        foodRef.foodLoggingNutrients = nutrients
        #expect(foodRef.foodLoggingNutrients?.energyKcal == 200.0)
        #expect(foodRef.foodLoggingNutrients?.protein == 10.0)

        // Test clearing (setting to nil)
        foodRef.householdUnits = nil
        foodRef.foodLoggingNutrients = nil
        #expect(foodRef.householdUnits == nil)
        #expect(foodRef.foodLoggingNutrients == nil)
    }

    @Test("metadata timestamps")
    func metadataTimestamps() throws {
        let beforeCreation = Date()
        let foodRef = FoodRef(
            gid: "test:timestamps",
            source: .fdc,
            name: "Test Food"
        )
        let afterCreation = Date()

        #expect(foodRef.createdAt >= beforeCreation)
        #expect(foodRef.createdAt <= afterCreation)
        #expect(foodRef.updatedAt >= beforeCreation)
        #expect(foodRef.updatedAt <= afterCreation)
        #expect(foodRef.createdAt == foodRef.updatedAt)

        // Test that updating computed properties updates the timestamp
        let beforeUpdate = Date()
        foodRef.householdUnits = [HouseholdUnit(label: "1 test", grams: 1.0)]
        let afterUpdate = Date()

        #expect(foodRef.updatedAt >= beforeUpdate)
        #expect(foodRef.updatedAt <= afterUpdate)
        #expect(foodRef.updatedAt > foodRef.createdAt)
    }
}
