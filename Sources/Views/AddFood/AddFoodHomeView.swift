//
//  AddFoodHomeView.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import SwiftUI

enum AddFoodMode: Hashable { case search, barcode, photo }
enum AddFoodRoute: Hashable {
    case summary(gid: String)
    case detail(gid: String)
    case barcodeSearch(upc: String)
    case unsupportedProduct(gid: String, source: SourceTag?)
}

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
                        FoodSearchView { gid in
                            path.append(.summary(gid: gid))
                        }
                    case .barcode:
                        BarcodeScannerView(onDetect: { upc in
                            path.append(.barcodeSearch(upc: upc))
                        })
                    case .photo:
                        PhotoIntakeView(onRecognize: { gid in
                            path.append(.summary(gid: gid))
                        })
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: AddFoodRoute.self) { route in
                destinationView(for: route)
            }
        }
        // Handle deep-link into a specific mode without reachitecting later
        .onChange(of: activation) { _, newValue in
            guard let newValue else { return }
            mode = newValue.mode
            path.removeAll()

            // reset so future activations re-trigger
            Task { @MainActor in
                activation = nil
            }
        }
    }

    @ViewBuilder
    private func destinationView(for route: AddFoodRoute) -> some View {
        switch route {
        case let .summary(gid):
            FoodView(
                gid: gid,
                onLog: { entry in
                    onLogged(entry)
                },
                onShowDetails: { gid in
                    // Check support status before navigating to details
                    let supportStatus = ProductSourceDetection.detectSupportStatus(from: gid)
                    switch supportStatus {
                    case .supported:
                        path.append(.detail(gid: gid))
                    case let .unsupported(source):
                        path.append(.unsupportedProduct(gid: gid, source: source))
                    case .unknown:
                        path.append(.detail(gid: gid))
                    }
                }
            )
        case let .detail(gid):
            FoodDetailsView(gid: gid) { entry in
                onLogged(entry)
            }
        case let .barcodeSearch(upc):
            BarcodeSearchResultsView(upc: upc) { gid in
                // Always go to summary view first for barcode results
                // Support status will be checked when user clicks Details button
                path.append(.summary(gid: gid))
            }
        case let .unsupportedProduct(gid, source):
            UnsupportedProductView(
                gid: gid,
                source: source,
                onSearchSimilar: {
                    // Navigate to search mode
                    mode = .search
                    path.removeAll()
                },
                onTryDifferentBarcode: {
                    // Navigate back to barcode scanner
                    mode = .barcode
                    path.removeAll()
                }
            )
        }
    }
}

#Preview() {
    @Previewable @State var tab: AppTab = .today
    @Previewable @State var addAvtivation: AddActivation?
    AddFoodHomeView(activation: $addAvtivation, onLogged: { _ in })
        .environment(\.appEnv, .preview)
}
