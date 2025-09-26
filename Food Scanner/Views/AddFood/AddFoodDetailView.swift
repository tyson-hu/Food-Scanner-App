//
//  AddFoodDetailView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftData
import SwiftUI

struct AddFoodDetailView: View {
    let fdcId: Int
    var onLog: (FoodEntry) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: AddFoodDetailViewModel?

    init(fdcId: Int, onLog: @escaping (FoodEntry) -> Void) {
        self.fdcId = fdcId
        self.onLog = onLog
    }

    var body: some View {
        Group {
            if let viewModel {
                detailContent(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = AddFoodDetailViewModel(fdcId: fdcId, client: appEnv.fdcClient)
                    }
            }
        }
    }

    @ViewBuilder
    private func detailContent(_ viewModel: AddFoodDetailViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            switch bindableViewModel.phase {
            case .loading:
                ProgressView()
                    .task { await viewModel.load() }

            case let .loaded(foodDetailResponse):
                NavigationView {
                    List {
                        // Serving Multiplier Section
                        Section {
                            Stepper(
                                value: $bindableViewModel.servingMultiplier,
                                in: 0.25 ... 10.0,
                                step: 0.25
                            ) {
                                Text("Serving: \(String(format: "%.2f", bindableViewModel.servingMultiplier))×")
                            }
                        }

                        basicInformationSection(foodDetailResponse)
                        brandInformationSection(foodDetailResponse)
                        servingInformationSection(foodDetailResponse)
                        additionalInformationSection(foodDetailResponse)
                        dateRangeSection(foodDetailResponse)
                        footnotesSection(foodDetailResponse)
                        foodCategorySection(foodDetailResponse)
                        wweiaFoodCategorySection(foodDetailResponse)
                        tradeChannelsSection(foodDetailResponse)
                        microbesSection(foodDetailResponse)
                        highlightFieldsSection(foodDetailResponse)
                        labelNutrientsSection(foodDetailResponse, bindableViewModel)
                        nutrientsSection(foodDetailResponse, bindableViewModel)
                        inputFoodsSection(foodDetailResponse)
                        nutrientConversionFactorsSection(foodDetailResponse)
                        foodComponentsSection(foodDetailResponse)

                        // Food Portions Section
                        if let foodPortions = foodDetailResponse.foodPortions, !foodPortions.isEmpty {
                            Section("Food Portions") {
                                ForEach(foodPortions.indices, id: \.self) { index in
                                    let portion = foodPortions[index]
                                    FoodPortionRow(portion: portion)
                                }
                            }
                        }

                        // Food Measures Section
                        if let foodMeasures = foodDetailResponse.foodMeasures, !foodMeasures.isEmpty {
                            Section("Food Measures") {
                                ForEach(foodMeasures.indices, id: \.self) { index in
                                    let measure = foodMeasures[index]
                                    FoodMeasureRow(measure: measure)
                                }
                            }
                        }

                        // Food Attributes Section
                        if let foodAttributes = foodDetailResponse.foodAttributes, !foodAttributes.isEmpty {
                            Section("Food Attributes") {
                                ForEach(foodAttributes.indices, id: \.self) { index in
                                    let attribute = foodAttributes[index]
                                    FoodAttributeRow(attribute: attribute)
                                }
                            }
                        }

                        // Food Attribute Types Section
                        if let foodAttributeTypes = foodDetailResponse.foodAttributeTypes, !foodAttributeTypes.isEmpty {
                            Section("Food Attribute Types") {
                                ForEach(foodAttributeTypes.indices, id: \.self) { index in
                                    let attributeType = foodAttributeTypes[index]
                                    FoodAttributeRow(attribute: attributeType)
                                }
                            }
                        }

                        // Food Version IDs Section
                        if let foodVersionIds = foodDetailResponse.foodVersionIds, !foodVersionIds.isEmpty {
                            Section("Food Version IDs") {
                                ForEach(foodVersionIds, id: \.self) { versionId in
                                    Text(versionId)
                                        .font(.subheadline)
                                }
                            }
                        }

                        // Final Food Input Foods Section
                        if let finalFoodInputFoods = foodDetailResponse.finalFoodInputFoods,
                           !finalFoodInputFoods.isEmpty {
                            Section("Final Food Input Foods") {
                                ForEach(finalFoodInputFoods, id: \.self) { inputFood in
                                    Text(inputFood)
                                        .font(.subheadline)
                                }
                            }
                        }

                        // Action Section
                        Section {
                            Button("Log Food") {
                                // Convert back to FDCFoodDetails for logging
                                let details = foodDetailResponse.toFDCFoodDetails()
                                onLog(FoodEntry.from(
                                    details: details,
                                    multiplier: bindableViewModel.servingMultiplier
                                ))
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .navigationTitle("Food Details")
                    .navigationBarTitleDisplayMode(.large)
                }

            case let .error(message):
                VStack {
                    Text("Error: \(message)")
                        .foregroundColor(.red)
                    Button("Retry") {
                        Task { await viewModel.load() }
                    }
                }
            }
        }
    }

    // MARK: - Helper Functions for Detail Content

    @ViewBuilder
    private func basicInformationSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        Section("Basic Information") {
            InfoRow(label: "FDC ID", value: "\(foodDetailResponse.fdcId)")
            InfoRow(label: "Description", value: foodDetailResponse.description)
            InfoRow(label: "Publication Date", value: foodDetailResponse.publicationDate)
            InfoRow(label: "Data Type", value: foodDetailResponse.dataType)
            InfoRow(label: "Food Class", value: foodDetailResponse.foodClass)
            InfoRow(label: "NDB Number", value: foodDetailResponse.ndbNumber?.description)
            InfoRow(
                label: "Historical Reference",
                value: foodDetailResponse.isHistoricalReference?.description
            )
            InfoRow(label: "Scientific Name", value: foodDetailResponse.scientificName)
            InfoRow(label: "Food Code", value: foodDetailResponse.foodCode)
            InfoRow(label: "Score", value: foodDetailResponse.score?.description)
        }
    }

    @ViewBuilder
    private func brandInformationSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if foodDetailResponse.brandOwner != nil || foodDetailResponse.brandName != nil || foodDetailResponse
            .gtinUpc != nil {
            Section("Brand Information") {
                InfoRow(label: "Brand Owner", value: foodDetailResponse.brandOwner)
                InfoRow(label: "Brand Name", value: foodDetailResponse.brandName)
                InfoRow(label: "UPC/GTIN", value: foodDetailResponse.gtinUpc)
                InfoRow(label: "Data Source", value: foodDetailResponse.dataSource)
                InfoRow(label: "Market Country", value: foodDetailResponse.marketCountry)
                InfoRow(label: "Branded Food Category", value: foodDetailResponse.brandedFoodCategory)
            }
        }
    }

    @ViewBuilder
    private func servingInformationSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if foodDetailResponse.servingSize != nil || foodDetailResponse.servingSizeUnit != nil || foodDetailResponse
            .householdServingFullText != nil {
            Section("Serving Information") {
                InfoRow(label: "Serving Size", value: foodDetailResponse.servingSize?.description)
                InfoRow(label: "Serving Unit", value: foodDetailResponse.servingSizeUnit)
                InfoRow(label: "Household Serving", value: foodDetailResponse.householdServingFullText)
                InfoRow(label: "Package Weight", value: foodDetailResponse.packageWeight)
            }
        }
    }

    @ViewBuilder
    private func additionalInformationSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if foodDetailResponse.ingredients != nil || foodDetailResponse.availableDate != nil || foodDetailResponse
            .modifiedDate != nil || foodDetailResponse.discontinuedDate != nil {
            Section("Additional Information") {
                InfoRow(label: "Ingredients", value: foodDetailResponse.ingredients)
                InfoRow(label: "Available Date", value: foodDetailResponse.availableDate)
                InfoRow(label: "Modified Date", value: foodDetailResponse.modifiedDate)
                InfoRow(label: "Discontinued Date", value: foodDetailResponse.discontinuedDate)
            }
        }
    }

    @ViewBuilder
    private func dateRangeSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if foodDetailResponse.startDate != nil || foodDetailResponse.endDate != nil {
            Section("Date Range") {
                InfoRow(label: "Start Date", value: foodDetailResponse.startDate)
                InfoRow(label: "End Date", value: foodDetailResponse.endDate)
            }
        }
    }

    @ViewBuilder
    private func footnotesSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let footNote = foodDetailResponse.footNote {
            Section("Footnotes") {
                Text(footNote)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func foodCategorySection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let foodCategory = foodDetailResponse.foodCategory {
            Section("Food Category") {
                InfoRow(label: "ID", value: foodCategory.id?.description)
                InfoRow(label: "Code", value: foodCategory.code)
                InfoRow(label: "Description", value: foodCategory.description)
            }
        }
    }

    @ViewBuilder
    private func wweiaFoodCategorySection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let wweiaCategory = foodDetailResponse.wweiaFoodCategory {
            Section("WWEIA Food Category") {
                InfoRow(label: "Code", value: wweiaCategory.wweiaFoodCategoryCode?.description)
                InfoRow(label: "Description", value: wweiaCategory.wweiaFoodCategoryDescription)
            }
        }
    }

    @ViewBuilder
    private func tradeChannelsSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let tradeChannels = foodDetailResponse.tradeChannels, !tradeChannels.isEmpty {
            Section("Trade Channels") {
                ForEach(tradeChannels, id: \.self) { channel in
                    Text(channel)
                        .font(.subheadline)
                }
            }
        }
    }

    @ViewBuilder
    private func microbesSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let microbes = foodDetailResponse.microbes, !microbes.isEmpty {
            Section("Microbes") {
                ForEach(microbes, id: \.self) { microbe in
                    Text(microbe)
                        .font(.subheadline)
                }
            }
        }
    }

    @ViewBuilder
    private func highlightFieldsSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let highlightFields = foodDetailResponse.allHighlightFields {
            Section("Highlight Fields") {
                Text(highlightFields)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private func labelNutrientsSection(
        _ foodDetailResponse: ProxyFoodDetailResponse,
        _ bindableViewModel: AddFoodDetailViewModel
    ) -> some View {
        if let labelNutrients = foodDetailResponse.labelNutrients {
            Section("Label Nutrients") {
                LabelNutrientRow(
                    label: "Calories",
                    nutrient: labelNutrients.calories,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Protein",
                    nutrient: labelNutrients.protein,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Fat",
                    nutrient: labelNutrients.fat,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Saturated Fat",
                    nutrient: labelNutrients.saturatedFat,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Trans Fat",
                    nutrient: labelNutrients.transFat,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Cholesterol",
                    nutrient: labelNutrients.cholesterol,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Sodium",
                    nutrient: labelNutrients.sodium,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Carbohydrates",
                    nutrient: labelNutrients.carbohydrates,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Fiber",
                    nutrient: labelNutrients.fiber,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Sugars",
                    nutrient: labelNutrients.sugars,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Calcium",
                    nutrient: labelNutrients.calcium,
                    multiplier: bindableViewModel.servingMultiplier
                )
                LabelNutrientRow(
                    label: "Iron",
                    nutrient: labelNutrients.iron,
                    multiplier: bindableViewModel.servingMultiplier
                )
            }
        }
    }

    @ViewBuilder
    private func nutrientsSection(
        _ foodDetailResponse: ProxyFoodDetailResponse,
        _ bindableViewModel: AddFoodDetailViewModel
    ) -> some View {
        if let nutrients = foodDetailResponse.foodNutrients, !nutrients.isEmpty {
            Section("Detailed Nutrients") {
                ForEach(nutrients.indices, id: \.self) { index in
                    let nutrient = nutrients[index]
                    NutrientRow(
                        nutrient: nutrient,
                        multiplier: bindableViewModel.servingMultiplier
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func inputFoodsSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let inputFoods = foodDetailResponse.inputFoods, !inputFoods.isEmpty {
            Section("Input Foods") {
                ForEach(inputFoods.indices, id: \.self) { index in
                    let inputFood = inputFoods[index]
                    InputFoodRow(inputFood: inputFood)
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientConversionFactorsSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let conversionFactors = foodDetailResponse.nutrientConversionFactors, !conversionFactors.isEmpty {
            Section("Nutrient Conversion Factors") {
                ForEach(conversionFactors.indices, id: \.self) { index in
                    let factor = conversionFactors[index]
                    ConversionFactorRow(factor: factor)
                }
            }
        }
    }

    @ViewBuilder
    private func foodComponentsSection(_ foodDetailResponse: ProxyFoodDetailResponse) -> some View {
        if let foodComponents = foodDetailResponse.foodComponents, !foodComponents.isEmpty {
            Section("Food Components") {
                ForEach(foodComponents.indices, id: \.self) { index in
                    let component = foodComponents[index]
                    FoodComponentRow(component: component)
                }
            }
        }
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

struct NutrientRow: View {
    let nutrient: ProxyFoodNutrient
    let multiplier: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(nutrient.nutrient?.name ?? "Unknown Nutrient")
                    .font(.headline)
                Spacer()
                if let amount = nutrient.amount {
                    Text("\(String(format: "%.2f", amount * multiplier)) \(nutrient.nutrient?.unitName ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let derivation = nutrient.foodNutrientDerivation {
                Text("Derivation: \(derivation.description ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let dataPoints = nutrient.dataPoints {
                Text("Data Points: \(dataPoints)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let min = nutrient.min, let max = nutrient.max {
                Text("Range: \(String(format: "%.2f", min)) - \(String(format: "%.2f", max))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct InputFoodRow: View {
    let inputFood: ProxyInputFood

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ID: \(inputFood.id?.description ?? "N/A")")
                    .font(.headline)
                Spacer()
            }

            if let description = inputFood.foodDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let detail = inputFood.inputFood {
                VStack(alignment: .leading, spacing: 2) {
                    if let fdcId = detail.fdcId {
                        Text("FDC ID: \(fdcId)")
                            .font(.caption)
                    }
                    if let description = detail.description {
                        Text("Description: \(description)")
                            .font(.caption)
                    }
                    if let foodClass = detail.foodClass {
                        Text("Food Class: \(foodClass)")
                            .font(.caption)
                    }
                    if let foodGroup = detail.foodGroup {
                        Text("Food Group: \(foodGroup.description ?? "N/A")")
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ConversionFactorRow: View {
    let factor: ProxyNutrientConversionFactor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(factor.name ?? "Unknown Factor")
                    .font(.headline)
                Spacer()
                if let value = factor.value {
                    Text("\(String(format: "%.4f", value))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if let type = factor.type {
                Text("Type: \(type)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                if let proteinValue = factor.proteinValue {
                    Text("Protein: \(String(format: "%.2f", proteinValue))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let fatValue = factor.fatValue {
                    Text("Fat: \(String(format: "%.2f", fatValue))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let carbValue = factor.carbohydrateValue {
                    Text("Carbs: \(String(format: "%.2f", carbValue))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct FoodComponentRow: View {
    let component: AnyCodable

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Food Component")
                .font(.headline)

            Text("Data: \(String(describing: component.value))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct LabelNutrientRow: View {
    let label: String
    let nutrient: ProxyLabelNutrient?
    let multiplier: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
            Spacer()
            if let value = nutrient?.value {
                Text("\(String(format: "%.1f", value * multiplier))")
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

struct FoodAttributeRow: View {
    let attribute: AnyCodable

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Try to extract structured data from the attribute
            if let dict = attribute.value as? [String: AnyCodable] {
                // Display structured food attribute data
                if let name = dict["name"]?.value as? String {
                    Text(name)
                        .font(.headline)
                } else {
                    Text("Food Attribute")
                        .font(.headline)
                }

                HStack {
                    if let id = dict["id"]?.value as? Int {
                        Text("ID: \(id)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let value = dict["value"]?.value as? Double {
                        Text("Value: \(String(format: "%.2f", value))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let value = dict["value"]?.value as? Int {
                        Text("Value: \(value)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let value = dict["value"]?.value as? String {
                        Text("Value: \(value)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                // Fallback for unstructured data
                Text("Food Attribute")
                    .font(.headline)

                Text("Data: \(String(describing: attribute.value))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct FoodPortionRow: View {
    let portion: ProxyFoodPortion

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(portion.portionDescription ?? "Unknown Portion")
                    .font(.headline)
                Spacer()
                if let amount = portion.amount {
                    Text("\(String(format: "%.2f", amount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                if let gramWeight = portion.gramWeight {
                    Text("Weight: \(String(format: "%.1f", gramWeight))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let modifier = portion.modifier {
                    Text("Modifier: \(modifier)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let measureUnit = portion.measureUnit {
                Text("Unit: \(measureUnit.name ?? measureUnit.abbreviation ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let dataPoints = portion.dataPoints {
                Text("Data Points: \(dataPoints)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

struct FoodMeasureRow: View {
    let measure: ProxyFoodMeasure

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(measure.portionDescription ?? "Unknown Measure")
                    .font(.headline)
                Spacer()
                if let amount = measure.amount {
                    Text("\(String(format: "%.2f", amount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                if let gramWeight = measure.gramWeight {
                    Text("Weight: \(String(format: "%.1f", gramWeight))g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let modifier = measure.modifier {
                    Text("Modifier: \(modifier)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let measureUnit = measure.measureUnit {
                Text("Unit: \(measureUnit.name ?? measureUnit.abbreviation ?? "Unknown")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("Sample Food Detail") {
    AddFoodDetailView(
        fdcId: 123_456,
        onLog: { _ in }
    )
    .environment(\.appEnv, .preview)
}
