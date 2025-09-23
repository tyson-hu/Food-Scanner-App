//
//  AddFoodDetailView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import SwiftData
import SwiftUI

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
            if let viewModel {
                detailContent(viewModel)
            } else {
                ProgressView()
                    .onAppear {
                        viewModel = AddFoodDetailViewModel(fdcId: fdcId, client: appEnv.fdcClient)
                    }
            }
        }
    }

    @ViewBuilder
    private func detailContent(_ viewModel: AddFoodDetailViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            switch bindableViewModel.phase {
            case .loading:
                ProgressView()
                    .task { await viewModel.load() }

            case let .loaded(foodDetails):
                Form {
                    Section {
                        Stepper(
                            value: $bindableViewModel.servingMultiplier,
                            in: 0.25 ... 10.0,
                            step: 0.25
                        ) {
                            Text("Serving: \(String(format: "%.2f", bindableViewModel.servingMultiplier))×")
                        }
                    }

                    Section("Nutrition") {
                        HStack {
                            Text("Calories")
                            Spacer()
                            Text("\(Int(Double(foodDetails.calories) * bindableViewModel.servingMultiplier))")
                        }
                        HStack {
                            Text("Protein")
                            Spacer()
                            Text(
                                "\(String(format: "%.1f", Double(foodDetails.protein) * bindableViewModel.servingMultiplier)) g"
                            )
                        }
                        HStack {
                            Text("Fat")
                            Spacer()
                            Text(
                                "\(String(format: "%.1f", Double(foodDetails.fat) * bindableViewModel.servingMultiplier)) g"
                            )
                        }
                        HStack {
                            Text("Carbs")
                            Spacer()
                            Text(
                                "\(String(format: "%.1f", Double(foodDetails.carbs) * bindableViewModel.servingMultiplier)) g"
                            )
                        }
                    }

                    Section {
                        Button("Log Food") {
                            onLog(FoodEntry.from(
                                details: foodDetails,
                                multiplier: bindableViewModel.servingMultiplier
                            ))
                        }
                        .buttonStyle(.borderedProminent)
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
}

#Preview("Sample Food Detail") {
    AddFoodDetailView(
        fdcId: 123_456,
        onLog: { _ in }
    )
    .environment(\.appEnv, .preview)
}
