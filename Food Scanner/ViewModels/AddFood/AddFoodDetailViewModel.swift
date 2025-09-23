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
        case loaded(FDCFoodDetails)
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
            let details = try await client.fetchFoodDetails(fdcId: fdcId)
            await MainActor.run { self.phase = .loaded(details) }
        } catch {
            await MainActor
                .run { self.phase = .error(error.localizedDescription) }
        }
    }

    // Helpers
    func scaled(_ value: Int) -> Int {
        Int((Double(value) * servingMultiplier).rounded())
    }
}
