//
//  PortionSheetView.swift
//  Calry
//
//  Created by Tyson Hu on 10/13/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import Observation
import SwiftData
import SwiftUI

struct PortionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: PortionSheetViewModel
    let onComplete: () async -> Void

    init(
        mode: PortionSheetMode,
        foodGID: String,
        meal: Meal,
        store: FoodLogStore,
        repository: FoodLogRepository,
        onComplete: @escaping () async -> Void
    ) {
        _viewModel = State(initialValue: PortionSheetViewModel(
            mode: mode,
            foodGID: foodGID,
            meal: meal,
            store: store,
            repository: repository
        ))
        self.onComplete = onComplete
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let error = viewModel.error {
                    ContentUnavailableView(
                        "Error",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                } else {
                    portionContent
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(actionTitle) {
                        Task {
                            await viewModel.saveEntry()
                            await onComplete()
                            dismiss()
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.load()
        }
    }

    private var navigationTitle: String {
        switch viewModel.mode {
        case .add:
            "Add to \(viewModel.meal.displayName)"
        case .edit:
            "Edit Entry"
        }
    }

    private var actionTitle: String {
        switch viewModel.mode {
        case .add:
            "Add"
        case .edit:
            "Save"
        }
    }

    @ViewBuilder
    private var portionContent: some View {
        @Bindable var bindableVM = viewModel

        List {
            foodSection
            portionSection
            nutritionSection
        }
    }

    @ViewBuilder
    private var foodSection: some View {
        Section("Food") {
            Text(viewModel.foodRef?.name ?? "Unknown")
                .font(AppTheme.Typography.headline)
            if let brand = viewModel.foodRef?.brand {
                Text(brand)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var portionSection: some View {
        @Bindable var bindableVM = viewModel

        Section("Portion") {
            Stepper(value: $bindableVM.quantity, in: 0.1 ... 100, step: 0.5) {
                HStack {
                    Text("Quantity")
                    Spacer()
                    Text(String(format: "%.1f", viewModel.quantity))
                        .font(AppTheme.Typography.headline)
                }
            }
            .onChange(of: viewModel.quantity) {
                viewModel.updateLiveSnapshot()
            }

            Picker("Unit", selection: $bindableVM.selectedUnit) {
                ForEach(viewModel.availableUnits, id: \.self) { unit in
                    Text(unit.displayName).tag(unit)
                }
            }
            .onChange(of: viewModel.selectedUnit) {
                viewModel.updateLiveSnapshot()
            }

            Picker("Meal", selection: $bindableVM.meal) {
                ForEach(Meal.allCases, id: \.self) { meal in
                    Text(meal.displayName).tag(meal)
                }
            }
        }
    }

    @ViewBuilder
    private var nutritionSection: some View {
        Section("Nutrition Preview") {
            liveNutrientsPreview
        }
    }

    private var liveNutrientsPreview: some View {
        VStack(spacing: 8) {
            nutrientRow(label: "Calories", value: viewModel.liveSnapshot.energyKcal, unit: "kcal")
            nutrientRow(label: "Protein", value: viewModel.liveSnapshot.protein, unit: "g")
            nutrientRow(label: "Fat", value: viewModel.liveSnapshot.fat, unit: "g")
            nutrientRow(label: "Carbs", value: viewModel.liveSnapshot.carbs, unit: "g")
            if let fiber = viewModel.liveSnapshot.fiber {
                nutrientRow(label: "Fiber", value: fiber, unit: "g")
            }
            if let sodium = viewModel.liveSnapshot.sodium {
                nutrientRow(label: "Sodium", value: sodium, unit: "mg")
            }
        }
    }

    private func nutrientRow(label: String, value: Double?, unit: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            if let value {
                Text("\(String(format: "%.1f", value)) \(unit)")
                    .font(AppTheme.Typography.headline)
            } else {
                Text("--")
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let schema = Schema([FoodEntry.self, FoodRef.self, UserFoodPrefs.self, RecentFood.self])
    let container: ModelContainer = {
        do { return try ModelContainer(for: schema, configurations: config) } catch {
            preconditionFailure("Failed to create preview ModelContainer: \(error)")
        }
    }()

    let store = FoodLogStore(container: container)
    let repository = FoodLogRepositorySwiftData(store: store)

    return PortionSheetView(
        mode: .add,
        foodGID: "sample-gid",
        meal: .lunch,
        store: store,
        repository: repository,
        onComplete: {}
    )
}
