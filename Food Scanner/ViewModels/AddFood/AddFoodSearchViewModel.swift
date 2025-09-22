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
    private var searchTask: Task<Void, Never>?
    private var lastSearchQuery: String = ""
    
    // Tunables
    private let minQueryLength: Int
    private let debounceNanos: UInt64
    
    init(client: FDCClient, minQueryLength: Int = 2, debounceMs: UInt64 = 250) {
        self.client = client
        self.minQueryLength = minQueryLength
        self.debounceNanos = debounceMs * 1_000_000 // ms → ns
    }
    
    deinit {
        searchTask?.cancel()
    }
    
    @MainActor
    func onQueryChange() {
        // Cancel any existing search
        searchTask?.cancel()
        
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle empty query
        guard !trimmed.isEmpty else {
            results = []
            phase = .idle
            lastSearchQuery = ""
            return
        }
        
        // Skip if query is too short
        guard trimmed.count >= minQueryLength else {
            results = []
            phase = .idle
            lastSearchQuery = "" // Reset to allow re-querying when user types back
            return
        }
        
        // Skip duplicate work
        guard trimmed != lastSearchQuery else {
            return
        }
        
        // Start new search task with explicit capture
        searchTask = Task { [trimmed, weak self] in
            guard let self = self else { return }
            
            do {
                // Debounce delay
                try await Task.sleep(nanoseconds: self.debounceNanos)
                
                // Check cancellation after debounce
                try Task.checkCancellation()
                
                // Only set searching state if we don't have results (reduces flicker)
                await MainActor.run {
                    if self.results.isEmpty {
                        self.phase = .searching
                    }
                }
                
                // Perform the actual search
                try await self.performSearch(trimmed)
                
            } catch is CancellationError {
                // Task was cancelled, clear task reference
                await MainActor.run {
                    self.searchTask = nil
                }
                return
            } catch let urlError as URLError where urlError.code == .cancelled {
                // URLSession cancelled - treat as silent cancel
                await MainActor.run {
                    self.searchTask = nil
                }
                return
            } catch {
                // Handle other errors
                await MainActor.run {
                    self.phase = .error(error.localizedDescription)
                    self.searchTask = nil
                }
            }
        }
    }
    
    private func performSearch(_ q: String) async throws {
        let page1 = try await client.searchFoods(matching: q, page: 1)
        
        // Check cancellation after network call
        try Task.checkCancellation()
        
        await MainActor.run {
            self.results = page1
            self.phase = .results
            self.lastSearchQuery = q
            self.searchTask = nil
        }
    }
}
