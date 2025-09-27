//
//  BarcodeSearchResultsView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
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
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Searching for UPC: \(upc)")
                        .foregroundColor(.secondary)
                }
                .task { await viewModel.search() }

            case let .loaded(result):
                if let food = result {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)

                        Text("Food Found!")
                            .font(.title2)
                            .fontWeight(.semibold)

                        VStack(spacing: 8) {
                            Text(food.description ?? "Unknown Food")
                                .font(.headline)
                                .multilineTextAlignment(.center)

                            if let brand = food.brand {
                                Text(brand)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Text("Type: \(food.kind.rawValue.capitalized)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Button("View Details") {
                            onSelect(food.id)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 60))
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

            case let .error(message):
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.red)

                    Text("Search Error")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(message)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    if message.contains("cancelled") {
                        Text("The search was interrupted. This usually happens when scanning multiple barcodes quickly."
                        )
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
    }
}

// MARK: - View Model

@MainActor
@Observable
final class BarcodeSearchResultsViewModel {
    enum Phase: Equatable {
        case loading
        case loaded(FoodMinimalCard?)
        case error(String)
    }

    let upc: String
    var phase: Phase = .loading

    private let client: FDCClient

    init(upc: String, client: FDCClient) {
        self.upc = upc
        self.client = client
    }

    func search() async {
        do {
            print("🔍 BarcodeSearchResultsViewModel: Searching for UPC: \(upc)")
            let result = try await client.getFoodByBarcode(code: upc)
            print("📱 BarcodeSearchResultsViewModel: Found result for UPC: \(upc)")
            await MainActor.run { self.phase = .loaded(result) }
        } catch {
            print("❌ BarcodeSearchResultsViewModel: Search failed for UPC: \(upc), error: \(error)")

            // Handle different types of errors
            let errorMessage: String
            if error.localizedDescription.contains("cancelled") {
                errorMessage = "Search was cancelled. Please try again."
            } else if error.localizedDescription.contains("noResults") {
                // Treat no results as a successful search with no result
                await MainActor.run { self.phase = .loaded(nil) }
                return
            } else {
                errorMessage = error.localizedDescription
            }

            await MainActor.run { self.phase = .error(errorMessage) }
        }
    }
}

#Preview("Barcode Search Results") {
    NavigationStack {
        BarcodeSearchResultsView(upc: "0031604031121") { _ in }
            .environment(\.appEnv, .preview)
    }
}
