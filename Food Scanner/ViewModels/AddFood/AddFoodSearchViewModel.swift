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
    @MainActor private var searchTask: Task<Void, Never>?
    private var lastSearchQuery: String = ""
    private var currentSearchId: Int = 0
    
    // Tunables
    private let minQueryLength: Int
    private let debounceNanos: UInt64
    
    init(client: FDCClient, minQueryLength: Int = 2, debounceMs: UInt64 = 250) {
        self.client = client
        self.minQueryLength = minQueryLength
        self.debounceNanos = debounceMs * 1_000_000 // ms → ns
    }
    
    deinit {
        Task { @MainActor in
            searchTask?.cancel()
        }
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
            lastSearchQuery = "" // Reset to allow re-querying when user types back
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
        
        // Increment search ID to track current search
        currentSearchId += 1
        let searchId = currentSearchId
        
        // Start new search task with explicit capture
        searchTask = Task { [trimmed, searchId, weak self] in
            guard let self = self else { return }
            
            do {
                // Debounce delay
                try await Task.sleep(nanoseconds: self.debounceNanos)
                
                // Check if this is still the current search (safe - only reading)
                let isCurrentSearch = await MainActor.run {
                    searchId == self.currentSearchId
                }
                guard isCurrentSearch else { return }
                
                // Check cancellation after debounce
                try Task.checkCancellation()
                
                // Only set searching state if we don't have results (reduces flicker)
                await MainActor.run {
                    if self.results.isEmpty {
                        self.phase = .searching
                    }
                }
                
                // Perform the actual search (now runs on background thread)
                try await self.performSearch(trimmed, searchId: searchId)
                
            } catch is CancellationError {
                // Task was cancelled, only clear if this is still the current search
                await MainActor.run {
                    if searchId == self.currentSearchId {
                        self.searchTask = nil
                    }
                }
                return
            } catch let urlError as URLError where urlError.code == .cancelled {
                // URLSession cancelled - treat as silent cancel
                await MainActor.run {
                    if searchId == self.currentSearchId {
                        self.searchTask = nil
                    }
                }
                return
            } catch {
                // Handle other errors
                await MainActor.run {
                    if searchId == self.currentSearchId {
                        self.phase = .error(error.localizedDescription)
                        self.searchTask = nil
                    }
                }
            }
        }
    }
    
    // This method now runs on background thread (no @MainActor)
    private func performSearch(_ q: String, searchId: Int) async throws {
        // Check if this is still the current search (safe - only reading)
        let isCurrentSearch = await MainActor.run {
            searchId == self.currentSearchId
        }
        guard isCurrentSearch else { return }
        
        // Network call now runs on background thread ✅
        let page1 = try await client.searchFoods(matching: q, page: 1)
        
        // Check if this is still the current search after network call (safe - only reading)
        let isStillCurrentSearch = await MainActor.run {
            searchId == self.currentSearchId
        }
        guard isStillCurrentSearch else { return }
        
        // Check cancellation after network call
        try Task.checkCancellation()
        
        // UI updates on main actor
        await MainActor.run {
            self.results = page1
            self.phase = .results
            self.lastSearchQuery = q
            self.searchTask = nil
        }
    }
}
