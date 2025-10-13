//
//  RecentFoodTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import SwiftData
import Testing

@testable import Calry

@Suite("RecentFood Model")
struct RecentFoodTests {
    @Test("recent food creation")
    func creation() throws {
        let recentFood = RecentFood(
            userId: "user123",
            foodGID: "fdc:12345",
            lastUsedAt: Date(),
            useCount: 5,
            isFavorite: true
        )

        #expect(recentFood.userId == "user123")
        #expect(recentFood.foodGID == "fdc:12345")
        #expect(recentFood.useCount == 5)
        #expect(recentFood.isFavorite == true)
        // Verify timestamp is initialized (within reasonable time window)
        let now = Date()
        let timeDifference = abs(recentFood.lastUsedAt.timeIntervalSince(now))
        #expect(timeDifference < 1.0) // Should be within 1 second
    }

    @Test("usage frequency updates")
    func frequencyUpdates() throws {
        let recentFood = RecentFood(foodGID: "fdc:67890")
        let initialCount = recentFood.useCount
        let initialLastUsed = recentFood.lastUsedAt

        Thread.sleep(forTimeInterval: 0.1) // Simulate time passing
        recentFood.recordUsage()

        #expect(recentFood.useCount == initialCount + 1)
        #expect(recentFood.lastUsedAt > initialLastUsed)
    }

    @Test("scoring algorithm 70% recency 30% frequency")
    func scoringAlgorithm() throws {
        let now = Date()
        let recentFood = RecentFood(
            foodGID: "fdc:11111",
            lastUsedAt: now,
            useCount: 10
        )

        // Fresh usage should have high recency score
        let score = recentFood.score
        #expect(score > 0.8) // Should be high due to recent usage

        // Test frequency component
        let highFrequencyFood = RecentFood(
            foodGID: "fdc:22222",
            lastUsedAt: now,
            useCount: 50 // Max frequency
        )
        let highFreqScore = highFrequencyFood.score
        #expect(highFreqScore > 0.2) // Should have good frequency component
    }

    @Test("90-day window score decays to zero")
    func ninetyDayWindow() throws {
        let oldDate = Date().addingTimeInterval(-91 * 24 * 60 * 60) // 91 days ago
        let oldFood = RecentFood(
            foodGID: "fdc:33333",
            lastUsedAt: oldDate,
            useCount: 100 // High frequency but old
        )

        let score = oldFood.score
        #expect(score < 0.1) // Should be very low due to age
    }

    @Test("favorite flag toggling")
    func favoriteToggle() throws {
        let recentFood = RecentFood(foodGID: "fdc:44444", isFavorite: false)
        #expect(recentFood.isFavorite == false)

        recentFood.toggleFavorite()
        #expect(recentFood.isFavorite == true)

        recentFood.toggleFavorite()
        #expect(recentFood.isFavorite == false)
    }

    @Test("score comparison for sorting")
    func scoreComparison() throws {
        let now = Date()
        let recentFood = RecentFood(
            foodGID: "fdc:55555",
            lastUsedAt: now,
            useCount: 5
        )

        let oldFood = RecentFood(
            foodGID: "fdc:66666",
            lastUsedAt: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
            useCount: 5
        )

        let recentScore = recentFood.score
        let oldScore = oldFood.score

        #expect(recentScore > oldScore) // Recent should score higher
    }

    @Test("frequency cap at 50 uses")
    func frequencyCap() throws {
        let now = Date()
        let cappedFood = RecentFood(
            foodGID: "fdc:77777",
            lastUsedAt: now,
            useCount: 100 // Above cap
        )

        let normalFood = RecentFood(
            foodGID: "fdc:88888",
            lastUsedAt: now,
            useCount: 50 // At cap
        )

        let cappedScore = cappedFood.score
        let normalScore = normalFood.score

        // Scores should be very close since frequency is capped
        #expect(abs(cappedScore - normalScore) < 0.01)
    }

    @Test("default values")
    func defaultValues() throws {
        let recentFood = RecentFood(foodGID: "fdc:99999")

        #expect(recentFood.userId == "default")
        #expect(recentFood.foodGID == "fdc:99999")
        #expect(recentFood.useCount == 1)
        #expect(recentFood.isFavorite == false)
        // Verify timestamp is initialized (within reasonable time window)
        let now = Date()
        let timeDifference = abs(recentFood.lastUsedAt.timeIntervalSince(now))
        #expect(timeDifference < 1.0) // Should be within 1 second
    }

    @Test("score calculation with different time intervals")
    func scoreTimeIntervals() throws {
        let now = Date()

        // Test 1 day ago
        let oneDayAgo = RecentFood(
            foodGID: "fdc:day1",
            lastUsedAt: Date().addingTimeInterval(-24 * 60 * 60),
            useCount: 1
        )

        // Test 45 days ago
        let fortyFiveDaysAgo = RecentFood(
            foodGID: "fdc:day45",
            lastUsedAt: Date().addingTimeInterval(-45 * 24 * 60 * 60),
            useCount: 1
        )

        let oneDayScore = oneDayAgo.score
        let fortyFiveDayScore = fortyFiveDaysAgo.score

        #expect(oneDayScore > fortyFiveDayScore) // More recent should score higher
        #expect(oneDayScore > 0.5) // Recent usage should have good score
        #expect(fortyFiveDayScore > 0.0) // Should still have some score
    }

    @Test("score with zero use count")
    func zeroUseCount() throws {
        let recentFood = RecentFood(
            foodGID: "fdc:zero",
            lastUsedAt: Date(),
            useCount: 0
        )

        let score = recentFood.score
        #expect(score >= 0.0) // Should not be negative
        #expect(score < 0.5) // Should be low due to zero frequency
    }
}
