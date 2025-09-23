//
//  FDCMock.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//  Updated: consolidated all mock data & logic
//

import Foundation

struct FDCMock: FDCClient {
    // Canonical mock catalog (details first; summaries derived from this)
    private static let catalog: [FDCFoodDetails] = [
        .init(id: 1234, name: "Greek Yogurt, Plain", brand: "Fage", calories: 100, protein: 17, fat: 0, carbs: 6),
        .init(id: 5678, name: "Peanut Butter", brand: "Jif", calories: 190, protein: 7, fat: 16, carbs: 8),
        .init(id: 9012, name: "Brown Rice, cooked", brand: nil, calories: 216, protein: 5, fat: 2, carbs: 45),
        // extras for nicer search feel
        .init(id: 1001, name: "Banana, raw", brand: nil, calories: 90, protein: 1, fat: 0, carbs: 23),
        .init(id: 1002, name: "Chicken Breast, cooked", brand: nil, calories: 165, protein: 31, fat: 3, carbs: 0),
        .init(id: 1003, name: "Oatmeal, rolled oats", brand: nil, calories: 150, protein: 5, fat: 3, carbs: 27),
        .init(
            id: 1004,
            name: "Greek Yogurt, Strawberry",
            brand: "Chobani",
            calories: 140,
            protein: 12,
            fat: 2,
            carbs: 16
        )
    ]

    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        try? await Task.sleep(nanoseconds: 150_000_000) // small latency

        let tokens = trimmed.lowercased().split(separator: " ")
        let filtered = Self.catalog.filter { food in
            let hay = "\(food.name) \(food.brand ?? "")".lowercased()
            return tokens.allSatisfy { hay.contains($0) }
        }

        // naive paging: 20 per page
        let pageSize = 20
        let start = max(0, (page - 1) * pageSize)
        let end = min(filtered.count, start + pageSize)
        let slice = (start < end) ? filtered[start ..< end] : []

        return slice.map {
            FDCFoodSummary(id: $0.id, name: $0.name, brand: $0.brand, caloriesPerServing: $0.calories)
        }
    }

    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        try? await Task.sleep(nanoseconds: 120_000_000)
        if let hit = Self.catalog.first(where: { $0.id == fdcId }) {
            return hit
        }
        // safe fallback
        return .init(id: fdcId, name: "Brown Rice, cooked", brand: nil, calories: 216, protein: 5, fat: 2, carbs: 45)
    }
}
