//
//  AddFoodSearchViewModel.swift
//  Food Scanner
//
//  Created by Tyson Hu on 9/19/25.
//

import Foundation
import Observation

@Observable
final class AddFoodSearchViewModel {
    enum Phase: Equatable { case idle, searching, results, error(String) }
    
    var query: String = ""
    var phase: Phase = .idle
    var results: [FDCFoodSummary] = []
    
    private let client: FDCClient
    private var task: Task<Void, Never>?
    
    init(client: FDCClient) {
        self.client = client
    }
    
    func onQueryChange() {
        task?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []; phase = .idle; return
        }
        phase = .searching
        task = Task { [trimmed] in
            try? await Task.sleep(nanoseconds: 250_000_000) // debounce
            await self.performSearch(trimmed)
        }
    }
    
    @MainActor
    private func performSearch(_ q: String) async {
        do {
            let page1 = try await client.searchFoods(matching: q, page: 1)
            self.results = page1
            self.phase = .results
        } catch {
            self.phase = .error(error.localizedDescription)
        }
    }
}
