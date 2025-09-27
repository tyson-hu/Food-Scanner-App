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
            await MainActor.run { self.phase = .loaded(foodCard) }
        } catch {
            await MainActor
                .run { self.phase = .error(error.localizedDescription) }
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
