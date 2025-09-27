//
//  AddFoodSearchView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftData
import SwiftUI

struct AddFoodSearchView: View {
    /// Parent provides selection handler (push to detail).
    var onSelect: (String) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: AddFoodSearchViewModel?

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
                        viewModel = AddFoodSearchViewModel(client: appEnv.fdcClient)
                    }
            }
        }
    }

    @ViewBuilder
    private func searchContent(_ viewModel: AddFoodSearchViewModel) -> some View {
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
    private func foodItemRow(_ item: FoodMinimalCard) -> some View {
        Button {
            // Pass the full GID directly - supports all ID types (fdc:, gtin:, dsld:)
            onSelect(item.id)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.description ?? "Unknown Food")
                    .font(.body)
                    .foregroundStyle(.primary)

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

                // Source information
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
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func sourceDisplayName(_ source: SourceTag) -> String {
        switch source {
        case .fdc:
            "FDC"
        case .dsld:
            "DSLD"
        case .dsid:
            "DSID"
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
    AddFoodSearchView(onSelect: { _ in })
        .environment(\.appEnv, .preview)
}
