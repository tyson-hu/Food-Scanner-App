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

    /// Fetch full detailed response for a specific FDC id (includes all metadata).
    func fetchFoodDetailResponse(fdcId: Int) async throws -> ProxyFoodDetailResponse
}

// MARK: - Error Types

enum FDCError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Invalid URL"
        case .invalidResponse:
            "Invalid response"
        case let .httpError(code):
            "HTTP error: \(code)"
        case let .networkError(error):
            "Network error: \(error.localizedDescription)"
        }
    }
}
