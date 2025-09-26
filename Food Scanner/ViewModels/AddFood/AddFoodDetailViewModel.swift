//
//  AddFoodDetailViewModel.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation
import Observation

@MainActor
@Observable
final class AddFoodDetailViewModel {
    enum Phase: Equatable {
        case loading
        case loaded(ProxyFoodDetailResponse)
        case error(String)
    }

    let fdcId: Int
    var servingMultiplier: Double = 1.0
    var phase: Phase = .loading

    private let client: FDCClient

    init(fdcId: Int, client: FDCClient) {
        self.fdcId = fdcId
        self.client = client
    }

    func load() async {
        do {
            // Use the new method to fetch the full ProxyFoodDetailResponse
            let proxyResponse = try await client.fetchFoodDetailResponse(fdcId: fdcId)
            await MainActor.run { self.phase = .loaded(proxyResponse) }
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
