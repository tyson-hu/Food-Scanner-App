//
//  FDCDISelectionTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/21/25.
//

import Testing
@testable import Food_Scanner

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
    @Test(
        "Selection Matrix (parameterized)",
        arguments: [
            // isRelease, builtIn, override, apiKey, expectedRemote
            (true,  true,  false, "k", true),
            (false, false, false, "k", false),
            (false, true,  false, "k", true),   // Debug + build flag on
            (false, true,  true,  "",  false),  // Override on but empty key → fallback
            (true,  false, false, nil, false),  // Release wants remote by default, but no key → fallback
        ]
    )
    func selection_matrix(
        _ args: (Bool, Bool, Bool, String?, Bool)
    ) async throws {
        let env = makeEnv(
            isRelease: args.0,
            builtIn: args.1,
            override: args.2,
            apiKey: args.3
        )
        let client = FDCClientFactory.make(env: env)
        let isRemote = client is FDCRemoteClient
        #expect(isRemote == args.4)
    }
}
