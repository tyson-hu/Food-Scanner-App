//
//  RecentFood.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData

@Model
public final class RecentFood {
    public var userId: String = "default"
    public var foodGID: String
    public var lastUsedAt: Date
    public var useCount: Int = 1
    public var isFavorite: Bool = false

    public init(
        foodGID: String,
        userId: String = "default",
        lastUsedAt: Date = Date(),
        useCount: Int = 1,
        isFavorite: Bool = false
    ) {
        self.userId = userId
        self.foodGID = foodGID
        self.lastUsedAt = lastUsedAt
        self.useCount = useCount
        self.isFavorite = isFavorite
    }

    // Scoring: 70% recency + 30% frequency
    public nonisolated var score: Double {
        let recencyWeight = 0.7
        let frequencyWeight = 0.3

        let daysSinceUse = Date().timeIntervalSince(lastUsedAt) / 86_400.0
        let recencyScore = max(0, 1.0 - (daysSinceUse / 90.0)) // 90-day window
        let frequencyScore = min(1.0, Double(useCount) / 50.0) // cap at 50 uses

        return recencyScore * recencyWeight + frequencyScore * frequencyWeight
    }

    // Helper method to update usage
    public func recordUsage() {
        lastUsedAt = Date()
        useCount += 1
    }

    // Helper method to toggle favorite
    public func toggleFavorite() {
        isFavorite.toggle()
    }
}
