//
//  AddFoodSearchViewModel.swift
//  Food Scanner
//
//  Created by Tyson Hu on 10/02/25.
//  Copyright © 2025 Tyson Hu. All rights reserved.
//

import Foundation
import Observation

@MainActor
@Observable
final class AddFoodSearchViewModel {
    enum Phase: Equatable {
        case idle
        case searching
        case results
        case error(String)
    }

    // MARK: - Observed State

    var query: String = ""
    var phase: Phase = .idle
    var genericResults: [FoodMinimalCard] = []
    var brandedResults: [FoodMinimalCard] = []

    // MARK: - Non-observed Dependencies & Internals

    @ObservationIgnored private let client: FoodDataClient
    @ObservationIgnored private var searchTask: Task<Void, Never>?
    @ObservationIgnored private var lastSearchQuery: String = ""
    @ObservationIgnored private var currentSearchId: Int = 0

    // Tunables
    @ObservationIgnored private let minQueryLength: Int
    @ObservationIgnored private let debounceNanos: UInt64

    // MARK: - Init / Deinit

    init(client: FoodDataClient, minQueryLength: Int = 2, debounceMs: UInt64 = 250) {
        self.client = client
        self.minQueryLength = minQueryLength
        debounceNanos = debounceMs * 1_000_000 // ms → ns
    }

    deinit {
        searchTask?.cancel()
    }

    // MARK: - Public API

    func onQueryChange() {
        // Cancel any existing search
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Handle empty or too-short query
        guard shouldProcessQuery(trimmed) else {
            resetToIdleState()
            return
        }

        // Skip duplicate work
        guard trimmed != lastSearchQuery else { return }

        startSearchTask(for: trimmed)
    }

    // MARK: - Private Helpers

    private func shouldProcessQuery(_ query: String) -> Bool {
        !query.isEmpty && query.count >= minQueryLength
    }

    private func resetToIdleState() {
        genericResults = []
        brandedResults = []
        phase = .idle
        lastSearchQuery = ""
    }

    private func startSearchTask(for query: String) {
        // Mark this as the current search
        currentSearchId += 1
        let searchId = currentSearchId

        // Launch an async task; this method is MainActor-isolated,
        // and we keep all state touches on MainActor.
        searchTask = Task { [query, searchId, weak self] in
            guard let self else { return }

            do {
                // Debounce
                try await Task.sleep(nanoseconds: debounceNanos)

                // Still the latest search?
                guard searchId == currentSearchId else { return }

                try Task.checkCancellation()

                if genericResults.isEmpty, brandedResults.isEmpty {
                    phase = .searching
                }

                try await performSearch(query, searchId: searchId)
            } catch is CancellationError {
                if searchId == currentSearchId {
                    searchTask = nil
                }
            } catch let urlError as URLError where urlError.code == .cancelled {
                if searchId == currentSearchId {
                    searchTask = nil
                }
            } catch {
                if searchId == currentSearchId {
                    print("[DEBUG] Search error for query '\(query)': \(error.localizedDescription)")
                    print("[DEBUG] Error type: \(type(of: error))")
                    if let foodDataError = error as? FoodDataError {
                        print("[DEBUG] FoodDataError case: \(foodDataError)")
                    }
                    phase = .error(error.localizedDescription)
                    searchTask = nil
                }
            }
        }
    }

    /// Performs the actual search. Runs under MainActor (class-isolated).
    /// Awaiting the network call does not block the main thread.
    private func performSearch(_ searchQuery: String, searchId: Int) async throws {
        // Verify we're still the current search
        guard searchId == currentSearchId else { return }

        print("[DEBUG] Starting search for query: '\(searchQuery)' with searchId: \(searchId)")

        // Network call (await suspends MainActor while URLSession works off-main)
        let searchResponse = try await client.searchFoods(query: searchQuery, limit: 25)

        // Still current after the call?
        guard searchId == currentSearchId else {
            print("[DEBUG] Search cancelled - searchId \(searchId) no longer current (\(currentSearchId))")
            return
        }

        try Task.checkCancellation()

        print(
            "[DEBUG] Search completed successfully - generic: \(searchResponse.generic.count), branded: \(searchResponse.branded.count)"
        )

        // Update UI state with separated results
        genericResults = searchResponse.generic
        brandedResults = searchResponse.branded
        phase = .results
        lastSearchQuery = searchQuery
        searchTask = nil
    }
}
