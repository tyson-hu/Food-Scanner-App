//
//  APIConfiguration.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

// MARK: - API Configuration Service

public struct APIConfiguration: Sendable {
    public let baseURL: URL
    public let basePath: String

    public init() throws {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            throw APIConfigurationError.missingInfoPlist
        }

        guard let scheme = infoDictionary["APIScheme"] as? String,
              let host = infoDictionary["APIHost"] as? String else {
            throw APIConfigurationError.invalidBaseURL
        }

        guard let basePath = infoDictionary["APIBasePath"] as? String else {
            throw APIConfigurationError.missingBasePath
        }

        guard let baseURL = URL(string: "\(scheme)://\(host)") else {
            throw APIConfigurationError.invalidBaseURL
        }

        self.baseURL = baseURL
        self.basePath = basePath
    }

    /// Constructs a full URL with the configured base path
    public func url(for endpoint: String) throws -> URL {
        let fullPath = basePath + endpoint
        guard let url = URL(string: fullPath, relativeTo: baseURL) else {
            throw APIConfigurationError.invalidEndpoint(endpoint)
        }
        return url
    }

    /// Constructs a URL with query parameters
    public func url(for endpoint: String, queryItems: [URLQueryItem]) throws -> URL {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = basePath + endpoint
        components.queryItems = queryItems

        guard let url = components.url else {
            throw APIConfigurationError.invalidEndpoint(endpoint)
        }
        return url
    }
}

// MARK: - API Configuration Errors

public enum APIConfigurationError: LocalizedError {
    case missingInfoPlist
    case invalidBaseURL
    case missingBasePath
    case invalidEndpoint(String)

    public var errorDescription: String? {
        switch self {
        case .missingInfoPlist:
            return "Missing Info.plist configuration"
        case .invalidBaseURL:
            return "Invalid API base URL configuration"
        case .missingBasePath:
            return "Missing API base path configuration"
        case let .invalidEndpoint(endpoint):
            return "Invalid API endpoint: \(endpoint)"
        }
    }
}
