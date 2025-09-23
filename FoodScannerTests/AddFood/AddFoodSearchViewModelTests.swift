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
}
