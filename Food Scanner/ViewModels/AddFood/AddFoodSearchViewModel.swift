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
    // Not main-actor isolated so deinit can cancel safely. All other mutations occur on MainActor.
    private var searchTask: Task<Void, Never>?
    private var lastSearchQuery: String = ""
    private var currentSearchId: Int = 0

    // Tunables
    private let minQueryLength: Int
    private let debounceNanos: UInt64

    init(client: FDCClient, minQueryLength: Int = 2, debounceMs: UInt64 = 250) {
        self.client = client
        self.minQueryLength = minQueryLength
        debounceNanos = debounceMs * 1_000_000 // ms → ns
    }

    deinit {
        searchTask?.cancel()
    }

    @MainActor
    func onQueryChange() {
        // Cancel any existing search
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle empty or invalid query
        guard shouldProcessQuery(trimmed) else {
            resetToIdleState()
            return
        }

        // Skip duplicate work
        guard trimmed != lastSearchQuery else {
            return
        }

        startSearchTask(for: trimmed)
    }

    // MARK: - Private Helper Methods

    @MainActor
    private func shouldProcessQuery(_ query: String) -> Bool {
        !query.isEmpty && query.count >= minQueryLength
    }

    @MainActor
    private func resetToIdleState() {
        results = []
        phase = .idle
        lastSearchQuery = "" // Reset to allow re-querying when user types back
    }

    @MainActor
    private func startSearchTask(for query: String) {
        // Increment search ID to track current search
        currentSearchId += 1
        let searchId = currentSearchId

        // Start new search task with explicit capture
        searchTask = Task { [query, searchId, weak self] in
            guard let self else { return }

            do {
                // Debounce delay
                try await Task.sleep(nanoseconds: debounceNanos)

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
                try await performSearch(query, searchId: searchId)

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
    private func performSearch(_ searchQuery: String, searchId: Int) async throws {
        // Check if this is still the current search (safe - only reading)
        let isCurrentSearch = await MainActor.run {
            searchId == self.currentSearchId
        }
        guard isCurrentSearch else { return }

        // Network call now runs on background thread ✅
        let page1 = try await client.searchFoods(matching: searchQuery, page: 1)

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
            self.lastSearchQuery = searchQuery
            self.searchTask = nil
        }
    }
}
