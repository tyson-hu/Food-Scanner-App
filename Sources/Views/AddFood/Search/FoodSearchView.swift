//
//  FoodSearchView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftData
import SwiftUI

struct FoodSearchView: View {
    /// Parent provides selection handler (push to detail).
    var onSelect: (String) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: FoodSearchViewModel?

    init(onSelect: @escaping (String) -> Void) {
        self.onSelect = onSelect
    }

    var body: some View {
        Group {
            if let viewModel {
                searchContent(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = FoodSearchViewModel(client: appEnv.fdcClient)
                    }
            }
        }
    }

    @ViewBuilder
    private func searchContent(_ viewModel: FoodSearchViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        List {
            // Generic Foods Section
            if !bindableViewModel.genericResults.isEmpty {
                Section("Generic Foods") {
                    ForEach(bindableViewModel.genericResults, id: \.id) { item in
                        foodItemRow(item)
                    }
                }
            }

            // Branded Foods Section
            if !bindableViewModel.brandedResults.isEmpty {
                Section("Branded Foods") {
                    ForEach(bindableViewModel.brandedResults, id: \.id) { item in
                        foodItemRow(item)
                    }
                }
            }
        }
        .overlay {
            switch bindableViewModel.phase {
            case .idle:
                ContentUnavailableView(
                    "Search foods",
                    systemImage: "magnifyingglass",
                    description: Text("Try \"yogurt\", \"rice\", or a brand name.")
                )
            case .searching:
                ProgressView().controlSize(.large)
            case .results:
                if bindableViewModel.genericResults.isEmpty, bindableViewModel.brandedResults.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "exclamationmark.magnifyingglass",
                        description: Text("Refine your terms.")
                    )
                }
            case let .error(msg):
                ContentUnavailableView(
                    "Search failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(msg)
                )
            }
        }
        .searchable(text: $bindableViewModel.query, placement: .automatic)
        .onChange(of: bindableViewModel.query) { _, _ in bindableViewModel.onQueryChange() }
    }

    @ViewBuilder
    private func foodItemRow(_ item: FoodCard) -> some View {
        Button {
            // Pass the full GID directly - supports all ID types (fdc:, gtin:)
            onSelect(item.id)
        } label: {
            foodItemContent(item)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func foodItemContent(_ item: FoodCard) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            foodDescription(item)
            foodDetails(item)
            sourceInformation(item)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func foodDescription(_ item: FoodCard) -> some View {
        Text(item.description ?? "Unknown Food")
            .font(.body)
            .foregroundStyle(.primary)
    }

    @ViewBuilder
    private func foodDetails(_ item: FoodCard) -> some View {
        HStack(spacing: 8) {
            if let brand = item.brand, !brand.isEmpty {
                Text(brand)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let serving = item.serving {
                let servingText = formatServingText(serving)
                if !servingText.isEmpty {
                    Text(servingText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func sourceInformation(_ item: FoodCard) -> some View {
        HStack {
            Text("Source:")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Text(sourceDisplayName(item.provenance.source))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemGray5))
                .cornerRadius(4)

            Spacer()
        }
    }

    private func sourceDisplayName(_ source: SourceTag) -> String {
        switch source {
        case .fdc:
            "FDC"
        case .off:
            "Open Food Facts"
        }
    }

    private func formatServingText(_ serving: FoodServing) -> String {
        if let amount = serving.amount, let unit = serving.unit {
            return "\(String(format: "%.1f", amount)) \(unit)"
        } else if let household = serving.household {
            return household
        }
        return ""
    }
}

#Preview {
    FoodSearchView(onSelect: { _ in })
        .environment(\.appEnv, .preview)
}
