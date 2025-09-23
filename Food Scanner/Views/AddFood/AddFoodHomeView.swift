//
//  AddFoodHomeView.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import SwiftUI

enum AddFoodMode: Hashable { case search, barcode, photo }
enum AddFoodRoute: Hashable { case detail(fdcId: Int) }

// Deep-link target, e,g. open Add tab directly to .barcode later.
struct AddActivation: Equatable {
    var mode: AddFoodMode
}

struct AddFoodHomeView: View {
    @Binding var activation: AddActivation?
    var onLogged: (FoodEntry) -> Void

    @State private var mode: AddFoodMode = .search
    @State private var path: [AddFoodRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 12) {
                Picker("", selection: $mode) {
                    Text("Search").tag(AddFoodMode.search)
                    Text("Scan").tag(AddFoodMode.barcode)
                    Text("Photo").tag(AddFoodMode.photo)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Group {
                    switch mode {
                    case .search:
                        AddFoodSearchView { fdcId in
                            path.append(.detail(fdcId: fdcId))
                        }
                    case .barcode:
                        BarcodeScannerView(onDetect: { fdcId in
                            path.append(.detail(fdcId: fdcId))
                        })
                    case .photo:
                        PhotoIntakeView(onRecognize: { fdcId in
                            path.append(.detail(fdcId: fdcId))
                        })
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AddFoodRoute.self) { route in
                switch route {
                case let .detail(id):
                    AddFoodDetailView(fdcId: id) { entry in
                        onLogged(entry)
                    }
                }
            }
        }
        // Handle deep-link into a specific mode without reachitecting later
        .onChange(of: activation) { _, newValue in
            guard let newValue else { return }
            mode = newValue.mode
            path.removeAll()

            // reset so future activations re-trigger
            DispatchQueue.main.sync {
                activation = nil
            }
        }
    }
}

#Preview() {
    @Previewable @State var tab: AppTab = .today
    @Previewable @State var addAvtivation: AddActivation?
    AddFoodHomeView(activation: $addAvtivation, onLogged: { _ in })
        .environment(\.appEnv, .preview)
}
