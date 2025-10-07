//
//  AddFoodDetailViewModel.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
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

    private let client: FoodDataClient

    init(gid: String, client: FoodDataClient) {
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
                print("❌ Error loading food details for \(gid): \(error)")
                // If details API fails, fall back to basic food API
                do {
                    let foodCard = try await client.getFood(gid: gid)
                    let foodDetails = convertToFoodAuthoritativeDetail(foodCard: foodCard)
                    phase = .loaded(foodDetails)
                } catch {
                    phase = .error("Unable to process food data. Please try again.")
                }
            }
        case let .unsupported(source):
            // For unsupported products, try to get basic food info instead of details
            do {
                let foodCard = try await client.getFood(gid: gid)
                // Convert FoodMinimalCard to FoodAuthoritativeDetail for display
                let foodDetails = convertToFoodAuthoritativeDetail(foodCard: foodCard)
                phase = .loaded(foodDetails)
            } catch {
                phase = .unsupported(source)
            }
        case .unknown:
            // Try the details API first for unknown sources
            do {
                let foodDetails = try await client.getFoodDetails(gid: gid)
                phase = .loaded(foodDetails)
            } catch {
                print("❌ Error loading food details for \(gid): \(error)")
                // If details API fails, try basic food API
                do {
                    let foodCard = try await client.getFood(gid: gid)
                    let foodDetails = convertToFoodAuthoritativeDetail(foodCard: foodCard)
                    phase = .loaded(foodDetails)
                } catch {
                    phase = .error("Unable to process food data. Please try again.")
                }
            }
        }
    }

    // Helper function to convert FoodMinimalCard to FoodAuthoritativeDetail
    private func convertToFoodAuthoritativeDetail(foodCard: FoodMinimalCard) -> FoodAuthoritativeDetail {
        // Create a basic FoodAuthoritativeDetail from FoodMinimalCard
        // This is a simplified conversion for unsupported products
        FoodAuthoritativeDetail(
            id: foodCard.id,
            kind: foodCard.kind,
            code: foodCard.code,
            description: foodCard.description,
            brand: foodCard.brand,
            ingredientsText: nil, // No ingredients available for basic info
            baseUnit: foodCard.baseUnit,
            per100Base: foodCard.per100Base,
            serving: foodCard.serving,
            portions: [], // No portions available for basic info
            densityGPerMl: foodCard.densityGPerMl,
            nutrients: foodCard.nutrients,
            provenance: foodCard.provenance
        )
    }

    // Helpers
    func scaled(_ value: Int) -> Int {
        Int((Double(value) * servingMultiplier).rounded())
    }

    func scaled(_ value: Double) -> Double {
        value * servingMultiplier
    }
}
