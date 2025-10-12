//
//  UserFoodPrefsTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData
import Testing

@testable import Calry

@Suite("UserFoodPrefs Model")
struct UserFoodPrefsTests {
    @Test("preference storage per user/food")
    func preferenceStorage() throws {
        let prefs = UserFoodPrefs(
            userId: "user123",
            foodGID: "fdc:12345",
            defaultUnit: .grams,
            defaultQty: 150.0,
            defaultMeal: .breakfast
        )

        #expect(prefs.userId == "user123")
        #expect(prefs.foodGID == "fdc:12345")
        #expect(prefs.defaultUnit == .grams)
        #expect(prefs.defaultQty == 150.0)
        #expect(prefs.defaultMeal == .breakfast)
        // Verify timestamp is initialized (within reasonable time window)
        let now = Date()
        let timeDifference = abs(prefs.updatedAt.timeIntervalSince(now))
        #expect(timeDifference < 1.0) // Should be within 1 second
    }

    @Test("default portion recall")
    func portionRecall() throws {
        let prefs = UserFoodPrefs(
            foodGID: "off:67890",
            defaultUnit: .serving,
            defaultQty: 2.0,
            defaultMeal: .lunch
        )

        #expect(prefs.defaultUnit == .serving)
        #expect(prefs.defaultQty == 2.0)
        #expect(prefs.defaultMeal == .lunch)
    }

    @Test("meal preference tracking")
    func mealTracking() throws {
        let breakfastPrefs = UserFoodPrefs(
            foodGID: "fdc:11111",
            defaultUnit: .grams,
            defaultQty: 100.0,
            defaultMeal: .breakfast
        )

        let dinnerPrefs = UserFoodPrefs(
            foodGID: "fdc:22222",
            defaultUnit: .milliliters,
            defaultQty: 250.0,
            defaultMeal: .dinner
        )

        #expect(breakfastPrefs.defaultMeal == .breakfast)
        #expect(dinnerPrefs.defaultMeal == .dinner)
    }

    @Test("Unit encoding/decoding especially household")
    func unitEncoding() throws {
        // Test basic units
        let gramsPrefs = UserFoodPrefs(
            foodGID: "test1",
            defaultUnit: .grams,
            defaultQty: 1.0,
            defaultMeal: .lunch
        )
        #expect(gramsPrefs.defaultUnit == .grams)
        #expect(gramsPrefs.defaultUnitRaw == "grams")

        let mlPrefs = UserFoodPrefs(
            foodGID: "test2",
            defaultUnit: .milliliters,
            defaultQty: 1.0,
            defaultMeal: .lunch
        )
        #expect(mlPrefs.defaultUnit == .milliliters)
        #expect(mlPrefs.defaultUnitRaw == "milliliters")

        let servingPrefs = UserFoodPrefs(
            foodGID: "test3",
            defaultUnit: .serving,
            defaultQty: 1.0,
            defaultMeal: .lunch
        )
        #expect(servingPrefs.defaultUnit == .serving)
        #expect(servingPrefs.defaultUnitRaw == "serving")

        // Test household unit encoding/decoding
        let householdPrefs = UserFoodPrefs(
            foodGID: "test4",
            defaultUnit: .household(label: "1 cup"),
            defaultQty: 1.0,
            defaultMeal: .lunch
        )
        #expect(householdPrefs.defaultUnit == .household(label: "1 cup"))
        #expect(householdPrefs.defaultUnitRaw == "household:1 cup")

        // Test updating household unit
        householdPrefs.defaultUnit = .household(label: "1 slice")
        #expect(householdPrefs.defaultUnit == .household(label: "1 slice"))
        #expect(householdPrefs.defaultUnitRaw == "household:1 slice")
    }

    @Test("upsert behavior")
    func upsert() throws {
        let prefs = UserFoodPrefs(
            userId: "default",
            foodGID: "fdc:99999",
            defaultUnit: .grams,
            defaultQty: 100.0,
            defaultMeal: .snack
        )

        // Test updating preferences
        let initialUpdatedAt = prefs.updatedAt
        Thread.sleep(forTimeInterval: 0.1) // Simulate time passing

        prefs.defaultUnit = .serving
        prefs.defaultQty = 2.0
        prefs.defaultMeal = .dinner

        #expect(prefs.defaultUnit == .serving)
        #expect(prefs.defaultQty == 2.0)
        #expect(prefs.defaultMeal == .dinner)
        #expect(prefs.updatedAt > initialUpdatedAt)
    }

    @Test("default values")
    func defaultValues() throws {
        let prefs = UserFoodPrefs(
            foodGID: "fdc:default",
            defaultUnit: .serving,
            defaultQty: 1.0,
            defaultMeal: .lunch
        )

        #expect(prefs.userId == "default")
        #expect(prefs.foodGID == "fdc:default")
        #expect(prefs.defaultUnit == .serving)
        #expect(prefs.defaultQty == 1.0)
        #expect(prefs.defaultMeal == .lunch)
    }

    @Test("meal fallback for invalid raw value")
    func mealFallback() throws {
        let prefs = UserFoodPrefs(
            foodGID: "test_fallback",
            defaultUnit: .serving,
            defaultQty: 1.0,
            defaultMeal: .breakfast
        )

        // Simulate invalid raw value
        prefs.defaultMealRaw = "invalid_meal"

        // Should fallback to lunch
        #expect(prefs.defaultMeal == .lunch)
    }

    @Test("unit fallback for invalid raw value")
    func unitFallback() throws {
        let prefs = UserFoodPrefs(
            foodGID: "test_unit_fallback",
            defaultUnit: .grams,
            defaultQty: 1.0,
            defaultMeal: .lunch
        )

        // Simulate invalid raw value
        prefs.defaultUnitRaw = "invalid_unit"

        // Should fallback to serving
        #expect(prefs.defaultUnit == .serving)
    }

    @Test("computed property updates timestamp")
    func computedPropertyUpdatesTimestamp() throws {
        let prefs = UserFoodPrefs(
            foodGID: "test_timestamp",
            defaultUnit: .grams,
            defaultQty: 1.0,
            defaultMeal: .lunch
        )

        let initialUpdatedAt = prefs.updatedAt
        Thread.sleep(forTimeInterval: 0.1)

        // Update via computed property
        prefs.defaultUnit = .milliliters
        #expect(prefs.updatedAt > initialUpdatedAt)

        let secondUpdateAt = prefs.updatedAt
        Thread.sleep(forTimeInterval: 0.1)

        prefs.defaultMeal = .dinner
        #expect(prefs.updatedAt > secondUpdateAt)
    }
}
