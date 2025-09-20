//
//  AddFoodDetailView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftUI
import SwiftData

struct AddFoodDetailView: View {
    let fdcId: Int
    var onLog: (FoodEntry) -> Void
    
    // MARK: Default to mock; swap in DI later (AppEnvironment/FDCRemoteClient).
    @State private var viewModel: AddFoodDetailViewModel
    
    init(
        fdcId: Int,
        onLog: @escaping (FoodEntry) -> Void,
        client: FDCClient = FDCMock()
    ) {
        self.fdcId = fdcId
        self.onLog = onLog
        _viewModel = State(
            initialValue: AddFoodDetailViewModel(fdcId: fdcId, client: client)
        )
    }
    
    var body: some View {
        @Bindable var vm = viewModel
        
        Group {
            switch vm.phase {
            case .loading:
                ProgressView()
                    .task { await vm.load() }
                
            case .loaded(let d):
                Form {
                    Section {
                        Stepper(value: $vm.servingMultiplier, in: 0.25...10.0, step: 0.25) {
                            Text("Serving: \(vm.servingMultiplier, specifier: "%.2f")×")
                        }
                    }
                    Section("Nutrition (approx)") {
                        LabeledContent("Calories", value: "\(vm.scaled(d.calories)) kcal")
                        LabeledContent("Protein",  value: "\(vm.scaled(d.protein)) g")
                        LabeledContent("Carbs",    value: "\(vm.scaled(d.carbs)) g")
                        LabeledContent("Fat",      value: "\(vm.scaled(d.fat)) g")
                    }
                    Section {
                        Button("Log to Today") {
                            let entry = FoodEntry.from(
                                details: d,
                                multiplier: vm.servingMultiplier
                            )
                            onLog(entry)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .navigationTitle(d.name)
                .navigationBarTitleDisplayMode(.inline)
                
            case .error(let msg):
                ContentUnavailableView(
                    "Failed to load",
                    systemImage: "exclamationmark.triangle",
                    description: Text(msg)
                )
            }
        }
    }
}

#Preview("Sample Food Detail") {
    AddFoodDetailView(
        fdcId: 123456,
        onLog: {_ in },
        client: FDCMock()
    )
}
