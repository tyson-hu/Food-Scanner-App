//
//  FoodLogRepositorySwiftData.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation
import SwiftData

@MainActor
final class FoodLogRepositorySwiftData: FoodLogRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func log(_ entry: FoodEntry) async throws {
        context.insert(entry)
        try context.save()
    }

    func entries(on day: Date) async throws -> [FoodEntry] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: day)
        guard let end = cal.date(byAdding: .day, value: 1, to: start) else {
            return []
        }
        let descriptor = FetchDescriptor<FoodEntry>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [.init(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func totals(on day: Date) async throws -> DayTotals {
        let items = try await entries(on: day)
        return items.reduce(.init(calories: 0, protein: 0, carbs: 0, fat: 0)) { acc, entry in
            .init(
                calories: acc.calories + entry.calories,
                protein: acc.protein + entry.protein,
                carbs: acc.carbs + entry.carbs,
                fat: acc.fat + entry.fat
            )
        }
    }
}
