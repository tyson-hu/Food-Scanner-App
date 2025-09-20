//
//  TodayView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    // Live query for *today's* entries; updates automatically when you save a new FoodEntry.
    @Query private var entries: [FoodEntry]
    
    init() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\.date, order: .reverse)],
            animation: .default
        )
    }
    
    // Aggregate totals, rounded to whole numbers for the UI.
    private var totals: (cal: Int, p: Int, f: Int, c: Int) {
        let agg = entries.reduce(into: (0.0, 0.0, 0.0, 0.0)) { acc, e in
            acc.0 += e.calories
            acc.1 += e.protein
            acc.2 += e.fat
            acc.3 += e.carbs
        }
        return (Int(agg.0.rounded()), Int(agg.1.rounded()), Int(agg.2.rounded()), Int(agg.3.rounded()))
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary").font(.title2).bold()
                    
                    HStack {
                        Text("Calories \(totals.cal)")
                        Spacer()
                        Text("P \(totals.p) • F \(totals.f) • C \(totals.c) g")
                    }
                    .foregroundStyle(.secondary)
                }
            }
            
            Section("Entries") {
                ForEach(entries, id: \.id) { e in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(e.name)
                        Text("\(e.servingDescription) × \(e.quantity, specifier: "%.2f") — \(Int(e.calories)) kcal")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if entries.isEmpty {
                    ContentUnavailableView("No entries yet", systemImage: "tray", description: Text("Add something on the Add tab."))
                }
            }
        }
        .navigationTitle("Today")
    }
}

#Preview { TodayView() }
