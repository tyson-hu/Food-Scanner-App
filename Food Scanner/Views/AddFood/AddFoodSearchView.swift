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
    var onSelect: (Int) -> Void

    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: AddFoodSearchViewModel?

    init(onSelect: @escaping (Int) -> Void) {
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
            ForEach(bindableViewModel.results, id: \.id) { item in
                Button {
                    onSelect(item.id)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name).font(.body)

                        HStack(spacing: 8) {
                            if let brand = item.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            if let serving = item.serving, !serving.isEmpty {
                                Text(serving)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
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
                if bindableViewModel.results.isEmpty {
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
}

#Preview {
    AddFoodSearchView(onSelect: { _ in })
        .environment(\.appEnv, .preview)
}
