//
//  AddFoodDetailViewModelTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

@testable import Food_Scanner
import Foundation
import Testing

struct AddFoodDetailViewModelTests {
    @Test func load_fetches_details_and_allows_scaling() async throws {
        let viewModel = AddFoodDetailViewModel(fdcId: 5678, client: FDCMock()) // Peanut Butter
        await viewModel.load()

        guard case let .loaded(details) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(details.name == "Peanut Butter")
        viewModel.servingMultiplier = 2.0
        #expect(viewModel.scaled(details.protein) == 14) // 7 * 2
        #expect(viewModel.scaled(details.calories) == 380)
    }

    @Test func load_unknown_id_still_succeeds_with_fallback() async throws {
        let viewModel = AddFoodDetailViewModel(fdcId: 999_999, client: FDCMock())
        await viewModel.load()
        guard case let .loaded(details) = viewModel.phase else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(details.name == "Brown Rice, cooked")
    }
}
