//
//  AddFoodSummaryView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftData
import SwiftUI

struct AddFoodSummaryView: View {
    let gid: String?
    let foodCard: FoodCard?
    var onLog: (FoodEntry) -> Void
    var onShowDetails: (String) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: AddFoodSummaryViewModel?
    @State private var showUnsupportedProduct = false

    // Initializer for when we have a GID (text search, photo recognition)
    init(gid: String, onLog: @escaping (FoodEntry) -> Void, onShowDetails: @escaping (String) -> Void) {
        self.gid = gid
        foodCard = nil
        self.onLog = onLog
        self.onShowDetails = onShowDetails
    }

    // Initializer for when we have the food card directly (barcode scan)
    init(foodCard: FoodCard, onLog: @escaping (FoodEntry) -> Void, onShowDetails: @escaping (String) -> Void) {
        gid = nil
        self.foodCard = foodCard
        self.onLog = onLog
        self.onShowDetails = onShowDetails
    }

    var body: some View {
        Group {
            if let viewModel {
                summaryContent(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        if let gid {
                            // Load from GID (text search, photo recognition)
                            viewModel = AddFoodSummaryViewModel(gid: gid, client: appEnv.fdcClient)
                        } else if let foodCard {
                            // Use food card directly (barcode scan)
                            viewModel = AddFoodSummaryViewModel(foodCard: foodCard)
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func summaryContent(_ viewModel: AddFoodSummaryViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        switch bindableViewModel.phase {
        case .loading:
            ProgressView()
                .task { await viewModel.load() }

        case let .loaded(foodCard):
            loadedFoodCardView(foodCard, Binding(
                get: { bindableViewModel },
                set: { bindableViewModel = $0 }
            ))

        case let .error(message):
            errorView(message, viewModel)
        }
    }

    @ViewBuilder
    private func loadedFoodCardView(
        _ foodCard: FoodCard,
        _ bindableViewModel: Binding<AddFoodSummaryViewModel>
    ) -> some View {
        List {
            servingMultiplierSection(foodCard, bindableViewModel)
            basicInformationSection(foodCard)
            servingInformationSection(foodCard)
            nutritionSection(foodCard, bindableViewModel)
            sourceInformationSection(foodCard)
            actionSection(foodCard, bindableViewModel)
        }
        .navigationTitle("Food Summary")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showUnsupportedProduct) {
            unsupportedProductSheet()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                toolbarButton()
            }
        }
    }

    @ViewBuilder
    private func servingMultiplierSection(
        _ foodCard: FoodCard,
        _ bindableViewModel: Binding<AddFoodSummaryViewModel>
    ) -> some View {
        Section {
            Stepper(
                value: bindableViewModel.servingMultiplier,
                in: 0.25 ... 10.0,
                step: 0.25
            ) {
                Text(
                    "Portion: \(String(format: "%.2f", bindableViewModel.wrappedValue.servingMultiplier))× \(foodCard.baseUnit.per100DisplayName)"
                )
            }
        } header: {
            Text("Adjust portion size (multiplier for \(foodCard.baseUnit.per100DisplayName) values)")
        }
    }

    @ViewBuilder
    private func basicInformationSection(_ foodCard: FoodCard) -> some View {
        Section("Food Information") {
            InfoRow(label: "Name", value: foodCard.description)
            InfoRow(label: "Brand", value: foodCard.brand)
            InfoRow(label: "Type", value: foodCard.kind.rawValue.capitalized)
            if let code = foodCard.code {
                InfoRow(label: "Barcode", value: code)
            }
        }
    }

    @ViewBuilder
    private func servingInformationSection(_ foodCard: FoodCard) -> some View {
        if let serving = foodCard.serving {
            Section("Serving Information") {
                if let amount = serving.amount {
                    InfoRow(
                        label: "Amount",
                        value: "\(String(format: "%.1f", amount)) \(serving.unit ?? "")"
                    )
                }
                if let household = serving.household {
                    InfoRow(label: "Household", value: household)
                }
            }
        }
    }

    @ViewBuilder
    private func nutritionSection(
        _ foodCard: FoodCard,
        _ bindableViewModel: Binding<AddFoodSummaryViewModel>
    ) -> some View {
        Section("Nutrition (\(foodCard.baseUnit.per100DisplayName))") {
            let nutrients = foodCard.per100Base.isEmpty ? foodCard.nutrients : foodCard.per100Base

            nutritionRows(nutrients: nutrients, multiplier: bindableViewModel.wrappedValue.servingMultiplier)
        }
    }

    @ViewBuilder
    private func nutritionRows(nutrients: [FoodNutrient], multiplier: Double) -> some View {
        BasicNutrientRow(
            name: "Calories",
            value: findNutrientValuePer100Base(nutrients, names: ["Energy", "Calories", "Calorie"]),
            unit: "kcal",
            multiplier: multiplier
        )

        BasicNutrientRow(
            name: "Protein",
            value: findNutrientValuePer100Base(nutrients, names: ["Protein", "Total protein"]),
            unit: "g",
            multiplier: multiplier
        )

        BasicNutrientRow(
            name: "Total Fat",
            value: findNutrientValuePer100Base(nutrients, names: ["Total lipid (fat)", "Fat", "Total fat"]),
            unit: "g",
            multiplier: multiplier
        )

        BasicNutrientRow(
            name: "Carbohydrates",
            value: findNutrientValuePer100Base(
                nutrients,
                names: ["Carbohydrate, by difference", "Carbohydrates", "Total carbohydrate"]
            ),
            unit: "g",
            multiplier: multiplier
        )

        BasicNutrientRow(
            name: "Fiber",
            value: findNutrientValuePer100Base(
                nutrients,
                names: ["Fiber, total dietary", "Dietary fiber", "Fiber"]
            ),
            unit: "g",
            multiplier: multiplier
        )

        BasicNutrientRow(
            name: "Sugars",
            value: findNutrientValuePer100Base(
                nutrients,
                names: ["Sugars, total including NLEA", "Sugars", "Total sugars"]
            ),
            unit: "g",
            multiplier: multiplier
        )
    }

    @ViewBuilder
    private func sourceInformationSection(_ foodCard: FoodCard) -> some View {
        Section("Source") {
            InfoRow(label: "Source", value: foodCard.provenance.source.rawValue.uppercased())
            InfoRow(label: "ID", value: foodCard.provenance.id)
            InfoRow(label: "Fetched", value: formatDate(foodCard.provenance.fetchedAt))
        }
    }

    @ViewBuilder
    private func actionSection(
        _ foodCard: FoodCard,
        _ bindableViewModel: Binding<AddFoodSummaryViewModel>
    ) -> some View {
        Section {
            Button("Log Food") {
                let entry = FoodEntry.from(
                    foodCard: foodCard,
                    multiplier: bindableViewModel.wrappedValue.servingMultiplier
                )
                onLog(entry)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private func unsupportedProductSheet() -> some View {
        let productId: String? = gid ?? foodCard?.id
        if let productId {
            let source = ProductSourceDetection.extractSource(from: productId)
            UnsupportedProductView(
                gid: productId,
                source: source,
                onSearchSimilar: {
                    showUnsupportedProduct = false
                },
                onTryDifferentBarcode: {
                    showUnsupportedProduct = false
                }
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func toolbarButton() -> some View {
        let productId: String? = gid ?? foodCard?.id
        if let productId {
            let supportStatus = ProductSourceDetection.detectSupportStatus(from: productId)
            switch supportStatus {
            case .supported:
                Button("Details") {
                    onShowDetails(productId)
                }
            case .unsupported, .unknown:
                Button("Why No Details?") {
                    showUnsupportedProduct = true
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func errorView(_ message: String, _ viewModel: AddFoodSummaryViewModel) -> some View {
        VStack {
            Text("Error: \(message)")
                .foregroundColor(.red)
            Button("Retry") {
                Task { await viewModel.load() }
            }
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            return displayFormatter.string(from: date)
        }
        return dateString
    }

    // Pre-built nutrient name mappings for efficient lookup
    private static let nutrientNameMappings: [String: [String]] = [
        "Energy": ["Energy", "Calories", "Calorie"],
        "Protein": ["Protein", "Total protein"],
        "Fat": ["Total lipid (fat)", "Fat", "Total fat"],
        "Carbohydrates": ["Carbohydrate, by difference", "Carbohydrates", "Total carbohydrate"],
        "Fiber": ["Fiber, total dietary", "Dietary fiber", "Fiber"],
        "Sugars": ["Sugars, total including NLEA", "Sugars", "Total sugars"],
        "Sodium": ["Sodium, Na", "Sodium"],
        "Calcium": ["Calcium, Ca", "Calcium"],
        "Iron": ["Iron, Fe", "Iron"],
        "Potassium": ["Potassium, K", "Potassium"]
    ]

    // Pre-built lookup dictionary for faster nutrient matching
    private static var nutrientLookupCache: [String: Set<String>] = {
        var cache: [String: Set<String>] = [:]
        for (_, names) in nutrientNameMappings {
            for name in names {
                cache[name.lowercased()] = Set(names.map { $0.lowercased() })
            }
        }
        return cache
    }()

    // Helper function to find nutrient value by name variations (optimized)
    private func findNutrientValue(_ nutrients: [FoodNutrient], names: [String]) -> Double? {
        // Create a set of normalized names for faster lookup
        let normalizedNames = Set(names.map { $0.lowercased() })

        for nutrient in nutrients where normalizedNames.contains(where: { searchName in
            nutrient.name.lowercased().contains(searchName)
        }) {
            return nutrient.amount
        }

        return nil
    }

    // Helper function to find nutrient value per 100g specifically (optimized)
    private func findNutrientValuePer100g(_ nutrients: [FoodNutrient], names: [String]) -> Double? {
        // Create a set of normalized names for faster lookup
        let normalizedNames = Set(names.map { $0.lowercased() })

        for nutrient in nutrients where nutrient.basis == .per100g && normalizedNames.contains(where: { searchName in
            nutrient.name.lowercased().contains(searchName)
        }) {
            return nutrient.amount
        }

        return nil
    }

    // Helper function to find nutrient value per 100 base unit specifically (optimized)
    private func findNutrientValuePer100Base(_ nutrients: [FoodNutrient], names: [String]) -> Double? {
        // Create a set of normalized names for faster lookup
        let normalizedNames = Set(names.map { $0.lowercased() })

        for nutrient in nutrients
            where (nutrient.basis == .per100Base || nutrient.basis == .per100g) && normalizedNames
            .contains(where: { searchName in
                nutrient.name.lowercased().contains(searchName)
            }) {
            return nutrient.amount
        }

        return nil
    }
}

// MARK: - Custom Row Components

struct InfoRow: View {
    let label: String
    let value: String?

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value ?? "N/A")
                .foregroundColor(.secondary)
        }
    }
}

struct NutrientSummaryRow: View {
    let nutrient: FoodNutrient
    let multiplier: Double

    var body: some View {
        HStack {
            Text(nutrient.name)
                .font(.subheadline)
            Spacer()
            if let amount = nutrient.amount {
                Text("\(String(format: "%.1f", amount * multiplier)) \(nutrient.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("N/A")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 1)
    }
}

struct BasicNutrientRow: View {
    let name: String
    let value: Double?
    let unit: String
    let multiplier: Double

    var body: some View {
        HStack {
            Text(name)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            if let value {
                Text("\(String(format: "%.1f", value * multiplier)) \(unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("N/A")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("Sample Food Summary") {
    AddFoodSummaryView(
        gid: "fdc:123456",
        onLog: { _ in },
        onShowDetails: { _ in }
    )
    .environment(\.appEnv, .preview)
}
