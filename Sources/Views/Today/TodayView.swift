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
            VStack(spacing: AppTheme.Spacing.lg) {
                TodayHeaderView(currentDate: $bindableVM.currentDate)
                TodaySummaryView(
                    totals: viewModel.totals,
                    onAddFood: { viewModel.openSearch(forMeal: .lunch) }
                )

                QuickAddGridView(
                    recentFoods: viewModel.recentFoods,
                    favoriteFoods: viewModel.favoriteFoods,
                    foodNames: viewModel.foodNames,
                    onSelect: { gid, meal in viewModel.quickAdd(foodGID: gid, meal: meal) }
                )

                mealSections(viewModel)
            }
        }
        .task(id: viewModel.currentDate) {
            await viewModel.load()
        }
        .task {
            await viewModel.loadQuickAdd()
        }
        .sheet(item: $bindableVM.activeSheet) { route in
            sheetContent(for: route, viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func mealSections(_ viewModel: TodayViewModel) -> some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            MealSectionView(
                meal: .breakfast,
                entries: viewModel.breakfastEntries,
                onAddFood: { viewModel.openSearch(forMeal: .breakfast) },
                onEditEntry: { viewModel.editEntry($0) },
                onDeleteEntry: { id in Task { await viewModel.deleteEntry(id) } }
            )

            MealSectionView(
                meal: .lunch,
                entries: viewModel.lunchEntries,
                onAddFood: { viewModel.openSearch(forMeal: .lunch) },
                onEditEntry: { viewModel.editEntry($0) },
                onDeleteEntry: { id in Task { await viewModel.deleteEntry(id) } }
            )

            MealSectionView(
                meal: .dinner,
                entries: viewModel.dinnerEntries,
                onAddFood: { viewModel.openSearch(forMeal: .dinner) },
                onEditEntry: { viewModel.editEntry($0) },
                onDeleteEntry: { id in Task { await viewModel.deleteEntry(id) } }
            )

            MealSectionView(
                meal: .snack,
                entries: viewModel.snackEntries,
                onAddFood: { viewModel.openSearch(forMeal: .snack) },
                onEditEntry: { viewModel.editEntry($0) },
                onDeleteEntry: { id in Task { await viewModel.deleteEntry(id) } }
            )
        }
    }

    @ViewBuilder
    private func sheetContent(for route: SheetRoute, viewModel: TodayViewModel) -> some View {
        switch route {
        case let .search(meal, onSelect):
            NavigationStack {
                FoodSearchView(onSelect: onSelect)
                    .navigationTitle("Add to \(meal.displayName)")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                viewModel.activeSheet = nil
                            }
                        }
                    }
            }
        case let .portion(foodGID, meal):
            PortionSheetView(
                mode: .add,
                foodGID: foodGID,
                meal: meal,
                store: viewModel.store,
                repository: viewModel.repository,
                onComplete: {
                    await viewModel.load()
                }
            )
        case let .editEntry(entryId):
            editEntrySheet(entryId: entryId, viewModel: viewModel)
        }
    }

    @ViewBuilder
    private func editEntrySheet(entryId: UUID, viewModel: TodayViewModel) -> some View {
        if let entry = viewModel.entries.first(where: { $0.id == entryId }),
           let foodGID = entry.foodGID {
            PortionSheetView(
                mode: .edit(entryId: entryId),
                foodGID: foodGID,
                meal: entry.meal,
                store: viewModel.store,
                repository: viewModel.repository,
                onComplete: {
                    await viewModel.load()
                }
            )
        } else {
            ContentUnavailableView(
                "Entry Not Found",
                systemImage: "exclamationmark.triangle",
                description: Text("The selected entry could not be found.")
            )
        }
    }
}

#Preview { TodayView() }
