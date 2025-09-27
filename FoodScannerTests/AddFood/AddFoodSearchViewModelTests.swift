//
//  AddFoodSearchViewModelTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

@testable import Food_Scanner
import Foundation
import Testing

struct AddFoodSearchViewModelTests {
    // MARK: - Mock Client Tests (Fast, Reliable)

    @Test @MainActor func typing_query_debounces_and_populates_results() async throws {
        let viewModel = AddFoodSearchViewModel(client: FDCMock())
        viewModel.query = "yogurt"
        viewModel.onQueryChange()

        // Wait for debounce (250ms) + mock latency (200ms) + extra headroom
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        #expect(viewModel.phase == .results)
        #expect(
            viewModel.genericResults.contains(where: { $0.id == "fdc:1234" }) || viewModel.brandedResults
                .contains(where: { $0.id == "fdc:1234" }),
        )
    }

    @Test @MainActor func clearing_query_resets_to_idle() async throws {
        let viewModel = AddFoodSearchViewModel(client: FDCMock())
        viewModel.query = "rice"
        viewModel.onQueryChange()

        // Wait for search to complete
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        #expect(viewModel.genericResults.isEmpty == false || viewModel.brandedResults.isEmpty == false)

        viewModel.query = ""
        viewModel.onQueryChange()
        #expect(viewModel.phase == .idle)
        #expect(viewModel.genericResults.isEmpty && viewModel.brandedResults.isEmpty)
    }

    @Test @MainActor func mock_client_handles_empty_query() async throws {
        let viewModel = AddFoodSearchViewModel(client: FDCMock())
        viewModel.query = ""
        viewModel.onQueryChange()

        #expect(viewModel.phase == .idle)
        #expect(viewModel.genericResults.isEmpty && viewModel.brandedResults.isEmpty)
    }

    @Test @MainActor func mock_client_handles_short_query() async throws {
        let viewModel = AddFoodSearchViewModel(client: FDCMock())
        viewModel.query = "a"
        viewModel.onQueryChange()

        #expect(viewModel.phase == .idle)
        #expect(viewModel.genericResults.isEmpty && viewModel.brandedResults.isEmpty)
    }

    // MARK: - Integration Tests (Live Network)

    @Test @MainActor func integration_proxy_client_search() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            return
        }

        let client = FDCClientFactory.makeProxyClient()
        let viewModel = AddFoodSearchViewModel(client: client)
        viewModel.query = "oatmeal"
        viewModel.onQueryChange()

        // Wait for network request
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Should either have results or be in error state
        #expect(viewModel.phase == .results || viewModel.phase == .error(""))
        if case .results = viewModel.phase {
            #expect(!viewModel.genericResults.isEmpty || !viewModel.brandedResults.isEmpty)
            let allResults = viewModel.genericResults + viewModel.brandedResults
            #expect(allResults.first?.description?.contains("OATMEAL") == true)
        }
    }

    @Test @MainActor func integration_proxy_client_handles_network_error() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            return
        }

        // Use an invalid URL to simulate network error
        guard let invalidURL = URL(string: "https://invalid-url-for-testing.com") else {
            #expect(Bool(false), "Failed to create invalid URL")
            return
        }
        let client = FDCClientFactory.makeProxyClient(baseURL: invalidURL)
        let viewModel = AddFoodSearchViewModel(client: client)
        viewModel.query = "apple"
        viewModel.onQueryChange()

        // Wait for network request
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Should be in error state with a network error message
        if case let .error(message) = viewModel.phase {
            #expect(!message.isEmpty)
        } else {
            #expect(Bool(false), "Expected error state but got: \(viewModel.phase)")
        }
    }
}
