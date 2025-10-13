//
//  FDCDISelectionTests.swift
//  Calry
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Calry
import Testing

@Suite("FDC Dependency Injection — Selection Matrix")
struct FDCDISelectionTests {
    // Helper to construct a launch environment without touching process state.
    private func makeEnv(
        isRelease: Bool,
        builtIn: Bool,
        override: Bool
    ) -> AppLaunchEnvironment {
        .init(
            isRelease: isRelease,
            buildDefaultRemote: builtIn,
            runtimeOverrideRemote: override
        )
    }

    @Test("Release defaults to Proxy")
    @MainActor
    func release_defaults_to_proxy() async throws {
        let env = makeEnv(isRelease: true, builtIn: true, override: false)
        let client = FoodDataClientFactory.make(env: env)
        #expect(client is FoodDataCachedClient)
        guard let cachedClient = client as? FoodDataCachedClient else {
            #expect(Bool(false), "Expected FoodDataCachedClient")
            return
        }
        #expect(cachedClient.underlyingClientType is FoodDataClientAdapter)
    }

    @Test("Debug defaults to Mock")
    @MainActor
    func debug_defaults_to_mock() async throws {
        let env = makeEnv(isRelease: false, builtIn: false, override: false)
        let client = FoodDataClientFactory.make(env: env)
        #expect(client is FoodDataCachedClient)
        guard let cachedClient = client as? FoodDataCachedClient else {
            #expect(Bool(false), "Expected FoodDataCachedClient")
            return
        }
        #expect(cachedClient.underlyingClientType is FDCMock)
    }

    @Test("Debug runtime override → Proxy")
    @MainActor
    func debug_override_forces_proxy() async throws {
        let env = makeEnv(isRelease: false, builtIn: false, override: true)
        let client = FoodDataClientFactory.make(env: env)
        #expect(client is FoodDataCachedClient)
        guard let cachedClient = client as? FoodDataCachedClient else {
            #expect(Bool(false), "Expected FoodDataCachedClient")
            return
        }
        #expect(cachedClient.underlyingClientType is FoodDataClientAdapter)
    }

    @Test("Debug with build flag → Proxy")
    @MainActor
    func debug_with_build_flag_uses_proxy() async throws {
        let env = makeEnv(isRelease: false, builtIn: true, override: false)
        let client = FoodDataClientFactory.make(env: env)
        #expect(client is FoodDataCachedClient)
        guard let cachedClient = client as? FoodDataCachedClient else {
            #expect(Bool(false), "Expected FoodDataCachedClient")
            return
        }
        #expect(cachedClient.underlyingClientType is FoodDataClientAdapter)
    }

    // Optional: compact parameterized sweep over a few combos.
    private struct TestCase {
        let isRelease: Bool
        let builtIn: Bool
        let override: Bool
        let expectedProxy: Bool
    }

    @Test(
        "Selection Matrix (parameterized)",
        arguments: [
            TestCase(isRelease: true, builtIn: true, override: false, expectedProxy: true),
            TestCase(isRelease: false, builtIn: false, override: false, expectedProxy: false),
            TestCase(
                isRelease: false,
                builtIn: true,
                override: false,
                expectedProxy: true
            ), // Debug + build flag on
            TestCase(
                isRelease: false,
                builtIn: false,
                override: true,
                expectedProxy: true
            ), // Debug + runtime override
            TestCase(
                isRelease: true,
                builtIn: false,
                override: false,
                expectedProxy: true
            ) // Release defaults to proxy
        ]
    )
    @MainActor
    private func selection_matrix(
        _ testCase: TestCase
    ) async throws {
        let env = makeEnv(
            isRelease: testCase.isRelease,
            builtIn: testCase.builtIn,
            override: testCase.override
        )
        let client = FoodDataClientFactory.make(env: env)
        #expect(client is FoodDataCachedClient)
        guard let cachedClient = client as? FoodDataCachedClient else {
            #expect(Bool(false), "Expected FoodDataCachedClient")
            return
        }
        let isProxy = cachedClient.underlyingClientType is FoodDataClientAdapter
        #expect(isProxy == testCase.expectedProxy)
    }
}
