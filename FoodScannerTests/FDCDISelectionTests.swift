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
        apiKey: String?
    ) -> AppLaunchEnvironment {
        .init(
            isRelease: isRelease,
            buildDefaultRemote: builtIn,
            runtimeOverrideRemote: override,
            apiKey: apiKey
        )
    }

    @Test("Release defaults to Remote when API key present")
    func release_defaults_remote_with_key() async throws {
        let env = makeEnv(isRelease: true, builtIn: true, override: false, apiKey: "k")
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCRemoteClient)
    }

    @Test("Debug defaults to Mock (even if key present)")
    func debug_defaults_mock_even_with_key() async throws {
        let env = makeEnv(isRelease: false, builtIn: false, override: false, apiKey: "k")
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCMock)
    }

    @Test("Debug runtime override → Remote when API key present")
    func debug_override_forces_remote_with_key() async throws {
        let env = makeEnv(isRelease: false, builtIn: false, override: true, apiKey: "k")
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCRemoteClient)
    }

    @Test("Fallback to Mock when Remote wanted but API key missing")
    func fallback_to_mock_when_key_missing() async throws {
        let env = makeEnv(isRelease: true, builtIn: true, override: true, apiKey: nil)
        let client = FDCClientFactory.make(env: env)
        #expect(client is FDCMock)
    }

    // Optional: compact parameterized sweep over a few combos.
    private struct TestCase {
        let isRelease: Bool
        let builtIn: Bool
        let override: Bool
        let apiKey: String?
        let expectedRemote: Bool
    }

    @Test(
        "Selection Matrix (parameterized)",
        arguments: [
            TestCase(isRelease: true, builtIn: true, override: false, apiKey: "k", expectedRemote: true),
            TestCase(isRelease: false, builtIn: false, override: false, apiKey: "k", expectedRemote: false),
            TestCase(
                isRelease: false,
                builtIn: true,
                override: false,
                apiKey: "k",
                expectedRemote: true
            ), // Debug + build flag on
            TestCase(
                isRelease: false,
                builtIn: true,
                override: true,
                apiKey: "",
                expectedRemote: false
            ), // Override on but empty key → fallback
            TestCase(
                isRelease: true,
                builtIn: false,
                override: false,
                apiKey: nil,
                expectedRemote: false
            ), // Release wants remote by default, but no key → fallback
        ]
    )
    private func selection_matrix(
        _ testCase: TestCase
    ) async throws {
        let env = makeEnv(
            isRelease: testCase.isRelease,
            builtIn: testCase.builtIn,
            override: testCase.override,
            apiKey: testCase.apiKey
        )
        let client = FDCClientFactory.make(env: env)
        let isRemote = client is FDCRemoteClient
        #expect(isRemote == testCase.expectedRemote)
    }
}
