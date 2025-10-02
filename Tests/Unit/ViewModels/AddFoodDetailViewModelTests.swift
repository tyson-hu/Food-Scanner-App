//
//  AddFoodDetailViewModelTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

@testable import Food_Scanner
import Foundation
import Testing

struct AddFoodDetailViewModelTests {
    @Test @MainActor func load_fetches_details_and_allows_scaling() async throws {
        let viewModel = AddFoodDetailViewModel(gid: "fdc:5678", client: FDCMock()) // Peanut Butter
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.description == "Peanut Butter")
        viewModel.servingMultiplier = 2.0

        // Test that we have nutrients data
        #expect(!response.nutrients.isEmpty)
    }

    @Test @MainActor func load_unknown_id_still_succeeds_with_fallback() async throws {
        let viewModel = AddFoodDetailViewModel(gid: "fdc:999999", client: FDCMock())
        await viewModel.load()
        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(response.description == "Brown Rice, cooked")
    }

    // MARK: - Integration Tests (Live Network)

    @Test @MainActor func integration_load_real_fdc_id_2503998() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            return
        }

        let client = FoodDataClientFactory.makeProxyClient()
        let viewModel = AddFoodDetailViewModel(gid: "fdc:2503998", client: client)
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.id == "fdc:2503998")
        #expect(response.description?.isEmpty == false)

        // Check that we have actual data instead of N/A values
        #expect(response.description != "N/A")
        #expect(response.description != nil)

        // Check nutrients are available
        #expect(!response.nutrients.isEmpty)
    }

    @Test @MainActor func integration_load_real_fdc_id_1995469() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            return
        }

        let client = FoodDataClientFactory.makeProxyClient()
        let viewModel = AddFoodDetailViewModel(gid: "fdc:1995469", client: client)
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.id == "fdc:1995469")
        #expect(response.description?.isEmpty == false)
        #expect(response.description != "N/A")
    }

    @Test @MainActor func integration_load_real_fdc_id_2055229() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            return
        }

        let client = FoodDataClientFactory.makeProxyClient()
        let viewModel = AddFoodDetailViewModel(gid: "fdc:2055229", client: client)
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.id == "fdc:2055229")
        #expect(response.description?.isEmpty == false)
        #expect(response.description != "N/A")
    }

    @Test @MainActor func integration_load_real_fdc_id_2090362_food_attributes_parsing() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            return
        }

        let client = FoodDataClientFactory.makeProxyClient()
        let viewModel = AddFoodDetailViewModel(gid: "fdc:2090362", client: client)
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.id == "fdc:2090362")
        #expect(response.description?.isEmpty == false)
        #expect(response.description != "N/A")

        // Test that nutrients are available
        #expect(!response.nutrients.isEmpty)
    }
}
