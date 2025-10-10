//
//  FoodViewModel.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class FoodViewModel {
    enum Phase: Equatable {
        case loading
        case loaded(FoodCard)
        case error(String)
    }

    let gid: String?
    var servingMultiplier: Double = 1.0
    var phase: Phase = .loading

    private let client: FoodDataClient?

    // Initializer for when we have a GID (text search, photo recognition)
    init(gid: String, client: FoodDataClient) {
        self.gid = gid
        self.client = client
    }

    // Initializer for when we have the food card directly (barcode scan)
    init(foodCard: FoodCard) {
        gid = foodCard.id
        client = nil
        phase = .loaded(foodCard)
    }

    func load() async {
        // If we already have the food card (from barcode scan), no need to load
        if case .loaded = phase {
            return
        }

        guard let gid, let client else {
            phase = .error("No GID or client available")
            return
        }

        print("🔍 FoodViewModel.load() - Starting load for GID: \(gid)")

        do {
            let foodCard = try await client.getFood(gid: gid)

            // Enhanced Debug: Log received food card data
            print("🔍 FoodViewModel DEBUG - Received Food Card for \(gid):")
            print("   Description: \(foodCard.description ?? "nil")")
            print("   Brand: \(foodCard.brand ?? "nil")")
            print("   Kind: \(foodCard.kind)")
            print("   Code: \(foodCard.code ?? "nil")")
            if let serving = foodCard.serving {
                print(
                    "   Serving: amount=\(serving.amount ?? 0), unit=\(serving.unit ?? "nil"), household=\(serving.household ?? "nil")"
                )
            } else {
                print("   Serving: nil")
            }
            print("   Nutrients count: \(foodCard.nutrients.count)")
            print("   Nutrients details:")
            for (index, nutrient) in foodCard.nutrients.enumerated() {
                print(
                    "     [\(index)] \(nutrient.name): \(nutrient.amount ?? 0) \(nutrient.unit) (basis: \(nutrient.basis))"
                )
            }
            print("   Provenance: \(foodCard.provenance)")

            // Check for empty data and provide better error message
            if foodCard.description == nil, foodCard.brand == nil, foodCard.nutrients.isEmpty {
                print("⚠️ Food data is empty - this might be a proxy service issue")
                phase = .error(
                    "Food data is currently unavailable. This might be a temporary issue with the data source."
                )
            } else {
                print("✅ FoodViewModel - Successfully loaded food card, setting phase to loaded")
                phase = .loaded(foodCard)
            }
        } catch {
            print("❌ FoodViewModel ERROR - Failed to load food for \(gid): \(error)")
            print("   Error type: \(type(of: error))")
            print("   Error description: \(error.localizedDescription)")
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
