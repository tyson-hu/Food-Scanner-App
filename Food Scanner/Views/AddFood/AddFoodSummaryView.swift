//
//  AddFoodSummaryView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//  Renamed from AddFoodDetailView to AddFoodSummaryView for clarity
//

import SwiftData
import SwiftUI

struct AddFoodSummaryView: View {
    let gid: String
    var onLog: (FoodEntry) -> Void
    var onShowDetails: (String) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: AddFoodSummaryViewModel?

    init(gid: String, onLog: @escaping (FoodEntry) -> Void, onShowDetails: @escaping (String) -> Void) {
        self.gid = gid
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
                        viewModel = AddFoodSummaryViewModel(gid: gid, client: appEnv.fdcClient)
                    }
            }
        }
    }

    @ViewBuilder
    private func summaryContent(_ viewModel: AddFoodSummaryViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            switch bindableViewModel.phase {
            case .loading:
                ProgressView()
                    .task { await viewModel.load() }

            case let .loaded(foodCard):
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

                    // Basic Information
                    Section("Food Information") {
                        InfoRow(label: "Name", value: foodCard.description)
                        InfoRow(label: "Brand", value: foodCard.brand)
                        InfoRow(label: "Type", value: foodCard.kind.rawValue.capitalized)
                        if let code = foodCard.code {
                            InfoRow(label: "Barcode", value: code)
                        }
                    }

                    // Serving Information
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

                    // Key Nutrients
                    if !foodCard.nutrients.isEmpty {
                        Section("Key Nutrients") {
                            ForEach(foodCard.nutrients.prefix(5), id: \.name) { nutrient in
                                NutrientSummaryRow(
                                    nutrient: nutrient,
                                    multiplier: bindableViewModel.servingMultiplier
                                )
                            }
                        }
                    }

                    // Source Information
                    Section("Source") {
                        InfoRow(label: "Source", value: foodCard.provenance.source.rawValue.uppercased())
                        InfoRow(label: "ID", value: foodCard.provenance.id)
                        InfoRow(label: "Fetched", value: formatDate(foodCard.provenance.fetchedAt))
                    }

                    // Action Section
                    Section {
                        Button("Log Food") {
                            // Convert to FoodEntry for logging
                            let entry = FoodEntry.from(
                                foodCard: foodCard,
                                multiplier: bindableViewModel.servingMultiplier
                            )
                            onLog(entry)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .navigationTitle("Food Summary")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Details") {
                            onShowDetails(gid)
                        }
                    }
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

#Preview("Sample Food Summary") {
    AddFoodSummaryView(
        gid: "fdc:123456",
        onLog: { _ in },
        onShowDetails: { _ in }
    )
    .environment(\.appEnv, .preview)
}
