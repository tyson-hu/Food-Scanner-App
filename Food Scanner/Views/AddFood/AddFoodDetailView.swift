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
    
    @Environment(\.appEnv) private var appEnv
    @State private var viewModel: AddFoodDetailViewModel?
    
    init(fdcId: Int, onLog: @escaping (FoodEntry) -> Void) {
        self.fdcId = fdcId
        self.onLog = onLog
    }
    
    var body: some View {
        Group {
            if let vm = viewModel {
                detailContent(vm)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = AddFoodDetailViewModel(fdcId: fdcId, client: appEnv.fdcClient)
                    }
            }
        }
    }
    
    @ViewBuilder
    private func detailContent(_ vm: AddFoodDetailViewModel) -> some View {
        @Bindable var bindableVM = vm
        
        Group {
            switch bindableVM.phase {
            case .loading:
                ProgressView()
                    .task { await vm.load() }
                
            case .loaded(let d):
                Form {
                    Section {
                        Stepper(value: $bindableVM.servingMultiplier, in: 0.25...10.0, step: 0.25) {
                            Text("Serving: \(bindableVM.servingMultiplier, specifier: "%.2f")×")
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
                                multiplier: bindableVM.servingMultiplier
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
        onLog: {_ in }
    )
    .environment(\.appEnv, .preview)
}
