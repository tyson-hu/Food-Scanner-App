//
//  FDCMockTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Food_Scanner
import Foundation
import Testing

struct FDCMockTests {
    private let client = FDCMock()

    // Basic search returns known yogurt entry
    @Test @MainActor func search_returns_expected_items() async throws {
        let results = try await client.searchFoods(matching: "yogurt", page: 1)
        #expect(results.contains(where: { $0.id == 1_234 && $0.name.contains("Greek Yogurt") }))
    }

    // Search is case-insensitive and matches brand tokens
    @Test @MainActor func search_is_case_insensitive_and_brand_aware() async throws {
        let results = try await client.searchFoods(matching: "CHOBANI yogurt", page: 1)
        #expect(results.contains(where: { $0.id == 1_004 && $0.name.contains("Strawberry") }))
    }

    // Empty query yields empty results
    @Test @MainActor func search_empty_query_yields_empty() async throws {
        let results = try await client.searchFoods(matching: "   ", page: 1)
        #expect(results.isEmpty)
    }

    // Paging never exceeds page size
    @Test @MainActor func search_page_size_limit() async throws {
        let results = try await client.searchFoods(matching: "a", page: 1) // broad term
        #expect(results.count <= 20)
    }

    // Details for known IDs are stable
    @Test @MainActor func details_known_id_are_correct() async throws {
        let details = try await client.fetchFoodDetails(fdcId: 5_678) // Peanut Butter
        #expect(details.name == "Peanut Butter")
        #expect(details.brand == "Jif")
        #expect(details.calories == 190)
        #expect(details.protein == 7)
        #expect(details.fat == 16)
        #expect(details.carbs == 8)
    }

    // Unknown IDs fall back to a safe default
    @Test @MainActor func details_unknown_id_fallback() async throws {
        let details = try await client.fetchFoodDetails(fdcId: 999_999)
        #expect(details.name == "Brown Rice, cooked")
        #expect(details.calories == 216)
    }

    // MARK: - Barcode GID Tests

    // Test that barcode search returns GTIN GID
    @Test @MainActor func barcode_search_returns_gtin_gid() async throws {
        let result = try await client.getFoodByBarcode(code: "031604031121")
        #expect(result.id.hasPrefix("gtin:"))
        #expect(result.description == "Greek Yogurt, Strawberry")
        #expect(result.brand == "Chobani")
    }

    // Test that GTIN GID can be resolved back to food details
    @Test @MainActor func gtin_gid_resolves_to_food_details() async throws {
        // First get a barcode result
        let barcodeResult = try await client.getFoodByBarcode(code: "031604031121")
        let gtinGid = barcodeResult.id

        // Then resolve the GTIN GID
        let foodResult = try await client.getFood(gid: gtinGid)
        #expect(foodResult.id == gtinGid)
        #expect(foodResult.description == "Greek Yogurt, Strawberry")
        #expect(foodResult.brand == "Chobani")
    }

    // Test that GTIN GID can be resolved to detailed food information
    @Test @MainActor func gtin_gid_resolves_to_detailed_food() async throws {
        // First get a barcode result
        let barcodeResult = try await client.getFoodByBarcode(code: "031604031121")
        let gtinGid = barcodeResult.id

        // Then get detailed food information
        let detailedResult = try await client.getFoodDetails(gid: gtinGid)
        #expect(detailedResult.id == gtinGid)
        #expect(detailedResult.description == "Greek Yogurt, Strawberry")
        #expect(detailedResult.brand == "Chobani")
        #expect(!detailedResult.nutrients.isEmpty)
    }

    // Test that unknown barcode returns no results
    @Test @MainActor func unknown_barcode_returns_no_results() async throws {
        do {
            _ = try await client.getFoodByBarcode(code: "9999999999999")
            Issue.record("Expected no results for unknown barcode")
        } catch FoodDataError.noResults {
            // Expected behavior
        } catch {
            Issue.record("Expected FoodDataError.noResults, got \(error)")
        }
    }
}
