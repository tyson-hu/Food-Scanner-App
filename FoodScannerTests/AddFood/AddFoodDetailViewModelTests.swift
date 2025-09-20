//
//  AddFoodDetailViewModelTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation
import Testing
@testable import Food_Scanner

struct AddFoodDetailViewModelTests {
    
    @Test func load_fetches_details_and_allows_scaling() async throws {
        let vm = AddFoodDetailViewModel(fdcId: 5678, client: FDCMock()) // Peanut Butter
        await vm.load()
        
        guard case .loaded(let d) = vm.phase else {
            Issue.record("Expected loaded state, got \(String(describing: vm.phase))")
            return
        }
        
        #expect(d.name == "Peanut Butter")
        vm.servingMultiplier = 2.0
        #expect(vm.scaled(d.protein) == 14)  // 7 * 2
        #expect(vm.scaled(d.calories) == 380)
    }
    
    @Test func load_unknown_id_still_succeeds_with_fallback() async throws {
        let vm = AddFoodDetailViewModel(fdcId: 999_999, client: FDCMock())
        await vm.load()
        guard case .loaded(let d) = vm.phase else {
            Issue.record("Expected loaded state")
            return
        }
        #expect(d.name == "Brown Rice, cooked")
    }
}
