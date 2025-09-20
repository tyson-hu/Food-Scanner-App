//
//  FDCMockTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation
import Testing
@testable import Food_Scanner

struct FDCMockTests {
    
    private let client = FDCMock()
    
    // Basic search returns known yogurt entry
    @Test func search_returns_expected_items() async throws {
        let results = try await client.searchFoods(matching: "yogurt", page: 1)
        #expect(results.contains(where: { $0.id == 1234 && $0.name.contains("Greek Yogurt") }))
    }
    
    // Search is case-insensitive and matches brand tokens
    @Test func search_is_case_insensitive_and_brand_aware() async throws {
        let results = try await client.searchFoods(matching: "CHOBANI yogurt", page: 1)
        #expect(results.contains(where: { $0.id == 1004 && $0.name.contains("Strawberry") }))
    }
    
    // Empty query yields empty results
    @Test func search_empty_query_yields_empty() async throws {
        let results = try await client.searchFoods(matching: "   ", page: 1)
        #expect(results.isEmpty)
    }
    
    // Paging never exceeds page size
    @Test func search_page_size_limit() async throws {
        let results = try await client.searchFoods(matching: "a", page: 1) // broad term
        #expect(results.count <= 20)
    }
    
    // Details for known IDs are stable
    @Test func details_known_id_are_correct() async throws {
        let d = try await client.fetchFoodDetails(fdcId: 5678) // Peanut Butter
        #expect(d.name == "Peanut Butter")
        #expect(d.brand == "Jif")
        #expect(d.calories == 190)
        #expect(d.protein == 7)
        #expect(d.fat == 16)
        #expect(d.carbs == 8)
    }
    
    // Unknown IDs fall back to a safe default
    @Test func details_unknown_id_fallback() async throws {
        let d = try await client.fetchFoodDetails(fdcId: 999_999)
        #expect(d.name == "Brown Rice, cooked")
        #expect(d.calories == 216)
    }
}
