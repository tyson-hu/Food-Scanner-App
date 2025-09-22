//
//  AddFoodSearchViewModelTests.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation
import Testing
@testable import Food_Scanner

struct AddFoodSearchViewModelTests {
    
    @Test func typing_query_debounces_and_populates_results() async throws {
        let vm = AddFoodSearchViewModel(client: FDCMock())
        vm.query = "yogurt"
        await MainActor.run {
            vm.onQueryChange()
        }
        
        // debounce(250ms) + mock latency(~150ms) headroom
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        #expect(vm.phase == .results)
        #expect(vm.results.contains(where: { $0.id == 1234 }))
    }
    
    @Test func clearing_query_resets_to_idle() async throws {
        let vm = AddFoodSearchViewModel(client: FDCMock())
        vm.query = "rice"
        await MainActor.run {
            vm.onQueryChange()
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
        #expect(vm.results.isEmpty == false)
        
        vm.query = ""
        await MainActor.run {
            vm.onQueryChange()
        }
        #expect(vm.phase == .idle)
        #expect(vm.results.isEmpty)
    }
}
