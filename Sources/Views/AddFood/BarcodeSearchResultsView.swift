//
//  BarcodeSearchResultsView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

struct BarcodeSearchResultsView: View {
    let upc: String
    var onSelect: (String) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: BarcodeSearchResultsViewModel?

    init(upc: String, onSelect: @escaping (String) -> Void) {
        self.upc = upc
        self.onSelect = onSelect
    }

    var body: some View {
        Group {
            if let viewModel {
                searchContent(viewModel)
            } else {
                ProgressView("Searching for UPC: \(upc)")
                    .onAppear {
                        viewModel = BarcodeSearchResultsViewModel(upc: upc, client: appEnv.fdcClient)
                    }
            }
        }
        .navigationTitle("Barcode Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func searchContent(_ viewModel: BarcodeSearchResultsViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            switch bindableViewModel.phase {
            case .loading:
                loadingView(viewModel)
            case let .loaded(result):
                loadedView(result: result, viewModel: viewModel)
            case let .error(message):
                errorView(message: message, viewModel: viewModel)
            }
        }
    }

    @ViewBuilder
    private func loadingView(_ viewModel: BarcodeSearchResultsViewModel) -> some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Searching for UPC: \(upc)")
                .foregroundColor(.secondary)
        }
        .task { await viewModel.search() }
    }

    @ViewBuilder
    private func loadedView(result: FoodCard?, viewModel: BarcodeSearchResultsViewModel) -> some View {
        if let food = result {
            // Render Summary immediately from envelope data
            AddFoodSummaryView(
                foodCard: food,
                onLog: { _ in
                    // Handle logging if needed
                },
                onShowDetails: { gid in
                    // Navigate to detail view
                    onSelect(gid)
                }
            )
        } else {
            noResultsView()
        }
    }

    @ViewBuilder
    private func noResultsView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "barcode.viewfinder")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.secondary)

            Text("No Food Found")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No food items found for UPC: \(upc)")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Text("This UPC code may not be in our database yet. Try searching by name instead.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button("Try Different Barcode") {
                // Navigate back to scanner
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    @ViewBuilder
    private func errorView(message: String, viewModel: BarcodeSearchResultsViewModel) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.red)

            Text("Search Error")
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            if message.contains("cancelled") {
                Text("The search was interrupted. This usually happens when scanning multiple barcode quickly.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Button("Retry") {
                Task { await viewModel.search() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - View Model

@MainActor
@Observable
final class BarcodeSearchResultsViewModel {
    enum Phase: Equatable {
        case loading
        case loaded(FoodCard?)
        case error(String)
    }

    let upc: String
    var phase: Phase = .loading

    private let client: FoodDataClient

    init(upc: String, client: FoodDataClient) {
        self.upc = upc
        self.client = client
    }

    func search() async {
        print("🔍 BarcodeSearchResultsViewModel.search() - Starting barcode search for UPC: \(upc)")

        do {
            let result = try await client.getFoodByBarcode(code: upc)

            print("📱 BarcodeSearchResultsViewModel - Found result for UPC: \(upc)")
            print("   GID: \(result.id)")
            print("   Description: \(result.description ?? "nil")")
            print("   Brand: \(result.brand ?? "nil")")
            print("   Nutrients count: \(result.nutrients.count)")
            print("   Nutrients: \(result.nutrients.map { "\($0.name): \($0.amount ?? 0) \($0.unit)" })")
            print("   Provenance: \(result.provenance)")

            phase = .loaded(result)
        } catch {
            print("❌ BarcodeSearchResultsViewModel - Search failed for UPC: \(upc)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")

            // Handle different types of errors
            let errorMessage: String
            if error is CancellationError || error.localizedDescription.contains("cancelled") {
                errorMessage = "Search was cancelled. Please try again."
            } else if let fdcError = error as? FoodDataError, case .noResults = fdcError {
                // Treat no results as a successful search with no result
                print("   Treating no results as successful search with nil result")
                phase = .loaded(nil)
                return
            } else if let fdcError = error as? FoodDataError, case .networkError = fdcError {
                errorMessage = "No internet connection. Please check your network and try again."
            } else if let fdcError = error as? FoodDataError, case let .httpError(code) = fdcError {
                errorMessage = "Server error (\(code)). Please try again later."
            } else {
                errorMessage = error.localizedDescription
            }

            phase = .error(errorMessage)
        }
    }
}

// MARK: - Helper Functions

// Helper function to find nutrient value by name variations
private func findNutrientValue(_ nutrients: [FoodNutrient], names: [String]) -> Double? {
    for nutrient in nutrients where names.contains(where: { name in
        nutrient.name.lowercased().contains(name.lowercased())
    }) {
        return nutrient.amount
    }
    return nil
}

// MARK: - Custom Components

struct BasicNutrientChip: View {
    let name: String
    let value: Double?
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)

            if let value {
                Text("\(String(format: "%.1f", value)) \(unit)")
                    .font(.caption)
                    .fontWeight(.medium)
            } else {
                Text("N/A")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview("Barcode Search Results") {
    NavigationStack {
        BarcodeSearchResultsView(upc: "049000028911") { _ in }
            .environment(\.appEnv, .preview)
    }
}
