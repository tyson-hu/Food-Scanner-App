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
    var fat: Double
    var saturatedFat: Double?
    var carbs: Double
    var fiber: Double?
    var sugars: Double?
    var addedSugars: Double?
    var sodium: Double?
    var cholesterol: Double?
}

protocol FoodLogRepository: Sendable {
    var store: FoodLogStore { get }

    func log(_ entry: FoodEntry) async throws
    func entries(on day: Date) async throws -> [FoodEntryDTO]
    func entries(on day: Date, forMeal: Meal) async throws -> [FoodEntryDTO]
    func totals(on day: Date) async throws -> DayTotals
    func update(_ entry: FoodEntry) async throws
    func delete(entryId: UUID) async throws
}
