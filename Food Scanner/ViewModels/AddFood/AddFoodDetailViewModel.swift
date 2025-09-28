//
//  AddFoodDetailViewModel.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/26/25.
//  New view model for full food details using the new API
//

import Foundation
import Observation

@MainActor
@Observable
final class AddFoodDetailViewModel {
    enum Phase: Equatable {
        case loading
        case loaded(FoodAuthoritativeDetail)
        case unsupported(SourceTag?)
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
        // Check if product is supported before making API call
        let supportStatus = ProductSourceDetection.detectSupportStatus(from: gid)

        switch supportStatus {
        case .supported:
            do {
                let foodDetails = try await client.getFoodDetails(gid: gid)
                phase = .loaded(foodDetails)
            } catch {
                phase = .error(error.localizedDescription)
            }
        case let .unsupported(source):
            phase = .unsupported(source)
        case .unknown:
            // Try the API call anyway for unknown sources
            do {
                let foodDetails = try await client.getFoodDetails(gid: gid)
                phase = .loaded(foodDetails)
            } catch {
                phase = .error(error.localizedDescription)
            }
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
