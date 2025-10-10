//
//  TestConfig.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation

enum TestConfig {
    /// Whether to run integration tests that require live network access
    static var runIntegrationTests: Bool {
        // Check for environment variable first
        if let envValue = ProcessInfo.processInfo.environment["RUN_INTEGRATION_TESTS"] {
            return envValue.lowercased() == "true" || envValue == "1"
        }

        // Check for build configuration
        #if INTEGRATION_TESTS
            return true
        #else
            return false
        #endif
    }

    /// Whether to run tests that depend on external services
    static var runExternalServiceTests: Bool {
        runIntegrationTests
    }
}
