//
//  TodayView.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftData
import SwiftUI

struct TodayView: View {
    // Live query for *today's* entries; updates automatically when you save a new FoodEntry.
    @Query private var entries: [FoodEntry]

    init() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\.date, order: .reverse)],
            animation: .default
        )
    }

    // Aggregate totals, rounded to whole numbers for the UI.
    private struct NutritionTotals {
        let calories: Int
        let protein: Int
        let fat: Int
        let carbs: Int
    }

    private var totals: NutritionTotals {
        let aggregated = entries.reduce(into: (0.0, 0.0, 0.0, 0.0)) { accumulator, entry in
            accumulator.0 += entry.calories
            accumulator.1 += entry.protein
            accumulator.2 += entry.fat
            accumulator.3 += entry.carbs
        }
        return NutritionTotals(
            calories: Int(aggregated.0.rounded()),
            protein: Int(aggregated.1.rounded()),
            fat: Int(aggregated.2.rounded()),
            carbs: Int(aggregated.3.rounded())
        )
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary").font(.title2).bold()

                    HStack {
                        Text("Calories \(totals.calories)")
                        Spacer()
                        Text("P \(totals.protein) • F \(totals.fat) • C \(totals.carbs) g")
                    }
                    .foregroundStyle(.secondary)
                }
            }

            Section("Entries") {
                ForEach(entries, id: \.id) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.name)
                            .font(.headline)
                        Text(entry.servingDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No entries yet",
                        systemImage: "tray",
                        description: Text("Add something on the Add tab.")
                    )
                }
            }
        }
        .navigationTitle("Today")
    }
}

#Preview { TodayView() }
