//
//  AddFoodSummaryViewModel.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//  Renamed from AddFoodDetailViewModel to AddFoodSummaryViewModel for clarity
//

import Foundation
import Observation

@MainActor
@Observable
final class AddFoodSummaryViewModel {
    enum Phase: Equatable {
        case loading
        case loaded(FoodMinimalCard)
        case error(String)
    }

    let gid: String
    var servingMultiplier: Double = 1.0
    var phase: Phase = .loading

    private let client: FDCClient

    init(gid: String, client: FDCClient) {
        self.gid = gid
        self.client = client
    }

    func load() async {
        do {
            let foodCard = try await client.getFood(gid: gid)

            // Debug: Log received food card data
            print("🔍 Received Food Card for \(gid):")
            print("  Description: \(foodCard.description ?? "nil")")
            print("  Brand: \(foodCard.brand ?? "nil")")
            print("  Kind: \(foodCard.kind)")
            print("  Code: \(foodCard.code ?? "nil")")
            if let serving = foodCard.serving {
                print(
                    "  Serving: amount=\(serving.amount ?? 0), unit=\(serving.unit ?? "nil"), household=\(serving.household ?? "nil")",
                )
            } else {
                print("  Serving: nil")
            }
            print("  Nutrients count: \(foodCard.nutrients.count)")
            print("  Provenance: \(foodCard.provenance)")

            // Check for empty DSLD data and provide better error message
            if gid.hasPrefix("dsld:"), foodCard.description == nil, foodCard.brand == nil, foodCard.nutrients.isEmpty {
                print("⚠️ DSLD data is empty - this might be a proxy service issue")
                phase =
                    .error(
                        "DSLD data is currently unavailable. This might be a temporary issue with the supplement database.",
                    )
            } else {
                phase = .loaded(foodCard)
            }
        } catch {
            print("❌ Error loading food for \(gid): \(error)")
            phase = .error(error.localizedDescription)
        }
    }

    // Helpers
    func scaled(_ value: Int) -> Int {
        Int((Double(value) * servingMultiplier).rounded())
    }

    func scaled(_ value: Double) -> Double {
        value * servingMultiplier
    }
}
