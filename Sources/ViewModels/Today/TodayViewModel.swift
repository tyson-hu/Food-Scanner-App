//
//  TodayViewModel.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Observation

@Observable
final class TodayViewModel {
    var totals = DayTotals(calories: 0, protein: 0, carbs: 0, fat: 0)

    // MARK: Hook to repo later..
}
