//
//  FoodLogRepository.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation

struct DayTotals: Sendable, Equatable {
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
}

protocol FoodLogRepository: Sendable {
    func log(_ entry: FoodEntry) async throws
    func entries(on day: Date) async throws -> [FoodEntry]
    func totals(on day: Date) async throws -> DayTotals
}
