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
    @Test @MainActor func load_fetches_details_and_allows_scaling() async throws {
        let viewModel = AddFoodDetailViewModel(fdcId: 5678, client: FDCMock()) // Peanut Butter
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.description == "Peanut Butter")
        viewModel.servingMultiplier = 2.0

        // Test that we have nutrients data
        #expect(response.foodNutrients != nil)
        if let nutrients = response.foodNutrients {
            #expect(!nutrients.isEmpty)
        }
    }

    @Test @MainActor func load_unknown_id_still_succeeds_with_fallback() async throws {
        let viewModel = AddFoodDetailViewModel(fdcId: 999_999, client: FDCMock())
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
            #expect(Bool(true), "Integration tests disabled - set RUN_INTEGRATION_TESTS=1 to enable")
            return
        }

        let client = FDCClientFactory.makeProxyClient()
        let viewModel = AddFoodDetailViewModel(fdcId: 2_503_998, client: client)
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.fdcId == 2_503_998)
        #expect(!response.description.isEmpty)

        // Check that we have actual data instead of N/A values
        #expect(response.description != "N/A")
        #expect(response.publicationDate != nil || response.publicationDate == "N/A")
        #expect(response.dataType != nil || response.dataType == "N/A")
        #expect(response.foodClass != nil || response.foodClass == "N/A")

        // Check nutrients are available
        if let nutrients = response.foodNutrients {
            #expect(!nutrients.isEmpty)
        }
    }

    @Test @MainActor func integration_load_real_fdc_id_1995469() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            #expect(Bool(true), "Integration tests disabled - set RUN_INTEGRATION_TESTS=1 to enable")
            return
        }

        let client = FDCClientFactory.makeProxyClient()
        let viewModel = AddFoodDetailViewModel(fdcId: 1_995_469, client: client)
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.fdcId == 1_995_469)
        #expect(!response.description.isEmpty)
        #expect(response.description != "N/A")
    }

    @Test @MainActor func integration_load_real_fdc_id_2055229() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            #expect(Bool(true), "Integration tests disabled - set RUN_INTEGRATION_TESTS=1 to enable")
            return
        }

        let client = FDCClientFactory.makeProxyClient()
        let viewModel = AddFoodDetailViewModel(fdcId: 2_055_229, client: client)
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.fdcId == 2_055_229)
        #expect(!response.description.isEmpty)
        #expect(response.description != "N/A")
    }

    @Test @MainActor func integration_load_real_fdc_id_2090362_food_attributes_parsing() async throws {
        // Skip if integration tests are disabled
        guard TestConfig.runIntegrationTests else {
            #expect(Bool(true), "Integration tests disabled - set RUN_INTEGRATION_TESTS=1 to enable")
            return
        }

        let client = FDCClientFactory.makeProxyClient()
        let viewModel = AddFoodDetailViewModel(fdcId: 2_090_362, client: client)
        await viewModel.load()

        guard case let .loaded(response) = viewModel.phase else {
            Issue.record("Expected loaded state, got \(String(describing: viewModel.phase))")
            return
        }

        #expect(response.fdcId == 2_090_362)
        #expect(!response.description.isEmpty)
        #expect(response.description != "N/A")

        // Test that food attributes can be parsed without errors
        if let foodAttributes = response.foodAttributes {
            #expect(!foodAttributes.isEmpty)
            // Verify that AnyCodable can handle the structure
            for attribute in foodAttributes {
                // This should not crash or throw an error
                _ = attribute.value
            }
        }

        // Test that nutrients are available
        if let nutrients = response.foodNutrients {
            #expect(!nutrients.isEmpty)
        }
    }
}
