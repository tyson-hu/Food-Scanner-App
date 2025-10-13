//
//  TodayView.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import Observation
import SwiftUI

struct TodayView: View {
    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: TodayViewModel?

    var body: some View {
        Group {
            if let viewModel {
                todayContent(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = TodayViewModel(
                            repository: appEnv.foodLogRepository,
                            store: appEnv.foodLogStore
                        )
                    }
            }
        }
        .navigationTitle("Today")
    }

    @ViewBuilder
    private func todayContent(_ viewModel: TodayViewModel) -> some View {
        @Bindable var bindableVM = viewModel

        ScrollView {
            VStack(spacing: AppTheme.Spacing.md) {
                TodayHeaderView(currentDate: $bindableVM.currentDate)
                TodaySummaryView(
                    totals: viewModel.totals,
                    onAddFood: { viewModel.openSearch(forMeal: .lunch) }
                )
                // Meal sections and quick add in later phases
            }
        }
        .task(id: viewModel.currentDate) {
            await viewModel.load()
        }
    }
}

#Preview { TodayView() }
