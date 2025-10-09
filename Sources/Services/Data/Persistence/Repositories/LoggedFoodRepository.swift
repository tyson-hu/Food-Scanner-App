//
//  LoggedFoodRepository.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
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
