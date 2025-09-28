//
//  AddFoodDetailView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
//  New view for full food details using the new API
//

import SwiftData
import SwiftUI

struct AddFoodDetailView: View {
    let gid: String
    var onLog: (FoodEntry) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: AddFoodDetailViewModel?

    init(gid: String, onLog: @escaping (FoodEntry) -> Void) {
        self.gid = gid
        self.onLog = onLog
    }

    var body: some View {
        Group {
            if let viewModel {
                detailContent(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = AddFoodDetailViewModel(gid: gid, client: appEnv.fdcClient)
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

            case let .loaded(foodDetails):
                loadedFoodAuthoritativeDetailView(foodDetails: foodDetails, bindableViewModel: $bindableViewModel)

            case let .unsupported(source):
                UnsupportedProductView(
                    gid: gid,
                    source: source,
                    onSearchSimilar: {
                        // Navigate back to search - this will be handled by the parent navigation
                    },
                    onTryDifferentBarcode: {
                        // Navigate back to barcode scanner - this will be handled by the parent navigation
                    },
                )

            case let .error(message):
                errorView(message: message, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func loadedFoodAuthoritativeDetailView(
        foodDetails: FoodAuthoritativeDetail,
        bindableViewModel: Bindable<AddFoodDetailViewModel>,
    ) -> some View {
        List {
            servingMultiplierSection(bindableViewModel: bindableViewModel)
            basicInformationSection(foodDetails: foodDetails)
            servingInformationSection(foodDetails: foodDetails)
            portionsSection(foodDetails: foodDetails)
            nutrientsSection(foodDetails: foodDetails, bindableViewModel: bindableViewModel)
            dsidPredictionsSection(foodDetails: foodDetails)
            sourceInformationSection(foodDetails: foodDetails)
            actionSection(foodDetails: foodDetails, bindableViewModel: bindableViewModel)
        }
        .navigationTitle("Food Details")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func errorView(message: String, viewModel: AddFoodDetailViewModel) -> some View {
        VStack {
            Text("Error: \(message)")
                .foregroundColor(.red)
            Button("Retry") {
                Task { await viewModel.load() }
            }
        }
    }

    @ViewBuilder
    private func servingMultiplierSection(bindableViewModel: Bindable<AddFoodDetailViewModel>) -> some View {
        Section {
            Stepper(
                value: bindableViewModel.servingMultiplier,
                in: 0.25 ... 10.0,
                step: 0.25,
            ) {
                Text("Serving: \(String(format: "%.2f", bindableViewModel.servingMultiplier.wrappedValue))×")
            }
        }
    }

    @ViewBuilder
    private func basicInformationSection(foodDetails: FoodAuthoritativeDetail) -> some View {
        Section("Food Information") {
            InfoRow(label: "Name", value: foodDetails.description)
            InfoRow(label: "Brand", value: foodDetails.brand)
            InfoRow(label: "Type", value: foodDetails.kind.rawValue.capitalized)
            if let code = foodDetails.code {
                InfoRow(label: "Barcode", value: code)
            }
            if let ingredients = foodDetails.ingredientsText {
                InfoRow(label: "Ingredients", value: ingredients)
            }
        }
    }

    @ViewBuilder
    private func servingInformationSection(foodDetails: FoodAuthoritativeDetail) -> some View {
        if let serving = foodDetails.serving {
            Section("Serving Information") {
                if let amount = serving.amount {
                    InfoRow(
                        label: "Amount",
                        value: "\(String(format: "%.1f", amount)) \(serving.unit ?? "")",
                    )
                }
                if let household = serving.household {
                    InfoRow(label: "Household", value: household)
                }
            }
        }
    }

    @ViewBuilder
    private func portionsSection(foodDetails: FoodAuthoritativeDetail) -> some View {
        if !foodDetails.portions.isEmpty {
            Section("Available Portions") {
                ForEach(foodDetails.portions, id: \.unit) { portion in
                    PortionRow(portion: portion)
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientsSection(
        foodDetails: FoodAuthoritativeDetail,
        bindableViewModel: Bindable<AddFoodDetailViewModel>,
    ) -> some View {
        if !foodDetails.nutrients.isEmpty {
            Section("Nutrients") {
                ForEach(foodDetails.nutrients, id: \.name) { nutrient in
                    NutrientDetailRow(
                        nutrient: nutrient,
                        multiplier: bindableViewModel.servingMultiplier.wrappedValue,
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func dsidPredictionsSection(foodDetails: FoodAuthoritativeDetail) -> some View {
        if let predictions = foodDetails.dsidPredictions, !predictions.isEmpty {
            Section("DSID Predictions") {
                ForEach(predictions, id: \.ingredient) { prediction in
                    DSIDPredictionRow(prediction: prediction)
                }
            }
        }
    }

    @ViewBuilder
    private func sourceInformationSection(foodDetails: FoodAuthoritativeDetail) -> some View {
        Section("Source") {
            InfoRow(label: "Source", value: foodDetails.provenance.source.rawValue.uppercased())
            InfoRow(label: "ID", value: foodDetails.provenance.id)
            InfoRow(label: "Fetched", value: formatDate(foodDetails.provenance.fetchedAt))
        }
    }

    @ViewBuilder
    private func actionSection(
        foodDetails: FoodAuthoritativeDetail,
        bindableViewModel: Bindable<AddFoodDetailViewModel>,
    ) -> some View {
        Section {
            Button("Log Food") {
                // Convert to FoodEntry for logging
                let entry = FoodEntry.from(
                    foodDetails: foodDetails,
                    multiplier: bindableViewModel.servingMultiplier.wrappedValue,
                )
                onLog(entry)
            }
            .buttonStyle(.borderedProminent)
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
}

// MARK: - Custom Row Components

struct PortionRow: View {
    let portion: FoodPortion

    var body: some View {
        HStack {
            if let amount = portion.amount {
                Text("\(String(format: "%.1f", amount)) \(portion.unit ?? "")")
                    .font(.subheadline)
            } else {
                Text(portion.unit ?? "Unknown")
                    .font(.subheadline)
            }
            Spacer()
            if let household = portion.household {
                Text(household)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct NutrientDetailRow: View {
    let nutrient: FoodNutrient
    let multiplier: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(nutrient.name)
                    .font(.headline)
                Spacer()
                if let amount = nutrient.amount {
                    Text("\(String(format: "%.2f", amount * multiplier)) \(nutrient.unit)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("N/A")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Text("Per \(nutrient.basis.rawValue.replacingOccurrences(of: "_", with: " "))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }
}

struct DSIDPredictionRow: View {
    let prediction: DSIDPrediction

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(prediction.ingredient.capitalized)
                    .font(.headline)
                Spacer()
                Text("Study \(prediction.studyCode)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Label: \(String(format: "%.1f", prediction.labelAmount)) \(prediction.unit)")
                    .font(.subheadline)
                Spacer()
                Text("Predicted: \(String(format: "%.1f", prediction.predMeanValue)) \(prediction.unit)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Difference: \(String(format: "%.1f", prediction.pctDiffFromLabel))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(
                    "CI: \(String(format: "%.1f", prediction.ci95PredMeanLow))-\(String(format: "%.1f", prediction.ci95PredMeanHigh))",
                )
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview("Sample Food Detail") {
    AddFoodDetailView(
        gid: "fdc:123456",
        onLog: { _ in },
    )
    .environment(\.appEnv, .preview)
}
