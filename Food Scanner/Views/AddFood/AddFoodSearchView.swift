//
//  AddFoodSearchView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftUI
import SwiftData

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
            if let vm = viewModel {
                searchContent(vm)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = AddFoodSearchViewModel(client: appEnv.fdcClient)
                    }
            }
        }
    }
    
    @ViewBuilder
    private func searchContent(_ vm: AddFoodSearchViewModel) -> some View {
        @Bindable var bindableVM = vm
        
        List {
            ForEach(vm.results, id: \.id) { item in
                Button{
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
                            
                            Text("\(item.caloriesPerServing) kcal")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .overlay {
            switch vm.phase {
            case .idle:
                ContentUnavailableView(
                    "Search foods",
                    systemImage: "magnifyingglass",
                    description: Text("Try \"yougurt\", \"rice\", or a brand name.")
                )
            case .searching:
                ProgressView().controlSize(.large)
            case .results:
                if vm.results.isEmpty {
                    ContentUnavailableView(
                        "No matches",
                        systemImage: "exclamationmark.magnifyingglass",
                        description: Text("Refine your terms.")
                    )
                }
            case .error(let msg):
                ContentUnavailableView(
                    "Search failed",
                    systemImage: "exclamationmark.triangle",
                    description: Text(msg)
                )
            }
        }
        .searchable(text: $bindableVM.query, placement: .automatic)
        .onChange(of: vm.query) { _, _ in vm.onQueryChange() }
    }
}

#Preview {
    AddFoodSearchView(onSelect: { _ in })
        .environment(\.appEnv, .preview)
}
