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

        // debounce(250ms) + mock latency(~150ms) headroom
        try? await Task.sleep(nanoseconds: 500_000_000)

        #expect(viewModel.phase == .results)
        #expect(viewModel.results.contains(where: { $0.id == 1234 }))
    }

    @Test @MainActor func clearing_query_resets_to_idle() async throws {
        let viewModel = AddFoodSearchViewModel(client: FDCMock())
        viewModel.query = "rice"
        viewModel.onQueryChange()
        try? await Task.sleep(nanoseconds: 500_000_000)
        #expect(viewModel.results.isEmpty == false)

        viewModel.query = ""
        viewModel.onQueryChange()
        #expect(viewModel.phase == .idle)
        #expect(viewModel.results.isEmpty)
    }

    @Test @MainActor func mock_client_handles_empty_query() async throws {
        let viewModel = AddFoodSearchViewModel(client: FDCMock())
        viewModel.query = ""
        viewModel.onQueryChange()

        #expect(viewModel.phase == .idle)
        #expect(viewModel.results.isEmpty)
    }

    @Test @MainActor func mock_client_handles_short_query() async throws {
        let viewModel = AddFoodSearchViewModel(client: FDCMock())
        viewModel.query = "a"
        viewModel.onQueryChange()

        #expect(viewModel.phase == .idle)
        #expect(viewModel.results.isEmpty)
    }

    // MARK: - Proxy Client Tests

    @Test @MainActor func proxy_client_search() async throws {
        let client = FDCClientFactory.makeProxyClient()
        let viewModel = AddFoodSearchViewModel(client: client)
        viewModel.query = "oatmeal"
        viewModel.onQueryChange()

        // Wait for network request
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Should either have results or be in error state
        #expect(viewModel.phase == .results || viewModel.phase == .error(""))
        if case .results = viewModel.phase {
            #expect(!viewModel.results.isEmpty)
            #expect(viewModel.results.first?.name.contains("OATMEAL") == true)
        }
    }

    @Test @MainActor func proxy_client_handles_network_error() async throws {
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
