//
//  FDCClient.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/17/25.
//

import Foundation

public protocol FDCClient: Sendable {
    /// Search branded/generic foods by text.
    func searchFoods(matching query: String, page: Int) async throws -> [FDCFoodSummary]
    
    /// Fetch full nutrition for a specific FDC id.
    func fetchFoodDetails(fdcId: Int) async throws -> FDCFoodDetails
}
