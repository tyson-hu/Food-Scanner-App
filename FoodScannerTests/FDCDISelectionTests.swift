//
//  FDCDISelectionTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/21/25.
//

@testable import Food_Scanner
import Testing

@Suite("FDC Dependency Injection — Selection Matrix")
struct FDCDISelectionTests {
    // Helper to construct a launch environment without touching process state.
    private func makeEnv(
        isRelease: Bool,
        builtIn: Bool,
        override: Bool,
    ) -> AppLaunchEnvironment {
        .init(
            isRelease: isRelease,
            buildDefaultRemote: builtIn,
            runtimeOverrideRemote: override,
        )
    }

    @Test("Release defaults to Proxy")
    @MainActor
    func release_defaults_to_proxy() async throws {
        let env = makeEnv(isRelease: true, builtIn: true, override: false)
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCCachedClient)
        guard let cachedClient = client as? FDCCachedClient else {
            #expect(Bool(false), "Expected FDCCachedClient")
            return
        }
        #expect(cachedClient.underlyingClientType is FDCProxyClient)
    }

    @Test("Debug defaults to Mock")
    @MainActor
    func debug_defaults_to_mock() async throws {
        let env = makeEnv(isRelease: false, builtIn: false, override: false)
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCCachedClient)
        guard let cachedClient = client as? FDCCachedClient else {
            #expect(Bool(false), "Expected FDCCachedClient")
            return
        }
        #expect(cachedClient.underlyingClientType is FDCMock)
    }

    @Test("Debug runtime override → Proxy")
    @MainActor
    func debug_override_forces_proxy() async throws {
        let env = makeEnv(isRelease: false, builtIn: false, override: true)
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCCachedClient)
        guard let cachedClient = client as? FDCCachedClient else {
            #expect(Bool(false), "Expected FDCCachedClient")
            return
        }
        #expect(cachedClient.underlyingClientType is FDCProxyClient)
    }

    @Test("Debug with build flag → Proxy")
    @MainActor
    func debug_with_build_flag_uses_proxy() async throws {
        let env = makeEnv(isRelease: false, builtIn: true, override: false)
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCCachedClient)
        guard let cachedClient = client as? FDCCachedClient else {
            #expect(Bool(false), "Expected FDCCachedClient")
            return
        }
        #expect(cachedClient.underlyingClientType is FDCProxyClient)
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
                expectedProxy: true,
            ), // Debug + build flag on
            TestCase(
                isRelease: false,
                builtIn: false,
                override: true,
                expectedProxy: true,
            ), // Debug + runtime override
            TestCase(
                isRelease: true,
                builtIn: false,
                override: false,
                expectedProxy: true,
            ), // Release defaults to proxy
        ],
    )
    @MainActor
    private func selection_matrix(
        _ testCase: TestCase,
    ) async throws {
        let env = makeEnv(
            isRelease: testCase.isRelease,
            builtIn: testCase.builtIn,
            override: testCase.override,
        )
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCCachedClient)
        guard let cachedClient = client as? FDCCachedClient else {
            #expect(Bool(false), "Expected FDCCachedClient")
            return
        }
        let isProxy = cachedClient.underlyingClientType is FDCProxyClient
        #expect(isProxy == testCase.expectedProxy)
    }
}
