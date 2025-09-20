//
//  FDCRemoteClient.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import Foundation

struct FDCRemoteClient: FDCClient {
    let apiKet: String
    let session: URLSession = .shared
    
    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary] {
        // TODO: Implement api call in M2
        // Endpoint: GET /v1/foods/search?query=...&pageSize=... (requires api_key)
        // We’ll wire this in M2 when we flip from mock to live.
        // https://fdc.nal.usda.gov/api-guide  (see foods/search)
        throw NSError(
            domain: "FDCRemoteClient",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Not wired yet"]
        )
    }
    
    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails {
        // TODO: Implement in M2
        // Endpoint: GET /v1/food/{fdcId}?api_key=...
        throw NSError(
            domain: "FDCRemoteClient",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Not wired yet"]
        )
    }
    
}
