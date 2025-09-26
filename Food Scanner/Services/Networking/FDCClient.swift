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
    case decodingError(Error)
    case noResults
    case serverUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Unable to connect to food database. Please check your internet connection."
        case .invalidResponse:
            "Received invalid data from food database. Please try again."
        case let .httpError(code):
            switch code {
            case 400:
                "Invalid search request. Please try different search terms."
            case 401:
                "Authentication failed. Please check your API key."
            case 403:
                "Access denied. Please check your API permissions."
            case 404:
                "Food not found. Please try a different search."
            case 429:
                "Too many requests. Please wait a moment and try again."
            case 500 ... 599:
                "Food database is temporarily unavailable. Please try again later."
            default:
                "Server error (\(code)). Please try again later."
            }
        case let .networkError(error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    "No internet connection. Please check your network settings."
                case .timedOut:
                    "Request timed out. Please check your connection and try again."
                case .cannotConnectToHost:
                    "Cannot connect to food database. Please try again later."
                default:
                    "Network error: \(urlError.localizedDescription)"
                }
            } else {
                "Network error: \(error.localizedDescription)"
            }
        case .decodingError:
            "Unable to process food data. Please try again."
        case .noResults:
            "No foods found matching your search. Try different keywords."
        case .serverUnavailable:
            "Food database is temporarily unavailable. Please try again later."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .invalidURL, .invalidResponse, .decodingError:
            "Please try again or contact support if the problem persists."
        case let .httpError(code):
            switch code {
            case 400:
                "Try using different search terms or check your input."
            case 401, 403:
                "Please check your API configuration."
            case 404:
                "Try searching for a different food item."
            case 429:
                "Wait a few seconds before trying again."
            case 500 ... 599:
                "The service should be back online shortly."
            default:
                "Please try again later."
            }
        case let .networkError(error):
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet:
                    "Check your Wi-Fi or cellular connection."
                case .timedOut:
                    "Try again with a better connection."
                case .cannotConnectToHost:
                    "The service may be temporarily down."
                default:
                    "Check your internet connection and try again."
                }
            } else {
                "Check your internet connection and try again."
            }
        case .noResults:
            "Try using broader search terms or check spelling."
        case .serverUnavailable:
            "Please try again in a few minutes."
        }
    }
}
