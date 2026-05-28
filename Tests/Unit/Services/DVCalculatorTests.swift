//
//  DVCalculatorTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Calry
import Testing

@Suite("DVCalculator Service")
struct DVCalculatorTests {
    @Test("percent DV for energy/calories")
    func percentDVEnergy() throws {
        // Test energy calculations
        #expect(DVCalculator.percentDV(for: "energy", amount: 1_000) == 50.0)
        #expect(DVCalculator.percentDV(for: "calories", amount: 2_000) == 100.0)
        #expect(DVCalculator.percentDV(for: "kcal", amount: 500) == 25.0)

        // Test case insensitivity
        #expect(DVCalculator.percentDV(for: "ENERGY", amount: 1_000) == 50.0)
        #expect(DVCalculator.percentDV(for: "Calories", amount: 1_000) == 50.0)
    }

    @Test("percent DV for protein")
    func percentDVProtein() throws {
        #expect(DVCalculator.percentDV(for: "protein", amount: 25) == 50.0)
        #expect(DVCalculator.percentDV(for: "protein", amount: 50) == 100.0)
        #expect(DVCalculator.percentDV(for: "protein", amount: 12.5) == 25.0)
    }

    @Test("percent DV for fat")
    func percentDVFat() throws {
        #expect(DVCalculator.percentDV(for: "fat", amount: 39) == 50.0)
        #expect(DVCalculator.percentDV(for: "total fat", amount: 78) == 100.0)
        #expect(DVCalculator.percentDV(for: "FAT", amount: 19.5) == 25.0)
    }

    @Test("percent DV for saturated fat")
    func percentDVSaturatedFat() throws {
        #expect(DVCalculator.percentDV(for: "saturated fat", amount: 10) == 50.0)
        #expect(DVCalculator.percentDV(for: "saturatedfat", amount: 20) == 100.0)
        #expect(DVCalculator.percentDV(for: "Saturated Fat", amount: 5) == 25.0)
    }

    @Test("percent DV for carbohydrates")
    func percentDVCarbs() throws {
        #expect(DVCalculator.percentDV(for: "carbs", amount: 137.5) == 50.0)
        #expect(DVCalculator.percentDV(for: "carbohydrate", amount: 275) == 100.0)
        #expect(DVCalculator.percentDV(for: "carbohydrates", amount: 68.75) == 25.0)
        #expect(DVCalculator.percentDV(for: "total carbohydrate", amount: 275) == 100.0)
    }

    @Test("percent DV for fiber")
    func percentDVFiber() throws {
        #expect(DVCalculator.percentDV(for: "fiber", amount: 14) == 50.0)
        #expect(DVCalculator.percentDV(for: "dietary fiber", amount: 28) == 100.0)
        #expect(DVCalculator.percentDV(for: "Fiber", amount: 7) == 25.0)
    }

    @Test("percent DV for sodium")
    func percentDVSodium() throws {
        #expect(DVCalculator.percentDV(for: "sodium", amount: 1_150) == 50.0)
        #expect(DVCalculator.percentDV(for: "sodium", amount: 2_300) == 100.0)
        #expect(DVCalculator.percentDV(for: "Sodium", amount: 575) == 25.0)
    }

    @Test("percent DV for cholesterol")
    func percentDVCholesterol() throws {
        #expect(DVCalculator.percentDV(for: "cholesterol", amount: 150) == 50.0)
        #expect(DVCalculator.percentDV(for: "cholesterol", amount: 300) == 100.0)
        #expect(DVCalculator.percentDV(for: "Cholesterol", amount: 75) == 25.0)
    }

    @Test("returns nil for unknown nutrients")
    func unknownNutrients() throws {
        #expect(DVCalculator.percentDV(for: "unknown nutrient", amount: 100) == nil)
        #expect(DVCalculator.percentDV(for: "vitamin c", amount: 100) == nil)
        #expect(DVCalculator.percentDV(for: "calcium", amount: 100) == nil)
        #expect(DVCalculator.percentDV(for: "iron", amount: 100) == nil)
    }

    @Test("returns nil for sugars (no established DV)")
    func sugarsNoDV() throws {
        #expect(DVCalculator.percentDV(for: "sugars", amount: 50) == nil)
        #expect(DVCalculator.percentDV(for: "total sugars", amount: 50) == nil)
        #expect(DVCalculator.percentDV(for: "added sugars", amount: 25) == nil)
        #expect(DVCalculator.percentDV(for: "addedsugars", amount: 25) == nil)
    }

    @Test("handles zero amounts")
    func zeroAmounts() throws {
        #expect(DVCalculator.percentDV(for: "energy", amount: 0) == 0.0)
        #expect(DVCalculator.percentDV(for: "protein", amount: 0) == 0.0)
        #expect(DVCalculator.percentDV(for: "fat", amount: 0) == 0.0)
        #expect(DVCalculator.percentDV(for: "sodium", amount: 0) == 0.0)
    }

    @Test("handles negative amounts")
    func negativeAmounts() throws {
        #expect(DVCalculator.percentDV(for: "energy", amount: -100) == nil)
        #expect(DVCalculator.percentDV(for: "protein", amount: -50) == nil)
        #expect(DVCalculator.percentDV(for: "fat", amount: -25) == nil)
    }

    @Test("handles whitespace and case variations")
    func whitespaceAndCaseVariations() throws {
        #expect(DVCalculator.percentDV(for: "  ENERGY  ", amount: 1_000) == 50.0)
        #expect(DVCalculator.percentDV(for: "total   fat", amount: 78) == 100.0)
        #expect(DVCalculator.percentDV(for: "SATURATED FAT", amount: 10) == 50.0)
        #expect(DVCalculator.percentDV(for: "dietary  fiber", amount: 14) == 50.0)
    }

    @Test("percentDVs for multiple nutrients")
    func percentDVsMultiple() throws {
        let nutrients = [
            "energy": 1_000.0,
            "protein": 25.0,
            "fat": 39.0,
            "sodium": 1_150.0,
            "sugars": 50.0, // Should be excluded (no DV)
            "unknown": 100.0 // Should be excluded (unknown)
        ]

        let result = DVCalculator.percentDVs(for: nutrients)

        #expect(result.count == 4)
        #expect(result["energy"] == 50.0)
        #expect(result["protein"] == 50.0)
        #expect(result["fat"] == 50.0)
        #expect(result["sodium"] == 50.0)
        #expect(result["sugars"] == nil)
        #expect(result["unknown"] == nil)
    }

    @Test("percentDVs with empty input")
    func percentDVsEmpty() throws {
        let result = DVCalculator.percentDVs(for: [:])
        #expect(result.isEmpty)
    }

    @Test("percentDVs with all unknown nutrients")
    func percentDVsAllUnknown() throws {
        let nutrients = [
            "sugars": 50.0,
            "unknown": 100.0,
            "vitamin c": 75.0
        ]

        let result = DVCalculator.percentDVs(for: nutrients)
        #expect(result.isEmpty)
    }
}
