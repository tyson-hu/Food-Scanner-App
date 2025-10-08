//
//  FoodDetailsView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftData
import SwiftUI

struct FoodDetailsView: View {
    let gid: String
    var onLog: (FoodEntry) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: FoodDetailsViewModel?

    init(gid: String, onLog: @escaping (FoodEntry) -> Void) {
        self.gid = gid
        self.onLog = onLog
    }

    var body: some View {
        Group {
            if let viewModel {
                detailsContent(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = FoodDetailsViewModel(gid: gid, client: appEnv.fdcClient)
                    }
            }
        }
    }

    @ViewBuilder
    private func detailsContent(_ viewModel: FoodDetailsViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            switch bindableViewModel.phase {
            case .loading:
                ProgressView()
                    .task { await viewModel.load() }

            case let .loaded(foodDetails):
                loadedFoodDetailsView(foodDetails: foodDetails, bindableViewModel: $bindableViewModel)

            case let .unsupported(source):
                UnsupportedProductView(
                    gid: gid,
                    source: source,
                    onSearchSimilar: {
                        // Navigate back to search - this will be handled by the parent navigation
                    },
                    onTryDifferentBarcode: {
                        // Navigate back to barcode scanner - this will be handled by the parent navigation
                    }
                )

            case let .error(message):
                errorView(message: message, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func loadedFoodDetailsView(
        foodDetails: FoodDetails,
        bindableViewModel: Bindable<FoodDetailsViewModel>
    ) -> some View {
        List {
            servingMultiplierSection(bindableViewModel: bindableViewModel)
            basicInformationSection(foodDetails: foodDetails)
            servingInformationSection(foodDetails: foodDetails)
            portionsSection(foodDetails: foodDetails)
            nutrientsSection(foodDetails: foodDetails, bindableViewModel: bindableViewModel)
            sourceInformationSection(foodDetails: foodDetails)
            actionSection(foodDetails: foodDetails, bindableViewModel: bindableViewModel)
        }
        .navigationTitle("Food Details")
        .navigationBarTitleDisplayMode(.large)
    }

    @ViewBuilder
    private func errorView(message: String, viewModel: FoodDetailsViewModel) -> some View {
        VStack {
            Text("Error: \(message)")
                .foregroundColor(.red)
            Button("Retry") {
                Task { await viewModel.load() }
            }
        }
    }

    @ViewBuilder
    private func servingMultiplierSection(bindableViewModel: Bindable<FoodDetailsViewModel>) -> some View {
        Section {
            Stepper(
                value: bindableViewModel.servingMultiplier,
                in: 0.25 ... 10.0,
                step: 0.25
            ) {
                Text("Serving: \(String(format: "%.2f", bindableViewModel.servingMultiplier.wrappedValue))×")
            }
        }
    }

    @ViewBuilder
    private func basicInformationSection(foodDetails: FoodDetails) -> some View {
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
    private func servingInformationSection(foodDetails: FoodDetails) -> some View {
        if let serving = foodDetails.serving {
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
    private func portionsSection(foodDetails: FoodDetails) -> some View {
        if !foodDetails.portions.isEmpty {
            Section("Available Portions") {
                ForEach(Array(foodDetails.portions.enumerated()), id: \.offset) { _, portion in
                    PortionRow(portion: portion)
                }
            }
        }
    }

    @ViewBuilder
    private func nutrientsSection(
        foodDetails: FoodDetails,
        bindableViewModel: Bindable<FoodDetailsViewModel>
    ) -> some View {
        if !foodDetails.nutrients.isEmpty {
            Section("All Nutrients") {
                ForEach(Array(foodDetails.nutrients.enumerated()), id: \.offset) { _, nutrient in
                    NutrientDetailRow(
                        nutrient: nutrient,
                        multiplier: bindableViewModel.servingMultiplier.wrappedValue
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func sourceInformationSection(foodDetails: FoodDetails) -> some View {
        Section("Source") {
            InfoRow(label: "Source", value: foodDetails.provenance.source.rawValue.uppercased())
            InfoRow(label: "ID", value: foodDetails.provenance.id)
            InfoRow(label: "Fetched", value: formatDate(foodDetails.provenance.fetchedAt))
        }
    }

    @ViewBuilder
    private func actionSection(
        foodDetails: FoodDetails,
        bindableViewModel: Bindable<FoodDetailsViewModel>
    ) -> some View {
        Section {
            Button("Log Food") {
                // Convert to FoodEntry for logging
                let entry = FoodEntry.from(
                    foodDetails: foodDetails,
                    multiplier: bindableViewModel.servingMultiplier.wrappedValue
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
            Text(portion.label)
                .font(.subheadline)
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

#Preview("Sample Food Details") {
    FoodDetailsView(
        gid: "fdc:123456",
        onLog: { _ in }
    )
    .environment(\.appEnv, .preview)
}
